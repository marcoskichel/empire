# ADR template

Template for the `docs/adr/NNNN-<slug>.md` file (numbering and placement rules live in the `weigh` SKILL).

```markdown
---
adr: NNNN
title: <title>
date: YYYY-MM-DD
status: proposed
supersedes: null
tags: []
modules: []
---

# ADR-NNNN: <TITLE>

## Status

[Proposed | Accepted | Deprecated | Superseded by ADR-MMMM]

## Context

[Situation requiring a decision]

### Requirements

- [Requirement]

### Constraints

- [Constraint]

## Decision

[What is the decision?]

### Justification

- [Reason]

## Consequences

### Positive

- [Benefit]

### Negative

- [Drawback]

## Alternatives Considered

### [Alternative]

Reason rejected: [Why]
```

Update frontmatter `status` when the decision changes state. To supersede: set `status: superseded-by ADR-MMMM` in the old ADR; reference the old one in the new ADR's `supersedes` field.
