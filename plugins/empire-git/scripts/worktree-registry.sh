#!/usr/bin/env bash
# worktree-registry.sh — Per-session registry of active worktrees.
# Part of the empire-git Claude Code plugin.
#
# Storage: ~/.claude/sessions/<session_id>/active-worktrees.json
# Session id source: $CLAUDE_CODE_SESSION_ID (falls back to "unknown" with warning).
#
# Subcommands:
#   add <branch> <path> --base <base> --repo-root <root>
#   remove <path>
#   list [--json]
#   prune
#   has <path>

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() {
  printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2
  exit 1
}

warn() {
  printf '\033[1;33mWARN:\033[0m %s\n' "$1" >&2
}

iso_utc_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

session_id() {
  if [[ -n "${CLAUDE_CODE_SESSION_ID:-}" ]]; then
    printf '%s' "$CLAUDE_CODE_SESSION_ID"
  else
    warn "CLAUDE_CODE_SESSION_ID not set — using 'unknown' namespace (best-effort, not authoritative)"
    printf '%s' 'unknown'
  fi
}

registry_file() {
  local sid
  sid="$(session_id)"
  printf '%s/.claude/sessions/%s/active-worktrees.json' "$HOME" "$sid"
}

atomic_write() {
  local file="$1"
  local content="$2"
  local tmp
  tmp="${file}.tmp.$$"
  printf '%s' "$content" >"$tmp"
  mv "$tmp" "$file"
}

ensure_registry() {
  local file="$1"
  local dir sid empty
  dir="$(dirname "$file")"
  mkdir -p "$dir"
  sid="$(basename "$dir")"
  if [[ ! -f "$file" ]]; then
    empty="$(jq -n --arg sid "$sid" --arg now "$(iso_utc_now)" \
      '{session_id: $sid, updated_at: $now, worktrees: []}')"
    atomic_write "$file" "$empty"
    return
  fi
  if ! jq -e . "$file" >/dev/null 2>&1; then
    warn "Registry file malformed — resetting: $file"
    empty="$(jq -n --arg sid "$sid" --arg now "$(iso_utc_now)" \
      '{session_id: $sid, updated_at: $now, worktrees: []}')"
    atomic_write "$file" "$empty"
  fi
}

LOCK_DIR=""
acquire_lock() {
  local file="$1"
  LOCK_DIR="${file}.lock"
  mkdir -p "$(dirname "$LOCK_DIR")"
  local attempts=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    attempts=$((attempts + 1))
    local lock_mtime now age
    lock_mtime=$(stat -f %m "$LOCK_DIR" 2>/dev/null || stat -c %Y "$LOCK_DIR" 2>/dev/null || true)
    if [[ -n "$lock_mtime" ]]; then
      now=$(date +%s)
      age=$((now - lock_mtime))
      if [[ "$age" -gt 30 ]]; then
        warn "Reclaiming stale registry lock (${age}s old)"
        rm -rf "$LOCK_DIR"
        continue
      fi
    fi
    if [[ "$attempts" -gt 300 ]]; then
      die "Could not acquire registry lock after 300 attempts: $LOCK_DIR"
    fi
    sleep 0.1
  done
  trap release_lock EXIT
}

release_lock() {
  [[ -n "$LOCK_DIR" && -d "$LOCK_DIR" ]] && rm -rf "$LOCK_DIR"
  LOCK_DIR=""
}

require_jq() {
  command -v jq >/dev/null 2>&1 || die "jq is required but not installed (brew install jq)"
}

# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------

cmd_add() {
  local branch="" path="" base="" repo_root=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --base)
        base="$2"
        shift 2
        ;;
      --repo-root)
        repo_root="$2"
        shift 2
        ;;
      -*) die "Unknown option: $1" ;;
      *)
        if [[ -z "$branch" ]]; then
          branch="$1"
        elif [[ -z "$path" ]]; then
          path="$1"
        else
          die "Unexpected argument: $1"
        fi
        shift
        ;;
    esac
  done
  [[ -z "$branch" || -z "$path" || -z "$base" || -z "$repo_root" ]] \
    && die "Usage: add <branch> <path> --base <base> --repo-root <root>"

  require_jq
  local file
  file="$(registry_file)"
  mkdir -p "$(dirname "$file")"
  acquire_lock "$file"
  ensure_registry "$file"

  local now
  now="$(iso_utc_now)"
  local updated
  updated="$(jq \
    --arg branch "$branch" \
    --arg path "$path" \
    --arg base "$base" \
    --arg repo_root "$repo_root" \
    --arg now "$now" \
    '
      .updated_at = $now
      | (.worktrees | map(.path) | index($path)) as $idx
      | if $idx == null then
          .worktrees += [{
            branch: $branch,
            path: $path,
            base: $base,
            repo_root: $repo_root,
            created_at: $now,
            opened_at: $now
          }]
        else
          .worktrees[$idx].opened_at = $now
          | .worktrees[$idx].branch = $branch
          | .worktrees[$idx].base = $base
          | .worktrees[$idx].repo_root = $repo_root
        end
      | .worktrees |= sort_by(.created_at)
    ' "$file")"

  atomic_write "$file" "$updated"
  release_lock
}

cmd_remove() {
  local path="${1:-}"
  [[ -z "$path" ]] && die "Usage: remove <path>"
  require_jq

  local file
  file="$(registry_file)"
  [[ -f "$file" ]] || return 0
  acquire_lock "$file"
  ensure_registry "$file"

  local updated
  updated="$(jq \
    --arg path "$path" \
    --arg now "$(iso_utc_now)" \
    '.updated_at = $now | .worktrees |= map(select(.path != $path))' \
    "$file")"

  atomic_write "$file" "$updated"
  release_lock
}

cmd_list() {
  require_jq
  local file
  file="$(registry_file)"
  [[ -f "$file" ]] || return 0

  if [[ "${1:-}" == "--json" ]]; then
    cat "$file"
  else
    jq -r '.worktrees | sort_by(.created_at) | .[].path' "$file"
  fi
}

cmd_prune() {
  require_jq
  local file
  file="$(registry_file)"
  [[ -f "$file" ]] || return 0
  acquire_lock "$file"
  ensure_registry "$file"

  local survivors="[]"
  while IFS= read -r entry; do
    local p
    p="$(printf '%s' "$entry" | jq -r '.path')"
    if [[ -d "$p" ]]; then
      survivors="$(jq --argjson e "$entry" '. + [$e]' <<<"$survivors")"
    fi
  done < <(jq -c '.worktrees[]' "$file" 2>/dev/null || true)

  local updated
  updated="$(jq \
    --argjson survivors "$survivors" \
    --arg now "$(iso_utc_now)" \
    '.updated_at = $now | .worktrees = $survivors' "$file")"

  atomic_write "$file" "$updated"
  release_lock
}

cmd_has() {
  local path="${1:-}"
  [[ -z "$path" ]] && die "Usage: has <path>"
  require_jq
  local file
  file="$(registry_file)"
  [[ -f "$file" ]] || exit 1
  jq -e --arg path "$path" '.worktrees | map(.path) | index($path) != null' \
    "$file" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Dispatcher
# ---------------------------------------------------------------------------

[[ $# -lt 1 ]] && die "Usage: worktree-registry.sh <add|remove|list|prune|has> [args...]"
op="$1"
shift
case "$op" in
  add) cmd_add "$@" ;;
  remove) cmd_remove "$@" ;;
  list) cmd_list "$@" ;;
  prune) cmd_prune "$@" ;;
  has) cmd_has "$@" ;;
  *) die "Unknown subcommand: $op" ;;
esac
