#!/usr/bin/env bash
# sync-codex.sh — Materialize Codex-consumable artifacts from the marketplace source.
# Part of the empire Claude Code plugin marketplace.
#
# skills.sh ships each skill's own directory verbatim, and Codex reads skills from
# .agents/skills. Two artifacts must therefore be generated from the canonical
# source and kept in lockstep with it:
#   1. Specialist personas — copies of a plugin's agents/*.md placed in the
#      dispatching skill's references/personas/ so they travel with the skill (a
#      skill referenced only relatively stays self-contained across agents).
#   2. .agents/skills/<skill> symlinks — a project-local mirror so Codex discovers
#      these skills when run inside this repo (skills.sh handles external installs).
#
# Add a plugin to the migration by extending PERSONA_BUNDLES and MIRROR_BUNDLES.
#
# Usage:
#   sync-codex.sh           # write artifacts (idempotent)
#   sync-codex.sh --check   # verify artifacts are current; exit 1 on drift

set -euo pipefail
shopt -s nullglob

die() {
  printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2
  exit 1
}

info() {
  printf '\033[1;34m==>\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33mWARN:\033[0m %s\n' "$1" >&2
}

success() {
  printf '\033[1;32m==>\033[0m %s\n' "$1"
}

CHECK=false
case "${1:-}" in
  --check) CHECK=true ;;
  "") ;;
  *) die "Unknown argument: $1 (usage: sync-codex.sh [--check])" ;;
esac

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

DRIFT=0

# Persona bundles: "SRC_AGENTS_DIR::DST_PERSONAS_DIR". The dispatching skill
# bundles its plugin's full agent roster; the skill selects the right one.
PERSONA_BUNDLES=(
  "plugins/empire-dev/agents::plugins/empire-dev/skills/team-review/references/personas"
  "plugins/empire-product/agents::plugins/empire-product/skills/vet/references/personas"
  "plugins/empire-product/agents::plugins/empire-product/skills/recon/references/personas"
  "plugins/empire-research/agents::plugins/empire-research/skills/explore/references/personas"
  "plugins/empire-research/agents::plugins/empire-research/skills/compare/references/personas"
)

# Project-local Codex skill mirror: "PLUGIN::skill1 skill2 ...".
MIRROR_BUNDLES=(
  "empire-dev::team-review socratic-pr-review handoff shape weigh slice plan-reviewer"
  "empire-product::pitch vet recon mint distill probe"
  "empire-research::explore compare dissect"
  "empire-visual::visualize"
  "empire-git::worktree-open worktree-close worktree-list worktree-cleanup worktree-merge worktree-help pr-description pr-comment-reply pr-merge pr-review-post pr-merge-stack"
)

# Script bundles: "SRC_SCRIPT::DST_SKILL_SCRIPTS_DIR". Copied so skills.sh ships
# the script inside the skill (Codex); Claude keeps using ${CLAUDE_PLUGIN_ROOT}/scripts.
SCRIPT_BUNDLES=(
  "plugins/empire-dev/workflows/team-review.js::plugins/empire-dev/skills/team-review/workflows"
  "plugins/empire-dev/workflows/address-review.js::plugins/empire-dev/skills/address-review/workflows"
  "plugins/empire-dev/workflows/plan-reviewer.js::plugins/empire-dev/skills/plan-reviewer/workflows"
  "plugins/empire-research/workflows/explore-deepdive.js::plugins/empire-research/skills/explore/workflows"
  "plugins/empire-research/workflows/compare-score.js::plugins/empire-research/skills/compare/workflows"
  "plugins/empire-git/scripts/worktree-setup.sh::plugins/empire-git/skills/worktree-open/scripts"
  "plugins/empire-git/scripts/worktree-registry.sh::plugins/empire-git/skills/worktree-open/scripts"
  "plugins/empire-git/scripts/worktree-registry.sh::plugins/empire-git/skills/worktree-close/scripts"
  "plugins/empire-git/scripts/worktree-registry.sh::plugins/empire-git/skills/worktree-cleanup/scripts"
  "plugins/empire-git/scripts/worktree-registry.sh::plugins/empire-git/skills/worktree-merge/scripts"
)

MIRROR_DIR=".agents/skills"

sync_persona_set() {
  local src_dir="$1" dst_dir="$2"
  local src dst base
  [[ -d "$src_dir" ]] || die "missing persona source: $src_dir"

  if $CHECK; then
    for src in "$src_dir"/*.md; do
      base="$(basename "$src")"
      dst="$dst_dir/$base"
      if [[ ! -f "$dst" ]] || ! cmp -s "$src" "$dst"; then
        warn "persona out of sync: $dst"
        DRIFT=1
      fi
    done
    for dst in "$dst_dir"/*.md; do
      base="$(basename "$dst")"
      if [[ ! -f "$src_dir/$base" ]]; then
        warn "stale persona (no source): $dst"
        DRIFT=1
      fi
    done
    return
  fi

  mkdir -p "$dst_dir"
  for dst in "$dst_dir"/*.md; do
    base="$(basename "$dst")"
    [[ -f "$src_dir/$base" ]] || rm -f "$dst"
  done
  for src in "$src_dir"/*.md; do
    cp "$src" "$dst_dir/$(basename "$src")"
  done
}

sync_personas() {
  local bundle
  for bundle in "${PERSONA_BUNDLES[@]}"; do
    sync_persona_set "${bundle%%::*}" "${bundle##*::}"
  done
  $CHECK || success "synced personas (${#PERSONA_BUNDLES[@]} bundles)"
}

sync_mirror() {
  local bundle plugin skill link target actual count=0
  local -a skills

  $CHECK || mkdir -p "$MIRROR_DIR"
  for bundle in "${MIRROR_BUNDLES[@]}"; do
    plugin="${bundle%%::*}"
    read -ra skills <<<"${bundle##*::}"
    for skill in "${skills[@]}"; do
      link="$MIRROR_DIR/$skill"
      target="../../plugins/$plugin/skills/$skill"
      if $CHECK; then
        if [[ ! -L "$link" ]]; then
          warn "missing symlink: $link"
          DRIFT=1
          continue
        fi
        actual="$(readlink "$link")"
        if [[ "$actual" != "$target" ]]; then
          warn "symlink target wrong: $link -> $actual (want $target)"
          DRIFT=1
        fi
      else
        ln -sfn "$target" "$link"
        count=$((count + 1))
      fi
    done
  done
  $CHECK || success "synced $MIRROR_DIR mirror ($count skills)"
}

sync_scripts() {
  local bundle src dst_dir dst base count=0
  for bundle in "${SCRIPT_BUNDLES[@]}"; do
    src="${bundle%%::*}"
    dst_dir="${bundle##*::}"
    base="$(basename "$src")"
    dst="$dst_dir/$base"
    [[ -f "$src" ]] || die "missing script source: $src"
    if $CHECK; then
      if [[ ! -f "$dst" ]] || ! cmp -s "$src" "$dst"; then
        warn "script out of sync: $dst"
        DRIFT=1
      fi
    else
      mkdir -p "$dst_dir"
      cp "$src" "$dst"
      chmod +x "$dst"
      count=$((count + 1))
    fi
  done
  $CHECK || success "synced scripts ($count copies)"
}

info "Syncing Codex artifacts (mode: $([[ $CHECK == true ]] && echo check || echo write))"
sync_personas
sync_scripts
sync_mirror

if $CHECK; then
  [[ "$DRIFT" -eq 0 ]] || die "Codex artifacts are out of date. Run: scripts/sync-codex.sh"
  success "Codex artifacts up to date"
fi
