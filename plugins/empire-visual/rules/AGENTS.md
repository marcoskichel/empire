# empire-visual

Skills installed under the `empire-visual` Claude Code plugin.

- Prefer visual over prose for anything with structure (architecture, flow, state, sequence, hierarchy, comparison, quantity) — SHOULD lead with a diagram/table/tree and reserve prose for the why, caveats, and next steps a picture cannot encode.
- The Claude Code terminal TUI does NOT render mermaid — it prints raw source. MUST default to ASCII / Unicode box-drawing + Markdown tables, which render in terminal, IDE panels, and GitHub. Use a ` ```mermaid ` block ONLY when output targets GitHub, a PR, or a markdown viewer, and never as the sole representation in a terminal reply.
- Quality bar (else visuals become noise): coherence (cut meaningless elements), spatial contiguity (labels beside what they label), ≤ ~15 nodes per figure, no prose that restates the diagram.
- The `visual-first` output style is opt-in — activate via `/config` → Output style → "Visual first" → `/clear`. It is not forced on users.
- Do NOT force a diagram onto a one-line factual answer that has no structure.
