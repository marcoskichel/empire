---
name: verify
description: >
  Systematic verification pass on generated content — catch hallucinations,
  confabulations, unsupported assertions. MUST be a separate pass from
  generation; cannot reliably self-check in one pass. Use after research
  synthesis or content generation, or whenever claim accuracy matters before
  delivery. For external claims (social media, sources), use
  `/empire-research:dissect`.
  Trigger phrases: "fact-check this", "verify these claims", "check for hallucinations",
  "second pass on accuracy", "verify the output", "is this accurate",
  "/empire-research:verify".
  Findings stay local — never post to GitHub.
---

<section id="separate-pass-requirement">

**Verification MUST be a separate pass from generation.** LLMs in generation mode cannot reliably catch their own hallucinations:

- Attention is on generation, not verification
- Coherence pressure makes false claims feel correct in context
- Same weights that produced the error will confirm it
- No external grounding to contradict confabulation

MUST complete generation first. THEN run a verification pass with adversarial stance, external grounding, and fresh attention on each claim.

</section>

<section id="states">

| State                         | Symptoms                                                                       | Risk                                                                  | Intervention                                   |
| ----------------------------- | ------------------------------------------------------------------------------ | --------------------------------------------------------------------- | ---------------------------------------------- |
| F1: No Verification Pass      | Content generated and delivered without fact-checking                          | Hallucinations pass through undetected                                | Run verification pass before delivery          |
| F2: Self-Verification         | Same pass asked to "check your facts" while generating                         | False confidence — errors confirmed by same process that created them | Complete generation first, then separate pass  |
| F3: Memory-Based Verification | Claims checked against "what I know" without external sources                  | Hallucinations verified by hallucinated knowledge                     | Require explicit source citation per claim     |
| F4: Selective Verification    | Only some claims checked; others assumed correct                               | Unchecked claims may contain errors                                   | Systematic extraction of ALL verifiable claims |
| F5: Verification Complete     | All claims extracted, each checked against sources, confidence levels assigned | —                                                                     | Deliver with verification status               |

</section>

<section id="claim-extraction">

Extract every verifiable statement from the content.

**Types to extract:**

- Factual assertions ("X is Y", "X causes Y")
- Statistics and numbers ("40% of...", "in 2023...")
- Attributions ("According to X...", "Research shows...")
- Definitions ("X means...", "X is defined as...")
- Historical claims ("X happened in...", "X was founded by...")
- Causal claims ("X leads to Y", "X prevents Y")
- Comparative claims ("X is better than Y", "X is the largest...")

**Skip:**

- Opinions clearly marked as such
- Hypotheticals and speculation (if labeled)
- Logical deductions from stated premises
- Direct quotes (verify attribution, not content)

**Categorize by verifiability:**

| Category        | Description                          | Strategy                                        |
| --------------- | ------------------------------------ | ----------------------------------------------- |
| Verifiable-Hard | Numbers, dates, names, quotes        | Must match source exactly                       |
| Verifiable-Soft | General facts, processes, mechanisms | Source should substantially support             |
| Attribution     | "X said...", "According to..."       | Verify source exists and said something similar |
| Inference       | Conclusions drawn from evidence      | Verify premises, assess reasoning               |
| Opinion-as-Fact | Subjective claim stated as objective | Flag for rewording or qualification             |

</section>

<section id="verification-process">

**Phase 1: Extract** — list all verifiable claims from the content.

**Phase 2: Check** — for each claim, attempt source verification.

```
### Claim: "[exact claim text]"
- Category: [Verifiable-Hard/Soft/Attribution/Inference]
- Source checked: [specific source]
- Finding: [Confirmed/Partially supported/Not found/Contradicted]
- Confidence: [High/Medium/Low]
- Notes: [discrepancies, qualifications needed]
```

**Verification outcomes:**

| Outcome             | Action                             |
| ------------------- | ---------------------------------- |
| Confirmed           | Keep, cite source                  |
| Partially supported | Qualify or narrow claim            |
| Not found           | Mark unverified, consider removing |
| Contradicted        | Remove or correct                  |
| Outdated            | Update or add recency caveat       |

**Phase 3: Assign confidence:**

| Level      | Criteria                                               |
| ---------- | ------------------------------------------------------ |
| High       | All key claims verified; no contradictions found       |
| Medium     | Most claims verified; some unverified but plausible    |
| Low        | Significant claims unverified; some corrections needed |
| Unreliable | Multiple contradictions found; major revision needed   |

</section>

<section id="hallucination-patterns">

Watch for these specific hallucination types:

**Plausible Fabrication** — specific details that sound right but don't exist. Examples: fake paper citations, non-existent statistics, invented quotes. Detection: verify specific claims against primary sources.

**Confident Extrapolation** — reasonable inference stated as established fact. Examples: "Studies show..." (no specific study), "Experts agree..." (no citation). Detection: require specific source for any claim of external support.

**Temporal Confusion** — mixing information from different time periods. Examples: old statistics presented as current, defunct organizations described as active. Detection: check dates on sources.

**Attribution Drift** — correct information attributed to wrong source. Examples: quote assigned to wrong person, finding attributed to wrong study. Detection: verify attribution specifically, not just content.

**Amalgamation** — combining details from multiple sources into one fictional source. Examples: invented study combining real findings from separate papers. Detection: verify the specific source exists and contains all attributed claims.

**Precision Inflation** — adding false precision to vague knowledge. Examples: "approximately 47.3%" when only "about half" is supported. Detection: check if source actually provides that level of precision.

</section>

<section id="output-format">

Deliver fact-checked content with verification status:

```markdown
## [Content Title]

[Content body]

---

### Verification Status

**Overall Confidence:** [High/Medium/Low]

**Verified Claims:**

- [Claim] — Source: [citation]

**Unverified Claims:**

- [Claim] — No source found; treat as uncertain

**Corrections Made:**

- [Original claim] → [Corrected claim] (Source: [citation])

**Caveats:**

- [Limitations or qualifications]
```

</section>

<section id="anti-patterns">

| Pattern                       | Problem                          | Fix                         |
| ----------------------------- | -------------------------------- | --------------------------- |
| "I'm confident"               | Confidence ≠ accuracy            | Require source citation     |
| "To the best of my knowledge" | Memory is unreliable             | Check external source       |
| "Research shows"              | Which research?                  | Cite specific source        |
| Verify-while-generating       | Same pass can't catch own errors | Separate passes mandatory   |
| Check one, assume rest        | Partial verification             | Check all or mark unchecked |

</section>
