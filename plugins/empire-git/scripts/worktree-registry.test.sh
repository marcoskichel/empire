#!/usr/bin/env bash
# worktree-registry.test.sh — Manual self-test for worktree-registry.sh.
# Usage: bash plugins/empire-git/scripts/worktree-registry.test.sh
# Exits non-zero on any failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY="$SCRIPT_DIR/worktree-registry.sh"

TMP_HOME="$(mktemp -d)"
export HOME="$TMP_HOME"
export CLAUDE_CODE_SESSION_ID="test-session-0001"

trap 'rm -rf "$TMP_HOME"' EXIT

REG_FILE="$HOME/.claude/sessions/$CLAUDE_CODE_SESSION_ID/active-worktrees.json"

assert_eq() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$label" "$expected" "$actual" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$label"
}

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    printf 'FAIL: %s\n  needle: %s\n  haystack: %s\n' "$label" "$needle" "$haystack" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$label"
}

# --- Test 1: add creates a new entry ---
WT1="$TMP_HOME/wt-feat-a"
mkdir -p "$WT1"
bash "$REGISTRY" add "feat/a" "$WT1" --base "main" --repo-root "$TMP_HOME"
count=$(jq '.worktrees | length' "$REG_FILE")
assert_eq "$count" "1" "add creates one entry"

# --- Test 2: list (default) prints the path ---
out=$(bash "$REGISTRY" list)
assert_eq "$out" "$WT1" "list prints path"

# --- Test 3: add same path again refreshes opened_at, not created_at ---
created_before=$(jq -r '.worktrees[0].created_at' "$REG_FILE")
sleep 1
bash "$REGISTRY" add "feat/a" "$WT1" --base "main" --repo-root "$TMP_HOME"
count=$(jq '.worktrees | length' "$REG_FILE")
assert_eq "$count" "1" "re-add does not duplicate"
created_after=$(jq -r '.worktrees[0].created_at' "$REG_FILE")
opened_after=$(jq -r '.worktrees[0].opened_at' "$REG_FILE")
assert_eq "$created_after" "$created_before" "created_at unchanged on re-open"
if [[ "$opened_after" == "$created_before" ]]; then
  printf 'FAIL: opened_at should have advanced\n' >&2
  exit 1
fi
printf 'PASS: opened_at advances on re-open\n'

# --- Test 4: a second add lands in sorted order ---
WT2="$TMP_HOME/wt-feat-b"
mkdir -p "$WT2"
bash "$REGISTRY" add "feat/b" "$WT2" --base "main" --repo-root "$TMP_HOME"
out=$(bash "$REGISTRY" list)
expected=$(printf '%s\n%s' "$WT1" "$WT2")
assert_eq "$out" "$expected" "list is sorted by created_at ascending"

# --- Test 5: has returns 0 for known path, 1 for unknown ---
if bash "$REGISTRY" has "$WT1"; then
  printf 'PASS: has returns 0 for known\n'
else
  printf 'FAIL: has known\n'
  exit 1
fi
if bash "$REGISTRY" has "/nonexistent/path"; then
  printf 'FAIL: has should return 1 for unknown\n'
  exit 1
else
  printf 'PASS: has returns 1 for unknown\n'
fi

# --- Test 6: remove drops the entry ---
bash "$REGISTRY" remove "$WT1"
count=$(jq '.worktrees | length' "$REG_FILE")
assert_eq "$count" "1" "remove drops one entry"
out=$(bash "$REGISTRY" list)
assert_eq "$out" "$WT2" "list shows only remaining entry"

# --- Test 7: prune drops entries whose path no longer exists ---
rm -rf "$WT2"
bash "$REGISTRY" prune
count=$(jq '.worktrees | length' "$REG_FILE")
assert_eq "$count" "0" "prune removes missing worktree"

# --- Test 8: list on empty registry exits 0 with no output ---
out=$(bash "$REGISTRY" list)
assert_eq "$out" "" "list on empty registry is empty"

# --- Test 9: unknown session warns but still works ---
unset CLAUDE_CODE_SESSION_ID
WT3="$TMP_HOME/wt-unknown"
mkdir -p "$WT3"
stderr_out=$(bash "$REGISTRY" add "feat/u" "$WT3" --base "main" --repo-root "$TMP_HOME" 2>&1 >/dev/null)
assert_contains "$stderr_out" "unknown" "warns when session id missing"
unknown_file="$HOME/.claude/sessions/unknown/active-worktrees.json"
if [[ -f "$unknown_file" ]]; then
  printf 'PASS: unknown session file created\n'
else
  printf 'FAIL: unknown session file missing\n'
  exit 1
fi

# --- Test 10: malformed JSON resets ---
export CLAUDE_CODE_SESSION_ID="test-session-malformed"
malformed_file="$HOME/.claude/sessions/$CLAUDE_CODE_SESSION_ID/active-worktrees.json"
mkdir -p "$(dirname "$malformed_file")"
printf 'this is not json' >"$malformed_file"
WT4="$TMP_HOME/wt-malformed"
mkdir -p "$WT4"
bash "$REGISTRY" add "feat/m" "$WT4" --base "main" --repo-root "$TMP_HOME"
count=$(jq '.worktrees | length' "$malformed_file")
assert_eq "$count" "1" "malformed registry resets and accepts new entries"

printf '\nAll registry tests passed.\n'
