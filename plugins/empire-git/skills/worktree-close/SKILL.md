---
name: worktree-close
description: >
  Finish work in a SINGLE worktree: push, remove the worktree, optionally
  delete the branch. Use when done with a specific worktree, wrapping one up,
  pushing and moving on, or no longer needing a parallel environment. Triggers
  on "close this worktree", "I'm done with this worktree", "wrap up this
  branch", "push and remove", "tear down this worktree". For batch cleanup of
  MULTIPLE stale worktrees, use worktree-cleanup instead. Also triggers for
  `/empire-git:worktree-close [branch] [--push] [--discard] [--force]`.
model: sonnet
allowed-tools: Bash Read Glob Grep
argument-hint: "[branch | path] [--push] [--discard] [--force]"
---

# Worktree Close

Finish work in a worktree: check for unsaved work, optionally push, remove the worktree, and let the user decide what happens to the branch.

**User input:** $ARGUMENTS

**Flag semantics (do not conflate):**

| Flag        | Meaning                                                                       |
| ----------- | ----------------------------------------------------------------------------- |
| `--push`    | Push the branch to `origin` before removing the worktree.                     |
| `--discard` | Skip the dirty-check prompt and proceed even with uncommitted changes.        |
| `--force`   | Skip the cleanup-option prompt; default to "remove worktree + delete branch". |

`--discard` and `--force` are independent. The user can pass either, both, or neither. Never treat one as implying the other.

## Step 1 — Identify the worktree to close

**Priority order:**

1. If `$ARGUMENTS` contains a branch name or worktree path, use that.
2. If the current directory is inside a worktree (not the main working tree), use the current worktree.
3. If neither, list worktrees with `git worktree list` and ask the user to pick one.

Parse `git worktree list --porcelain` to find the worktree path and branch. Identify the main working tree (the first entry) — it cannot be closed.

## Step 2 — Check for uncommitted changes

```bash
git -C "<worktree-path>" status --porcelain
```

**If clean** (empty output): proceed to Step 3.

**If dirty** (uncommitted changes):

Show the user what's pending:

```bash
git -C "<worktree-path>" status --short
```

Then present options:

1. **Commit first** (recommended) — suggest running `/commit` in the worktree, then re-run `/empire-git:worktree-close`
2. **Discard changes** — proceed with force removal (requires explicit confirmation)
3. **Abort** — cancel the close operation

If `--discard` was in `$ARGUMENTS`, skip this prompt and proceed with force removal of uncommitted work.

## Step 3 — Push if requested

If `--push` was in `$ARGUMENTS`, or the user mentioned pushing:

```bash
git -C "<worktree-path>" push -u origin "<branch>"
```

If push fails, report the error and stop. If no `--push` flag, skip this step.

If there are unpushed commits and the user did NOT request `--push`, mention it:

> This branch has X unpushed commit(s) that are not backed up to the remote. Add `--push` to push before closing, or continue to close without pushing.

## Step 4 — Present cleanup options

Ask the user what they'd like to do. Present these choices:

1. **Remove worktree only** — removes the worktree directory but keeps the branch. Good when the work might continue later or a PR is still open.
2. **Remove worktree + delete branch** — full cleanup. Good when the branch has been merged or is no longer needed. Uses `git branch -d` (safe delete — refuses if unmerged).
3. **Keep everything** — cancel the close. The worktree and branch remain as-is.

Pick a sensible default based on context:

- Branch is merged into its target → default to option 2
- Branch has an open PR → default to option 1
- Branch has unmerged work → default to option 1

If `--force` was specified, skip the cleanup-option prompt and use option 2 (but still use safe delete with `git branch -d`).

## Step 5 — Execute the chosen action

### Option 1: Remove worktree only

```bash
git worktree remove "<worktree-path>"
```

If the worktree is dirty and the user confirmed discard (or passed `--discard`):

```bash
git worktree remove --force "<worktree-path>"
```

### Option 2: Remove worktree + delete branch

**Critical: both commands MUST run in a single Bash call.** Claude Code's Bash tool resolves the shell's cwd at the start of each invocation. If the session is running from inside the worktree and you remove the worktree in one Bash call, the _next_ Bash call will fail immediately ("No such file or directory") before any command — including `git -C` — can execute. The branch delete becomes impossible and the branch is orphaned.

The worktree must be removed before the branch delete (`git branch -d` refuses to delete a branch that's checked out in a worktree). So the correct sequence is: remove worktree, then delete branch — but **in one shell invocation**.

First, resolve the main working tree path:

```bash
MAIN_REPO=$(git worktree list --porcelain | awk '/^worktree / { print $2; exit }')
```

Then run both commands in a **single Bash call**, chained with `&&`:

```bash
git -C "$MAIN_REPO" worktree remove "<worktree-path>" && git -C "$MAIN_REPO" branch -d "<branch>"
```

**Why this works:** the shell resolves its cwd once when the Bash call starts. Both `git` commands use `-C "$MAIN_REPO"` so git operates from the main repo regardless of the shell's cwd. Since they run in the same shell process, the cwd is only checked once — at launch — before any directory is removed.

If `git branch -d` fails (branch not fully merged), tell the user:

> Branch '<branch>' has unmerged commits. Keeping the branch. To force-delete: `git branch -D <branch>`

### Option 3: Keep everything

Do nothing. Confirm to the user that the worktree is still active.

## Step 6 — Prune, deregister, and confirm

```bash
git worktree prune
```

Then remove the entry from the session registry (idempotent — no-op if absent):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-registry.sh" remove "<worktree-path>"
```

If the registry call fails, print a warning and continue — the worktree removal already succeeded.

Print a summary:

```
Worktree closed.

  Path:    <worktree-path> (removed)
  Branch:  <branch> (deleted | kept | pushed)
```

## Guiding principles

**The main working tree is not a worktree.** It's the user's primary repo checkout — removing it would be catastrophic. If someone accidentally targets it, explain the difference.

**Uncommitted work is sacred.** Silently discarding changes is one of the worst things a tool can do. The user should always see what's at risk and explicitly choose to discard. The `--discard` flag exists for when they've already made that choice. `--force` only skips the cleanup-option prompt — it does NOT authorize discarding uncommitted work.

**Use `git branch -d` (safe delete), not `-D`.** If `-d` refuses, it means the branch has unmerged commits — that's valuable information to surface, not override. Tell the user the command to force-delete if they really want to.

**Use `git worktree remove`, not `rm -rf`.** Git tracks worktree metadata internally; removing the directory without telling git leaves stale references that cause confusing errors later. If anything goes wrong, `git worktree prune` cleans up the metadata.
