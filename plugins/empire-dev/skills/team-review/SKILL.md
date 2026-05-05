---
name: team-review
description: >
  Trigger when user says: "team review", "have specialists review", "review my
  changes", "re-review", "review again", "another pass", "ask the team",
  "specialist review", "/empire-dev:team-review", "have the team look at this",
  "get specialists to review", "run a team review", "do a specialist review".
  Spawns parallel specialist subagents to review diffs and consolidates findings.
  Never posts to GitHub.
---

<section id="intent-gate">

- Trigger phrases split into two classes:
  - Strong: "team review", "specialist review", "have specialists", "ask the team", "parallel review", "have the team look", "/empire-dev:team-review", "re-review", "another pass"
  - Weak: "review my changes", "review again", "look at this"
- If user used a Strong phrase → proceed without confirmation
- If user used only a Weak phrase → MUST confirm before dispatch:
  - "Run a parallel team review (3–6 specialists), or a single-pass review?"
  - Default to single-pass on ambiguity; dispatch a team review only when user explicitly opts in or repo CLAUDE.md mandates it for non-trivial diffs
- MUST NOT silently dispatch a multi-agent review on weak phrasing alone

</section>

<section id="target-detection">

- Infer target from conversation context first
- Signals to read:
  - Files just edited this session
  - Recent tool calls touching specific paths
  - Explicit user mention ("the auth changes", "this PR", "uncommitted work")
  - Last commit topic if user references it
  - Current task scope from todos or plan
- No default fallback chain
- If conversation gives clear scope → use it (specific files, commits, branch range)
- If signals conflict or ambiguous → ASK user; offer concrete options:
  - Option A: files X, Y just edited
  - Option B: open PR #N
  - Option C: uncommitted diff
  - Option D: branch vs base
- MUST state inferred target + evidence before dispatch
- MUST confirm with user when not certain

</section>

<section id="no-github-writes">

- NEVER run `gh pr review`, `gh pr comment`, `gh pr edit`
- NEVER post inline PR comments
- NEVER write findings to GitHub in any form
- All reports stay local in chat only

</section>

<section id="specialist-selection">

- Inspect diff; pick 3–6 specialists matching change content
- Agent names vary by environment; do not assume a specific agent exists
- Inspect available subagents via the `Agent` tool's `subagent_type` parameter
- For each signal present in the diff, pick the available agent whose name/description best matches; if multiple candidates fit, prefer the most specific; if none fit, fall back to the most general code-reviewer-style agent available
- Signals to detect in the diff:
  - Language/framework — dominant language or framework of changed files
  - Security surface — auth, crypto, secrets, permissions, input handling
  - Architectural change — new module or package boundaries, dependency shifts, interface redesigns
  - Test changes — test files added or modified
  - Performance hotspot — hot paths, DB queries, batching, caching, resource allocation
  - Debugging need — complex logic, non-obvious control flow, subtle state mutations
  - Generalist coverage — always include at least one general code-reviewer agent to anchor the roster
- MUST list chosen specialists with their actual `subagent_type` values + one-line rationale per pick BEFORE dispatch
- If confident in every pick (clear signal-to-agent fit, no ambiguity) → dispatch immediately; user may interrupt mid-flight
- If uncertain about any pick (multiple candidates equally fit, no clear-fit agent for a signal, ambiguous diff scope) → MUST confirm roster with user before dispatch; allow swaps, additions, removals

</section>

<section id="parallel-dispatch">

- Send single message with multiple `Agent` tool calls (one per specialist)
- Each specialist receives:
  - Full diff or PR number
  - List of changed files
  - User's stated intent (if provided)
  - Output format instruction (see below)
  - "Do NOT post to GitHub. Report findings in chat only."
- Required specialist output format:

  ```
  ## Must-fix
  <file:line> — <concrete suggestion>

  ## Should-fix
  <file:line> — <concrete suggestion>

  ## Nits
  <file:line> — <concrete suggestion>

  ## Praise
  <what was done well>
  ```

- Cap each specialist response under 400 words

</section>

<section id="rereview-mode">

- Trigger: user says "re-review", "review again", "another pass"
- MUST use same roster as prior review; scroll back in conversation to find it
- If prior roster cannot be located (long conversation, summarization, ambiguity) → MUST ask user to confirm the roster before dispatch; do NOT improvise a new roster silently
- Pass each specialist:
  - Their prior review findings
  - User's responses or decisions since last review
  - New diff (what changed since last review)
  - Instruction: surface unresolved prior issues + new issues only
- Same output format as initial review

</section>

<section id="consolidated-report">

- After all specialists return, produce consolidated report
- Summary table:
  ```
  | Specialist | Must-fix | Should-fix | Nits |
  |---|---|---|---|
  ```
- Deduplicated `## Must-fix` — merged across specialists, file:line, concrete fix
- Deduplicated `## Should-fix`
- `## Conflicts` — where specialists disagree; state each side
- `## Recommended actions` — prioritized list; include rationale per item

</section>

<section id="confirmation-gate">

- Present recommended actions; ask user which to apply
- MUST wait for user reply before implementing anything
- Implement only chosen fixes
- One atomic commit per logical fix (follow repo git rules)

</section>

<section id="agent-availability">

- If zero suitable code-review/specialist agents exist in the environment → MUST stop and tell user; never inline-impersonate a specialist
- MUST NOT fabricate specialist personas inside the main thread

</section>
