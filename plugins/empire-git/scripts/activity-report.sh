#!/usr/bin/env bash
# activity-report.sh — Collect raw GitHub PR activity for a date range.
# Part of the empire-git plugin (Claude Code and OpenAI Codex).
#
# Usage:
#   activity-report.sh [START_DATE] [END_DATE]   # dates as YYYY-MM-DD, default: last 7 days
#
# Prints markdown-friendly raw data (merged PRs + open PRs authored by the
# current gh user) for an agent to cluster into an area/feature report.

set -euo pipefail

die() {
  printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2
  exit 1
}

if [[ "${OSTYPE:-}" == darwin* ]]; then
  DEFAULT_START="$(date -v-7d +%Y-%m-%d)"
else
  DEFAULT_START="$(date -d "7 days ago" +%Y-%m-%d)"
fi
DEFAULT_END="$(date +%Y-%m-%d)"

START_DATE="${1:-$DEFAULT_START}"
END_DATE="${2:-$DEFAULT_END}"

DATE_REGEX='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
[[ "$START_DATE" =~ $DATE_REGEX ]] || die "START_DATE must be YYYY-MM-DD (got '$START_DATE')"
[[ "$END_DATE" =~ $DATE_REGEX ]] || die "END_DATE must be YYYY-MM-DD (got '$END_DATE')"

command -v gh >/dev/null 2>&1 || die "gh CLI not installed (https://cli.github.com/)"
gh auth status >/dev/null 2>&1 || die "not authenticated — run: gh auth login"

echo "# GitHub PR activity: $START_DATE to $END_DATE"
echo

echo "## Merged PRs"
gh search prs \
  --author=@me \
  --merged-at="$START_DATE..$END_DATE" \
  --limit 100 \
  --json title,repository,url \
  --jq '.[] | "- \(.title) (\(.repository.nameWithOwner)) \(.url)"'

echo
echo "## Open PRs (created in range)"
gh search prs \
  --author=@me \
  --state=open \
  --created="$START_DATE..$END_DATE" \
  --limit 100 \
  --json title,repository,url,isDraft \
  --jq '.[] | "- \(if .isDraft then "[draft] " else "" end)\(.title) (\(.repository.nameWithOwner)) \(.url)"'
