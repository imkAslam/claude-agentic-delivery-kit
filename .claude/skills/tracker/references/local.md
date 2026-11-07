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
type: feature                 # feature | chore | spike | bug
role: backend
module: <module>
milestone: ms-1
size: M                       # S | M | L
status: ready
bug_of: null                  # bugs: the original ticket id
bugs: []                      # originals: the linked bug ids
severity: null                # bugs: P1 | P2 | P3
depends_on: []
acceptance: [AC-…]
test_cases: [TC-…]
contracts: [<operation ids>]
owned_paths: ["<glob>"]
tracker_ref: docs/delivery/tickets/T-001.md
---
## Goal
## Checklist
## Notes
## Status history
- <ISO> ready → in_progress (dispatch)
## Comments
- <ISO> <author>: <text>
```

## Index row (`TICKETS.md`)
`| T-001 | feature | <title> | backend | ms-1 | M | ready | — | AC-… | — |`, with the columns id, type, title, role, milestone, size, status, depends_on, acceptance, bugs.
Below it, a **Bugs** table: `| T-045 | P1 | <symptom> | of T-010 | ready | acceptance TC-004 |` (id, severity, title, original, status, found in).

## Operations
- **create:** take the next free number (the highest existing id + 1), write the file, append the index row.
- **list:** read the front matter of `docs/delivery/tickets/*.md` and filter.
- **create-bug:** create the bug file from the bug template with `bug_of:`; add the bug id to the original's `bugs:` list and a comment there; add a row to the Bugs table.
- **update-status:** edit the `status:` line in the file and in the index row, and append a line to `## Status history`.
- **comment:** append under `## Comments`.
