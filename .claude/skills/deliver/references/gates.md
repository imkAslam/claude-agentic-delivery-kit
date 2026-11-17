# Human gates

Only the human can pass a gate. The orchestrator presents the package with the `gate-review` skill, records the decision with `.claude/skills/deliver/scripts/delivery-state.sh approve|reject`, and **ties the approval to the sha256 of every file in the package**. Editing a file in an approved package later invalidates the approval: `guard-gates.sh` blocks such edits unless a change request is open, and `delivery-state.sh verify <gate>` fails.

| Gate id | Name | Package (paths relative to `docs/delivery/` unless shown; the full list of documents and their sections: [documents.md](documents.md)) | Reviewers | Decisions | Approval unlocks |
|---|---|---|---|---|---|
| `baseline` | Adopt baseline (adopt runs only; stands in for `intake`, `g1` and `g2`) | `PRD.md` (light, as built), `ARCHITECTURE.md` (as built, diagrams in §14), `BASELINE.md` (check results, boundaries, debt register, test inventory), `DATA-MODEL.md`, the contracts, `DESIGN.md` + `tokens.json` (+ `THREAT-MODEL.md` for sensitive data) | Client / Product Owner, Human Architect | `approve`, `revise`, `hold` | Coding on the adopted codebase, through increments (workflow.md) |
| `intake` | Intake decision | `Intake-Readiness.md` | Client / Product Owner | `start`, `update`, `provisional`, `hold` | research/BA (`start`, `provisional`) |
| `g1` | PRD + architecture direction (**no coding**) | `PRD.md` (the complete document: requirements, analysis, §10–§12 architecture and every diagram; the **tech stack** in §10, which the client confirms or replaces), `ARCHITECTURE.md` (§14 mirrors the diagrams; `check-diagrams.sh --mirror` passes), `DESIGN.md › Directions` + `brand/directions/` (the client picks one) (+ `THREAT-MODEL.md` for sensitive data) | Client / Product Owner, Human Architect | `approve`, `revise-prd`, `revise-architecture` | Lane plan: detailed planning only; no coding |
| `g2` | Implementation scope: **approval to start coding** | `ARCHITECTURE.md` (complete, incl. integrations, operations, security), `DATA-MODEL.md`, `DESIGN.md`, `tokens*.json`, `mockups/` (key screens), `brand/`, `PLAN.md` (milestones, tickets, quality, test cases), plus every path in `project.json → contracts.paths` | Client, Human Architect, UI/UX, QA, DevOps (as planned) | `approve`, `revise` | **Coding starts** (lane build; `guard-coding.sh` blocks every code write, scaffold, code commit and build agent until this approval). **Contracts and design frozen** |
| `mbr:<ms>` | Milestone Build Review | `milestones/<ms>/REVIEW.md` (build, tickets, checks, run guide, design QA, performance, improvement report) and `milestones/<ms>/screens/` | Human Architect, UI/UX, Product Owner, DevOps/security (as planned) | `approve`, `request-fixes` | Merge the milestone and start the next one, or lane verify |
| `acceptance` | Client Acceptance + Quality | `ACCEPTANCE.md` (summary, QA, open issues, quality and security, security audit, performance) | Client / Product Owner, Human Architect / QA, UI/UX / security (as needed) | `accept`, `bug-feedback` | Lane release |
| `g3` | Named release / environment | `RELEASE.md` (review, deployment plan, rollback, operations handoff) (+ the release name, artifact and environment) | Release Owner, Human Architect / DevOps, Business Owner | `approve`, `revise` | **The production pipeline trigger** (`guard-prod.sh`) |
| `ops_ack` | Operations handoff | `RELEASE.md › Result` and `RELEASE.md › Operations handoff` | Operations owner | `acknowledge`, `corrections` | Lane done (this is not a new deploy authorization) |

## Recording
```bash
bash .claude/skills/deliver/scripts/delivery-state.sh approve <gate> <decision> "<approver name/role>" "<notes>" <file-or-dir>...
bash .claude/skills/deliver/scripts/delivery-state.sh reject  <gate> <decision> "<approver>" "<notes>"
bash .claude/skills/deliver/scripts/delivery-state.sh verify  <gate>          # exit 0 only when approved and all hashes match
bash .claude/skills/deliver/scripts/delivery-state.sh approve-baseline "<approver>" "<notes>" <file-or-dir>...   # adopt runs: records baseline + g1 + g2, tags delivery-baseline (commit the package first)
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
