---
paths:
  - "docs/delivery/**"
  - "docs/intake/**"
  - "docs/adr/**"
---

# Delivery artifact rules

- **The lean set:** a run writes only the documents listed in `.claude/skills/deliver/references/documents.md`, each within its length limit; everything else is a section of one of them (`X.md › Name` means the section "Name" inside X.md). Each agent edits only its own section. Gate approvals hash these files.
- Every document opens with a plain summary of at most five lines that a non-engineer can read.
- Every artifact starts with a header:
  ```
  > Status: draft | in-review | approved (<gate>) | superseded by <file>
  > Owner: <agent> · Sources: <evidence files/sections> · Updated: <ISO date>
  ```
- **Supersession:** the latest *agreed* decision wins; a newer draft or a later timestamp alone does not. When a decision changes, strike the old text (`~~…~~`), point to the new decision, and keep both visible.
- Keep facts, assumptions and questions apart: facts cite evidence, assumptions are labeled `ASSUMPTION:`, and questions are labeled `QUESTION:` with the consequence of leaving them unanswered.
- An artifact in an approved gate package changes only through a change request (`.claude/skills/deliver/scripts/delivery-state.sh cr-open … --approved-by "<human>"`), and only after the human said yes. `guard-gates.sh` enforces this.
- **Architecture diagrams** (D0–D8) are written in `PRD.md` and mirrored, identically, into `ARCHITECTURE.md` §14 by `design-architecture/scripts/sync-diagrams.sh`. Never edit the mirrored block, never store diagrams as separate files, and reference them by id everywhere else.
- Acceptance criteria are Given/When/Then with stable IDs (`AC-<area>-<n>`), business rules are `BR-<n>`, and test cases are `TC-<n>`. Tickets, tests and reports cite these IDs.
- **Evidence is shown, not stored:** the commands, exit codes and result lines go in the agent's return block and become one row in `milestones/<ms>/REVIEW.md › Tickets`. No log files, no per-ticket evidence folders. UI tickets save one screenshot per screen to `milestones/<ms>/screens/`.
- **No extra files:** no change-request drafts (a change request is a row in `GATE-LOG.md` plus the edits), no per-agent reports, no message log. `check-hygiene.sh` (`docs` check) flags any file outside the lean set.
- **Append-only logs** (`GATE-LOG.md`, `LESSONS.md`, `failures/`) are never rewritten and never read whole: query them with `grep -n <id>` or `tail` (`.claude/skills/deliver/references/memory.md` §3). `LESSONS.md` is the exception that gets curated: at most 30 active lines, retired lines kept under `## Retired`.
