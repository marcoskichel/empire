# Bundled skills — attribution

Skills adapted from upstream open-source projects under the MIT License.
Originals live at the repos below. Local copies have been rewritten in
empire voice (`MUST`/`SHOULD`/`MAY`, fragments, `<section>` tags) and the
trigger phrases in `description` were retuned for empire's auto-route;
diagnostic content and intent are preserved.

## Sources

### From [jwynia/agent-skills](https://github.com/jwynia/agent-skills) — MIT, © Jerry Wynia

- `weigh/SKILL.md` — adapted from `skills/tech/development/architecture/architecture-decision/SKILL.md`. Renamed `architecture-decision` → `weigh`.
- `shape/SKILL.md` — adapted from `skills/tech/development/architecture/system-design/SKILL.md`. Renamed `system-design` → `shape`.
- `slice/SKILL.md` — adapted from `skills/tech/development/quality/task-decomposition/SKILL.md`. Renamed `task-decomposition` → `slice`.

## Greenfield (no upstream)

- `team-review/SKILL.md` — written for empire.

## Local modifications

- Renamed each skill via `/empire-product:mint` to match empire's terse-verb naming convention (`vet`, `recon`, `pitch`, `deck`).
- Rewrote frontmatter: dropped `license`, `compatibility`, `metadata` fields; expanded `description` to list trigger phrases verbatim per empire's auto-route requirement.
- Rewrote prose voice: imperative mood, MUST/SHOULD/MAY, fragments, `<section>` tags. Reference: `plugins/empire-dev/skills/team-review/SKILL.md`.
- Dropped jwynia-specific sections: `Output Persistence`, `Output Discovery`, `Reasoning Requirements`, `Context Management`, references to `context-network`, `references/*` paths.
- Rewrote cross-skill `Integration` references to point at empire skills (e.g. `distill` → `shape`, `shape` → `weigh`) instead of jwynia originals.
- Diagnostic states, decision tables, anti-patterns, and core principles preserved.
