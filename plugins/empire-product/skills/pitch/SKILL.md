---
name: pitch
description: >
  Generate a personal elevator pitch or a repository/project pitch.
  Trigger phrases: "elevator pitch", "pitch this project", "introduce myself",
  "personal pitch", "how do I pitch myself", "pitch for this repo",
  "/empire-product:pitch", "tell me about yourself", "what's a good way to introduce this",
  "explain this repo in one line", "describe this project", "intro paragraph", "tagline",
  "one-liner", "GitHub repo description", "package.json description", "what does this do".
compatibility: Designed for Claude Code (or similar agents).
---

# Elevator Pitch Generator

## When to use

- User asks for a personal elevator pitch or intro
- User asks to pitch a project, repo, or library
- User is preparing for networking event, job interview, investor meeting, or conference
- User wants a "tell me about yourself" or "what does this do?" answer

## Pattern

### 1. Detect mode

Infer from user request:

| Signal                                                       | Mode                      |
| ------------------------------------------------------------ | ------------------------- |
| "pitch myself", "introduce myself", "tell me about yourself" | Personal                  |
| "pitch this project/repo/library", "elevator pitch for X"    | Repo                      |
| Ambiguous + active repo in context                           | Ask via `AskUserQuestion` |

"Active repo in context" = `git rev-parse --is-inside-work-tree` returns true (cwd is inside a git repo).

If ambiguous, use `AskUserQuestion`:

```
question: "What would you like to pitch?"
header: "Pitch type"
options:
  - label: "This repo"
    description: "Generate a pitch for the current project or library"
  - label: "Myself"
    description: "Generate a personal elevator pitch"
```

---

## Repo Pitch

### 1. Read context silently

Before asking anything, read:

- `package.json` — name, description, keywords
- `README.md` — what it does, why it exists
- `git log --oneline -10` — recent trajectory

Identify: what problem it solves, who it's for, one design decision that signals taste.

### 2. Ask what can't be inferred

Use a single `AskUserQuestion` call with up to 3 questions:

```
Question 1:
  question: "Who is the primary audience for this pitch?"
  header: "Audience"
  options:
    - label: "Developers"
      description: "Engineers evaluating the library or tool"
    - label: "Investors"
      description: "People evaluating the business opportunity"
    - label: "General tech"
      description: "Mixed audience — conference, meetup, demo day"

Question 2:
  question: "What format do you need?"
  header: "Format"
  options:
    - label: "One-liner (Recommended)"
      description: "Fits in package.json or GitHub repo description"
      preview: |
        Persistent, associative memory for AI agents —
        short-term, long-term, and consolidation in
        composable TypeScript packages.
    - label: "30-second spoken"
      description: "For demos, meetups, or conference intros"
      preview: |
        Every AI agent you build starts with amnesia.
        Neurome fixes that — five composable packages
        modeled on how the brain actually works.
        Are you building agents that need to remember?
    - label: "Full pitch deck intro"
      description: "60-second investor or demo day version"

Question 3 (only if no proof point found in README/package.json):
  question: "Do you have any traction or proof points to include?"
  header: "Proof point"
  options:
    - label: "Skip for now"
      description: "I'll flag where a proof point should go"
    - label: "I'll provide one"
      description: "I'll add it in the next message"
```

### 3. Framework by context

| Context               | Framework                                                      | Length     |
| --------------------- | -------------------------------------------------------------- | ---------- |
| Developer / one-liner | Problem + differentiator, no fluff                             | 1 sentence |
| Developer networking  | Problem image → What it does → Design decision → Hook question | 30–45s     |
| Conference / demo day | Counterintuitive claim → Solution → Architecture hook          | 20–30s     |
| Investor meeting      | Problem at scale → Solution → Traction → Explicit ask          | 60s        |

### 4. Output

- **One-liner** — ready to paste into `package.json` or GitHub description
- **30-second spoken** — Problem → Solution → Hook question
- **Context-specific** — adapted to chosen format

---

## Personal Pitch

### 1. Read what's available

Check for any context already provided. If in a repo, skip repo-specific fields.

### 2. Ask what's missing

Use a single `AskUserQuestion` call:

```
Question 1:
  question: "What's the context for this pitch?"
  header: "Context"
  options:
    - label: "Networking event"
      description: "Casual 'what do you do?' — short form, memorable"
    - label: "Job interview"
      description: "Tell me about yourself — structured 60–90s arc"
    - label: "Investor meeting"
      description: "Problem at scale, traction, explicit ask"
    - label: "Conference intro"
      description: "15-second counterintuitive hook"

Question 2 (if role/domain not clear from context):
  question: "What kind of work do you do?"
  header: "Your work"
  options:
    - label: "Engineering / technical"
      description: "Software, systems, infrastructure, ML"
    - label: "Founding / building"
      description: "Startup founder or early-stage builder"
    - label: "Product / design"
      description: "Product management, design, strategy"
```

### 3. Framework by context

| Context          | Framework                                               | Length |
| ---------------- | ------------------------------------------------------- | ------ |
| Networking event | Who I help → How → Why it matters → Hook question       | 30–45s |
| Job interview    | Present → Past → Future → close to the role             | 60–90s |
| Investor meeting | Problem at scale → Solution → Traction → Explicit ask   | 60s    |
| Conference intro | Counterintuitive claim → what you're curious about here | 15–20s |

IMPORTANT: "What do you do?" and "Tell me about yourself" are different. For casual networking, generate the short-form version first.

### 4. Output

- **30-second** — Problem → Solution → Ask
- **60-second** — Problem → Solution → Proof → Ask
- **Context-specific** — adapted to chosen context

---

## Rules (both modes)

- Open with the problem, not the name or title
- Use one of three hook types:
  - Problem image: "Every agent you build starts with amnesia..."
  - Tension/reversal: "We kept hitting X, so we built Y..."
  - Unusual claim: something that earns a follow-up question
- Power verbs only: built, shipped, fixed, cut, grew, decided, finished
- Avoid: "responsible for", "worked on", "passionate about", "it's a library that..."
- Include exactly one number or named result — flag `[PROOF POINT NEEDED]` if none available
- End with curiosity opener, soft signal, or direct ask — never a thud
- No insider jargon — translate mechanism to impact

IMPORTANT: Pitch must sound fluent, not scripted. Contractions, one casual phrase, avoid relentlessly parallel structure.

Annotate each version with one sentence explaining the structural choice made.
