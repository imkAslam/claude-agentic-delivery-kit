# Local tracker (markdown files)

Default backend. It works offline and needs no credentials.

## Layout
- `docs/delivery/tickets/T-<nnn>.md`: one file per ticket
- `docs/delivery/TICKETS.md`: the index table, kept sorted by id

## Ticket file
```markdown
---
id: T-001
title: <title>
role: backend
milestone: ms-1
status: ready
depends_on: []
acceptance: [AC-…]
test_cases: [TC-…]
contracts: [<operation ids>]
owned_paths: ["<glob>"]
size: S
tracker_ref: docs/delivery/tickets/T-001.md
---
## Goal
## Notes
## Comments
- <ISO> <author>: <text>
```

## Index row (`TICKETS.md`)
`| T-001 | <title> | backend | ms-1 | ready | — | AC-… |`, with the columns id, title, role, milestone, status, depends_on, acceptance.

## Operations
- **create:** take the next free number (the highest existing id + 1), write the file, append the index row.
- **list:** read the front matter of `docs/delivery/tickets/*.md` and filter.
- **update-status:** edit the `status:` line in the file and in the index row.
- **comment:** append under `## Comments`.
