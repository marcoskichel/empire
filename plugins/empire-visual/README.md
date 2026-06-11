# empire-visual

Visual-first communication: stop answering structure with walls of text. Ships an
opt-in output style that leads every answer with a diagram, plus an on-demand skill that
draws terminal-native ASCII diagrams (and mermaid when the target is GitHub).

Part of the [empire](../../README.md) marketplace.

## Why

The brain processes verbal and visual information on separate channels (dual-coding
theory), and working memory saturates fast (cognitive load theory). A wall of text
loads one channel and idles the other; a labeled diagram loads both, so structure is
grasped faster and remembered longer. The catch: a badly built diagram is visual noise,
worse than prose — so both pieces here enforce a quality bar (coherence, spatial
contiguity, node budget).

## Install

```sh
/plugin marketplace add marcoskichel/empire
/plugin install empire-visual@empire
```

Or install the full empire bundle (which includes this plugin):

```sh
/plugin install empire@empire
```

## Output style: `Visual first`

An opt-in [output style](https://code.claude.com/docs/en/output-styles) that makes every
response lead with a diagram, table, or tree, reserving prose for what visuals cannot
carry. Keeps Claude's coding behavior intact (`keep-coding-instructions: true`).

Activate it:

```
/config  →  Output style  →  Visual first  →  /clear
```

It is **opt-in** — it does not override your output style automatically. Terminal-first
by design: it draws ASCII (which renders in the terminal TUI) and uses mermaid only when
the output targets GitHub or a markdown viewer.

**Source:** [`output-styles/visual-first.md`](output-styles/visual-first.md)

## Skills

### `visualize`

Turn a concept, codebase, flow, or comparison into the diagram that carries it best —
reads the source when needed, picks one format per intent, draws it terminal-native, and
prunes to the quality bar. Covers ASCII architecture, indented trees, flowcharts, state
machines, sequences, comparison tables, and ASCII bars. Uses mermaid only when the
output is bound for GitHub/PR/markdown.

**Triggers:** "draw this", "diagram this", "visualize", "show me a diagram", "map this
out", "flowchart", "architecture diagram", "sequence diagram", "state machine", "ascii
diagram", "make this visual", "/empire-visual:visualize".

**Usage:** `/empire-visual:visualize [what to draw]`

```mermaid
flowchart LR
  structure[Find the structure] --> format[Match intent → format]
  format --> target[Terminal? → ASCII]
  target --> draw[Draw + prune to quality bar]
```

**Source:** [`skills/visualize/SKILL.md`](skills/visualize/SKILL.md)

## Rendering reality

````
                 renders as a picture?
                 ┌──────────┬──────────┬──────────┐
                 │ terminal │  IDE ext │  GitHub  │
  ┌──────────────┼──────────┼──────────┼──────────┤
  │ ```mermaid   │    no    │    no    │   yes    │
  │ ASCII / box  │   yes    │   yes    │   yes    │
  │ tables       │   yes    │   yes    │   yes    │
  └──────────────┴──────────┴──────────┴──────────┘
````

Native mermaid rendering in the terminal and IDE extension are open feature requests,
not shipped — so this plugin defaults to ASCII and treats mermaid as a GitHub/markdown
export only.
