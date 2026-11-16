# Local tracker (markdown files)

Default backend. It works offline and needs no credentials.

## Layout
- **`docs/delivery/PLAN.md › Tickets`**: every ticket is one short block in that section (no file per ticket). The run state holds the live status and history (`delivery-state.sh ticket …`).

## Ticket block
```markdown
### T-001 · backend · <title>  (feature, M, ms-1)
Scope: 1. … 2. … 3. …            <!-- numbered: the brief's SCOPE items -->
Not in scope: …
AC: AC-…, AC-…   Contracts: <operation ids>   Paths: `<glob>`, `<glob>`
Depends on: — (or foundation ticket ids only)
Checklist: [ ] … [ ] …
```
A bug block adds `Bug of: T-010 · P1 · found in: <where>` and the expected and actual behavior in one line each. At most 12 lines per ticket.

## Status table (top of `PLAN.md › Tickets`)
`| T-001 | feature | <title> | backend | ms-1 | M | done | — | AC-… |` (id, type, title, role, milestone, size, status, depends on, acceptance). The orchestrator refreshes the status column from the run state at each milestone review, not after every change.

## Operations
- **create:** take the next free number, add the block and the table row, and register it (`delivery-state.sh ticket add …`).
- **list / get:** `delivery-state.sh ready <ms>`, `ticket show <id>`, or read the block.
- **create-bug:** add a bug block and row, linked with `--of <original-id>` in the state.
- **update-status:** `delivery-state.sh ticket status <id> <status>` (the state records the history).
- **comment:** a note in the state (`ticket status … --note`), never a growing comment thread in the document.
