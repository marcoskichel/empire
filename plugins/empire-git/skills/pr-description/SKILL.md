---
name: pr-description
description: >
  Render the canonical PR description body. Use when drafting, writing,
  updating, or regenerating a "PR description", "PR body", "pull request
  description", "pull request body", "PR summary", "PR template", "GitHub PR
  body", or any text bound for `gh pr create --body`, `gh pr create
  --body-file`, `gh pr edit --body`, `gh pr edit --body-file`, or a GitHub PR
  template. Triggers on "draft a PR", "write the PR", "summarize this branch
  for review", "regenerate PR body". MUST be invoked before any `gh pr create
  --body*` or `gh pr edit --body*` per empire-git rules. Outputs markdown for
  stdin.
compatibility: Requires the gh CLI and git. Designed for Claude Code (or similar agents).
allowed-tools: Bash Read Glob Grep
---

# PR Description Template

IMPORTANT: Output the rendered description verbatim. Do not summarize, paraphrase, or describe this skill. The caller pipes your output to `gh pr create` or `gh pr edit` unchanged.

## Voice

- Senior dev writing for peers. Direct. Active voice. Imperative mood.
- One idea per sentence. Short sentences. Lead with the point. Cut every word that adds no information; a reviewer should grasp each line in one pass.
- No dashes as connectors in prose. Avoid the em dash (`—`), en dash (`–`), and the spaced hyphen (`-`); they read as machine written. Split into two sentences or use a comma or colon. Hyphenated words like `off-by-one` and Markdown list bullets stay fine.
- No "this PR", "this commit", "I am", "we", filler openers.
- Explain why and what users or callers experience differently. Cut anything obvious from the diff.
- No emoji. No H1. No marketing tone. No "N/A".
- If `CONTEXT.md` exists in the repo, use its vocabulary for domain terms.

## Length

| Diff size | Budget                                                                |
| --------- | --------------------------------------------------------------------- |
| ≤ 100 LOC | ≤ 80 words, drop Test plan unless non-trivial                         |
| ≤ 500 LOC | ≤ 200 words, include only non-empty sections                          |
| > 500 LOC | ≤ 200 words, summarize at higher level, note the size in What changed |

Skip empty sections entirely.

## Sections

Render between markers. Preserve everything outside markers when updating.

```
<!-- pr-description:start -->
## Why
1–2 sentences. Problem or goal. Link issue if a commit references one.

## What changed
3–5 bullets. Behavior changes only — what users or callers experience differently.
Skip mechanical changes (renames, moves, test additions) unless they affect behavior.
Pick the most important changes; don't enumerate everything.

## Test plan
Manual steps to verify the change locally.
Omit for simple diffs or when the behavior is self-evident.
Never list CI steps (lint, typecheck, unit tests, CI pipelines).
<!-- pr-description:end -->
```

### Extra sections

Default to Why / What changed / Test plan only. Add an extra `##` section **only when the change carries something a reviewer must not miss** and no existing section fits — e.g. a breaking change, a required migration, a new env var or dependency, a rollback step, or a security-relevant note. Never add one by default or to pad a thin PR. Prefix breaking changes with `BREAKING:`.

## PR chains

When the branch was cut from another feature branch (not from main/master), or when the user provides a parent PR URL, add before the opening marker:

```
Depends on: <PR URL or branch name>
```

Detect by running `git log --oneline <default-branch>..HEAD` and checking if the branch base differs from the repo default branch.

For the visual stack overview (every PR in the chain, current one highlighted, merged ones struck-through), the `pr-stack` skill maintains a separate comment. Keep that out of the body — `Depends on:` is the only chain marker the body needs.

## Update mode

If an existing body is provided:

- Replace only content between `<!-- pr-description:start -->` and `<!-- pr-description:end -->`.
- Preserve all content outside markers (screenshots, reviewer notes, `Fixes #N`, task lists, `Depends on:` lines).
- If markers are absent: wrap new body in markers, append after author-written content.

## Labels and assignee

The rendered body is the only thing piped to `gh`. Labels and assignee are set with flags on the same `gh pr create`/`gh pr edit` call — never inside the body.

- **Assignee** — assign the PR to the author: `--assignee @me` on create, or `gh pr edit --add-assignee @me` on an existing PR.
- **Labels** — apply the labels that fit the change:
  - List the repo's real labels first: `gh label list`. Map type (`feat`/`fix`/`docs`/`chore`), affected area/scope, and size (only if the repo uses size labels) to the closest existing label.
  - Apply with `--label` on create or `gh pr edit --add-label`. If no existing label fits, apply none — do not force a wrong one.
  - **Never create a new label** unless the repo's issue-tracker agents file (e.g. `docs/agents/issue-tracker.md`) explicitly defines the label set agents may create. Absent that file, the existing labels are the only allowed set.

## Special cases

- Formatting/whitespace only: single line `Formatting only. No behavior change.` between markers.
- Title (when requested): Conventional Commits, lowercase, no period, ≤ 72 chars.
- Body language matches the language of recent commit messages.

## Anti-patterns

| Bad                         | Good                                                          |
| --------------------------- | ------------------------------------------------------------- |
| "This PR adds support for…" | "Add support for…"                                            |
| "We refactor auth to…"      | "Refactor auth: extract token validation into…"               |
| "Various fixes"             | (list each)                                                   |
| "Fixes bug"                 | "Fix off-by-one in pagination cursor when total % limit == 0" |
| "Updated tests"             | (omit — visible in diff)                                      |
| "Renamed X to Y"            | (omit unless rollout-relevant)                                |
| "Ran lint / CI / tests"     | (never include in test plan)                                  |
