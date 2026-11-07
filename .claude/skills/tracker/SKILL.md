---
name: tracker
description: "Ticket tracker adapter with one operation set (create, create-bug, list, get, update-status, comment) over local markdown tickets, Linear (MCP) or GitHub Issues (gh CLI), selected by project.json tracker.kind. Keeps docs/delivery/TICKETS.md and the run state in sync."
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
`id` (T-nnn, stable across backends; bugs use the same sequence) · `type` (feature, chore, spike, bug) · `title` · `role` · `module` · `milestone` (ms-n) · `size` (S, M, L) · `status` (below) · `depends_on` · `acceptance` (AC ids) · `test_cases` (TC ids) · `contracts` (operation ids) · `owned_paths` · `checklist` · `tracker_ref` (the backend's id or URL) · `history` (every status change: from, to, when, note).
**Bugs add:** `bug_of` (the original ticket), `severity` (P1, P2, P3), `found_in`, the reproduction, the root cause; the original ticket lists its `bugs`.

## Status lifecycle (enforced by `delivery-state.sh ticket status`)
```
backlog → ready → in_progress → in_review → approved → done → verified
                     ↑   ↓          ↓   ↑        ↓        ↓
                     └ changes_requested ┘    reopened ←──┘     (+ blocked, cancelled from most states)
```
| Status | Meaning | Set when |
|---|---|---|
| `backlog` | Planned, not yet scheduled (or new scope awaiting a decision) | planning, triage of new scope |
| `ready` | Scheduled; starts when its dependencies are `done` | planning; reopened work re-queued |
| `in_progress` | An engineer is working on it | dispatch |
| `in_review` | Returned DONE with evidence; reviewer(s) checking | after the engineer's return block |
| `changes_requested` | The reviewer returned CHANGES | review verdict; next attempt → `in_progress` |
| `approved` | All reviewers APPROVE | review verdict |
| `done` | Merged into the milestone integration branch, combined checks and the journey passed | integrator |
| `verified` | QA confirmed it on the candidate (required for bugs; optional for features) | QA in Lane 4, or after a bug fix |
| `reopened` | A defect inside its own AC found **before** the milestone review approved it | triage (integration, design QA, `mbr` "request fixes") |
| `blocked` | Can't proceed (failure report, missing input, dependency problem) | `delivery-state.sh fail`, or the orchestrator with a note |
| `cancelled` | Dropped by a human decision (scope change) | after the decision, with the reason |
Illegal jumps (for example `ready → done`) are rejected. `--force "<reason>"` exists only to correct a status that was set wrongly; the reason is kept in the history.

## Reopen or file a bug?
- **Before** the milestone's `mbr` gate approved it: the defect is part of unfinished work → **reopen** the original ticket (`ticket status <id> reopened --note "<finding>"`).
- **After** `mbr` approved it (QA, acceptance, quality/security, staging or production): → **create a bug ticket linked to the original** (`create-bug`). The original stays `done`; its history and `bugs` list show the link.

## Operations
| Operation | Effect |
|---|---|
| `create <ticket>` | Create it in the backend, record `tracker_ref`, append a row to `docs/delivery/TICKETS.md` |
| `list [milestone] [status] [role]` | List tickets, filtered |
| `get <id>` | Full ticket, including comments |
| `create-bug <bug> --of <original>` | Create the bug ticket (bug template), link it to the original in both directions in the backend, comment on the original ("Bug T-… reported: <symptom>"), and add it to the Bugs table in `TICKETS.md` |
| `update-status <id> <status> [note]` | Run `delivery-state.sh ticket status` first (it validates the transition), then set the status in the backend and in `TICKETS.md`, and append the change to the ticket's status history |
| `comment <id> <text>` | Add a comment (findings, failure-report link, evidence links) |

## Rules
- Status vocabulary maps onto backend states as each reference describes. The run state (`.claude/delivery/state.json`) is the cursor; the backend is what the team sees. After every operation, the orchestrator runs `delivery-state.sh ticket …` so the two match.
- Never put secrets or personal data in tickets.
- One ticket = one role and one cohesive capability of one module (plan-delivery → sizing). Split cross-role work.
- Every bug has a `bug_of` link (or `none` with the reason), a severity and a reproduction.
