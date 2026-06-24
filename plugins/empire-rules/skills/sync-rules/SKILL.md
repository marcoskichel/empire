---
name: sync-rules
description: >
  Reconcile empire-* plugin skill-routing snippets into a rules file (project
  AGENTS.md or user-global ~/.claude/CLAUDE.md). Idempotent. Use when the user
  asks to "sync empire rules", "update AGENTS.md from empire", "apply empire
  routing rules", "install empire skill rules", "refresh empire CLAUDE.md",
  "rewrite empire rules", or after installing/updating an empire-* plugin to
  write its routing block.
compatibility: Requires file write access to the rules file. Designed for Claude Code (or similar agents).
argument-hint: "[plugin] [--scope user|project|both]"
allowed-tools: Bash, Read, Write
---

# sync-rules

Reconcile installed empire-\* plugin snippets into a rules file. Default target is the user-global file (`~/.claude/CLAUDE.md`) — that matches the default `claude plugin install` scope so the routing rules apply wherever the skills do. Project scope (`./AGENTS.md`) is for teammates who share rules via version control.

## Flow

1. **Run preview** — invoke `${CLAUDE_PLUGIN_ROOT}/scripts/sync-rules.sh "$ARGUMENTS"`. The script prints a summary, a unified diff, and one or two pairs of lines like:

   ```
   ==> NEW_FILE: /path/to/persistent/new-<scope>.md
   ==> TARGET:   /path/to/target/file.md
   ```

   Print the script's full stdout in your reply so the user can read the summary and diff.

2. **Handle exit codes**:

   - **0 + "Already in sync"**: stop. Nothing to do.
   - **0 + ops > 0**: continue to step 3.
   - **3** (no scope determined): the script printed instructions. Do NOT show those instructions. Instead ask the user this exact prompt and stop, waiting for the reply:

     > Where should empire routing rules be written?
     >
     > - **`u` — user scope** (`~/.claude/CLAUDE.md`). Recommended. Rules apply in every repo, matching the default plugin install scope.
     > - **`p` — project scope** (`./AGENTS.md`). Per-repo. Teammates share rules via version control.
     > - **`b` — both**.
     >
     > Pick scope: [U/p/b]

     On reply, re-run the script with `--scope <user|project|both>` and the original positional arguments.

   - **Any other non-zero exit**: surface the script's stderr in a fenced code block and stop.

3. **Apply via Write tool** — for each `NEW_FILE` / `TARGET` pair the script printed:

   1. Use the `Read` tool on `NEW_FILE` to load the reconciled content.
   2. Use the `Read` tool on `TARGET` (only if it exists — skip on first sync). Required by `Write` for files that already exist.
   3. Use the `Write` tool on `TARGET` with content **byte-identical** to what `Read` returned for `NEW_FILE`. Claude Code will display a native diff and ask the user to approve the write.

   When `--scope both`, the script emits two pairs. Process them sequentially: Write the user-scope pair first, then the project-scope pair.

## Arguments

- `[plugin]`: optional plugin name (e.g. `empire-git`). Restricts reconciliation to that plugin's marker block; other empire blocks are left untouched.
- `--scope user|project|both`: optional. When passed, the script uses that scope; otherwise it auto-detects from existing markers and exits 3 if neither file has them.

## Rules for the model

- The `Write` tool's `content` parameter MUST be byte-identical to the `Read` result of `NEW_FILE`. Do not paraphrase, reformat list bullets, normalize whitespace, fix typos, or "improve" markdown. Copy the bytes exactly. The script already reconciled the content between its markers; any drift makes the next sync report a spurious diff and breaks idempotency.
- Do not invoke `Edit` or `Write` on a target before showing the script's preview output to the user.
- Do not invent flags. Only `--scope <user|project|both>` and a positional plugin name are valid.
- If the script exits 1 or any other unexpected non-zero, surface its stderr exactly and stop. Do not retry.
