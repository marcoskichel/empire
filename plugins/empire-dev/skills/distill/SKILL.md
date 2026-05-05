---
name: distill
description: >
  Diagnose requirements problems and guide discovery of real needs vs. stated wants.
  Use before any implementation to distinguish problem from solution, surface hidden
  constraints, and bound scope to a viable V1.
  Trigger phrases: "requirements analysis", "what should I build", "clarify requirements",
  "is this the right problem", "define scope", "what does the user need",
  "distill requirements", "/empire-dev:distill".
  Findings stay local — never post to GitHub.
---

<section id="core">

**Requirements are hypotheses about what will solve a problem.** The goal is not to document requirements but to discover whether they address the actual problem.

MUST NOT discuss architecture or implementation until requirements are validated. Use `/empire-dev:shape` only after reaching RA5.

</section>

<section id="states">

### RA0: No Problem Statement

**Symptoms:** Starting with "I want to build X" (solution, not problem). Can't articulate who has what problem. "Everyone needs this" reasoning. Feature list without problem grounding. Copying existing solutions without understanding why they exist.

**Key questions:** What happens if this doesn't exist? Who suffers? What are people doing today instead? What triggered you thinking about this now?

**Interventions:** Jobs-to-be-Done interview: "When I [situation], I want to [motivation], so I can [outcome]." Problem archaeology: trace the idea back to a specific frustration. "Five users" test: name 5 specific people who would benefit.

---

### RA1: Solution-First Thinking

**Symptoms:** Requirements describe implementation ("needs a database", "should use React"). Can't explain requirements without referencing technology. Answering "what" with "how." Technology choice before problem clarity.

**Key questions:** If that technology didn't exist, what would you need? What outcome does this feature produce? Are you solving YOUR problem or copying someone else's solution?

**Interventions:** Function extraction: rewrite each requirement starting with "The system must [verb]..." without technology words. "Remove the solution" exercise: describe the need without ANY implementation. Constraint vs. preference distinction: is this technology required, or just familiar?

---

### RA2: Vague Needs

**Symptoms:** "Users should be able to..." without specifics. Requirements that can't be tested. Adjective requirements: "fast", "easy", "intuitive", "modern." No acceptance criteria imaginable. Can't describe what "done" looks like.

**Key questions:** How would you know if this requirement is met? What's the minimum that would satisfy this need? Can you give a specific example scenario?

**Interventions:** Specificity ladder: who specifically? doing what specifically? when specifically? Acceptance scenario writing: "Given X, when Y, then Z." Testability check: if you can't test it, you don't understand it yet.

---

### RA3: Hidden Constraints

**Symptoms:** Discovering blockers mid-implementation. "Oh, I forgot to mention..." Assumptions treated as facts. Surprise dependencies appearing late.

**Key questions:** What's definitely true about this context (real constraints)? What are you assuming is true (assumptions to validate)? What resources/skills/time do you actually have? What external dependencies exist?

**Interventions:** Constraint inventory: list budget, time, skills, dependencies, integrations. Assumption mapping: validated vs. unvalidated. Risk pre-mortem: "It's 6 months later and this failed. Why?" Dependency discovery: what must exist before this can work?

---

### RA4: Scope Creep

**Symptoms:** Requirements expanding faster than they're satisfied. "While we're at it..." additions. Can't distinguish core from nice-to-have. No clear boundary between V1 and future. Every feature feels equally important.

**Key questions:** What's the smallest thing that would be useful? What could you cut and still solve the core problem? If you could only ship 3 things, what are they? What triggers reconsidering deferred items?

**Interventions:** MoSCoW prioritization: Must / Should / Could / Won't. Walking skeleton identification: thinnest useful version. Force-rank exercise: strict ordering, no ties. Cut-first approach: start with everything out, add back only what's essential.

---

### RA5: Requirements Validated

**Indicators:** Problem articulated without mentioning solutions. Each requirement has acceptance criteria. Constraint inventory separates facts from assumptions. V1 boundary is explicit with deferred items listed. You know what would make the requirements wrong.

**Next step:** Hand off to `/empire-dev:shape` with Validated Requirements Document.

</section>

<section id="diagnostic-process">

1. Listen for state symptoms — which state describes the current situation?
2. Start at the earliest problem state — MUST NOT skip ahead (if RA0 symptoms exist, don't jump to RA2)
3. Ask key questions for that state
4. Apply interventions — work through exercises
5. Validate before moving on — check indicators before progressing
6. Produce artifacts — Problem Statement, Need Hierarchy, Constraint Inventory, Scope Definition

</section>

<section id="key-questions">

**Problem discovery:** What's the problem? Who has it (be specific)? What do they do today without this? What triggered this idea?

**Need clarification:** What must the solution accomplish? How would you know if it's working? What's the minimum viable version?

**Constraint discovery:** What's your actual time budget? What skills do you have / need? What must this integrate with? What assumptions haven't you validated? What would kill the project?

**Scope definition:** What's in V1 vs. later? What would you cut if forced? What triggers reconsidering deferred items? What's explicitly NOT in scope?

</section>

<section id="anti-patterns">

**The Solution Specification** — requirements that describe implementation, not needs. "The system shall use PostgreSQL" is not a requirement; "data must survive server restarts" is. Fix: for each requirement, ask "could this be satisfied a different way?"

**The Stakeholder Fiction** — solo developer imagining requirements instead of discovering them. Fix: if you're the user, be honest about YOUR needs. Don't invent users.

**The Infinite Backlog** — everything is equally important. Fix: force-rank. If you could only ship ONE thing, what is it?

**The Premature Precision** — specifying details that don't matter yet. Fix: identify which requirements need precision now vs. can be deferred.

**The Constraint Blindness** — not inventorying real constraints, then hitting them mid-build. Fix: explicit constraint inventory BEFORE requirements.

**The Feature Transplant** — copying features from existing products without understanding if they solve YOUR problem. Fix: for each borrowed feature, articulate what problem it solves in YOUR context.

</section>
