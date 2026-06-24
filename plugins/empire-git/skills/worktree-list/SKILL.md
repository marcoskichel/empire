---
name: worktree-list
description: >
  Read-only inventory of active worktrees: branch, status, sync state,
  staleness. Use when user asks what worktrees exist, "list worktrees", "show
  my worktrees", "what's in flight", "which branches have worktrees", "stale
  worktrees", "any forgotten worktrees", or wants a parallel-work overview.
  Reports state only, never deletes or modifies. For removal use worktree-close
  (single) or worktree-cleanup (batch). Also triggers for
  `/empire-git:worktree-list [--stale]`.
compatibility: Requires git. Designed for Claude Code (or similar agents).
model: haiku
allowed-tools: Bash Read Glob Grep
argument-hint: "[--stale]"
---

# Worktree List

List all active worktrees with rich context: branch, status, sync state, and staleness detection.

**User input:** $ARGUMENTS

## Step 1 — Gather worktree data

```bash
git worktree list --porcelain
```

Parse the output to extract for each worktree:

- **Path** (`worktree <path>`)
- **HEAD commit** (`HEAD <sha>`)
- **Branch** (`branch refs/heads/<name>`) or `(detached HEAD)`

Identify the main working tree (first entry) and label it as such.

If there are no worktrees beyond the main working tree, report:

> No additional worktrees found. Use `/empire-git:worktree-open` to create one.

Then stop.

## Step 2 — Enrich each worktree

For each worktree, gather the following:

### Clean/dirty status

```bash
git -C "<path>" status --porcelain 2>/dev/null | wc -l | tr -d ' '
```

- `0` → "clean"
- `>0` → report count of modified files

### Ahead/behind remote

```bash
git -C "<path>" rev-list --left-right --count @{upstream}...HEAD 2>/dev/null
```

Output format: `<behind>\t<ahead>`. If no upstream is set, note "no remote".

### Last commit

```bash
git -C "<path>" log -1 --format="%cr|%s" 2>/dev/null
```

This gives relative time and subject (e.g., `2 hours ago|add JWT validation`).

### Staleness check

```bash
git -C "<path>" log -1 --format="%ct" 2>/dev/null
```

Compare the commit timestamp to now. Flag as **stale** if the last commit is **3 or more days old**. This is the informational threshold; `worktree-cleanup` uses a stricter 7-day threshold for actual removal. The two thresholds differ on purpose: list is a soft warning, cleanup is the action.

### Port offset

```bash
printf '%s' "<absolute-worktree-path>" | cksum | awk '{print $1 % 100}'
```

`worktree-setup.sh` derives the offset from the worktree's absolute path with this exact formula. Feed the raw absolute path straight from the `worktree <path>` porcelain line (Step 1), not the shortened relative path shown in the Step 3 examples, and don't run it through `realpath` or append a trailing slash. Any difference in the string changes the cksum and yields a wrong offset; match it exactly and the recompute is deterministic. Show it in the listing and use it for the collision check in Step 4.

## Step 3 — Format the output

Present each worktree as a block, for example:

```
Active worktrees:

  main (main working tree)
    /path/to/repo
    Clean | Last commit: 1h ago "update deps"

  feat/auth
    .claude/worktrees/feat-auth-1a2b3c4d
    Clean | 2 ahead | Last commit: 2h ago "add JWT validation"
    Ports: offset 17

  feat/billing
    .claude/worktrees/feat-billing-5e6f7a8b
    1 modified file | 0 ahead | Last commit: 20m ago "wip: invoice model"
    Ports: offset 42

  fix/typo-header
    .claude/worktrees/fix-typo-header-9c0d1e2f
    Clean | 1 ahead | Last commit: 3d ago "fix typo in header"
    Ports: offset 91
    ⚠ Stale (no commits in 3+ days)
```

If `$ARGUMENTS` contains `--stale`, only show worktrees flagged as stale.

## Step 4 — Recommendations

After the listing, add actionable suggestions for any issues found:

- **Stale worktrees:** "Consider closing stale worktrees with `/empire-git:worktree-close <branch>` to keep your workspace tidy."
- **Dirty worktrees:** "Worktree `<branch>` has uncommitted changes. Consider committing with `/commit`."
- **Behind remote:** "Worktree `<branch>` is behind its remote. Consider pulling."
- **Port offset collisions:** If two worktrees share the same port offset, warn about potential port conflicts.

## Guiding principles

This is a **read-only** command — it reports state but never changes it. The user is asking "what do I have?" not "fix things for me." If a worktree is in a broken state (missing on disk, detached HEAD, etc.), report what you can and skip what you can't rather than erroring out. Suggest `git worktree prune` for missing directories so the user can clean up on their own terms.
