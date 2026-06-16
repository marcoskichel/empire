---
name: worktree-open
description: >
  Create or reopen a git worktree for parallel development. Use when user
  wants to "open a worktree", "spin up a branch", "work on X separately",
  "work on this in parallel", "start a parallel task", "isolated environment
  for an agent", "side branch without switching", or mentions worktrees,
  parallel branches, or stacked work. Also triggers for
  `/empire-git:worktree-open [branch | task description] [--base <branch>]`.
model: sonnet
allowed-tools: Bash Read Glob Grep
argument-hint: "[branch | task description] [--base <branch>]"
---

# Worktree Open

Create or reopen a git worktree for parallel development, then guide the user to launch a Claude Code session in it.

**User input:** $ARGUMENTS

## Step 1 — Parse the user's intent

Determine what the user wants from `$ARGUMENTS`:

| Input pattern                                                                                                           | Action                                 |
| ----------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| Empty (no arguments)                                                                                                    | Ask the user what they want to work on |
| Looks like a branch name (contains `/`, or starts with `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `ci/`, `test/`) | Use as the branch name directly        |
| Natural language (a task description like "add auth to the API")                                                        | Derive a branch name (see below)       |

### Deriving a branch name from a task description

Generate a branch name following this convention:

- Pattern: `<type>/<1-4-word-slug>`
- Type: `feat`, `fix`, `refactor`, `chore`, `docs`, `ci`, `test` — infer from the description
- Slug: lowercase, hyphen-separated, max 4 words, no special characters
- Examples: `feat/auth-api-refactor`, `fix/login-timeout`, `chore/upgrade-deps`

Do not ask the user to confirm the branch name, just use it and proceed immediately.

## Step 2 — Determine base branch

If the user specified `--base <branch>` in their arguments, use that.

Otherwise, default base = the current branch. If the current branch matches `^(feat|fix|refactor|chore|docs|ci|test)/`, ask the user via `AskUserQuestion`:

```
question: "Branch from current `<current-branch>` or from the default branch?"
header:   "Base branch"
options:
  - label: "Current (`<current-branch>`)"
    description: "Stack this work on top of an existing feature branch"
  - label: "Default (`main` or repo default)"
    description: "Independent branch off the repo's default branch"
```

Resolve the repo's default branch via `git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||'`. If that fails, fall back to `main`, then `master`.

## Step 3 — Check if this worktree already exists

Run:

```bash
git worktree list --porcelain
```

Derive the expected worktree directory:

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
SAFE_BRANCH="$(echo "<branch-name>" | tr '/' '-')"
BRANCH_HASH="$(printf '%s' "<branch-name>" | cksum | awk '{printf "%08x", $1}')"
WORKTREE_DIR="${REPO_ROOT}/.claude/worktrees/${SAFE_BRANCH}-${BRANCH_HASH}"
```

**If the worktree directory exists and is valid** (has a `.git` file):

- This is a **reopen**. Run setup with `--reopen` flag (Step 4).

**If the branch exists but has no worktree**:

- Create a new worktree for the existing branch (Step 4).

**If neither exists**:

- Create both the branch and worktree (Step 4).

## Step 4 — Run the setup script

The setup script ships with this plugin and is always available at `${CLAUDE_PLUGIN_ROOT}/scripts/worktree-setup.sh`.

**New worktree:**

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-setup.sh" "<branch-name>" --base "<base-branch>"
```

**Reopen existing worktree:**

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-setup.sh" "<branch-name>" --reopen
```

The script auto-detects the package manager from lockfiles (pnpm, npm, yarn, bun, uv, poetry, pipenv, bundler, cargo, go modules) and runs the matching install command. No per-repo configuration is required.

## Step 4.5 — Register the worktree

After the setup script succeeds, record the worktree in the per-session registry so external tooling can discover it:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree-registry.sh" add \
  "<branch-name>" \
  "<worktree-path>" \
  --base "<base-branch>" \
  --repo-root "<repo-root>"
```

The registry lives at `~/.claude/sessions/$CLAUDE_CODE_SESSION_ID/active-worktrees.json`. Re-opening an existing worktree refreshes its `opened_at` without duplicating the entry.

If the registry call fails (e.g., `jq` missing), print a warning and continue — the worktree itself is still usable.

## Step 5 — Print result and next steps

After the setup script completes, print:

```
Worktree ready!

  Branch:  <branch-name>
  Path:    <worktree-path>
  Status:  new | reopened

To start working in this worktree, navigate to it and launch a Claude Code session or open in VSCode:
  cd <worktree-path>
  claude  # Starts a Claude Code session in this worktree
  code .  # Opens the worktree in a new VSCode window
```

## Design principles

This skill is **deterministic** — the same branch name always produces the same worktree path and ports, so the user can bookmark URLs and expect consistency. It's also **idempotent** — running it twice with the same branch reopens rather than duplicates, which means the user never has to worry about accidentally creating a mess.

Git only allows a branch to be checked out in one worktree at a time, so the setup script will refuse if the branch is already in use elsewhere. If that happens, surface the error clearly so the user knows which worktree has it.

If the setup script fails partway through, just report what happened. Don't try to auto-clean — partial state is easier for the user to inspect and fix (via `/empire-git:worktree-close`) than state that was silently deleted.
