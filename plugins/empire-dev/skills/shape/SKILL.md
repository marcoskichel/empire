---
name: shape
description: >
  Diagnose system design problems and guide architecture decisions — catches
  over- and under-engineering, surfaces missing integration points, drives
  toward a walking skeleton before full build-out. Use when designing a
  system, when architecture feels too complex or too vague, or when
  integration points are unclear. Findings stay local. Trigger phrases:
  "system design", "how should I structure this", "too much abstraction",
  "under-engineered", "where do I start building", "design this system",
  "walking skeleton", "/empire-dev:shape".
---

<section id="core">

**Design emerges from constraints.** Every architectural decision is a trade-off against something else. Make trade-offs explicit before they become bugs.

MUST NOT proceed with design until requirements exist — architecture serves requirements, so designing without them optimizes for the wrong target. If requirements are unclear, use `/empire-dev:distill` first.

</section>

<section id="domain-awareness">

SHOULD read `CONTEXT.md` at repo root before proceeding — use its vocabulary verbatim; never substitute synonyms.
SHOULD scan `docs/adr/` for decisions in the area under analysis — respect accepted ADRs; do not re-litigate closed decisions.
If neither exists, proceed without them. Do not create these files unprompted.

</section>

<section id="states">

### SD0: No Requirements Clarity

**Symptoms:** Starting architecture before requirements are clear. "I'll figure it out as I build." Can't articulate what problem architecture serves. Technology choices made before needs understood.

**Key questions:** What problem does this system solve? What are the constraints? What must it accomplish vs. what would be nice?

**Interventions:** Return to `/empire-dev:distill`. At minimum: write one paragraph describing the problem (no solutions); list 3-5 things the system must do; list real constraints (time, skills, integrations). MUST NOT proceed until you can explain what you're building and why.

---

### SD1: Under-Engineering

**Symptoms:** No separation of concerns. Database schema is "I'll figure it out." No thought to data flow or error handling. "I'll refactor later" for everything. Building without mental model of how pieces connect.

**Key questions:** What happens when X fails? Where does data come from and go? What changes are likely? What's the most complex operation?

**Interventions:** Data flow mapping — trace data from entry to exit. Error case enumeration for critical paths. Change likelihood assessment: stable vs. volatile? Component identification: what are the major pieces?

---

### SD2: Over-Engineering

**Symptoms:** Abstracting for hypothetical futures. "In case we ever need..." driving decisions. Microservices for a solo project. Patterns without problems. Configuration for things that will never change.

**Key questions:** What problem does this abstraction solve TODAY? Are you designing for users you have or imagine? What's the simplest thing that could work? Would you bet money this flexibility will be needed?

**Interventions:** YAGNI audit — flag anything serving hypothetical needs. Complexity budget: pick your battles, be simple elsewhere. "What would break" test: if simpler, what actually fails? Rule of three: don't abstract until you see the pattern three times.

---

### SD3: Missing Integration Points

**Symptoms:** Building in isolation without considering what connects. APIs designed without clients in mind. No thought to authentication, logging, deployment. External dependencies discovered late.

**Key questions:** What does this component need from outside itself? What does the outside world need from this component? How does data enter and leave the system? What about auth, logging, monitoring, deployment?

**Interventions:** Interface-first design for critical boundaries. Dependency inventory: what's external? Integration checklist: auth, config, logging, errors, deployment. Boundary identification: where does your code meet the world?

---

### SD4: Risky Decisions Unidentified

**Symptoms:** No explicit architectural decision records. Can't articulate why this approach vs. alternatives. Decisions made implicitly or by default. No reversal cost awareness. "I just went with what I know."

**Key questions:** Which decisions would be expensive to reverse? Why this approach instead of alternatives? What would make this decision wrong? Where are you relying on assumptions vs. knowledge?

**Interventions:** ADR for significant decisions. Reversal cost assessment: easy / moderate / hard to change. Assumption log with validation approach. Use `/empire-dev:weigh` for decisions that would hurt to change.

---

### SD5: No Walking Skeleton

**Symptoms:** All components designed to completion before any integration. No end-to-end path through the system. Can't demo anything working together. Building horizontally. Integration deferred until "everything is ready."

**Key questions:** What's the thinnest path through the whole system? Can you demo one thing working end-to-end? What's the riskiest integration? Can you test it early?

**Interventions:** Walking skeleton definition: minimal end-to-end path. Integration order planning: what connects first? Risk-first integration: prove risky connections early. Identify first vertical slice.

---

### SD6: Design Validated

**Indicators:** Architecture supports requirements without excess. Risky decisions documented with rationale. Integration points identified. Walking skeleton defined. Clear path to implementation.

**Next step:** Begin implementation, starting with walking skeleton.

</section>

<section id="diagnostic-process">

1. Read `CONTEXT.md` and relevant ADRs in `docs/adr/` if present — use domain vocabulary throughout
2. Confirm requirements exist — if not, redirect to `/empire-dev:distill`
3. Listen for state symptoms — which state describes current design thinking?
4. Start at the earliest problem state — MUST NOT skip ahead; earlier states gate later ones, and an unaddressed foundation resurfaces downstream
5. Ask key questions for that state
6. Apply interventions — work through exercises
7. Produce artifacts — document decisions that matter
8. Define walking skeleton — know what to build first

</section>

<section id="anti-patterns">

**The Architecture Astronaut** — designing for scale, flexibility, extensibility you'll never need. Microservices for a weekend project. Fix: YAGNI audit. For every abstraction, ask "what problem does this solve TODAY?"

**The Implicit Decision** — architecture by accident. Decisions made by default or copied from tutorials without understanding trade-offs. Fix: ADRs for any decision expensive to reverse. "Why this instead of alternatives?" If you can't answer, you haven't decided yet.

**The Big Bang Integration** — building all components in isolation, connecting at the end. Fix: walking skeleton first. Thinnest path through all layers. Prove integration works before building out.

**The Golden Hammer** — using familiar technology regardless of fit. Fix: match technology to problem. Let constraints guide choices, not familiarity.

**The Premature Optimization** — designing for performance problems you don't have. Fix: design for clarity first. Optimize where performance actually matters. Measure before optimizing.

**The Dependency Denial** — not acknowledging external dependencies until they cause problems. Fix: integration checklist early. What external services? What must be configured? What could fail?

</section>
