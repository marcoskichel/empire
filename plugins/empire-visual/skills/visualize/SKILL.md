---
name: visualize
description: >
  Turn a concept, codebase, flow, or comparison into a diagram instead of a wall of
  text. Produces terminal-native ASCII architecture diagrams, flowcharts, state
  machines, sequences, trees, and comparison tables — and mermaid only when the output
  targets GitHub or a markdown viewer. Use when the user wants something drawn, mapped,
  or visualized rather than described in prose.
  Trigger phrases: "draw this", "diagram this", "visualize", "show me a diagram",
  "map this out", "flowchart", "architecture diagram", "sequence diagram", "state
  machine", "ascii diagram", "make this visual", "/empire-visual:visualize".
allowed-tools: Read, Grep, Glob
---

<section id="core">

**A diagram loads two cognitive channels; prose loads one.** Verbal and visual
information travel separate paths (dual-coding theory), and working memory saturates
fast (cognitive load theory). A labeled diagram lets a reader grasp structure at a
glance and hold it longer. This skill converts a thing-with-structure into the visual
that carries it best.

Scope: structure, flow, state, sequence, hierarchy, comparison, quantity. If the
answer has no structure — a single fact, a yes/no — do NOT force a diagram. Say it.

</section>

<section id="process">

1. **Identify what has structure.** Read the source if needed (`Read`/`Grep`/`Glob` a
   file, function, or directory). Find the entities and the relationships between them —
   that is what the diagram encodes.
2. **Match intent to format** (table below). One intent → one primary format. Do not mix
   three diagram types in one figure.
3. **Choose the render target.** Terminal/chat → ASCII. GitHub/PR/markdown viewer →
   mermaid is allowed. When unsure → ASCII (it renders everywhere).
4. **Draw it, then prune.** Apply the quality bar. Cut every element that carries no
   meaning.
5. **Add only the prose the picture cannot encode** — the _why_, a caveat, the next step.

</section>

<section id="format-by-intent">

| Intent                                | Format                             |
| ------------------------------------- | ---------------------------------- |
| Structure / architecture / layers     | ASCII box-drawing                  |
| File / module / type hierarchy        | Indented tree                      |
| Control flow / decisions / algorithm  | ASCII flowchart (boxes + arrows)   |
| State / lifecycle transitions         | ASCII state diagram                |
| Request path / call order             | Numbered sequence or `A → B → C`   |
| Options / trade-offs / feature matrix | Markdown table                     |
| Quantities / distribution / progress  | ASCII bars (`█████░░░`) or a table |

</section>

<section id="render-rules">

- MUST default to ASCII / Unicode box-drawing + Markdown tables. They render in the
  Claude Code terminal TUI, IDE panels, and GitHub.
- MUST use a ` ```mermaid ` block ONLY when output targets GitHub, a PR, or a markdown
  viewer. The terminal TUI does NOT render mermaid — it prints the raw source. Never
  make mermaid the sole representation in a terminal reply. When both terminal and
  GitHub are in play, lead with ASCII; offer mermaid as an addition if asked.
- SHOULD keep box-drawing characters consistent within one figure: `┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼ │ ─`
  for boxes, `→ ← ↑ ↓` for flow.

</section>

<section id="quality-bar">

Badly built diagrams read as visual noise — worse than prose. Enforce:

- **Coherence** — exclude every element that does not carry meaning. Fewer nodes wins.
- **Spatial contiguity** — labels inside or directly beside what they label, never in a
  separate paragraph.
- **Size** — under ~15 nodes per figure. Bigger → split into layers or show the top
  level and drill down on request.
- **No redundancy** — do not restate in prose what the figure already shows.

</section>

<section id="templates">

**ASCII architecture (box-drawing):**

```
┌─────────────┐     ┌─────────────┐
│   Client    │────▶│   API/BFF   │
└─────────────┘     └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌─────────┐  ┌─────────┐  ┌─────────┐
        │  Auth   │  │  Orders │  │  Cache  │
        └─────────┘  └────┬────┘  └─────────┘
                          ▼
                    ┌─────────┐
                    │   DB    │
                    └─────────┘
```

**Indented tree (hierarchy):**

```
app/
├── api/        request handlers
│   ├── auth/   login, tokens
│   └── orders/ CRUD + checkout
├── core/       domain logic (no I/O)
└── db/         repositories
```

**Flowchart (control flow):**

```
        ┌───────────┐
        │  request  │
        └─────┬─────┘
              ▼
        ╱ token? ╲──no──▶ 401
        ╲        ╱
           │ yes
           ▼
        ┌───────────┐
        │  handle   │──▶ 200
        └───────────┘
```

**State machine:**

```
  [idle] ──start──▶ [running] ──done──▶ [complete]
                       │
                     error
                       ▼
                    [failed] ──retry──▶ [running]
```

**Sequence (call order):**

```
Client → API:   POST /orders
API    → Auth:  verify(token)
Auth   → API:   ok
API    → DB:    insert(order)
API    → Client: 201 Created
```

**Quantity (ASCII bar):**

```
p50  ██░░░░░░░░  12ms
p95  ██████░░░░  48ms
p99  █████████░  91ms
```

</section>
