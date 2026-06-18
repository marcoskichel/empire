# empire-dev

Skills installed under the `empire-dev` Claude Code plugin.

- `/empire-dev:team-review` is opt-in; dispatch only when user uses a Strong trigger phrase or explicitly confirms after a Weak phrase — never auto-escalate based on diff size
- For follow-up review passes after addressing comments, the same roster is reused — say "re-review" or "another pass" to re-dispatch
- When a bundled or general-purpose subagent is better-qualified for a question than the main thread, MUST delegate — pick by fit, not by question size
- When independent subtasks exist, SHOULD dispatch specialist subagents in parallel; if isolation requirements are unclear, MUST ask whether subagents share one worktree or each get their own before dispatching
- MUST route product prompt authoring (system prompts, agent definitions, tool descriptions, eval prompts for user's LLM features) through `ai-engineer` subagent — does not apply to project meta prompts (CLAUDE.md, SKILL.md, plugin rules)
- Default local-only; never write to GitHub without explicit user validation of each item and the specific action
- MUST surface assumptions before implementing; present ambiguous interpretations, never pick silently
- Surgical edits: every changed line MUST trace to the user's request — no drive-by refactors or adjacent touches
- MUST remove imports/vars/functions YOUR edits made unused; MUST NOT remove pre-existing dead code unless asked
- Simplicity: no speculative abstractions, no unrequested "flexibility" — min code that solves the problem
