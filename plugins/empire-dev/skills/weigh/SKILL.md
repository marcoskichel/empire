---
name: weigh
description: >
  Systematically evaluate architecture decisions, document trade-offs, and select
  appropriate patterns for context. Use when making technology choices, evaluating
  architectural patterns, creating Architecture Decision Records, assessing technical
  debt, or comparing design alternatives.
  Trigger phrases: "architecture decision", "ADR", "which pattern should I use",
  "evaluate trade-offs", "technology choice", "design pattern selection",
  "weigh the options", "/empire-dev:weigh".
  Findings stay local — never post to GitHub.
---

<section id="core">

**Context drives decisions.** No pattern is universally good or bad. The best architecture is not the most elegant — it's the one that best serves its purpose while remaining maintainable and evolvable.

Every architectural decision trades off:

| Vertex          | Maximized By                             | Cost                |
| --------------- | ---------------------------------------- | ------------------- |
| **Simplicity**  | Monolith, sync communication, single DB  | Scalability limits  |
| **Flexibility** | Microservices, event-driven, plugins     | Complexity overhead |
| **Performance** | Caching, denormalization, optimized code | Maintainability     |

Balance strategies: start simple; add complexity as needed; measure before optimizing; use abstractions to defer decisions; evolve incrementally.

</section>

<section id="domain-awareness">

SHOULD read `CONTEXT.md` at repo root before proceeding — use its vocabulary verbatim; never substitute synonyms.
SHOULD scan `docs/adr/` for decisions in the area under analysis — respect accepted ADRs; do not re-litigate closed decisions.
If neither exists, proceed without them. Do not create these files unprompted.

</section>

<section id="context-mapping">

MUST consider team and scale context before recommending patterns.

**Team context:**

| Context        | Prefer                               | Avoid                               |
| -------------- | ------------------------------------ | ----------------------------------- |
| Small team     | Monolith, vertical slices, shared DB | Microservices, complex abstractions |
| Multiple teams | Service boundaries, API contracts    | Shared state, tight coupling        |

**Scale context:**

| Context         | Prefer                           | Reasoning                      |
| --------------- | -------------------------------- | ------------------------------ |
| Startup / early | Monolith first, vertical scaling | Optimize for development speed |
| Enterprise      | Service mesh, horizontal scaling | Optimize for operational scale |

**Quality attributes to surface:**

- Performance: response time (p50/p95/p99), throughput, resource utilization
- Scalability: horizontal, vertical, elastic
- Reliability: uptime, MTBF, MTTR; patterns = circuit breakers, retries, redundancy
- Maintainability: readability, modularity, testability; patterns = Clean Architecture, DDD, SOLID

</section>

<section id="decision-matrix">

Use weighted matrix for comparing alternatives. Weight factors based on context priorities.

| Option   | Consistency | Flexibility | Scalability | Complexity | Cost | Total |
| -------- | ----------- | ----------- | ----------- | ---------- | ---- | ----- |
| Option A | 5           | 2           | 3           | 2          | 3    | 15    |
| Option B | 3           | 5           | 4           | 3          | 3    | 18    |
| Option C | 2           | 3           | 5           | 1          | 2    | 13    |

MUST list criteria and weights before scoring. MUST justify weights against stated context.

</section>

<section id="adr-template">

Use ADR for any decision that would be expensive to reverse.

Write to `docs/adr/NNNN-<slug>.md` — NNNN = next available number zero-padded to 4 digits; slug = lowercase-hyphenated title. Create `docs/adr/` if absent.

```markdown
---
adr: NNNN
title: <title>
date: YYYY-MM-DD
status: proposed
supersedes: null
tags: []
modules: []
---

# ADR-NNNN: <TITLE>

## Status

[Proposed | Accepted | Deprecated | Superseded by ADR-MMMM]

## Context

[Situation requiring a decision]

### Requirements

- [Requirement]

### Constraints

- [Constraint]

## Decision

[What is the decision?]

### Justification

- [Reason]

## Consequences

### Positive

- [Benefit]

### Negative

- [Drawback]

## Alternatives Considered

### [Alternative]

Reason rejected: [Why]
```

Update frontmatter `status` when the decision changes state. To supersede: set `status: superseded-by ADR-MMMM` in the old ADR; reference the old one in the new ADR's `supersedes` field.

</section>

<section id="refactoring-patterns">

**Branch by Abstraction** — create abstraction over current implementation → implement new solution behind abstraction → switch → remove old.

**Strangler Fig** — identify boundary → implement new solution for new features → gradually migrate old features → retire old system.

**Parallel Run** — implement new solution → run both old and new → compare results → switch when confident.

</section>

<section id="technical-debt">

| Type          | Examples                             | Payment Strategy      |
| ------------- | ------------------------------------ | --------------------- |
| Design        | Missing abstractions, tight coupling | Refactoring sprints   |
| Code          | Duplication, complexity, poor naming | Continuous cleanup    |
| Test          | Missing tests, flaky tests           | Test improvement      |
| Documentation | Missing docs, outdated diagrams      | Documentation sprints |

Metrics: debt ratio = debt work / total work (target < 20%); interest rate = extra effort caused by debt; debt ceiling = maximum acceptable debt.

</section>

<section id="anti-patterns">

**Big Ball of Mud** — no clear structure, everything depends on everything. Remedy: identify boundaries, extract modules, establish interfaces.

**Distributed Monolith** — services must deploy together, sync chains, shared DBs. Remedy: merge related services, async communication, separate DBs.

**Golden Hammer** — one solution for all problems, force-fitting patterns. Remedy: learn alternatives, evaluate objectively, prototype options.

</section>
