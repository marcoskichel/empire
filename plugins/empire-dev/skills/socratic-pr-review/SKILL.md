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
- MUST state the resolved PR (number + url) before dispatch.
- No open PR + no explicit target → ASK; do not guess.
- Capture once for later API calls:
  - `OWNER=$(gh repo view --json owner -q .owner.login)`
  - `REPO=$(gh repo view --json name -q .name)`
  - `PR=<number>`; `SHA=$(gh pr view "$PR" --json headRefOid -q .headRefOid)`

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
  - Deleted line → `side: LEFT`
  - Span → `start_line` + `line` (same side)
- Inline comments MUST land on lines present in the PR diff. Finding outside the diff → fold into the summary body, never invent a line.
- Drop Single-source low-confidence findings unless the lone specialist owns that category (per team-review tiering). Do not auto-include nits.
- Draft only; nothing is posted in this section.

</section>

<section id="socratic-style">

- Phrase each comment as one genuine question that points at the defect and lets the author reach the fix.
- Ask about the gap, not the symptom: "What happens here when `items` is empty?" not "This crashes on empty input."
- Assume competence; no rhetorical or leading-to-humiliate questions.
- One question per comment. No stacked questions.
- Example transforms:
  - Assertion "Missing null check on `user`" → "Is `user` guaranteed non-null at this point?"
  - Assertion "This N+1 query is slow" → "How many queries does this loop issue per request?"

</section>

<section id="recheck">

- Before proposing ANY comment, re-verify it against the current code.
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
- User MAY override the event and edit the summary.

</section>

<section id="post-review">

- Post the ENTIRE review in ONE GitHub API call. Never post comments individually; never create a pending review then submit separately.
- Build the payload, then a single POST:

  ```bash
  gh api --method POST "repos/$OWNER/$REPO/pulls/$PR/reviews" --input payload.json
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

- `COMMENT` and `REQUEST_CHANGES` require a non-empty `body` when `comments` is empty; `APPROVE` MAY have empty `body`.
- After posting, report the review URL from the API response.
- On API error (line not in diff, stale `SHA`): re-resolve the anchor or `SHA`, then retry the single call. Never split into multiple posts.

</section>

<section id="boundaries">

- The only GitHub write is the single review POST in [post-review](#post-review), gated by [verdict](#verdict) approval.
- MUST NOT push commits, edit the PR body, change labels, or comment outside the review.
- MUST NOT modify the code under review.

</section>
