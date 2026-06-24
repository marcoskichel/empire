#!/usr/bin/env bash
#
# pr-stack.sh — maintain the "PR stack" comment across a chain of stacked PRs.
#
# Builds the chain from the live GitHub PR graph (each PR's base branch linked
# to another PR's head branch), unions it with the membership recorded in any
# existing stack comment (so merged PRs whose head branch was deleted stay in
# the list), then upserts one marker comment on every open PR in the chain —
# each highlighting itself with "← this PR". Merged rows render struck-through
# with a check. When the chain is no longer meaningful (a lone PR against the
# default branch with no merged siblings), the stale comment is removed.
#
# Usage:
#   pr-stack.sh [--pr <number>] [--repo <owner/repo>] [--dry-run]
#
#   --pr      PR to anchor on. Default: the PR for the current branch.
#   --repo    owner/repo. Default: detected from the current repo.
#   --dry-run Print the rendered comment(s) and planned actions; mutate nothing.

set -euo pipefail

# ---- output helpers ---------------------------------------------------------
if [ -t 1 ]; then
  BLUE=$'\033[1;34m'
  YELLOW=$'\033[1;33m'
  RED=$'\033[1;31m'
  GREEN=$'\033[1;32m'
  RESET=$'\033[0m'
else
  BLUE=''
  YELLOW=''
  RED=''
  GREEN=''
  RESET=''
fi
info() { printf '%s==>%s %s\n' "$BLUE" "$RESET" "$*"; }
warn() { printf '%s==>%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die() {
  printf '%s==>%s %s\n' "$RED" "$RESET" "$*" >&2
  exit 1
}
success() { printf '%s==>%s %s\n' "$GREEN" "$RESET" "$*"; }

MARKER='<!-- empire:pr-stack'
MAX_DEPTH=50

# ---- args -------------------------------------------------------------------
PR=''
REPO=''
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --pr)
      PR="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *) die "Unknown argument: $1" ;;
  esac
done

command -v gh >/dev/null 2>&1 || die "gh CLI not found."
command -v jq >/dev/null 2>&1 || die "jq not found."

# ---- resolve repo + default branch + target PR ------------------------------
if [ -z "$REPO" ]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)" || die "Not in a GitHub repo (pass --repo)."
fi
DEFAULT_BRANCH="$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)"

if [ -z "$PR" ]; then
  PR="$(gh pr view --repo "$REPO" --json number -q .number 2>/dev/null)" \
    || die "No PR for the current branch. Pass --pr <number>."
fi

# ---- load open PRs ----------------------------------------------------------
OPEN_JSON="$(gh pr list --repo "$REPO" --state open --limit 300 \
  --json number,title,url,headRefName,baseRefName,state)"

base_of() { jq -r --argjson n "$1" '.[] | select(.number==$n) | .baseRefName' <<<"$OPEN_JSON"; }
head_of() { jq -r --argjson n "$1" '.[] | select(.number==$n) | .headRefName' <<<"$OPEN_JSON"; }
by_head() { jq -r --arg h "$1" 'first(.[] | select(.headRefName==$h) | .number) // empty' <<<"$OPEN_JSON"; }
child_of() { jq -r --arg h "$1" 'first(.[] | select(.baseRefName==$h) | .number) // empty' <<<"$OPEN_JSON"; }
is_open() { jq -e --argjson n "$1" 'any(.[]; .number==$n)' <<<"$OPEN_JSON" >/dev/null; }

# ---- build the live chain around the target PR ------------------------------
above=()
below=()
cur="$PR"
depth=0
while :; do
  parent="$(by_head "$(base_of "$cur")")"
  [ -n "$parent" ] || break
  above=("$parent" "${above[@]}")
  cur="$parent"
  depth=$((depth + 1))
  [ "$depth" -ge "$MAX_DEPTH" ] && break
done
cur="$PR"
depth=0
while :; do
  child="$(child_of "$(head_of "$cur")")"
  [ -n "$child" ] || break
  below+=("$child")
  cur="$child"
  depth=$((depth + 1))
  [ "$depth" -ge "$MAX_DEPTH" ] && break
done
live_chain=("${above[@]}" "$PR" "${below[@]}")

# ---- read stored membership + comment id from open chain members ------------
declare -A COMMENT_ID
STORED=''
comment_info() { # repo n -> sets REPLY_ID, REPLY_MEMBERS
  local body id members
  body="$(gh api "repos/$1/issues/$2/comments" --paginate \
    -q ".[] | select(.body|startswith(\"$MARKER\")) | {id,body}" 2>/dev/null | jq -s 'first // empty')"
  if [ -z "$body" ]; then
    REPLY_ID=''
    REPLY_MEMBERS=''
    return
  fi
  id="$(jq -r '.id' <<<"$body")"
  members="$(jq -r '.body' <<<"$body" | sed -n 's/.*members=\([0-9,]*\).*/\1/p' | head -1)"
  REPLY_ID="$id"
  REPLY_MEMBERS="$members"
}

for n in "${live_chain[@]}"; do
  comment_info "$REPO" "$n"
  [ -n "$REPLY_ID" ] && COMMENT_ID[$n]="$REPLY_ID"
  # keep the longest stored membership found (most complete history)
  if [ -n "$REPLY_MEMBERS" ]; then
    cur_len=$(awk -F, '{print NF}' <<<"$REPLY_MEMBERS")
    best_len=$([ -n "$STORED" ] && awk -F, '{print NF}' <<<"$STORED" || echo 0)
    [ "$cur_len" -gt "$best_len" ] && STORED="$REPLY_MEMBERS"
  fi
done

# ---- membership = stored order ∪ live chain (preserve order, append new tips)
members=()
if [ -n "$STORED" ]; then
  IFS=',' read -ra members <<<"$STORED"
fi
in_members() {
  local x="$1" m
  for m in "${members[@]:-}"; do [ "$m" = "$x" ] && return 0; done
  return 1
}
for n in "${live_chain[@]}"; do in_members "$n" || members+=("$n"); done

# ---- resolve state/title/url for every member ------------------------------
declare -A STATE TITLE URL
for n in "${members[@]}"; do
  if is_open "$n"; then
    STATE[$n]=OPEN
    TITLE[$n]="$(jq -r --argjson n "$n" '.[] | select(.number==$n) | .title' <<<"$OPEN_JSON")"
    URL[$n]="$(jq -r --argjson n "$n" '.[] | select(.number==$n) | .url' <<<"$OPEN_JSON")"
  else
    if meta="$(gh pr view "$n" --repo "$REPO" --json state,title,url 2>/dev/null)"; then
      STATE[$n]="$(jq -r '.state' <<<"$meta")"
      TITLE[$n]="$(jq -r '.title' <<<"$meta")"
      URL[$n]="$(jq -r '.url' <<<"$meta")"
    else
      continue
    fi
  fi
done

# drop members that failed to resolve
resolved=()
for n in "${members[@]}"; do [ -n "${STATE[$n]:-}" ] && resolved+=("$n"); done
members=("${resolved[@]}")

open_members=()
merged_count=0
for n in "${members[@]}"; do
  [ "${STATE[$n]}" = OPEN ] && open_members+=("$n")
  [ "${STATE[$n]}" = MERGED ] && merged_count=$((merged_count + 1))
done

# ---- chain meaningfulness ---------------------------------------------------
# Active while ≥2 PRs are open, OR ≥1 open rides on ≥1 merged sibling.
ACTIVE=0
if [ "${#open_members[@]}" -ge 2 ] || { [ "${#open_members[@]}" -ge 1 ] && [ "$merged_count" -ge 1 ]; }; then
  ACTIVE=1
fi

# ---- render the comment body for a given "current" PR -----------------------
render_body() {
  local current="$1" m t u s row
  printf '%s v=1 members=%s -->\n' "$MARKER" "$(
    IFS=,
    echo "${members[*]}"
  )"
  printf '### PR stack\n\n| PR |\n| --- |\n'
  for m in "${members[@]}"; do
    t="${TITLE[$m]//|/\\|}"
    u="${URL[$m]}"
    s="${STATE[$m]}"
    if [ "$m" = "$current" ]; then
      row="**[$t]($u) ← this PR**"
    elif [ "$s" = MERGED ]; then
      row="~~[$t]($u)~~ ✅"
    elif [ "$s" = CLOSED ]; then
      row="~~[$t]($u)~~"
    else
      row="[$t]($u)"
    fi
    printf '| %s |\n' "$row"
  done
}

upsert() { # repo n body
  local repo="$1" n="$2" body="$3" id="${COMMENT_ID[$2]:-}"
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] would ${id:+update}${id:-create} stack comment on #$n"
    printf '%s\n---\n' "$body"
    return
  fi
  if [ -n "$id" ]; then
    jq -n --arg b "$body" '{body:$b}' | gh api -X PATCH "repos/$repo/issues/comments/$id" --input - >/dev/null
    success "updated stack comment on #$n"
  else
    jq -n --arg b "$body" '{body:$b}' | gh api "repos/$repo/issues/$n/comments" --input - >/dev/null
    success "created stack comment on #$n"
  fi
}

remove_comment() { # repo n
  local repo="$1" n="$2" id="${COMMENT_ID[$2]:-}"
  [ -n "$id" ] || return 0
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] would remove stale stack comment on #$n"
    return
  fi
  gh api -X DELETE "repos/$repo/issues/comments/$id" >/dev/null
  success "removed stale stack comment on #$n"
}

# ---- act --------------------------------------------------------------------
if [ "$ACTIVE" = 1 ]; then
  info "Chain: ${#members[@]} PR(s), ${#open_members[@]} open, $merged_count merged."
  for n in "${open_members[@]}"; do
    # ensure we have the comment id for open members discovered via stored membership
    if [ -z "${COMMENT_ID[$n]:-}" ]; then
      comment_info "$REPO" "$n"
      [ -n "$REPLY_ID" ] && COMMENT_ID[$n]="$REPLY_ID"
    fi
    upsert "$REPO" "$n" "$(render_body "$n")"
  done
else
  info "Not a stack (single PR against $DEFAULT_BRANCH, no merged siblings). Cleaning up."
  for n in "${open_members[@]}"; do
    if [ -z "${COMMENT_ID[$n]:-}" ]; then
      comment_info "$REPO" "$n"
      [ -n "$REPLY_ID" ] && COMMENT_ID[$n]="$REPLY_ID"
    fi
    remove_comment "$REPO" "$n"
  done
fi
