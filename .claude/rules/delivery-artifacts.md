---
paths:
  - "docs/delivery/**"
  - "docs/intake/**"
  - "docs/adr/**"
---

# Delivery artifact rules

- File names match `.claude/skills/deliver/references/workflow.md` exactly (`PRD.md`, `ARCHITECTURE.md`, `TEST-CASES.md`, …). Gate approvals hash these paths.
- Every artifact starts with a header:
  ```
  > Status: draft | in-review | approved (<gate>) | superseded by <file>
  > Owner: <agent> · Sources: <evidence files/sections> · Updated: <ISO date>
  ```
- **Supersession:** the latest *agreed* decision wins; a newer draft or a later timestamp alone does not. When a decision changes, strike the old text (`~~…~~`), point to the new decision, and keep both visible.
- Keep facts, assumptions and questions apart: facts cite evidence, assumptions are labeled `ASSUMPTION:`, and questions are labeled `QUESTION:` with the consequence of leaving them unanswered.
- An artifact in an approved gate package changes only through a change request (`.claude/skills/deliver/scripts/delivery-state.sh cr-open … --approved-by "<human>"`), and only after the human said yes. `guard-gates.sh` enforces this.
- Acceptance criteria are Given/When/Then with stable IDs (`AC-<area>-<n>`), business rules are `BR-<n>`, and test cases are `TC-<n>`. Tickets, tests and reports cite these IDs.
- Evidence (screenshots, logs, reports) lives under `docs/delivery/evidence/` or `docs/delivery/milestones/<ms>/evidence/`, named `<id>-<what>.<ext>`.
- **Append-only logs** (`MESSAGES.md`, `GATE-LOG.md`, `LESSONS.md`, `failures/`) are never rewritten and never read whole: query them with `grep -n <id>` or `tail` (`.claude/skills/deliver/references/memory.md` §3). `LESSONS.md` is the exception that gets curated: at most 30 active lines, retired lines kept under `## Retired`.
