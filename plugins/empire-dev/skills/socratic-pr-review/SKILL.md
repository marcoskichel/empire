---
name: socratic-pr-review
description: >
  Trigger when user says: "socratic review", "socratic pr review", "socratic
  code review", "review this PR socratically", "review the PR with questions",
  "ask questions on the PR", "question-style review", "leave socratic comments",
  "/empire-dev:socratic-pr-review". Runs team-review on a PR, turns recommended
  actions into short question-style inline comments, validates each comment with
  the user one by one, then posts ONE review (approve / request changes /
  comment) at once. Posts to GitHub only after explicit user validation of every
  comment and the final verdict.
compatibility: Requires the gh CLI and network access; dispatches review subagents.
allowed-tools: Bash Read Glob Grep Skill Agent WebSearch WebFetch
---

<section id="overview">

Socratic PR review: lead the author to the defect with a question, do not dictate the fix.
Pipeline: resolve PR → team-review → draft question-comments → re-check vs code → validate one by one → propose verdict → post one review atomically.
This is the one empire-dev skill that writes to GitHub. It posts exactly ONE review, only after the user validates every comment and the verdict.

</section>

<section id="target-detection">

- Resolve the target PR before anything else.
- Signals, in order:
  - Explicit PR number or URL in the invocation
  - Open PR for the current branch: `gh pr view --json number,url,headRefOid`
  - PR referenced earlier in conversation
- No open PR + no explicit target → ASK; do not guess.
- Derive `OWNER`/`REPO` from the PR's OWN base repo, never from `gh repo view` (the cwd repo may differ from the PR's repo or fork):
  - `gh pr view "$PR" --json number,url,baseRefName,headRefOid` (a bare number resolves against cwd; pass a full URL for any other repo or fork)
  - Parse `OWNER`/`REPO` from the returned `.url` (`https://github.com/OWNER/REPO/pull/N`); set `PR` from `.number`
- MUST echo `OWNER/REPO#PR @ <sha>` + url and confirm it is the intended PR before team-review or any post. A wrong target is unrecoverable once posted.
- Treat `SHA` as provisional here; re-fetch it immediately before posting (see [post-review](#post-review)).

</section>

<section id="run-team-review">

- Invoke the `team-review` skill on the resolved PR; pass the PR number.
- Let team-review pick the roster and return its consolidated tiered report.
- Use the report's Recommended actions as the comment seed set.
- team-review never posts; this skill owns all GitHub writes.

</section>

<section id="draft-comments">

- Convert each Recommended action into one draft inline comment.
- Anchor every comment to `path` + `line` from the diff:
  - Added or context line → `side: RIGHT`
  - Deleted line → `side: LEFT`, only when that line sits inside a displayed diff hunk; else fold into the summary body
  - Span → `start_line` + `line` (same side)
- Inline comments MUST land on lines present in the PR diff. Finding outside the diff → fold into the summary body, never invent a line.
- Drop Single-source low-confidence findings unless the lone specialist owns that category (per team-review tiering). Do not auto-include nits.
- Draft only; nothing is posted in this section.

</section>

<section id="socratic-style">

- Phrase each comment as the question a curious teammate would ask reading the diff.
- Lead with genuine curiosity, not a gotcha. Seek to understand the change, not corner the author.
- Sound natural and conversational. Plain words, thinking out loud. Drop stiff phrasing like "Is `X` guaranteed to be non-null".
- When there's a clear set of answers, name them in the question: "Do `permissions` / `harness-support` replace `allowed-tools` / `compatibility`, or coexist?"
- Two shapes, both valid:
  - Understand intent: "What are the `permissions` values?", "Why drop the retry here?"
  - Surface a gap: "What happens when `items` is empty?" not "This crashes on empty input."
- Assume competence; no rhetorical or leading-to-humiliate questions.
- One question per comment. No stacked questions.
- Example transforms:
  - "Missing null check on `user`" → "Is `user` ever null by the time we reach this?"
  - "This N+1 query is slow" → "How many queries does this loop fire per request?"

</section>

<section id="recheck">

- Re-verify EVERY draft comment against the current code in one batch pass, BEFORE the one-by-one validation loop.
- Read the actual file and line; confirm the issue still exists in the diff as drafted.
- MAY use WebSearch / WebFetch to confirm API behavior, version semantics, or library contracts the finding depends on.
- Drop the comment if re-check shows it is wrong, already handled, or off-target. State dropped ones briefly.
- Correct the anchor line if the finding is real but the line drifted.

</section>

<section id="comment-rules">

- Length: short and direct, ideally under 150 characters.
- No fix suggestions UNLESS the fix is unambiguous; only then MAY append a GitHub ```suggestion block.
- Comment prose: no dashes, no emojis.
- One issue per comment.
- Use backticks for identifiers, paths, and symbols.

</section>

<section id="one-by-one-validation">

- Present comments ONE AT A TIME. Never dump the full list.
- For each, show:
  - `path:line` and a 1-2 line diff snippet for context
  - The draft question comment
  - One line on why it matters (tier + category from team-review)
- Then discuss: keep as-is, adjust wording, or drop.
- MUST wait for the user's decision on the current comment before showing the next.
- Track the running set of validated comments; reflect edits verbatim.

</section>

<section id="verdict">

- After every comment is validated or dropped, propose the review event:
  - `APPROVE` — no unresolved Must-fix; only questions or nits remain
  - `REQUEST_CHANGES` — one or more unresolved Must-fix comments
  - `COMMENT` — questions worth raising, no blocking stance
- Propose a summary body (MAY be empty). Keep it short; same prose rules (no dashes, no emojis).
- Present verdict + summary; MUST get explicit user approval of both before posting.
- `REQUEST_CHANGES` blocks the PR; MUST confirm the blocking event explicitly, separate from summary approval.
- User MAY override the event and edit the summary.

</section>

<section id="post-review">

- Post the ENTIRE review in ONE GitHub API call. Never post comments individually; never create a pending review then submit separately.
- Immediately before posting:
  - Re-fetch `SHA=$(gh pr view "$PR" --json headRefOid -q .headRefOid)`. If it changed since [target-detection](#target-detection), warn the user and re-confirm (anchors may have drifted).
  - Re-display the exact destination + action — `OWNER/REPO#PR @ $SHA`, event — and get a final explicit "post" confirmation. The per-comment gate does not cover the destination.
- Build the payload with `jq` into a temp file; pass every comment `body` and the summary as `--arg` values, NEVER via string interpolation (bodies hold quotes, backticks, `$()`). Then a single POST, deleting the temp file after:

  ```bash
  payload=$(mktemp)
  # Append each comment as data, never interpolated into the JSON:
  comments='[]'
  comments=$(jq -c --arg path "$P" --argjson line "$N" --arg side RIGHT --arg body "$Q" \
    '. + [{path: $path, line: $line, side: $side, body: $body}]' <<<"$comments")
  # repeat per comment; for a span add --argjson start_line and --arg start_side
  jq -n --arg commit "$SHA" --arg event "$EVENT" --arg body "$SUMMARY" --argjson comments "$comments" \
    '{commit_id: $commit, event: $event, body: $body, comments: $comments}' >"$payload"
  gh api --method POST "repos/$OWNER/$REPO/pulls/$PR/reviews" --input "$payload"
  rm -f "$payload"
  ```

- `payload.json` shape:

  ```json
  {
    "commit_id": "<SHA>",
    "event": "COMMENT|APPROVE|REQUEST_CHANGES",
    "body": "<summary or empty>",
    "comments": [
      { "path": "src/x.ts", "line": 42, "side": "RIGHT", "body": "..." },
      {
        "path": "src/x.ts",
        "start_line": 40,
        "start_side": "RIGHT",
        "line": 44,
        "side": "RIGHT",
        "body": "..."
      }
    ]
  }
  ```

- With `comments` present, any event MAY omit `body`; with no `comments`, `COMMENT` and `REQUEST_CHANGES` require a non-empty `body` (`APPROVE` MAY always be empty).
- After posting, report the review URL from the API response.
- On API error (line not in diff, stale `SHA`): re-resolve the anchor or `SHA` and retry the single call, max 2 retries. If a retry changes an anchor the user validated, re-confirm that comment first. Never split into multiple posts; surface to the user after repeated failure.

</section>

<section id="boundaries">

- The only GitHub write is the single review POST in [post-review](#post-review), gated by [verdict](#verdict) approval.
- MUST NOT push commits, edit the PR body, change labels, or comment outside the review.
- MUST NOT modify the code under review.

</section>
