---
name: release-docs
description: "Templates and procedure for the DevOps plan, the one-time bootstrap checklist, and the release package (RELEASE-REVIEW, DEPLOYMENT-PLAN, ROLLBACK-RUNBOOK, OPERATIONS-HANDOFF, DEPLOYMENT-RESULT), plus the release-reviewer's completeness checks. Pairs with the ci and ship skills for the actual pipeline and hosting steps."
when_to_use: "Use when writing DEVOPS-PLAN.md or BOOTSTRAP.md, preparing a release for G3, recording a deployment result, preparing the operations handoff, or reviewing a release package."
---

# Release docs

For the **devops-engineer** (plan mode in lane plan, release mode in lane release) and the **release-reviewer**.

## When to Use
- Lane plan, `design-fork`: `DEVOPS-PLAN.md` (reviewed by the architect-reviewer)
- Lane build, foundation: `BOOTSTRAP.md` (the human's one-time setup steps)
- Lane release, `release-prep`: the four G3 documents
- Lane release, `handoff`: `DEPLOYMENT-RESULT.md` + the final `OPERATIONS-HANDOFF.md`

## Instructions

### Step 0: Load the inputs
`ARCHITECTURE.md` (topology, data), `project.json` (`deploy`, `ci`, `commands`), the **ship** target reference for `deploy.target`, the **ci** reference for `ci.kind`, `QUALITY-RELEASE-PLAN.md`, `SYSTEM-PROFILE.md`.

### Step 1: DevOps plan (plan mode)
Fill [DEVOPS_PLAN_TEMPLATE.md](references/DEVOPS_PLAN_TEMPLATE.md). Every stateful component needs a backup, a restore drill and a rollback path. Production deploys are manual or protected and promote the same artifact that staging received. Refine the **D8 CI/CD flow** (and D3 deployment if the topology changes): Diagrams are written only by the solution-architect, in the PRD, and mirrored into ARCHITECTURE §14 (`design-architecture/references/DIAGRAMS.md` → "Two homes, one source"): send the Mermaid source to the solution-architect in a `handoff` message, and never create a separate diagram file or a copy in your document.

### Step 2: Bootstrap checklist (build mode, foundation)
Fill [BOOTSTRAP_TEMPLATE.md](references/BOOTSTRAP_TEMPLATE.md) from the ship target's "Bootstrap" section. List **names** of secrets only. The human performs these steps; the system-detector then confirms the secret names exist.

### Step 3: Release package (release mode, before G3)
Fill the four documents in [RELEASE_TEMPLATES.md](references/RELEASE_TEMPLATES.md):
1. `RELEASE-REVIEW.md`: one immutable artifact (digest or build id + commit), the config/secret-name diff, migrations, open issues and their decisions
2. `DEPLOYMENT-PLAN.md`: pre-checks, CI steps, smoke tests, observation window, go/no-go criteria
3. `ROLLBACK-RUNBOOK.md`: app and data rollback, with triggers, steps, owner, and the date it was rehearsed on staging
4. `OPERATIONS-HANDOFF.md`: runbooks, dashboards, alerts, on-call, backups, known issues

Then the orchestrator records the release identity (`delivery-state.sh release …`) and presents **g3**.

### Step 4: Deploy, smoke, result (after G3)
Trigger production through the **ci** skill (`trigger production <artifact>`). Watch the run; smoke-test `prod_url + health_path` and the critical journeys; observe the error rate and latency for the planned window. On failure, run the ROLLBACK-RUNBOOK steps and record the outcome. Write `DEPLOYMENT-RESULT.md`.

### Step 5: Release-reviewer checks
Check each item in the "Release review checklist" in RELEASE_TEMPLATES.md. Return `VERDICT` with findings labeled `Release correction`.

## Integration with Other Skills
- **ci:** pipeline, secrets by name, triggers, run status
- **ship:** per-target IaC, deploy steps, health, rollback, bootstrap items
- **setup-docker:** container builds for the container targets
- **gate-review:** the g3 and ops_ack packages

## File Structure
```
.claude/skills/release-docs/
├── SKILL.md
└── references/
    ├── DEVOPS_PLAN_TEMPLATE.md
    ├── BOOTSTRAP_TEMPLATE.md
    └── RELEASE_TEMPLATES.md     # the 5 release documents + the release review checklist
```
