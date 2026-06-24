---
name: pr-stack
description: >
  Maintain the "PR stack" comment across a chain of stacked PRs. Use when
  working on stacked or chained PRs, when a PR in a chain is created, merged,
  or retargeted, or when the user says "PR stack", "stacked PRs", "PR chain",
  "PR chain header", "stack comment", "update the PR stack", "refresh the
  stack", "mark merged PRs sliced through". Builds the chain from the live
  GitHub PR graph and upserts one idempotent marker comment on every open PR in
  the chain — current PR highlighted, merged PRs struck-through. Skips and
  removes the comment for a lone PR against the default branch. MUST run after
  merging or rebasing a PR in a chain to keep the stack current. Distinct from
  `pr-description`, which renders the PR body.
model: sonnet
allowed-tools: Bash Read
argument-hint: "[--pr <number>] [--repo <owner/repo>] [--dry-run]"
---

# PR Stack

Keep a "PR stack" comment in sync on every PR in a stacked chain. One comment per PR, each listing the whole chain with that PR highlighted. Merged PRs render struck-through. A lone PR against the default branch gets no comment.

**User input:** $ARGUMENTS

## When to run

- After creating a PR whose base is another open PR (a stacked PR).
- After merging a PR in a chain — merged rows must flip to struck-through, and downstream bases change (`pr-merge` retargets children before merging).
- After retargeting (changing the base of) any PR in a chain.
- Whenever the user asks to refresh, fix, or rebuild the stack comment.

`pr-merge` invokes this automatically after a successful merge. Run it manually otherwise.

## Step 1 — Anchor on a PR

The script anchors on one PR and discovers the rest of the chain from it.

- Default: the PR for the current branch.
- If the user named a PR number or URL, pass `--pr <number>`.
- If not inside the target repo, pass `--repo <owner/repo>`.

## Step 2 — Run the script

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/pr-stack.sh" [--pr <number>] [--repo <owner/repo>] [--dry-run]
```

Use `--dry-run` first when you want to preview the rendered comment and planned actions without posting anything.

The script:

1. Detects the repo and default branch.
2. Builds the live chain around the anchor PR by linking each PR's base branch to another open PR's head branch (walks parents up, children down).
3. Unions that with the membership recorded in any existing stack comment, so PRs that already merged (head branch deleted, link broken) stay listed.
4. Resolves each member's current state, title, and URL.
5. Upserts the marker comment on every open member, or removes it when the chain is no longer meaningful.

## Step 3 — Report

State what changed per PR (created / updated / removed / unchanged). Do not paste the full comment back unless asked.

## Rendering rules

The comment the script renders, for reference:

```
<!-- empire:pr-stack v=1 members=25,15,16 -->
### PR stack

| PR |
| --- |
| ~~[Shared ESLint/Prettier/TypeScript config](https://github.com/o/r/pull/25)~~ ✅ |
| **[Coder server baseline](https://github.com/o/r/pull/15) ← this PR** |
| [Template CI + nightly deploy](https://github.com/o/r/pull/16) |
```

- Order is base → tip, top to bottom.
- Each row is `[<PR title>](<PR url>)`. GitHub does not render a bare PR link as its title — only the explicit link text shows inline — so the title is written out and refreshed every run.
- Current PR: bold, suffixed `← this PR`.
- Merged PR: struck-through, suffixed ✅.
- Closed-unmerged PR: struck-through, no check.
- First line is a hidden marker. `members=` records chain order and survives head-branch deletion. The marker is how the script finds and updates its own comment instead of duplicating.

## Chain detection

- A chain exists when ≥2 PRs are open, or ≥1 open PR rides on ≥1 merged sibling from the same stack.
- A single PR based on the default branch with no merged siblings is not a chain → any existing stack comment is removed.
- Branching stacks (a PR with multiple stacked children) render flat in discovery order; the script follows one child per level.

## Why

Stacked PRs hide their relationships. A reviewer opening PR 4 of 7 has no idea what came before or what depends on it. A self-updating stack comment makes the whole chain visible from any PR, and reflects merges as they happen so the picture never goes stale. Keeping it in a comment (not the PR body) leaves the body clean for `pr-description` and survives body rewrites.
