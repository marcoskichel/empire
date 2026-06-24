---
name: worktree-help
description: >
  Answer questions about the worktree toolkit: VSCode integration, gitignore,
  port offsets, env files, dependency installs, workflow tips. Use when user
  asks how worktrees work, "how do I open this in VSCode", "why is .env
  copied", "what about port collisions", "how do worktrees affect main repo",
  "worktree workflow", "show me the worktree FAQ", or any question about the
  setup. Also triggers for `/empire-git:worktree-help [question]`.
compatibility: Requires git. Designed for Claude Code (or similar agents).
model: haiku
allowed-tools: Bash Read Glob Grep
argument-hint: "[question]"
---

# Worktree Help

`$ARGUMENTS` is the user's question. If empty, MUST print the **Overview** section below byte-for-byte verbatim — do not paraphrase, summarize, or reorder. Otherwise, answer their question using the **FAQ** section as your primary reference, falling back to your knowledge of git worktrees and this plugin's setup.

Keep answers concise and practical. When relevant, include `code .claude/worktrees/<branch-dir>` — it's the single most useful tip for new users.

---

## Overview (print when `$ARGUMENTS` is empty)

The empire worktree skills are a toolkit for running multiple branches of the same repo in parallel, each in its own isolated git worktree, with Claude Code skills that handle the lifecycle for you.

**Why it exists.** Switching branches mid-task is disruptive: you stash, rebuild, lose dev server state, and risk polluting one branch's `.env` with another's. Worktrees give each branch its own directory, dependencies, ports, and env — so you (or a Claude agent) can spin up a parallel task without touching what you're already working on. This plugin automates the boring parts: derived ports, copied env files, dependency installs, cleanup, and merge/close flows.

**Zero per-repo setup.** The plugin ships with `worktree-setup.sh` and the skills invoke it via `${CLAUDE_PLUGIN_ROOT}`. Lockfiles are auto-detected (pnpm, npm, yarn, bun, uv, poetry, pipenv, bundler, cargo, go modules). The `.claude/worktrees` ignore entry is written to `.git/info/exclude`, never the repo's tracked `.gitignore`.

### Available skills

| Command                                                               | Purpose                                                   |
| --------------------------------------------------------------------- | --------------------------------------------------------- |
| `/empire-git:worktree-open [branch or description] [--base <branch>]` | Create or reopen a worktree (env, deps, ports handled)    |
| `/empire-git:worktree-list [--stale]`                                 | List active worktrees with branch, sync state, staleness  |
| `/empire-git:worktree-merge <branch> --into <target> [--no-close]`    | Local git merge of one branch into another                |
| `/empire-git:worktree-close [branch] [--push] [--force]`              | Push, remove the worktree, optionally delete the branch   |
| `/empire-git:worktree-cleanup [--dry-run]`                            | Batch cleanup of stale worktrees and orphaned branches    |
| `/empire-git:worktree-help [question]`                                | This help — ask any worktree question in natural language |

Ask `/empire-git:worktree-help <your question>` for anything specific (VSCode setup, ports, env files, merge strategy, etc.).

### Credits

Inspired by [`@thinkvelta/claude-worktree-tools`](https://github.com/ThinkVelta/claude-worktree-tools) (MIT).

---

## FAQ

**Q: How do I see a worktree in VSCode?**
Open it as its own window: `code .claude/worktrees/<branch-dir>`. The main repo's Source Control panel won't show worktree changes — that's by design (worktrees are excluded). Alternative: File → Add Folder to Workspace for a multi-root setup.

**Q: Why is `.claude/worktrees/` in `.git/info/exclude`?**
Required. Worktrees are git's own checkout mechanism, not nested repos. Without an exclude entry, git would try to track the worktree's files as content of the parent repo. The plugin writes to `.git/info/exclude` (per-clone, not committed) so the host repo's tracked `.gitignore` stays untouched.

**Q: What's the typical workflow?**
`/empire-git:worktree-open <task>` → `code .claude/worktrees/<branch-dir>` → work & commit → `/empire-git:worktree-close --push` (or `/empire-git:worktree-merge` to fold into another branch first). Use `/empire-git:worktree-list` to see everything in flight.

**Q: How do port offsets work?**
Each worktree gets a deterministic 0–99 offset derived from its path. Same branch → same offset (bookmarkable). Different worktrees → near-zero collision odds. The script prints the offset on completion. If your app needs to read it, set `PORT_OFFSET` in the worktree's `.env` (manually or via your own post-setup hook) — the plugin no longer mutates `.env` automatically.

**Q: What happens to `.env` files?**
All `.env*` files are copied from the main repo into the worktree, preserving directory structure (monorepo-friendly). On `--reopen`, they're re-copied so worktrees pick up changes from the main repo. Symlinked `.env` files are skipped.

**Q: How does dependency install work?**
The script auto-detects the package manager from lockfiles in the worktree root: `pnpm-lock.yaml` → `pnpm install --frozen-lockfile`, `yarn.lock` → `yarn install --frozen-lockfile`, `bun.lockb`/`bun.lock` → `bun install --frozen-lockfile`, `package-lock.json` → `npm ci`, `uv.lock` → `uv sync`, `poetry.lock` → `poetry install`, `Pipfile.lock` → `pipenv install --deploy`, `Gemfile.lock` → `bundle install`, `Cargo.lock` → `cargo fetch`, `go.sum` → `go mod download`. No lockfile = skip.

**Q: When should I use `/empire-git:worktree-merge` instead of opening a PR?**
Two cases: **batching small fixes** (merge several tiny worktrees into one branch, open one PR), and **branch decomposition** (split a big feature into sub-worktrees, fold them back into the parent, then open one PR from the parent). For everything else, just `/empire-git:worktree-close --push` and PR normally.

**Q: Can I run multiple worktrees at once?**
Yes — that's the whole point. Each has isolated deps, ports, and env. Run `/empire-git:worktree-list` to see them all. A common pattern: one worktree for your main task, others for parallel Claude agents working on smaller things.

**Q: How do I update dependencies in a worktree?**
Run your normal install command inside the worktree directory (`pnpm install`, `bun install`, etc.). The worktree has its own `node_modules` — installs don't affect the main repo or other worktrees.

**Q: What if I forget about a worktree?**
`/empire-git:worktree-list --stale` shows worktrees with no recent activity. `/empire-git:worktree-cleanup` batch-removes stale ones (use `--dry-run` first to preview).

**Q: Is the main repo affected when I work in a worktree?**
No. The main repo's working directory, branch, and dev server are untouched. Only the shared `.git` directory is updated when you commit (which is the same as any branch switch).

**Q: How do I delete a branch and its worktree completely?**
`/empire-git:worktree-close <branch> --force` removes the worktree and deletes the local branch. Add `--push` first if you want to push before tearing down.
