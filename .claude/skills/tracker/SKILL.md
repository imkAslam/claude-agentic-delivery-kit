---
name: tracker
description: "Ticket tracker adapter with one operation set (create, list, get, update-status, comment) over local markdown tickets, Linear (MCP) or GitHub Issues (gh CLI), selected by project.json tracker.kind. Keeps docs/delivery/TICKETS.md and the run state in sync."
when_to_use: "Use when publishing, listing, updating or commenting on delivery tickets, or when a ticket status must match the run state."
---

# Tracker adapter

Backend: `.claude/project.json → tracker.kind`. Before `project.json` exists, or when the chosen backend isn't reachable (per `docs/delivery/SYSTEM-PROFILE.md`), use **local** and tell the orchestrator.

| kind | Reference |
|---|---|
| `local` | [local.md](references/local.md) |
| `linear` | [linear.md](references/linear.md) |
| `github` | [github.md](references/github.md) |

## Ticket model (the same for every backend)
`id` (T-nnn, stable across backends) · `title` · `role` · `milestone` (ms-n) · `status` (ready, in_progress, in_review, approved, done, blocked) · `depends_on` · `acceptance` (AC ids) · `test_cases` (TC ids) · `contracts` (operation ids) · `owned_paths` · `size` · `tracker_ref` (the backend's id or URL).

## Operations
| Operation | Effect |
|---|---|
| `create <ticket>` | Create it in the backend, record `tracker_ref`, append a row to `docs/delivery/TICKETS.md` |
| `list [milestone] [status] [role]` | List tickets, filtered |
| `get <id>` | Full ticket, including comments |
| `update-status <id> <status>` | Set the status in the backend and in `TICKETS.md` |
| `comment <id> <text>` | Add a comment (findings, failure-report link, evidence links) |

## Rules
- Status vocabulary maps onto backend states as each reference describes. The run state (`.claude/delivery/state.json`) is the cursor; the backend is what the team sees. After every operation, the orchestrator runs `delivery-state.sh ticket …` so the two match.
- Never put secrets or personal data in tickets.
- One ticket = one role. Split cross-role work.
