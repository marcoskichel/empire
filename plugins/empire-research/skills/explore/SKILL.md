---
name: explore
description: >
  Trigger when user says: "explore options", "what could we do for X",
  "research approaches", "/empire-research:explore",
  "investigate approaches", "spawn research team", "what are the options",
  "options analysis", "explore solutions", "have the team explore". Open-ended
  exploration: shallow scan enumerates 3–5 candidate approaches, user picks
  subset to deep-dive, parallel research per approach, consolidated comparison
  with recommended direction. Findings stay local — never posted externally.
---

<section id="purpose-vs-compare">

- Use `explore` when the solution space is open: user knows the problem, not the options
- Use `/empire-research:compare` instead when user already has a known set of options to evaluate head-to-head
- If user input names specific options (A vs B vs C), suggest `/empire-research:compare` and confirm before proceeding here

</section>

<section id="context-gathering">

- Read conversation for problem statement, scope, constraints, success criteria
- Signals to read:
  - Explicit user description of the problem
  - Recent code or files providing technical context
  - Stated constraints (budget, timeline, stack, team size)
  - Prior approaches already ruled out
  - Definition of "good enough" outcome
- If problem statement unclear → ask one clarifying question at a time
- If structured choices help → use `AskUserQuestion` with concrete options
- MUST state inferred problem statement back to user before any dispatch
- MUST get user confirmation on problem statement
- MUST NOT dispatch any agent until problem is confirmed

</section>

<section id="shallow-scan">

- After problem confirmed, dispatch ONE research agent for broad enumeration
- Agent names vary by environment; do not assume a specific agent exists
- Inspect available subagents via the `Agent` tool's `subagent_type` parameter
- Pick the available agent whose name/description best matches general research synthesis or broad information retrieval; if multiple candidates fit, prefer the most specific; if none fit, use the most general research-oriented agent available
- Shallow agent instructions:

  - Enumerate 3–5 candidate approaches only
  - One short paragraph per approach — no deep evaluation
  - Required output format:

    ```
    1. <Approach Name>
       <One-paragraph description — what it is, how it addresses the problem>

    2. <Approach Name>
       ...
    ```

  - Cap response under 300 words

- Present shallow-scan output to user verbatim before proceeding

</section>

<section id="user-gate">

- Gate exists because deep-dive spawns one parallel agent per approach (real cost) — user steers spend toward the approaches worth researching
- After shallow scan, present results and ask user:
  - Which approaches to deep-dive (may pick multiple)
  - Whether to add, remove, or reframe any approach
- MUST wait for explicit user selection before deep dispatch
- MUST NOT infer selection and proceed silently
- If user requests a different approach not in list → add it, confirm updated list

</section>

<section id="agent-selection">

- Pick one deep agent per selected approach
- Agent names vary by environment; do not assume a specific agent exists
- Inspect available subagents via the `Agent` tool's `subagent_type` parameter
- For each selected approach, identify its dominant signal from these categories:
  - General synthesis, multi-source aggregation
  - Fast targeted retrieval, known-solution space
  - Quantitative datasets, benchmarks, numerical evidence
  - Peer-reviewed or scientific evidence
  - Emerging-tech trajectory, trend analysis
- For each signal that applies, pick the available agent whose name/description best matches; if multiple candidates fit, prefer the most specific; if none fit, use the most general research-synthesis agent available
- MUST always include at least one general research-synthesis agent to anchor the roster
- List chosen agent per approach (using its actual `subagent_type` value) + one-line rationale BEFORE dispatch
- If confident in every pick → dispatch immediately
- If uncertain about any pick → confirm roster with user before dispatch; allow swaps

</section>

<section id="parallel-deep-dispatch">

- Send single message with multiple `Agent` tool calls (one per approach)
- Each agent receives:
  - Original confirmed problem statement
  - The specific approach assigned to them
  - All known constraints and success criteria
  - Output format instruction (see below)
  - "Do NOT post findings to any external system. Report in chat only."
- Required deep agent output format:

  ```
  Approach: <name>

  Summary: <2-3 sentences>

  Pros:
  - <point>

  Cons:
  - <point>

  Key Evidence / Citations:
  - <source or concrete reference>

  Fit Rating: <High / Medium / Low> — <one sentence rationale>
  ```

- Cap each agent response under 500 words

</section>

<section id="consolidated-report">

- After all deep agents return, produce consolidated report
- Comparison table:
  ```
  | Approach | Pros | Cons | Fit |
  |---|---|---|---|
  ```
- `Conflicts` section — where agents cite contradicting evidence; state each side
- `Recommended approach` — prioritized pick with rationale; cite supporting evidence
- MUST cite sources where agents returned citations
- MUST present report then stop; ask user which direction to pursue
- MUST NOT begin implementation

</section>

<section id="guardrails">

- MUST gather and confirm problem context before any agent dispatch
- MUST clarify ambiguity before shallow scan
- MUST confirm shallow results with user before deep dispatch
- MUST dispatch deep agents in parallel (single message, multiple tool uses)
- MUST keep all findings local in chat only
- MUST NOT post to Slack, GitHub, Jira, or any external system unless user explicitly authorizes
- MUST NOT implement chosen approach — recommendation only
- MUST NOT proceed through any gate without explicit user confirmation
- If zero suitable research-synthesis agents exist in environment → MUST stop and tell user; never inline-impersonate a researcher

</section>
