# Human gates

Only the human can pass a gate. The orchestrator presents the package with the `gate-review` skill, records the decision with `.claude/skills/deliver/scripts/delivery-state.sh approve|reject`, and **ties the approval to the sha256 of every file in the package**. Editing a file in an approved package later invalidates the approval: `guard-gates.sh` blocks such edits unless a change request is open, and `delivery-state.sh verify <gate>` fails.

| Gate id | Name | Package (paths relative to `docs/delivery/` unless shown) | Reviewers | Decisions | Approval unlocks |
|---|---|---|---|---|---|
| `intake` | Intake decision | `Intake-Readiness.md` | Client / Product Owner | `start`, `update`, `provisional`, `hold` | research/BA (`start`, `provisional`) |
| `g1` | PRD + architecture direction (**no coding**) | `PRD.md`: the complete document, incl. §10 D1 main system diagram, "Why this architecture" and the layered architecture; §11 folder structure; **§12 every other diagram (D0, D2–D8)**. There are no separate diagram files, `ARCHITECTURE-RESEARCH.md`, `ARCHITECTURE.md`, `BRAND-DIRECTIONS.md` + `brand/directions/` (the visual directions; the client picks one); the **tech stack** in PRD §10 (the client confirms it or names their own) (+ `RESEARCH.md`, `BA-ANALYSIS.md`, `THREAT-MODEL.md` if present) | Client / Product Owner, Human Architect | `approve`, `revise-prd`, `revise-architecture` | Lane plan: detailed planning only; no coding |
| `g2` | Implementation scope: **approval to start coding** | `ARCHITECTURE.md` (references the PRD diagrams), `DATA-MODEL.md`, `API-GUIDELINES.md`, `INTEGRATIONS.md`, `UI-UX.md`, `BRAND-BRIEF.md`, `DESIGN-SYSTEM.md`, `tokens*.json`, `mockups/`, `brand/assets/`, `brand/fonts/` (if any), `TEST-CASES.md`, `DEVOPS-PLAN.md`, `DELIVERY-PLAN.md`, `TICKETS.md`, `QUALITY-RELEASE-PLAN.md`, plus every path in `project.json → contracts.paths` | Client, Human Architect, UI/UX, QA, DevOps (as planned) | `approve`, `revise` | **Coding starts** (lane build; `guard-coding.sh` blocks every code write, scaffold, code commit and build agent until this approval). **Contracts and design frozen** |
| `mbr:<ms>` | Milestone Build Review | `milestones/<ms>/BUILD-REVIEW.md`, `COMPLETED-TICKETS.md`, `VERIFICATION-RESULTS.md`, `RUN-GUIDE.md`, `DESIGN-QA.md` (UI milestones), `evidence/` | Human Architect, UI/UX, Product Owner, DevOps/security (as planned) | `approve`, `request-fixes` | Merge the milestone and start the next one, or lane verify |
| `acceptance` | Client Acceptance + Quality | `ACCEPTANCE-REVIEW.md`, `QA-REPORT.md`, `OPEN-ISSUES.md`, `QUALITY-SECURITY-REPORT.md`, `SECURITY-AUDIT-REPORT.md`, `evidence/` | Client / Product Owner, Human Architect / QA, UI/UX / security (as needed) | `accept`, `bug-feedback` | Lane release |
| `g3` | Named release / environment | `RELEASE-REVIEW.md`, `DEPLOYMENT-PLAN.md`, `ROLLBACK-RUNBOOK.md`, `OPERATIONS-HANDOFF.md` (+ the release name, artifact and environment) | Release Owner, Human Architect / DevOps, Business Owner | `approve`, `revise` | **The production pipeline trigger** (`guard-prod.sh`) |
| `ops_ack` | Operations handoff | `DEPLOYMENT-RESULT.md`, `OPERATIONS-HANDOFF.md` | Operations owner | `acknowledge`, `corrections` | Lane done (this is not a new deploy authorization) |

## Recording
```bash
bash .claude/skills/deliver/scripts/delivery-state.sh approve <gate> <decision> "<approver name/role>" "<notes>" <file-or-dir>...
bash .claude/skills/deliver/scripts/delivery-state.sh reject  <gate> <decision> "<approver>" "<notes>"
bash .claude/skills/deliver/scripts/delivery-state.sh verify  <gate>          # exit 0 only when approved and all hashes match
bash .claude/skills/deliver/scripts/delivery-state.sh release "<name>" "<artifact digest/tag>" "<environment>"   # before approving g3
```

## Change requests (editing an approved artifact)
```bash
# only after the human approved the change (AskUserQuestion: what changes, why, impact on cost/timeline, recommendation)
bash .claude/skills/deliver/scripts/delivery-state.sh cr-open <gate> "<reason>" --approved-by "<human>" <path>...   # prints CR id
bash .claude/skills/deliver/scripts/delivery-state.sh cr-close <CR-id>                      # after the change, set the gate back to pending and re-run it
```
Opening a CR sets the gate's status to `invalidated`. The gate has to be presented and approved again before the work that depends on it continues.

**G1 re-confirmation after `prd-sync`.** The Lane 2 diagram refinements reach the PRD through a CR on g1 (workflow.md, `prd-sync`). The human approves opening that CR with one short question when `prd-sync` starts ("update the PRD diagrams with the Lane 2 refinements; no requirement change"). Present the re-approval **in the same sitting as g2**, first: a short summary listing only the diagrams that changed (ids, one line each) and confirming "no requirement change". Record it with `approve g1 approve …` on the same package paths as before, `cr-close` the CR, then present g2. If the human rejects the refinements, they become g2 revisions.
