---
name: pr-merge-stack
description: >
  Merge an entire stack of dependent PRs bottom-up: merge the base PR, pull
  the base branch, rebase the next PR onto it, wait for CI, merge, repeat
  until the stack is empty. Use when the user says "merge the stack", "merge
  pr stack", "land the stack", "merge all these PRs", "merge the chain",
  "ship the whole stack", or names several stacked PRs to merge in order.
  Infers the stack from conversation; asks when it can't. Offers admin merge
  (skip review requirements) up front — CI must still pass either way.
compatibility: Requires the gh CLI, git, and network access to GitHub.
model: sonnet
allowed-tools: Bash Read Glob Grep
argument-hint: "[pr numbers or branches, bottom to top] [--admin]"
---

# PR Merge Stack

Merge a chain of stacked PRs one by one, bottom-up, keeping each remaining PR rebased and green before it lands.

**User input:** $ARGUMENTS

CRITICAL: Never merge red CI — not even with `--admin`. Admin mode only bypasses review requirements. And never plain-rebase a child onto the base after its parent squash-merged; always `git rebase --onto` (Step 4).

## Step 1 — Identify the stack

Build the ordered list of PRs, bottom (base = default branch) to top:

- If `$ARGUMENTS` names PRs or branches, use those.
- Otherwise infer from the conversation: PRs or branches discussed in this session.
- Verify and order the chain — each PR's `baseRefName` must be the previous PR's `headRefName`:

```bash
gh pr view <pr> --json number,title,state,baseRefName,headRefName,mergeable,mergeStateStatus,url
```

- If no stack can be inferred, or the chain has gaps (a base branch with no open PR), ask the user which PRs form the stack before touching anything.

Confirm the resolved order with the user in one line before merging: `#12 ← #13 ← #14 (3 PRs, bottom-up)`.

## Step 2 — Offer admin merge

Check whether the user can bypass review requirements:

```bash
gh api repos/<owner>/<repo> --jq .permissions.admin
```

If true (and the user didn't already pass `--admin`), ask once up front:

```
question: "Merge with admin privileges (skip review requirements)? CI must still pass for every PR."
header:   "Admin merge"
options:
  - label: "Yes — admin merge"
    description: "Merge each PR without waiting for review approval. CI stays a hard gate."
  - label: "No — wait for approvals"
    description: "Each PR must satisfy branch protection (reviews) before it merges."
```

Remember the answer for the whole stack; don't re-ask per PR.

## Step 3 — Merge the bottom PR

For the current bottom PR:

1. **Wait for CI:**

```bash
gh pr checks <pr> --watch
```

- Green → continue.
- Red → stop the loop. Investigate and fix (the `pr-merge` skill's CI gate applies), or report to the user. Never merge red, never skip to the next PR — the stack above depends on this one.

2. **Merge and delete the branch:**

```bash
gh pr merge <pr> --squash --delete-branch  # add --admin only if authorized in Step 2
```

Honor the repo's allowed merge methods (`gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`); prefer squash.

## Step 4 — Pull base and rebase the next PR

Nothing left in the stack → Step 5. Otherwise:

1. **Update the local base branch** (fast-forward only, never clobber a dirty tree):

```bash
git fetch origin <base>
git -C <base-checkout> merge --ff-only origin/<base>   # if the base is checked out locally
```

2. **Verify retargeting.** GitHub retargets the child PR's base to `<base>` when the merged branch is deleted — confirm with `gh pr view <next-pr> --json baseRefName` before pushing.

3. **Rebase the child.** The parent was squash-merged, so its old commits would replay and conflict on a plain rebase. Replay only the child's own commits:

```bash
git fetch origin
git rebase --onto origin/<base> <merged-parent-branch> <child-branch>
git push --force-with-lease
```

If more PRs sit above, one command restacks them all: rebase from the topmost branch with `--update-refs`, then `git push --force-with-lease origin <each-branch>`. If a rebase skill is available, prefer it — it also checks the branch still makes semantic sense on the new base.

Resolve conflicts by understanding both sides, never by blindly taking one. If a conflict is non-trivial, stop and ask the user.

4. **Loop.** The rebased PR is the new bottom → back to Step 3. The `--force-with-lease` push restarts its CI; `--watch` in Step 3 covers the wait.

## Step 5 — Report

One line per PR: merged (method, admin or not), plus the final state — e.g. `#12 ✓ squash, #13 ✓ squash (admin), #14 ✓ squash — stack merged, local master fast-forwarded`. Note anything deferred to the user (conflicts, red CI, missing permissions).

## Why

Stacked PRs merged naively break in two ways: merging out of order orphans children, and plain-rebasing after a squash merge replays the parent's commits as conflicts. Merging strictly bottom-up with `rebase --onto` and a hard CI gate per PR lands the whole chain without either failure mode.
