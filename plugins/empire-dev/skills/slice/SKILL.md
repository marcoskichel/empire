---
name: slice
description: >
  Transform overwhelming development tasks into manageable units — diagnoses why
  tasks fail to complete and applies decomposition patterns to create right-sized,
  independently deliverable work.
  Use when a task feels too big to estimate, when unsure where to start, when blocked
  by dependencies, or when scope keeps growing.
  Trigger phrases: "task too big", "can't estimate", "overwhelmed by scope",
  "where do I start", "break this down", "epic needs breakdown",
  "slice this up", "/empire-dev:slice".
---

<section id="core">

**The goal isn't more tasks — it's the right tasks.** Small enough to understand completely. Large enough to deliver value. Independent enough to avoid blocking.

| Cognitive Limit              | Threshold  | Implication             |
| ---------------------------- | ---------- | ----------------------- |
| Working memory               | 7±2 items  | Max concepts per task   |
| Context switch recovery      | 23 minutes | Minimize task switching |
| Files examined               | 15-20 max  | Bound task scope        |
| Days before completion drops | 2-3 days   | Keep tasks under this   |

| Duration          | Completion Rate |
| ----------------- | --------------- |
| < 2 hours         | 95%             |
| 2-4 hours         | 90%             |
| 4-8 hours (1 day) | 80%             |
| 2-3 days          | 60%             |
| 1 week            | 35%             |
| > 2 weeks         | <10%            |

</section>

<section id="domain-awareness">

SHOULD read `CONTEXT.md` at repo root before proceeding — use its vocabulary verbatim; never substitute synonyms.
SHOULD scan `docs/adr/` for decisions in the area under analysis — respect accepted ADRs; do not re-litigate closed decisions.
If neither exists, proceed without them. Do not create these files unprompted.

</section>

<section id="diagnostic-states">

### TD1: Too Big to Understand

**Symptoms:** Estimates range wildly. Can't hold all requirements in mind. More than 7 concepts to track.

**Interventions:** Apply INVEST criteria: Independent, Negotiable, Valuable, Estimable, Small, Testable. Use vertical slicing (each slice independently deployable). Apply walking skeleton (minimal end-to-end first).

---

### TD2: No Clear Entry Point

**Symptoms:** Multiple valid starting points. Paralysis. Everything seems connected.

**Interventions:** Front-load risk: start with highest-uncertainty items. Tracer bullet: minimal proof of concept. Find the walking skeleton: thinnest slice through all layers.

---

### TD3: Dependency Problems

**Symptoms:** "Blocked on X." Diamond dependencies. Coordination overhead.

**Interventions:** Interface contracts: define API, mock while implementing. Feature flags: deploy independently, enable when ready. Branch by abstraction: create layer, swap implementations.

---

### TD4: No Clear Done Criteria

**Symptoms:** "Almost done" forever. No way to verify completion.

**Interventions:** Define acceptance criteria (Given / When / Then). Time-box to force prioritization. Define explicit out-of-scope items.

---

### TD5: Scope Creep

**Symptoms:** Task keeps growing. "While we're here" additions.

**Interventions:** Freeze scope, spawn new tasks for additions. Define minimum viable version. Ship smallest version that solves the problem.

---

### TD6: Need Spike First

**Symptoms:** Estimate variance > 4x. New technology. Multiple viable approaches.

**Interventions:** Time-boxed spike (8 hours max). Deliverables: options, POC, trade-offs, revised estimate. Spike-then-implement pattern.

</section>

<section id="decomposition-patterns">

**Vertical Slicing (preferred for features)** — each slice is independently deployable and delivers value end-to-end.

```
Feature: User Profile Management

Slice 1: View basic profile (4h)
  - UI: Profile display
  - API: GET /profile
  - DB: Read profile

Slice 2: Edit profile name (6h)
  - UI: Edit dialog
  - API: PATCH /profile/name
  - DB: Update profile
```

**Walking Skeleton (for new systems)** — minimal end-to-end first, then flesh out incrementally.

```
1. Hello World page
2. One GET endpoint
3. Single table
4. Basic deploy
```

**Tracer Bullet (validate architecture)** — minimal proof that components can communicate.

```
Step 1: Minimal Service A (1h) - Hardcoded response
Step 2: Minimal Service B (1h) - Simple transformation
Step 3: Integrate (2h) - Prove they communicate
→ 4 hours to decision point
```

</section>

<section id="estimation">

**Fibonacci sizing:**

| Points | Meaning                       |
| ------ | ----------------------------- |
| 1      | Trivial, < 1 hour             |
| 2      | Simple, 1-2 hours             |
| 3      | Standard, 2-4 hours           |
| 5      | Moderate, 4-8 hours           |
| 8      | Complex, 1-2 days             |
| 13     | Very complex, 2-3 days        |
| 21     | **Too large, must decompose** |

**Three-point estimation:**

```
O = Optimistic (everything perfect)
L = Likely (normal case)
P = Pessimistic (major issues)

PERT estimate: (O + 4L + P) / 6
```

</section>

<section id="checklist">

Before starting any task, verify:

- [ ] All requirements fit in working memory?
- [ ] Duration under 2-3 days?
- [ ] Clear acceptance criteria?
- [ ] Dependencies identified and broken where possible?
- [ ] Can be completed independently?
- [ ] Delivers verifiable value?
- [ ] Estimate confidence is high?

Any "no" → further decomposition needed.

</section>

<section id="anti-patterns">

**Big Bang Delivery** — building complete system before any delivery. Fix: vertical slices, incremental value.

**Technical Tasks Without Value** — "Set up database," "Create service layer." Fix: include in feature tasks: "User can view products (includes DB)."

**Research Forever** — unbounded investigation. Fix: time-boxed spikes with deliverables.

**Perfect Decomposition** — over-analyzing before starting. Fix: decompose next 2 weeks only; details for later work emerge.

</section>
