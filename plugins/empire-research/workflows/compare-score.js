export const meta = {
  name: "compare-score",
  description:
    "Parallel blind per-option scoring for /empire-research:compare — each option scored against the agreed dimensions in isolation, no cross-option anchoring; the skill builds the weighted matrix.",
  whenToUse:
    "Invoked by /empire-research:compare after the option list and dimensions are confirmed, when the Workflow tool is available. Requires args {options:[{name}], dimensions:[{name,description}]}. Recommendation-only: never edits or posts externally.",
  phases: [{ title: "Score", detail: "one scorer per option, blind to rivals" }],
};

const OPTION_SCHEMA = {
  type: "object",
  required: ["option", "summary", "scores", "pros", "cons"],
  properties: {
    option: { type: "string" },
    summary: { type: "string" },
    scores: {
      type: "array",
      minItems: 1,
      items: {
        type: "object",
        required: ["dimension", "score", "confidence"],
        properties: {
          dimension: { type: "string" },
          score: { type: "integer", minimum: 1, maximum: 5 },
          evidence: { type: "string" },
          confidence: { type: "string", enum: ["Confirmed", "Estimated", "Inferred"] },
        },
      },
    },
    pros: { type: "array", items: { type: "string" } },
    cons: { type: "array", items: { type: "string" } },
    citations: { type: "array", items: { type: "string" } },
  },
};

const options = args?.options ?? [];
const dimensions = args?.dimensions ?? [];
const useCase = args?.useCase ?? "";
const constraints = args?.constraints ?? "";

if (options.length < 2 || dimensions.length === 0) {
  return {
    error: "compare-score requires args {options:[{name}] (>=2), dimensions:[{name,description}]}.",
  };
}

phase("Score");
const dimList = dimensions
  .map((d) => "- **" + d.name + "**" + (d.description ? " — " + d.description : ""))
  .join("\n");
log("Scoring " + options.length + " options on " + dimensions.length + " dimensions");

const SCORE_PROMPT = (o) =>
  "## Option scorer\n\n" +
  "Score ONE option against each dimension, in isolation. Do NOT compare to other options.\n\n" +
  (useCase ? "## Use case\n" + useCase + "\n\n" : "") +
  (constraints ? "## Constraints\n" + constraints + "\n\n" : "") +
  "## Option\n**" +
  o.name +
  "**" +
  (o.description ? " — " + o.description : "") +
  "\n\n" +
  "## Dimensions\n" +
  dimList +
  "\n\n" +
  "## Task\n" +
  "- Score each dimension 1-5 (5 best) for this option only.\n" +
  "- Back each score with concrete evidence; use WebSearch/WebFetch for facts.\n" +
  "- Tag each score Confirmed (official docs/benchmarks/source), Estimated (indirect evidence), or Inferred (reasoning, no citation).\n" +
  "- Never present Inferred as fact.\n" +
  "- Do NOT post findings to any external system.\n\nStructured output only.";

const results = await parallel(
  options.map(
    (o) => () =>
      agent(SCORE_PROMPT(o), {
        label: "score:" + o.name,
        phase: "Score",
        schema: OPTION_SCHEMA,
      }).then((r) => {
        if (!r) return null;
        log(o.name + ": scored " + r.scores.length + " dims");
        return r;
      }),
  ),
);

const optionResults = results.filter(Boolean);
log("Scoring done: " + optionResults.length + "/" + options.length + " scored");

return {
  useCase,
  dimensions,
  options: optionResults,
  stats: { requested: options.length, scored: optionResults.length },
};
