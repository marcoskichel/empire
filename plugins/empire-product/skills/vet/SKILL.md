---
name: vet
description: >
  Trigger when user says: "vet this idea", "vet idea", "validate idea",
  "go no go", "pressure test", "is this idea good",
  "kill the idea", "should I build this", "fatal flaw check", "what do you think of this product",
  "stress test the idea", "brutal honesty on this idea". Pressure-tests a
  product idea: web research for competitors and demand, fatal-flaw hypothesis,
  anti-sycophancy mode, structured go/no-go output with pivots.
  Findings stay local — never posted externally.
---

<section id="anti-sycophancy">

- Default stance: skeptical. Assume the idea has a fatal flaw until evidence proves otherwise.
- DO NOT validate ideas because they sound clever or because the user is excited
- DO NOT soften critique to spare feelings — vague praise hides real risk
- DO NOT pad weak signals into strong evidence
- DO credit strengths objectively only when evidence supports them
- If the idea genuinely survives scrutiny, say so plainly — anti-sycophancy ≠ contrarian

</section>

<section id="context-gathering">

- Required input before dispatch:
  - One-sentence pitch (problem + audience + proposed solution)
  - Target user / customer
  - Why now (market timing, unlock, trigger)
  - Assumed differentiator / unfair advantage
  - Monetization model (if relevant)
- Optional input: competitor list (2–6 names); if provided, `/empire-product:recon` runs before validator dispatch and its matrix pre-populates the Competitor Teardown section
- If any required input missing → ask one clarifying question at a time
- MUST state the inferred pitch back to user before any dispatch
- MUST get user confirmation on pitch and assumptions
- MUST NOT proceed without confirmed pitch

</section>

<section id="agent-selection">

- Inspect available subagents via the `Agent` tool's `subagent_type` parameter
- Pick the available agent whose name/description best matches idea validation, brutal pressure-testing, or go/no-go analysis. Bundled fallback: `project-idea-validator`. If a more specialized validator exists in the environment, use it.
- Competitor research — choose one path, never both:
  - Competitors provided → invoke `/empire-product:recon` now; wait for matrix output; it will pre-populate the Competitor Teardown section; do NOT ask the validator to research competitors
  - No competitors provided → include `competitive-analyst` subagent (or equivalent) alongside validator; it handles ad-hoc competitor discovery during validation
- MUST list chosen agents (`subagent_type`) and rationale BEFORE dispatch
- If confident in pick → dispatch immediately
- If uncertain (multiple validators equally fit, no clear-fit validator) → MUST confirm roster with user before dispatch; allow swaps

</section>

<section id="dispatch">

- Send dispatch message with the validator agent. Include:
  - Confirmed pitch + assumptions
  - User constraints (timeline, budget, team)
  - Required output format (see below)
  - "Default skepticism. Hunt for fatal flaws. Credit strengths only with evidence. Do NOT post findings externally."
- Required output format from validator agent:

  ```
  ## Pitch

  <restated in agent's words>

  ## Demand Signals

  <quantitative evidence: search volume, community size, competitor traction, willingness-to-pay indicators>

  ## Competitor Teardown

  <pre-populated from `/empire-product:recon` matrix when competitors were provided; otherwise researched by validator agent>

  | Competitor | Positioning | Strengths | Weaknesses | Threat Level |
  |---|---|---|---|---|

  ## Differentiation Test

  <does the proposed unfair advantage hold up under scrutiny? what's the wedge?>

  ## Fatal Flaws

  <if any — list with severity: HIGH / MEDIUM / LOW>

  ## Strengths (Earned)

  <only items with evidence>

  ## Risks

  | Type | Description | Severity |
  |---|---|---|
  | Market | ... | ... |
  | Execution | ... | ... |
  | Technical | ... | ... |
  | Distribution | ... | ... |
  | Regulatory | ... | ... |

  ## Recommendation

  <one of: PROCEED / PIVOT / KILL / INSUFFICIENT_DATA — with rationale>

  Use INSUFFICIENT_DATA when key signals (demand, competitor traction, willingness-to-pay) are `[Inferred]`-only and a confident verdict would manufacture false signal. Pair it with a concrete list of "evidence needed" items.

  ## Suggested Pivots (if PIVOT)

  - <concrete reframing of the idea — tighter niche, different audience, different wedge>

  ## MVP Scope (if PROCEED)

  - <stripped-down scope to validate the riskiest assumption>
  ```

- Cap response under 800 words

</section>

<section id="confidence-tagging">

- Mark each demand signal, competitor claim, and risk as `[Confirmed]`, `[Estimated]`, or `[Inferred]`:
  - Confirmed: cited search data, public competitor info, customer reviews, public reports
  - Estimated: derived from indirect evidence
  - Inferred: agent reasoning without citation
- MUST never present `[Inferred]` data as confirmed fact
- Recommendation MUST cite the strongest evidence supporting it

</section>

<section id="user-gate">

- Present validator output verbatim to user
- Then surface a one-paragraph summary highlighting:
  - Top fatal flaw (if any)
  - Strongest signal of demand or differentiation
  - Recommendation in one word
- Ask user which path forward: accept recommendation, push back with new evidence, request deeper-dive on a specific risk
- MUST wait for explicit user reply before any next step
- MUST NOT begin implementation, prototype, or pitch deck — recommendation only

</section>

<section id="preconditions">

- MUST verify web-search capability available before dispatch (`WebSearch` or equivalent in the validator agent's toolset)
- If unavailable → MUST refuse and tell user: validation depends on demand signals from public search data, competitor reviews, and public reports. Without web access the validator can only produce `[Inferred]` reasoning, which violates the anti-sycophancy contract.

</section>

<section id="guardrails">

- MUST gather and confirm pitch before dispatch
- MUST verify web-search capability before dispatch (see `preconditions`)
- MUST dispatch with anti-sycophancy framing in agent prompt
- MUST keep findings local in chat only
- MUST NOT post to Slack, GitHub, Jira, or external systems unless user explicitly authorizes
- MUST NOT soften critique on user pushback unless user supplies new evidence — explicitly require evidence to update the recommendation
- MUST distinguish confirmed evidence from inferred reasoning
- MUST NOT begin implementation work — even if recommendation is PROCEED
- If zero suitable validator/competitor agents exist in the environment → MUST stop and tell user; never inline-impersonate a validator

</section>
