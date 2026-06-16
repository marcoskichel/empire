# Diagram templates

Copy-adapt these terminal-native shapes. One intent → one format — pick via the
`format-by-intent` table in SKILL.md, then prune to the quality bar.

## ASCII architecture (box-drawing)

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

## Indented tree (hierarchy)

```
app/
├── api/        request handlers
│   ├── auth/   login, tokens
│   └── orders/ CRUD + checkout
├── core/       domain logic (no I/O)
└── db/         repositories
```

## Flowchart (control flow)

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

## State machine

```
  [idle] ──start──▶ [running] ──done──▶ [complete]
                       │
                     error
                       ▼
                    [failed] ──retry──▶ [running]
```

## Sequence (call order)

```
Client → API:   POST /orders
API    → Auth:  verify(token)
Auth   → API:   ok
API    → DB:    insert(order)
API    → Client: 201 Created
```

## Quantity (ASCII bar)

```
p50  ██░░░░░░░░  12ms
p95  ██████░░░░  48ms
p99  █████████░  91ms
```
