# Worktree skills — attribution

These skills are ported from an upstream open-source project under the MIT
License.

## Sources

### From [ThinkVelta/claude-worktree-tools](https://github.com/ThinkVelta/claude-worktree-tools) — MIT

- `worktree-open` — `skills/worktree-open/SKILL.md`
- `worktree-close` — `skills/worktree-close/SKILL.md`
- `worktree-list` — `skills/worktree-list/SKILL.md`
- `worktree-merge` — `skills/worktree-merge/SKILL.md`
- `worktree-cleanup` — `skills/worktree-cleanup/SKILL.md`
- `worktree-help` — `skills/worktree-help/SKILL.md`

## Greenfield (no upstream)

- `pr-description` — written from scratch.

## Local modifications

- Repackaged as a Claude Code plugin with auto-detection of package managers
  (pnpm, npm, yarn, bun, uv, poetry, pipenv, bundler, cargo, go modules).
- Removed per-repo `npx` install step and `/wt-adopt` bootstrap.
- Added deterministic worktree path derivation (branch name → stable hash),
  port offset allocation, and `.env*` copy-on-open.
- `worktree-setup.sh` rewritten from scratch following the same functional
  intent.
