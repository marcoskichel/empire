---
name: recon
description: >
  Trigger when user says: "competitor analysis", "compare competitors",
  "/empire-product:recon", "competitor matrix", "competitor research",
  "feature gap", "scout competitors", "size up competition", "pricing
  comparison vs competitors", "positioning analysis", "competitive landscape".
  Maps competitor pricing, features, positioning, and gaps into a side-by-side matrix
  with confidence-tagged data and a positioning angle. Different from
  `/empire-research:compare`, which evaluates tools, libraries, vendors, or architectural
  choices — NOT competitors. Findings stay local — never posted externally.
---

<section id="purpose">

- Map the competitive landscape across the dimensions that matter for a positioning or product decision
- Different from `/empire-research:compare` — `compare` evaluates options for a known purpose; `recon` scouts competitors for positioning intelligence
- Different from `/empire-product:vet` — `vet` pressure-tests an idea with go/no-go output; `recon` produces a structured matrix of competitor data without picking a winner
- MAY be invoked automatically by `/empire-product:vet` when competitors are provided; its matrix pre-populates `vet`'s Competitor Teardown section

</section>

<section id="context-gathering">

- Required inputs before dispatch:
  - Competitor list (at least 2; ideally 3–6 to keep matrix legible)
  - User's company / product (for relative comparison)
  - Industry / vertical
  - Dimensions to analyze (see `default-dimensions`)
  - Decision the analysis informs (positioning, pricing, feature roadmap, sales battlecard)
- If any input missing → ask one clarifying question at a time
- For dimensions, suggest a default subset based on the stated decision
- MUST confirm competitor list, dimensions, and decision goal before dispatch

</section>

<section id="default-dimensions">

Suggest the relevant subset based on the user's stated decision:

- Pricing: tier structure, anchor price, free tier, packaging, hidden costs, willingness-to-pay signals
- Features: core capabilities, recent launches, gaps vs. user's product, depth on top 3 jobs-to-be-done
- Positioning: tagline, value prop, audience targeting, narrative angle, perceived strengths
- Audience: target persona, ICP, geography, segment focus
- Distribution: channels, partnerships, content strategy, ad presence
- Tech stack: platform choice, language, infrastructure (when public)
- Funding / traction: funding stage, headcount estimate, public traction signals
- Moats: network effects, data, switching costs, brand, regulatory

User can add, remove, or reweight dimensions before dispatch.

</section>

<section id="agent-selection">

- One agent per competitor for parallel scouting
- Inspect available subagents via the `Agent` tool's `subagent_type` parameter
- Pick the available agent whose name/description best matches competitor research, market analysis, or competitive intelligence. Bundled fallback: `competitive-analyst`. Optionally include `market-researcher` for market-sizing dimensions.
- MUST list chosen agents (`subagent_type`) per competitor + rationale BEFORE dispatch
- If confident in every pick → dispatch immediately
- If uncertain (multiple scouts equally fit, no clear-fit agent for a competitor) → MUST confirm roster with user before dispatch; allow swaps

</section>

<section id="parallel-dispatch">

- Send single message with multiple `Agent` tool calls (one per competitor)
- Each agent receives:
  - The specific competitor assigned to them (one competitor per agent)
  - The agreed-upon dimension list with descriptions
  - User's company name and decision goal
  - Required output format (see below)
  - Ethical scope: "Use only publicly available info — websites, public reports, reviews, public ads. NEVER suggest social engineering, credential stuffing, or unauthorized access."
  - Confidence-tagging requirement (see `confidence-tagging`)
  - "Do NOT post findings externally."
- Required per-competitor output format:

  ```
  Competitor: <name>

  Summary: <2-3 sentences>

  Per-dimension data:
  | Dimension | Finding | Source | Confidence | As of |
  |---|---|---|---|---|

  Notable observations:
  - <point>

  Open questions / unknowns:
  - <point>
  ```

- Cap each agent response under 500 words

</section>

<section id="consolidated-matrix">

- After all competitor-agents return, produce side-by-side matrix
- Required structure:

  ```
  ## Competitive Landscape Matrix

  | Dimension     | <User's Co> | Competitor A | Competitor B | Competitor C |
  |---------------|-------------|--------------|--------------|--------------|
  | <dimension 1> | ...         | ... [Conf]   | ... [Est]    | ... [Inf]    |
  ...
  ```

- Cells include the confidence tag (`[Confirmed]`, `[Estimated]`, `[Inferred]`)
- Highlight cells where one competitor dominates or where a clear gap exists
- `## Gaps & Opportunities` — dimensions where the user's product is clearly behind OR where an unmet niche is visible
- `## Positioning Angle` — recommended narrative or wedge based on the matrix (where can the user own a position credibly?)
- `## Action Items` — prioritized, time-bound, specific (e.g. "Match competitor B's free-tier file limit within 30 days")
- `## Caveats` — known unknowns, freshness of data, dimensions that need primary research
- MUST cite sources from agent reports
- MUST present report then stop; ask user which action items to pursue

</section>

<section id="confidence-tagging">

- Every cell, claim, and source MUST carry one tag:
  - `[Confirmed]`: cited official site, public docs, public report, public reviews, public ad creative
  - `[Estimated]`: derived from indirect evidence (third-party reports, community estimates, similarweb-style traffic data)
  - `[Inferred]`: agent reasoning without citation
- Each cell MUST include an `As of` date when the data was observed
- MUST never present `[Inferred]` data as confirmed fact
- Recommendation and positioning angle MUST cite the strongest `[Confirmed]` evidence

</section>

<section id="ethical-scope">

- Use only publicly available information
- NEVER suggest, plan, or perform: social engineering, credential stuffing, unauthorized access, scraping behind authentication, impersonating customers or employees of competitors
- Quoted public claims by competitors are fair game; private info obtained through deception is not
- If the user requests a tactic that crosses this line, refuse and explain

</section>

<section id="preconditions">

- MUST verify web-search capability available before dispatch (`WebSearch` or equivalent in scout agents' toolset)
- If unavailable → MUST refuse and tell user: scouting depends on public sites, reviews, ads, and reports. Without web access scout agents can only emit `[Inferred]` data, which violates the confidence-tagging contract.

</section>

<section id="guardrails">

- MUST gather competitor list, dimensions, decision goal before dispatch
- MUST verify web-search capability before dispatch (see `preconditions`)
- MUST confirm with user before dispatch
- MUST dispatch in parallel (single message, multiple tool uses), one agent per competitor
- MUST keep findings local in chat only
- MUST NOT post to Slack, GitHub, Jira, or external systems unless user explicitly authorizes
- MUST tag every cell with confidence + as-of date
- MUST refuse out-of-scope tactics (social engineering, unauthorized access)
- MUST NOT begin implementation of any action item — recommendation only
- If zero suitable competitive-research/market-research agents exist in environment → MUST stop and tell user; never inline-impersonate a scout

</section>
