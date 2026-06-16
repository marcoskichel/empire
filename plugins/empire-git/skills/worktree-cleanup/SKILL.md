---
name: worktree-cleanup
description: >
  Batch cleanup across MULTIPLE stale worktrees and orphaned branches. Use
  when tidying up accumulated worktrees, asking about old branches, cleaning up
  the workspace, or saying "stale worktrees", "orphan branches", "prune
  worktrees", "clean up old branches", "purge stale worktrees", "housekeeping".
  For finishing ONE specific worktree, use worktree-close instead. Also
  triggers for `/empire-git:worktree-cleanup [--dry-run] [--days N]`.
model: haiku
allowed-tools: Bash Read Glob Grep
argument-hint: "[--dry-run] [--days N]"
---

# Worktree Cleanup

Scan for stale worktrees and orphaned branches, then let the user decide what to clean up. This is the batch housekeeping counterpart to `/empire-git:worktree-close` (which handles one worktree at a time).

**User input:** $ARGUMENTS

If `--dry-run` is in the arguments, report what would be cleaned up without making any changes.

If `--days N` is in the arguments (e.g. `--days 14`), use `N` as the staleness threshold. Otherwise default to **7 days**. Note: `worktree-list` uses a softer 3-day threshold (informational warning); cleanup uses 7 days because removal is the action and the longer window reduces false positives.

## Step 1 — Inventory worktrees

```bash
git worktree list --porcelain
```

For each worktree (excluding the main working tree), gather:

- **Branch name**
- **Path on disk** — verify the directory still exists
- **Last commit date:**
  ```bash
  git -C "<path>" log -1 --format="%ct" 2>/dev/null
  ```
- **Dirty/clean status:**
  ```bash
  git -C "<path>" status --porcelain 2>/dev/null | wc -l | tr -d ' '
  ```

Classify each worktree:

| Status      | Criteria                                                                       |
| ----------- | ------------------------------------------------------------------------------ |
| **Stale**   | Last commit more than `--days` (default 7) ago and clean (no uncommitted work) |
| **Missing** | Directory no longer exists on disk (stale git metadata)                        |
| **Active**  | Recent commits or has uncommitted changes                                      |

## Step 2 — Find stale local branches

First, prune remote-tracking references so git knows which remote branches are gone:

```bash
git fetch --prune
```

Determine which branches must **never** be flagged as orphans:

```bash
# The repo's default branch (main, master, develop, trunk, …) — detected, not assumed
DEFAULT_BRANCH=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
# Fallback 1: check well-known branch names
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH=$(git for-each-ref --format='%(refname:short)' refs/heads/main refs/heads/master refs/heads/trunk refs/heads/develop | head -n1)
# Fallback 2: use current HEAD (guaranteed as long as we are in a git repo)
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
# Fallback 3: pick the most-recently-committed local branch
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads | head -n1)

# Guard: if DEFAULT_BRANCH is still empty we cannot safely run merged checks
if [ -z "$DEFAULT_BRANCH" ]; then
  echo "Warning: could not determine default branch — merged-check classification will be skipped."
fi

# The branch currently checked out in the main working tree
CURRENT_BRANCH=$(git -C "$(git rev-parse --show-toplevel)" branch --show-current)

# Branches checked out in any worktree (these are "in use" — git won't let you delete them anyway)
git worktree list --porcelain | awk '/^branch / { sub("refs/heads/", "", $2); print $2 }'
```

Then list candidate local branches, **excluding** the default branch, the current branch, and any branch that has a worktree:

```bash
git branch --format='%(refname:short)'
```

Filter that list in your head (or with grep -v) against `$DEFAULT_BRANCH`, `$CURRENT_BRANCH`, and the worktree branches above. **Do not hardcode `main|master`** — many repos use `develop`, `trunk`, or custom default branches, and the user may currently be checked out on a branch that isn't the default.

For each remaining local branch, check:

- **Is it merged into the default branch?**
  ```bash
  git branch --merged "$DEFAULT_BRANCH" | grep -w "<branch>"
  ```
- **Was its remote deleted?** (common after merging a PR on GitHub)
  ```bash
  git branch -vv --format='%(refname:short) %(upstream:track)' | grep '\[gone\]'
  ```
  The `[gone]` marker means the branch once tracked a remote that no longer exists — a strong signal the PR was merged and the remote branch deleted.
- **Does it have an open PR?** (if `gh` is available)
  ```bash
  gh pr list --head "<branch>" --state open --json number 2>/dev/null
  ```

Classify:

| Status              | Criteria                                                                          |
| ------------------- | --------------------------------------------------------------------------------- |
| **Remote deleted**  | Tracked a remote that's gone (PR likely merged and branch deleted on GitHub)      |
| **Merged orphan**   | Merged into `$DEFAULT_BRANCH`, no worktree, no remote — safe to delete            |
| **Unmerged orphan** | Not merged into `$DEFAULT_BRANCH`, no worktree, no remote — may be abandoned work |
| **Has open PR**     | Skip — still in use                                                               |

## Step 3 — Present findings

Show a summary grouped by action:

```
Worktree Cleanup Report
═══════════════════════

Stale worktrees (no commits in 7+ days, clean):
  feat/old-experiment    .claude/worktrees/feat-old-experiment-1a2b3c4d    12d ago
  fix/typo-header        .claude/worktrees/fix-typo-header-5e6f7a8b         8d ago

Missing worktrees (directory gone, metadata remains):
  feat/deleted-thing     (path no longer exists)

Branches with deleted remote (PR likely merged on GitHub):
  feat/auth-refactor     remote gone — safe to delete locally
  fix/login-bug          remote gone — safe to delete locally

Orphaned branches (no worktree, no remote):
  feat/abandoned-idea    merged into $DEFAULT_BRANCH — safe to delete
  fix/half-done          NOT merged — review before deleting

Active worktrees (no action needed):
  feat/current-work      .claude/worktrees/feat-current-work-9c0d1e2f       2h ago
```

If `--dry-run`, stop here.

## Step 4 — Let the user choose

Present cleanup options as a checklist — the user picks what to clean up:

- **Prune missing worktrees** — run `git worktree prune` to clear stale metadata
- **Close stale worktrees** — remove worktree directories for stale entries
- **Delete branches with deleted remote** — `git branch -d` for each (their PRs were merged)
- **Delete merged orphan branches** — `git branch -d` for each
- **Skip unmerged orphans** — list them but don't touch (inform the user of `git branch -D` if they want to force)

Ask which of these the user wants to proceed with. Don't auto-execute anything — the user confirms first.

## Step 5 — Execute

For each action the user approved:

```bash
# Prune stale metadata
git worktree prune

# Close stale worktrees
git worktree remove "<path>"

# Delete merged orphan branches
git branch -d "<branch>"
```

Print a summary of what was done:

```
Cleanup complete:
  2 stale worktrees removed
  1 missing worktree pruned
  3 merged orphan branches deleted
  1 unmerged orphan branch kept (fix/half-done)
```

After the cleanup actions complete, prune the session registry so it forgets any worktree directories that were removed:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-registry.sh" prune
```

If the call fails, print a warning and continue — registry hygiene is best-effort.

## Guiding principles

**This is a housekeeping tool, not a destructive one.** The default posture is conservative — show what could be cleaned up, let the user decide. The `--dry-run` flag makes it completely safe to explore.

**Merged branches are safe to delete.** Their commits live in the target branch. Unmerged branches might contain work the user forgot about — flag them but don't delete without explicit confirmation.

**Use `git worktree remove`, not `rm -rf`.** And use `git branch -d` (safe delete), not `-D`. If something refuses to delete, that's useful information — surface it.
