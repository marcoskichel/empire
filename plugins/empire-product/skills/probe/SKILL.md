---
name: probe
description: >
  Diagnose thinking failures; audit whether reasoning serves inquiry or defense.
  Use when reasoning feels stuck or circular, a conclusion feels defended not discovered,
  confidence is high but evidence thin, analysis grows elaborate without growing accurate,
  or the same approach keeps failing.
  Trigger phrases: "check my thinking", "am I reasoning well", "why am I stuck",
  "reasoning feels circular", "probe my logic", "/empire-product:probe".
  Two modes: self-monitoring (audit own process) and user coaching (diagnose user's
  thinking with questions, not declarations).
compatibility: Designed for Claude Code (or similar agents).
---

<section id="core">

**Good thinking is an active achievement.** Operations without orientation produce sophisticated wrong answers. Orientation without operations produces good intentions with no traction.

Two types must work together:

- **Operations** — cognitive verbs that transform representations (Decouple, Differentiate, Match, Monitor, Hold, Compress, and their complements). Agnostic about what they serve. Same operations produce insight OR sophisticated self-deception.
- **Orientations** — what operations are in service of. Defined by what stays fixed while everything else moves.

**Process-sovereignty** (target orientation): inquiry is responsive to evidence. Conclusions move when evidence demands. What is fixed = the meta-commitment to responsiveness itself.

**Captured orientations** (what to diagnose):

- Conclusion-preservation — a conclusion is fixed; the process bends to defend it
- Authority-preservation — being the authority is fixed; conclusions flex to maintain status
- Threat-reduction — discomfort drives resolution; complexity misread as danger
- Completion-seeking — producing output that sounds good is the goal, not accuracy

</section>

<section id="domain-awareness">

SHOULD read `CONTEXT.md` at repo root if present — use its vocabulary verbatim; imprecise terminology can mask reasoning failures.
If `CONTEXT.md` does not exist, proceed without it. Do not create it unprompted.

</section>

<section id="operations">

Seven operations in complementary pairs. Skill = oscillation between poles, not picking one.

| Operation                     | Action                                                                                       | Failure Modes                                                                                                                                 |
| ----------------------------- | -------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Decouple / Re-couple**      | Detach from binding (belief, identity, context); reattach to reality                         | Fusion (can't separate idea from frame). Dissociation (detach without grounding back).                                                        |
| **Differentiate / Integrate** | Split: find joints. Merge: find common structure.                                            | Under-differentiation. Analysis paralysis. Premature integration. "And also" listing without connecting.                                      |
| **Match**                     | Detect structural correspondence; anomaly detection ("this should be like that but isn't")   | False matching. Surface matching (visible features not deep structure). Restricted match space from premature framing.                        |
| **Monitor / Interrupt**       | Evaluate whether current process is working; intervene when not. Always active.              | Co-option: under captured orientation, Monitor actively defends the wrong orientation. The self-corrective machinery becomes self-protective. |
| **Hold / Resolve**            | Hold: maintain unresolved tension against collapse pressure. Resolve: commit.                | Premature resolution (narrows recognition space). Perpetual hold (avoidance disguised as open-mindedness).                                    |
| **Compress / Expand**         | Build a map from territory, discarding detail. Return to source, recover what was discarded. | Compression that imposes structure source lacks. Map mistaken for territory.                                                                  |

</section>

<section id="states">

| State | Name                     | What's Fixed               | Mechanism        | First Move                            |
| ----- | ------------------------ | -------------------------- | ---------------- | ------------------------------------- |
| GT0   | No Orientation Awareness | Nothing (no metacognition) | Inertial         | Introduce orientation concept         |
| GT1   | Conclusion-Preservation  | A specific conclusion      | Identity fusion  | Decouple conclusion from identity     |
| GT2   | Authority-Preservation   | Being the authority        | Identity fusion  | Differentiate authority from accuracy |
| GT3   | Threat-Reduction         | Comfort / safety           | State activation | Address the state, then re-evaluate   |
| GT4   | Completion-Seeking       | Producing output           | Inertial / state | Hold before Resolve                   |
| GT5   | Monitor Co-option        | The defense itself         | Identity fusion  | External Monitor scaffolding          |
| GT6   | Operation Imbalance      | One operation pole         | Inertial         | Deploy the neglected pole             |
| GT7   | Premature Resolution     | The first frame            | Inertial / state | Re-open Hold, generate alternatives   |

**GT5 warning:** Cannot be fixed by more monitoring — that's the trap. More metacognitive activity that produces refinements but never reversals is the signature. Introduce external scaffolding (prediction tracking, outside feedback, literal scorekeeping).

**GT7 warning:** Early frame-commitment feels like clarity, not narrowing. Satisfaction-of-search: having found one answer, fails to recognize others even when looking directly at them.

</section>

<section id="diagnostic-process">

1. **Identify what's fixed.** Ask: "In this thinking process, what is not moving — what conclusion, role, comfort level, or output goal is treated as the immovable point?" If nothing is fixed except commitment to responsive inquiry, process-sovereignty is active.

2. **Check Monitor.** Is Monitor serving inquiry or defending a position? Red flag: metacognitive activity produces refinements but never reversals; engagement with counter-evidence always ends at the same conclusion.

3. **Assess operation balance.** Which operation pairs are active? Which poles are collapsed? Is the balance matched to the environment's structure, or habitual? Particular attention: is Hold active or collapsed? Is Decouple available or blocked by fusion?

4. **Match the capture mechanism.** Three mechanisms require different interventions:

   - **Identity fusion** — conclusion/role/method is part of self-concept. Monitor co-opted. Cannot be fixed by "just think harder." Requires Decouple applied to the identity binding + external Monitor scaffolding.
   - **State activation** — physiological state shifted orientation pre-deliberatively. Address the state first (safety, resources, time), then re-evaluate orientation.
   - **Inertial** — no active defense. Orientation appropriate at one point continues without re-evaluation. A prompt to re-evaluate is often sufficient.

5. **Select intervention based on mechanism, not surface behavior.** Same surface error (e.g., anchoring) can have different mechanisms. A simple re-evaluation prompt works for inertial capture and gets defended against in identity fusion.

</section>

<section id="modes">

**Self-monitoring mode** — apply to own process. Run diagnostic at key decision points. Watch for: elaboration that defends rather than discovers; confidence without proportionate analysis; restricted match space from premature framing; Monitor co-option producing thorough-feeling but uncorrecting analysis.

**User coaching mode** — diagnose the user's thinking pattern; guide with questions, not declarations. Lead with Key Questions from the relevant state. Goal: restore process-sovereignty, not impose conclusions about their thinking.

Coaching sequence:

1. Listen for symptoms — which state(s) might be active?
2. Ask diagnostic questions — confirm the mechanism
3. Name the pattern: "Here's what I'm noticing..."
4. Offer the relevant operation: "What if we tried [specific operation] here?"
5. Track whether intervention produces actual movement or better defense

</section>

<section id="key-questions">

Universal diagnostic questions — start here before state-specific:

1. What is fixed? "What conclusion, role, comfort level, or output goal is treated as the immovable point?"
2. Is Monitor serving inquiry or defending a position? "When did metacognitive checking last produce an actual course correction, not just a refinement?"
3. Which operations are active? "Which poles are collapsed?"
4. What is the mechanism? "Inertial, identity fusion, or state activation?"
5. Does the intervention match the mechanism? "Would a simple re-evaluation prompt work here, or be defended against?"

</section>

<section id="anti-patterns">

**The Bias Checklist** — treating good thinking as error avoidance; running through known biases and checking them off. Operates at surface-behavior level; cannot distinguish underlying mechanisms. Fix: diagnose orientation first.

**The Sophistication Trap** — responding to doubt about reasoning quality with more analysis, more careful reasoning, without checking orientation. More powerful operations under wrong orientation produce more effective defense of wrong conclusions. Fix: check orientation before adding analytical depth.

**The Uniform Fix** — applying the same intervention regardless of capture mechanism. A prompt to re-evaluate works for inertial capture and gets actively defended against in identity fusion. Fix: always diagnose the mechanism before selecting an intervention.

**The Perpetual Hold** — never resolving, never committing, disguised as open-mindedness. Hold and Resolve are a complementary pair. Fix: apply Monitor to the holding itself — is continued holding serving inquiry or serving comfort?

**The Surface Diagnosis** — matching observed behavior to a state label without investigating the underlying mechanism. Fix: go one level deeper; identify the mechanism.

</section>
