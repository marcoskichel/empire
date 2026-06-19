# Bundled skills — attribution

Skills adapted from upstream open-source projects under the MIT License.
Originals live at the repos below. Local copies have been rewritten in
empire voice (`MUST`/`SHOULD`/`MAY`, fragments, `<section>` tags) and the
trigger phrases in `description` were retuned for empire's auto-route;
diagnostic content and intent are preserved.

## Sources

### From [jwynia/agent-skills](https://github.com/jwynia/agent-skills) — MIT, © Jerry Wynia

- `dissect/SKILL.md` — adapted from `skills/general/research/verification/claim-investigation/SKILL.md`. Renamed `claim-investigation` → `dissect`.

## Greenfield (no upstream)

- `explore/SKILL.md` — written for empire.
- `compare/SKILL.md` — written for empire.

## Local modifications

- Renamed via `/empire-product:mint` to match empire's terse-verb naming convention.
- Rewrote frontmatter: dropped `license`, `metadata` fields; expanded `description` to list trigger phrases verbatim.
- Rewrote prose voice: imperative mood, MUST/SHOULD/MAY, fragments, `<section>` tags.
- Dropped jwynia-specific sections: `Output Persistence`, `Reasoning Requirements`, `Context Management`, `Feedback Loop`, references to `context-network` and `references/*` paths.
- Rewrote cross-skill references to point at empire skills.
- Claim categories, hallucination patterns, decomposition phases, source priority, and anti-patterns preserved.
