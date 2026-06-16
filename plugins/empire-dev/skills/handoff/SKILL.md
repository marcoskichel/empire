---
name: handoff
description: >
  Use for `/empire-dev:handoff` and whenever one request chains multiple
  delivery stages on a single coding task into one unattended run — implement
  it, get it reviewed, address the feedback, open the PR, make CI pass, add
  labels — and the user wants the finished pull request rather than a check-in
  at each step. Trigger phrases: "handoff this", "drive this to a PR", "take
  this and run with it", "implement, review, and open a PR", "build it, have
  the team review, then push a PR", "do the whole thing", "run this
  autonomously", "I'm stepping away — carry this to a PR", "ship this for me".
  Often points at a ticket or spec file. Invoking the skill is the ship-intent
  signal — it authorizes the full push-and-PR chain. NOT for a single stage in
  isolation (only review, only a PR body, only implement, only a plan) — those
  have their own skills. Flags judgment calls for human review instead of
  guessing silently.
allowed-tools: Bash Read Edit Write Glob Grep Skill Agent TodoWrite
argument-hint: "[task description | spec path]"
---

# Handoff

Drive one task from intent to a labelled PR with green CI, autonomously. The human hands off; you take it the whole way and surface what they should look at later.

**User input:** $ARGUMENTS

<section id="authorization">

Invoking this skill IS the user's ship-intent signal. It overrides the default "work stays local until the user says ship" rule: you are authorized to push, open a PR, and drive CI without stopping to ask permission for those steps.

Authorization is NOT unconditional. It covers the normal forward path. It does NOT cover the hard-stop cases in [autonomy-boundaries](#autonomy-boundaries) — there you still stop and ask, because guessing wrong on those is more expensive than a pause.

The point of handoff is to remove babysitting, not judgment. Run the routine; flag the consequential.

</section>

<section id="setup">

Before any work, build the spine so progress survives a long run and the user can see where you are.

- Create a TodoWrite list with one item per phase below (0 Plan, 1 Implement, 2 Review, 3 Address, 4 PR, 5 CI, 6 Label). Mark each in-progress/done as you go — this is the user's progress bar for an unattended run.
- Open an isolated worktree via `/empire-git:worktree-open` with a branch derived from the task, and do all work inside it. Rationale: handoff mutates files and pushes; keeping it off the user's current branch is the whole reason worktrees exist. The worktree lives until CI is green and labels are set — never close it mid-run (the CI fix loop needs it).
- Work in place ONLY if the user explicitly says so. If working in place, hard-stop and ask before mutating when EITHER holds: the current branch is the default/protected branch (`main`, `master`), or the working tree already carries unrelated uncommitted changes. Pushing handoff's commits onto the user's main branch or entangling them with unrelated work is exactly the kind of irreversible surprise [autonomy-boundaries](#autonomy-boundaries) exists to prevent.
- If `superpowers:*` skills referenced below are not installed, don't error mid-run: do the equivalent inline (plan/TDD by hand) or skip-with-a-flag. Never stall an unattended run on a missing optional dependency.
- Read `CONTEXT.md` at repo root and relevant `docs/adr/` entries if present. Carry their vocabulary and decisions through every phase — plans, code, PR body, and flags all use project terms verbatim.
- Start a running **flag log** (in-memory list). Append to it whenever you hit a decision worth human eyes (see [flagging](#flagging)). It feeds the PR body and the final report.

</section>

<section id="phase-plan">

## Phase 0 — Plan (only if a spec exists)

A spec means: the user pointed at a spec/plan file, `docs/superpowers/specs/` has a matching one, or the task is large/multi-step enough that implementing blind would thrash.

- Spec or plan-worthy scope → invoke `superpowers:writing-plans` to produce a written plan, then implement against it.
- No spec and the task is a small, well-bounded change → skip planning. A plan for a one-file fix is overhead, not safety. State that you're skipping and why.

If the task is ambiguous enough that you can't tell what "done" means, that's a hard stop — see [autonomy-boundaries](#autonomy-boundaries). Don't invent requirements.

</section>

<section id="phase-implement">

## Phase 1 — Implement

- Follow the plan if one exists; otherwise work directly from the task.
- Match the surrounding code — its conventions, naming, test style, comment density. Read neighbours before writing.
- Where the project has tests, prefer `superpowers:test-driven-development` (test first, then code). Where it doesn't, don't bolt on a framework unasked — flag the absence instead.
- Run the project's own checks (build, lint, tests, formatters) before declaring the phase done. Never claim it works without running it — evidence before assertion.
- Commit in atomic, logically-scoped commits following repo git rules (Conventional Commits with plugin scope per the repo conventions).

</section>

<section id="phase-review">

## Phase 2 — Team review

- Invoke `/empire-dev:team-review` on the diff. It picks the specialist roster, dispatches in parallel, and returns a tiered consensus report.
- Let it choose the roster from the diff signals. Don't hand-pick unless the diff is so narrow one specialist obviously covers it.

</section>

<section id="phase-address">

## Phase 3 — Address findings

Here handoff deliberately **overrides** team-review's wait-for-the-user gate. The user already authorized action by invoking handoff, so apply the safe fixes and flag the rest rather than blocking.

| Finding tier / kind                                                      | Action                                                                           |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| Consensus Must-fix / Should-fix                                          | Apply. High agreement, clear defect.                                             |
| Corroborated Must-fix                                                    | Apply.                                                                           |
| Corroborated Should-fix                                                  | Apply if the fix is mechanical and low-risk; otherwise flag.                     |
| Single-source (low-confidence)                                           | Do NOT auto-apply. Flag with the specialist's rationale so the human can decide. |
| Conflicts between specialists                                            | Do NOT pick a side silently. Flag both positions.                                |
| Nits                                                                     | Apply if trivial; otherwise drop. Don't flag nits — noise.                       |
| Any fix that changes intended behaviour, public API, or security posture | Flag, don't apply. That's a product decision.                                    |

After applying, re-run the project's checks. If fixes are substantial, a re-review pass is reasonable but not mandatory — use judgment on whether the change surface warrants it. A re-dispatched `team-review` will hit its own wait-for-the-user confirmation gate; handoff overrides that gate the same way this phase does — apply the safe tier, flag the rest, keep moving. Don't let an autonomous run silently stall waiting for input it promised not to need.

</section>

<section id="phase-pr">

## Phase 4 — Open the PR

- Generate the body with `/empire-git:pr-description` and use its output verbatim — never hand-write a `gh pr create --body`. This is a repo rule, not a preference.
- Append a flags section to the body so the human sees the judgment calls on the PR itself, not buried in chat:

  ```
  ## Decisions & flags for review
  - <decision or open question> — <why it needs a human> [<file:line> if applicable]
  ```

  Place it after the generated body. If the flag log is empty, omit the section entirely — don't write "None".

- Title: Conventional Commits, lowercase, no period, ≤ 72 chars.
- Push with `git push -u origin <branch>` from inside the worktree, then `gh pr create`. Do NOT run `/empire-git:worktree-close` here — it removes the worktree, and the CI fix loop in Phase 5 still needs it. Worktree teardown is the user's call after the PR lands; mention it in the final report rather than doing it mid-run.
- Push only handoff's own feature branch. Never push to the base/default branch, and never force-push.

</section>

<section id="phase-ci">

## Phase 5 — Watch CI

- Watch checks by polling `gh pr checks` on an interval. Prefer polling over `gh pr checks --watch`: `--watch` blocks until a terminal state and can't honor the wall-clock bound below, so a stuck pipeline would hang the run.
- If the repo has no CI configured (no checks ever register), skip this phase cleanly — don't watch nothing. Note it in the final report.
- On failure: read the failing job's logs, diagnose, fix, commit, push to the same feature branch (never force-push), re-watch. This is a bounded loop, not an infinite one.
- Bound the wait, not just the retries: if checks stay `queued`/`pending` without progress past a reasonable wall-clock window (~15–20 min), stop watching and flag — a stuck pipeline is the human's to chase, not yours to spin on.
- Stop the loop and flag when ANY of these holds:
  - 3 fix attempts on the same check have not turned it green — you're likely missing context the human has.
  - The failure is in infra/flaky territory (runner died, network, unrelated job), not your diff.
  - The fix would require a decision that belongs to [autonomy-boundaries](#autonomy-boundaries) (e.g. changing a security check, disabling a test).
- Never make a check pass by weakening it (deleting the assertion, adding `--no-verify`, `skip`, lowering coverage gates). That's defeating the signal, not fixing the code. Flag instead.

</section>

<section id="phase-label">

## Phase 6 — Assign labels

- List the repo's actual labels first: `gh label list`. Never invent labels that don't exist.
- Infer labels from the diff content and PR intent — type (`feat`/`fix`/`docs`/`chore`), affected area/scope, size if the repo uses size labels.
- Apply with `gh pr edit --add-label`. Map to the closest existing label; if no label clearly fits, add none and note it in the final report rather than forcing a wrong one.

</section>

<section id="flagging">

## What to flag for human review

The skill's value is knowing the difference between "decide and move on" and "a human needs to weigh in." Flag — don't silently decide — when:

- You picked between materially different implementation approaches and the choice has lasting consequences (data model, public API shape, dependency added).
- You inferred a requirement the task didn't state.
- A review finding was low-confidence, conflicting, or behaviour-changing (per [phase-address](#phase-address)).
- You worked around a CI failure rather than truly fixing it, or skipped a check.
- You noticed something out of scope that looks wrong but you chose not to touch.

Each flag is one line: **what** you decided or what's open, **why** it needs a human, and a `file:line` anchor when there is one. Flags land in the PR body and the final chat report. Routine, reversible choices do not get flagged — over-flagging buries the signal as badly as under-flagging.

</section>

<section id="autonomy-boundaries">

## Hard stops — ask, don't guess

Authorization to ship does not extend to these. Stop and ask the user:

- **Ambiguous done-criteria** — you can't tell what success looks like from the task + spec. Building the wrong thing fast is worse than asking.
- **Destructive / irreversible** — data migrations, deleting files you didn't create, force-push, history rewrite, dropping resources, pushing to the base/default branch. Handoff pushes only its own feature branch.
- **Security & secrets** — anything touching auth, crypto, credentials, permissions in a way the task didn't clearly call for; committing anything that looks like a secret.
- **Scope explosion** — the task turns out to need far more than implied (new service, broad refactor, breaking change). Surface the revised scope before sinking hours into it.
- **External side effects beyond the PR** — deploys, publishing packages, posting to external systems, anything outward-facing the task didn't authorize.

When stopped, report what you've done so far, the specific decision you need, and your recommendation. Resume when answered.

</section>

<section id="final-report">

## Final handoff report

End every run with a compact status the user can scan in seconds:

```
## Handoff complete  (or: paused / blocked)
- PR: <url>  ·  CI: <green / failing job> ·  Labels: <applied>
- Phases: Plan <state> · Implement <state> · Review <state> · Address <state> · PR <state> · CI <state> · Label <state>

## Flags for review
- <flag> — <why> [<file:line>]

## What I decided on my own
- <notable routine decision the user might want to know, kept short>
```

Omit empty sections. If paused at a hard stop, lead with the decision you need.

</section>
