export const meta = {
  name: "explore-deepdive",
  description:
    "Parallel per-approach deep research for /empire-research:explore — one researcher per selected approach returns structured pros/cons/fit for the skill to consolidate.",
  whenToUse:
    "Invoked by /empire-research:explore after the user picks which approaches to deep-dive, when the Workflow tool is available. Requires args {problem, approaches:[{name,description}]}. Recommendation-only: produces evidence, never edits or posts externally.",
  phases: [{ title: "Deep dive", detail: "one researcher per selected approach" }],
};

const APPROACH_SCHEMA = {
  type: "object",
  required: ["approach", "summary", "pros", "cons", "fit"],
  properties: {
    approach: { type: "string" },
    summary: { type: "string" },
    pros: { type: "array", items: { type: "string" } },
    cons: { type: "array", items: { type: "string" } },
    evidence: { type: "array", items: { type: "string" } },
    fit: { type: "string", enum: ["high", "medium", "low"] },
    fitRationale: { type: "string" },
  },
};

const problem = args?.problem ?? "";
const approaches = args?.approaches ?? [];
const constraints = args?.constraints ?? "";
const successCriteria = args?.successCriteria ?? "";

if (!problem || approaches.length === 0) {
  return {
    error: "explore-deepdive requires args {problem, approaches:[{name,description}]}.",
  };
}

phase("Deep dive");
log(
  "Researching " + approaches.length + " approaches: " + approaches.map((a) => a.name).join(", "),
);

const DEEP_PROMPT = (a) =>
  "## Approach researcher\n\n" +
  "Research ONE approach against the problem. Be evidence-based; cite concrete sources.\n\n" +
  "## Problem\n" +
  problem +
  "\n\n" +
  (constraints ? "## Constraints\n" + constraints + "\n\n" : "") +
  (successCriteria ? "## Success criteria\n" + successCriteria + "\n\n" : "") +
  "## Your assigned approach\n**" +
  a.name +
  "** — " +
  (a.description || "") +
  "\n\n" +
  "## Task\n" +
  "- Assess how well this approach solves the problem under the constraints.\n" +
  "- Use WebSearch/WebFetch where external evidence helps; prefer primary sources.\n" +
  "- Give concrete pros and cons and a fit rating (high/medium/low) with a one-sentence rationale.\n" +
  "- Do NOT compare to other approaches — judge this one on its own merits.\n" +
  "- Do NOT post findings to any external system.\n\nStructured output only.";

const results = await parallel(
  approaches.map(
    (a) => () =>
      agent(DEEP_PROMPT(a), {
        label: "deep:" + a.name,
        phase: "Deep dive",
        schema: APPROACH_SCHEMA,
      }).then((r) => {
        if (!r) return null;
        log(a.name + ": fit=" + r.fit);
        return r;
      }),
  ),
);

const approachResults = results.filter(Boolean);
log("Deep dive done: " + approachResults.length + "/" + approaches.length + " researched");

return {
  problem,
  approaches: approachResults,
  stats: { requested: approaches.length, researched: approachResults.length },
};
