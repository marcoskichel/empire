# Bundled skills — attribution

Skills adapted from upstream open-source projects under the MIT License.
Originals live at the repos below. Local copies have been rewritten in
empire voice (`MUST`/`SHOULD`/`MAY`, fragments, `<section>` tags) and the
trigger phrases in `description` were retuned for empire's auto-route;
diagnostic content and intent are preserved.

## Sources

### From [jwynia/agent-skills](https://github.com/jwynia/agent-skills) — MIT, © Jerry Wynia

- `mint/SKILL.md` — adapted from `skills/general/ideation/naming/SKILL.md`. Renamed `naming` → `mint`.
- `distill/SKILL.md` — adapted from `skills/tech/development/architecture/requirements-analysis/SKILL.md`. Renamed `requirements-analysis` → `distill`.
- `probe/SKILL.md` — adapted from `skills/general/meta/good-thinking/SKILL.md`. Renamed `good-thinking` → `probe`.

## Greenfield (no upstream)

- `pitch/SKILL.md` — written for empire.
- `vet/SKILL.md` — written for empire.
- `recon/SKILL.md` — written for empire.
- `deck/SKILL.md` — written for empire.

## Local modifications

- Renamed `naming` → `mint` via `/empire-product:mint` itself, applied to its own port. Power sounds (m, t), captures act of minting names, single syllable matches empire's verb pattern (`vet`, `recon`, `pitch`, `deck`).
- Rewrote frontmatter: dropped `license`, `metadata` fields; expanded `description` to list trigger phrases verbatim.
- Rewrote prose voice: imperative mood, MUST/SHOULD/MAY, fragments, `<section>` tags.
- Dropped jwynia-specific sections: `Output Persistence`, `Output Discovery`, references to `conlang`, `worldbuilding`, `sensitivity-check`, `cliche-transcendence` skills (jwynia-only).
- Updated category-conventions table to include "developer tools" row matching empire's voice.
- Five naming states (N1–N5), four alignment layers, sound-meaning tables, syllable patterns, quick fixes, and anti-patterns preserved.
