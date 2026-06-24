## Empire git workflow

Skills installed under the `empire-git` Claude Code plugin.

### Worktrees

- SHOULD open `/empire-git:worktree-open` for any user-requested change — keeps current branch clean
- MUST NOT push or open PR from worktree until user signals ship intent ("ship it", "open the PR", "let's merge", "push and PR") — default = work stays local in worktree
- MUST use `/empire-git:worktree-*` skills — never raw `git worktree add|remove|prune`
- Subagents doing isolated work MUST run inside a `/empire-git:worktree-open` worktree

Conventions:

- Branch name = source of truth — same branch always reopens the same worktree path (deterministic hash)
- Each worktree gets a deterministic port offset (0–99 from path hash) — no port collisions across parallel dev servers
- `.env*` files are copied (not symlinked) per worktree; symlinked envs are skipped

### Pull requests

- MUST invoke `/empire-git:pr-description` before any `gh pr create --body*` or `gh pr edit --body*` and use its output verbatim
- The skill preserves user-added content outside `<!-- pr-description:start -->` / `<!-- pr-description:end -->` markers when updating an existing body
- Title format: Conventional Commits, lowercase, no period, ≤ 72 chars

### Stacked PRs

- MUST invoke `/empire-git:pr-stack` after creating, merging, or retargeting a PR in a chain — keeps the stack comment current
- `pr-stack` posts nothing for a single PR against the default branch
- SHOULD use `/empire-git:pr-merge` to merge a chained PR — gates CI/conflicts/review threads, retargets children to base first (GitHub closes dependents otherwise), merges, refreshes stack
- Stack overview lives in a comment, not the PR body — keep the body clean
