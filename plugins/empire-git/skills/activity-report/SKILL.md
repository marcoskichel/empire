---
name: activity-report
description: >
  Generate a concise activity report of the user's GitHub work over a period,
  grouped by area or feature instead of PR by PR. Use when user says "activity
  report", "weekly report", "what did I do this week", "what did I ship",
  "work summary", "summarize my week", "status update for my manager", or
  `/empire-git:activity-report [start-date] [end-date]`.
compatibility: Requires gh (authenticated) and jq. Runs in Claude Code and OpenAI Codex; the bundled collection script ships with the skill.
allowed-tools: Bash Read
argument-hint: "[start-date] [end-date]"
---

# Activity Report

Produce a short, high-signal report of what the user shipped in a period. The report has one bullet per **area or feature**, never one bullet per PR.

**User input:** $ARGUMENTS

## Step 1 — Resolve the period

Dates are `YYYY-MM-DD`. Defaults when omitted: last 7 days. Interpret natural language ("this week", "last month", "since Monday") into concrete dates before running the script.

## Step 2 — Collect raw PR data

The collection script ships with this skill. On Claude Code it is at `${CLAUDE_PLUGIN_ROOT}/scripts/activity-report.sh`; on other agents (e.g. Codex) it is `scripts/activity-report.sh` inside this skill's directory.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/activity-report.sh" 2026-01-01 2026-01-07
```

It prints merged PRs and open PRs authored by the current `gh` user, with titles, repos, and URLs. It reads nothing but the date args and calls only `gh search prs`.

## Step 3 — Cluster into areas

Group the PRs semantically by the feature or area they serve, not by repo and not by conventional-commit type. Seven PRs that all build log aggregation become one "Logs aggregation" bullet. Use PR titles and scopes to infer the area; when a title is too vague to place, fetch its body with `gh pr view <url> --json body` before guessing.

Naming areas: use the feature's plain name ("Visual regression reports", "Onboarding wizard"), not repo names, not commit scopes, not "misc".

Singleton PRs that fit no cluster: fold true one-offs into a single "Maintenance" bullet (dependency bumps, CI tweaks, small fixes). A significant standalone PR keeps its own area bullet.

## Step 4 — Write the report

The report is exactly this shape:

```markdown
# Activity report — <start> to <end>

## Shipped

- **<Area or feature>** — <1-2 sentences: what changed and why it matters>
- **<Area or feature>** — ...
- **Maintenance** — <one sentence rolling up the one-offs>

## In progress

- **<Area or feature>** — <one sentence on current state>
```

Rules for the body:

- Order areas by impact, highest first. Maintenance is always last in Shipped.
- Each bullet states the outcome, not the activity: "Gated Grafana behind Cloudflare Access" beats "Worked on access changes".
- No PR links, counts, or repo names in bullets unless the user asks for them.
- Omit the "In progress" section when there are no open PRs in range.
- Target: the whole report fits on one screen.

Show the report in chat. Offer to save it to a file or copy it to the clipboard only if the user asks.
