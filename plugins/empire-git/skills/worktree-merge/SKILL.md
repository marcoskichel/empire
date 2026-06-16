---
name: worktree-merge
description: >
  Fold ONE worktree's branch INTO another branch using git merge. Use when
  combining a worktree branch into a parent, batching small fixes into one
  branch before opening a single PR, or folding sub-feature branches back
  together. Triggers on "merge this worktree into X", "fold sub-branches
  back", "combine worktree branches", "merge feat/X into main locally". Always
  a real `git merge`, defaults to `--no-ff`. For pushing to remote, use
  `worktree-close --push` instead. For batch teardown of stale worktrees, use
  worktree-cleanup. Also triggers for `/empire-git:worktree-merge [branch]
  --into <target> [--no-close] [--ff]`.
model: sonnet
allowed-tools: Bash Read Glob Grep
argument-hint: "<branch> --into <target> [--no-close] [--ff]"
---

# Worktree Merge

Merge a worktree's branch into a target branch. This is always a real `git merge` — the target is a local branch where the worktree's commits get folded in.

**User input:** $ARGUMENTS

## Step 1 — Determine the source branch

**If currently inside a worktree** (not the main working tree):

- Use the current worktree's branch.

**If `$ARGUMENTS` specifies a branch name or worktree path:**

- Use that. Verify it has an associated worktree via `git worktree list --porcelain`.

**If neither:**

- List all worktrees with `git worktree list` and ask the user which one to merge.

Record the worktree path and branch name for subsequent steps.

## Step 2 — Determine the target branch

The target is where the source branch's commits will be merged into.

**If `--into <target>` is in the arguments:** use that branch.

**If no target is specified:** ask the user which branch to merge into. Common choices:

- `main` — the default branch
- A parent feature branch (e.g., `feat/auth` when merging `feat/auth-nav`)

The target branch must be checked out somewhere — either in the main working tree or in another worktree. Find it:

```bash
git worktree list --porcelain
```

If the target branch isn't checked out anywhere, check it out in the main working tree first.

## Step 3 — Pre-flight checks

### Clean working tree

```bash
git -C "<source-worktree-path>" status --porcelain
```

If there are uncommitted changes, **stop** and tell the user:

> This worktree has uncommitted changes. Please commit them first (e.g., run `/commit`), then re-run `/empire-git:worktree-merge`.

### Commits to merge

```bash
git -C "<source-worktree-path>" log --oneline <target>..<source-branch>
```

If there are no commits ahead of the target, **stop**:

> Branch `<source>` has no new commits relative to `<target>`. Nothing to merge.

## Step 4 — Perform the merge

Default merge mode: `--no-ff` (preserves branch history as a merge commit, easier to read and revert).

If `--ff` was in `$ARGUMENTS`, omit `--no-ff` and let git fast-forward when possible. Use this for rebase-only or linear-history teams.

```bash
# Default
git -C "<target-worktree-path>" merge "<source-branch>" --no-ff

# With --ff
git -C "<target-worktree-path>" merge "<source-branch>"
```

If your team forbids merge commits entirely, this skill is the wrong tool — use `git rebase` directly in the source worktree, then `worktree-close --push`.

**If merge conflicts occur:**

1. List the conflicting files:
   ```bash
   git -C "<target-worktree-path>" diff --name-only --diff-filter=U
   ```
2. Report the conflicts clearly to the user.
3. **Stop.** Merge conflicts need human judgment — auto-resolving risks silently introducing bugs. Tell the user to resolve conflicts in the target worktree, then run `/empire-git:worktree-close` on the source worktree when ready.

**On success**, print:

```
Merged '<source-branch>' into '<target-branch>'.
```

## Step 5 — Cleanup (unless --no-close)

If `--no-close` was in the arguments, skip this step and just print the result. The user may want to keep the source worktree around for further work.

Otherwise, present the same cleanup options as `/empire-git:worktree-close`:

1. **Remove worktree only** — keeps the branch around in case it's needed
2. **Remove worktree + delete branch** — full cleanup, since the commits now live in the target branch
3. **Keep everything** — do nothing

After a successful merge, default to option 2 — the branch's commits are now in the target, so the source branch has served its purpose.

Execute the chosen option. Anchor every command to the main working tree with `git -C` so it runs regardless of the shell's cwd — the session may be sitting inside the source worktree, and removing that directory would otherwise break the next Bash call before it starts:

```bash
MAIN_REPO=$(git worktree list --porcelain | awk '/^worktree / { print $2; exit }')
```

### Option 1: remove worktree only

```bash
git -C "$MAIN_REPO" worktree remove "<source-worktree-path>"
```

### Option 2: remove worktree + delete branch

Run both commands in a **single Bash call**, chained with `&&`. `git branch -d` refuses to delete a branch still checked out in a worktree, so the worktree must be removed first. Chaining in one shell invocation means the cwd is resolved once at launch — before the worktree directory disappears — so the branch delete still runs even if the session was inside that worktree.

```bash
git -C "$MAIN_REPO" worktree remove "<source-worktree-path>" && git -C "$MAIN_REPO" branch -d "<source-branch>"
```

If `git branch -d` fails, the branch has commits beyond what was merged — surface that rather than force-deleting.

### Then prune and deregister

```bash
git -C "$MAIN_REPO" worktree prune
bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-registry.sh" remove "<source-worktree-path>"
```

If the registry call fails, print a warning and continue — the worktree removal already succeeded.

Print a summary of what was done.

## When to use this

**Batching small fixes:** Several small worktree branches (typo, dep bump, color tweak) merged locally into one branch before opening a single PR:

```
/empire-git:worktree-merge fix/typo --into feat/cleanup
/empire-git:worktree-merge fix/deps --into feat/cleanup
/empire-git:worktree-merge fix/color --into feat/cleanup
# Then open one PR from feat/cleanup
```

**Branch decomposition:** Sub-branches merged back into a parent feature branch:

```
/empire-git:worktree-merge feat/auth-nav --into feat/auth
/empire-git:worktree-merge feat/auth-table --into feat/auth
# Then open one PR from feat/auth
```

## Guiding principles

**This skill does one thing: git merge.** For pushing to remote, use `/empire-git:worktree-close --push`. For opening PRs, use the user's own PR workflow. Keeping these concerns separate avoids conflicts with existing conventions.

**Merge conflicts need human judgment.** When conflicts occur, clearly list the affected files and let the user decide. Attempting to auto-resolve risks silently introducing bugs.

**Use `git branch -d` (safe delete), not `-D`.** If the safe delete fails after a merge, something unexpected happened — surface it rather than force through.
