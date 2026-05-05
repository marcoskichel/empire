---
name: dissect
description: >
  Systematically investigate complex claims by decomposing them into atomic
  verifiable components, resolving vague entities, verifying each component
  independently, and separating confirmed facts from narrative interpretation.
  Use when fact-checking complex claims, investigating narratives that mix facts
  with interpretation, or when a claim bundles multiple assertions.
  Trigger phrases: "investigate this claim", "fact-check this", "is this true",
  "decompose this narrative", "viral content check", "trace this claim",
  "/empire-research:dissect".
  Findings stay local — never post to GitHub.
---

<section id="core">

**Complex claims combine verifiable facts with unverifiable interpretations.** Effective investigation decomposes claims into atomic components, verifies each independently, and clearly distinguishes confirmed facts from narrative framing.

Difference from `/empire-research:verify`: `dissect` investigates external claims (social media, sources). `verify` checks AI-generated output for hallucinations.

</section>

<section id="decomposition">

### Extract Atomic Claims

Break the statement into individual verifiable claims. Each MUST be:

- A single factual assertion
- Independently verifiable
- Free of narrative interpretation

**Example:**
Original: "The House Leader refusing to seat the newly-elected AZ-07 special election winner because she'd vote to release the Epstein files"

Atomic claims:

1. There is a House Leader (entity exists)
2. There was an AZ-07 special election (event occurred)
3. Someone won that election (result exists)
4. The winner has not been seated (current state)
5. A refusal action occurred (specific action claim)
6. Causal relationship with Epstein files (causation claim)

### Classify Each Component

| Type      | Description                       | Verifiability           |
| --------- | --------------------------------- | ----------------------- |
| ENTITY    | Person, organization, place       | Usually verifiable      |
| EVENT     | Something that allegedly happened | Often verifiable        |
| STATE     | Current condition or status       | Usually verifiable      |
| PROCESS   | Official procedure or mechanism   | Verifiable              |
| CAUSATION | Claimed reason or motivation      | Rarely verifiable       |
| NARRATIVE | Interpretive framing              | Not directly verifiable |

### Identify Missing Information

Note what's conspicuously absent: unnamed entities, unspecified dates, missing procedural context, absent opposing perspectives.

</section>

<section id="entity-resolution">

Convert vague references to specific, searchable terms before searching.

- "House Leader" → current House Speaker/Majority Leader name
- "newly-elected winner" → candidate names from election results
- "Epstein files" → specific documents/investigations

For each event: when did it allegedly occur? What is normal timeline for this type of event? Are there procedural deadlines?

Identify: primary actors (taking alleged actions), secondary actors (affected), official bodies with relevant authority, potential verification sources.

</section>

<section id="verification">

### Verify Foundational Facts First

Start with most basic, verifiable claims:

1. Did the event occur?
2. Do the entities exist?
3. Are basic facts correct?

Search strategy: official sources first (.gov, electoral bodies) → cross-reference multiple news sources → look for primary documents.

### Investigate Procedural Context

For any claimed action/inaction:

1. What is normal procedure?
2. What are the requirements?
3. What is typical timeline?
4. What are legitimate reasons for delays?

### Examine Causation Claims

Causation requires direct evidence — "X happened" + "Y exists" does not confirm "X because Y."

**Direct evidence:** quoted statements from alleged actor, official statements or press releases, video/audio of relevant statements.

**Indirect evidence:** other explanations for observed facts, standard reasons for similar situations, procedural explanations.

**Context:** previous positions by involved parties, historical precedents, timeline compatibility.

</section>

<section id="source-evaluation">

**Priority order:**

1. Official government records / databases
2. Direct statements from involved parties
3. Court documents or legal filings
4. Contemporary news reports (multiple outlets)
5. Analysis or opinion pieces (noted as such)

**For each source, note:** type (official / news / advocacy / social media), date relative to events, whether claims are attributed, presence of supporting documentation, corrections or updates issued.

**Document bias without dismissing:** source's typical alignment, stakeholder relationships, pattern of coverage, language choices (neutral vs. charged).

</section>

<section id="narrative-patterns">

Patterns indicating narrative rather than fact:

- Causal chains without evidence ("X because Y because Z")
- Mind-reading claims ("thinks that," "wants to")
- Selective fact inclusion
- Temporal conflation (mixing time periods)
- False dichotomies

For each narrative: what facts support it? What facts complicate it? What alternative narratives explain the same facts? What facts are excluded?

</section>

<section id="output-format">

```
VERIFIED FACTS:
- [Fact] (Source: [citation], Confidence: Certain/Probable/Possible)

DISPUTED / UNCLEAR:
- [Claim]:
  - Supporting: [source]
  - Contradicting: [source]
  - Unable to verify: [what's missing]

CONTEXT NEEDED:
- [Procedural context]
- [Historical precedent]

NARRATIVE ELEMENTS (not directly verifiable):
- [Claim]
  - Facts that support: [list]
  - Facts that complicate: [list]
  - Alternative explanations: [list]
```

**Confidence levels:**

| Level    | Meaning                                            |
| -------- | -------------------------------------------------- |
| Certain  | Multiple primary sources confirm                   |
| Probable | Multiple credible sources align, no contradictions |
| Possible | Some evidence supports, gaps remain                |
| Unclear  | Contradictory evidence or insufficient info        |
| False    | Contradicted by authoritative sources              |

</section>

<section id="anti-patterns">

**Confirmation Rush** — finding one source that matches the claim and declaring it verified. Fix: require 2-3 independent sources. Trace claims back to primary sources. Check if "multiple sources" are repeating the same original.

**Causation Collapse** — accepting "X happened because Y" when only "X happened" and "Y exists" are verified. Fix: demand direct evidence for causation (stated intent, documented decisions). Report as "alleged motivation" when causation can't be verified.

**Premature Debunking** — finding one fact wrong and dismissing the entire claim. Complex claims often mix true and false elements. Fix: decompose fully, verify each component independently.

**Authority Fallacy** — accepting official sources uncritically. Official sources can be wrong, incomplete, outdated, or misleading. Fix: cross-reference official sources; distinguish "official position" from "verified fact."

**Narrative Anchoring** — starting with a hypothesis and investigating to prove it. Fix: start with specific claims as stated. Investigate each on its own terms. Actively seek disconfirming evidence.

</section>
