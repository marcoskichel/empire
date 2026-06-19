# AGENTS.md

This file provides guidance for AI agents working with code in this repository.

## Repo nature

- Claude Code plugin marketplace. No build, no lint, no test harness.
- Single marketplace (`.claude-plugin/marketplace.json`) exposes six plugins: `empire` (meta bundle), `empire-git`, `empire-dev`, `empire-research`, `empire-product`, `empire-visual`. Plus `empire-rules` (utility, auto-installed as a transitive dependency).
- Plugin content = markdown SKILL files, dynamic-workflow `.js` scripts (in `empire-research`), and one bash bootstrap script (in `empire-git`).
- Validation = install-and-invoke in Claude Code. No CI suite.

## Layout

- `.claude-plugin/marketplace.json` — marketplace manifest. Each `plugins[]` entry points to one of the `plugins/empire-*` dirs.
- `plugins/empire-meta/.claude-plugin/plugin.json` — meta plugin (`name: "empire"`). Empty skills dir. Uses `dependencies` field to auto-install the sub-plugins.
- `plugins/empire-git/` — git workflow skills (`worktree-*`, `pr-description`) + `scripts/worktree-setup.sh`.
- `plugins/empire-dev/` — code `team-review` skill, pre-implementation engineering skills (`shape`, `weigh`, `slice`), plus 11 bundled dev subagents (code review, paradigms, domain experts).
- `plugins/empire-research/` — `explore` (open-ended), `compare` (closed), and `dissect` (claim investigation) research skills + `workflows/*.js` orchestration scripts, with `research-analyst` as bundled fallback subagent.
- `plugins/empire-product/` — product skills (`pitch`, `vet`, `recon`, `mint`, `distill`, `probe`), plus three bundled subagents (`project-idea-validator`, `competitive-analyst`, `market-researcher`).
- `plugins/empire-visual/` — `visual-first` output style (in `output-styles/`) + on-demand `visualize` skill for terminal-native ASCII diagrams. No subagents.
- `plugins/empire-*/skills/<skill-name>/SKILL.md` — one dir per skill. Skill name in frontmatter MUST match dir name.
- `plugins/empire-*/workflows/<name>.js` — dynamic-workflow scripts a skill drives via `Workflow({scriptPath})`. Plain JS run by the Claude Code workflow runtime; no `package.json`, no build.
- `plugins/empire-*/README.md` — one per plugin. Plugin-specific docs (skills list, triggers, source links). Root `README.md` is the project intro and links to these.
- `docs/superpowers/{specs,plans}/` — gitignored. Local-only design notes. Never commit.

## Skill authoring rules

- Use `/skill-creator` if available
- Frontmatter required: `name`, `description`. Optional: `model`, `allowed-tools`, `argument-hint`, `disable-model-invocation`.
- `description` MUST list trigger phrases verbatim — Claude auto-route uses them.
- Reference bundled scripts via `${CLAUDE_PLUGIN_ROOT}/scripts/<file>.sh`. Never hardcode repo paths.
- Reference bundled workflows via `${CLAUDE_PLUGIN_ROOT}/workflows/<file>.js` with the `Workflow` tool. A skill that drives a workflow MUST document an inline-Agent fallback for when the Workflow tool is unavailable.
- Users invoke skills as `/<plugin>:<skill-name>` once installed. Plugin namespaces: `empire-git`, `empire-dev`, `empire-research`, `empire-product`, `empire-visual`. The meta `empire` plugin contributes no skills.
- After editing a SKILL.md, also update the matching section in the plugin's `README.md` (`plugins/<plugin>/README.md`) if triggers, args, or behavior changed. Update root `README.md` only if the one-line plugin description in the plugins table needs to change.

## Adding a new skill

1. Use `/skill-creator` if available
2. Pick the right plugin (`empire-git`, `empire-dev`, `empire-research`, `empire-product`, or `empire-visual`). Create a new plugin only if the skill clearly fits no existing namespace.
3. Create `plugins/<plugin>/skills/<name>/SKILL.md` with frontmatter + body. Frontmatter `name` MUST match dir name.
4. Add a section to the plugin's `README.md` (`plugins/<plugin>/README.md`) under `## Skills`, mirroring existing entries (description, triggers, source link). If the plugin's one-line summary in the root `README.md` table is now out of date, update it too.
5. If shipping a script, drop it in `plugins/<plugin>/scripts/` and `chmod +x`.
6. Bump the version in `plugins/<plugin>/.claude-plugin/plugin.json`. If the change is user-visible across multiple sub-plugins, also bump `plugins/empire-meta/.claude-plugin/plugin.json`.
7. Test by installing the marketplace locally in Claude Code: `/plugin marketplace add <local-path-or-fork>` then `/plugin install <plugin>@empire` (or `empire@empire` for the bundle).

## Conventions

- Kebab-case for skill dirs and script filenames.
- Conventional Commits with optional scope. Use the plugin name as scope: `empire-git`, `empire-dev`, `empire-research`, `empire-product`, `empire-visual`, `empire-meta`, `empire-rules`. Use `marketplace` for marketplace-level changes. Use `!` for breaking marketplace/manifest changes.
- Skill prose voice depends on plugin:
  - `empire-dev`, `empire-product`, `empire-research`, `empire-visual`, `empire-rules`: imperative mood, MUST/SHOULD/MAY, fragments, `<section>` tags. See `plugins/empire-dev/skills/team-review/SKILL.md` as the reference.
  - `empire-git`: procedural prose with `## Step N` headers permitted. Command-style tools read more clearly as numbered procedures than as fragment lists. See `plugins/empire-git/skills/worktree-open/SKILL.md` as the reference.
- `allowed-tools` declaration:
  - Declare on skills that directly invoke `Bash`/`Read`/`Glob`/`Grep` (e.g. `worktree-*`, `sync-rules`, `pr-description`).
  - Do NOT declare on skills that purely delegate to subagents via `Agent` tool (e.g. `team-review`, `vet`, `recon`, `compare`, `explore`, `pitch`).
- Scripts use `set -euo pipefail`, color-coded `info/warn/die/success` helpers (pattern in `worktree-setup.sh`).

## Formatting and linting

- All formatting + security hooks orchestrated by `pre-commit` (config in `.pre-commit-config.yaml`).
- Tools: `prettier` (markdown/yaml/json), `shfmt` (shell), `shellcheck` (shell security), `actionlint` (GH Actions), `gitleaks` (secrets).
- One-time dev setup: `brew install pre-commit && pre-commit install`.
- CI runs identical checks via `.github/workflows/validate.yml`.
- Never bypass with `--no-verify`. If a hook fails, fix the underlying issue.

## What this repo is NOT

- Not a Node/Python/Go project. No `package.json`, no `pyproject.toml`. Don't add a build system unless asked.
- Not a backend. Skills run inside Claude Code on the user's machine. Assume zero server-side state.
