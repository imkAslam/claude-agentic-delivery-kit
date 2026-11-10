# Agentic Software Delivery Workflow — Orchestrator playbook

Legend: **→** progress · **⇢** correction loop · **[fork]/[join]** parallel steps · **(cond.)** runs only when warranted · **⏸** human gate (STOP & WAIT).
Each step below shows its `step id` for `delivery-state.sh set-step <lane> <step>`. Artifact paths are relative to the repo root.

**Rules for every lane**
1. The latest **agreed** decision wins; a newer draft or a later timestamp alone does not. Gate approvals are tied to file hashes.
2. At most `$DELIVERY_MAX_ROUNDS` (3) consolidated review rounds per loop; anything still unresolved goes to the human.
3. No claim without evidence. Reuse real screenshots and logs. A badge or a score is not evidence.
4. Each role writes only to its own paths (`project.json → roles.<role>.paths`). Contracts freeze at G2.
5. Only the orchestrator forks, joins, triages and runs gates. Subagents never ask the human directly.

---

## Lane `understand` — Understand & Agree

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `intake` | **intake-agent** | `docs/intake/**` → `docs/delivery/Intake-Readiness.md` (score, gaps, consequences, questions) | → `intake-gate`. ⇢ *Update*: ask the human for missing evidence, then re-run intake |
| `intake-gate` | ⏸ **gate `intake`** | Package: `Intake-Readiness.md` | 80% or more: Start / Update / Hold. Below 80%: Update / Provisional scope / Hold. A critical gap: resolve the work that depends on it first |
| `research` | **researcher-agent** (cond.) | Intake → `docs/delivery/RESEARCH.md` (5 comparable products) | For a known or narrow change: skip and record the reason (`delivery-state.sh note`) |
| `ba` | **ba-agent** | Intake + research → `docs/delivery/BA-ANALYSIS.md` | → `discovery` |
| `discovery` | **product-manager** → **product-owner-reviewer**; **solution-architect** (technical review ⇄ PM, **architecture research**, layered architecture + folder structure); **cybersecurity-agent** (cond.) → threat input; **uiux-agent** in *brand mode* (round 1, in parallel) → **design-reviewer** (loop id `brand-directions`) | → `docs/delivery/PRD.md` (PM sections + the architect-owned §10 *Solution architecture (layer by layer)* and §11 *Application folder structure*), `docs/delivery/ARCHITECTURE-RESEARCH.md`, `docs/delivery/ARCHITECTURE.md` (overview + §12 layers + §13 folders), `docs/delivery/THREAT-MODEL.md` (cond.), `docs/delivery/BRAND-DIRECTIONS.md` + `docs/delivery/brand/directions/*` (2–3 visual directions, or a brand audit when a full brand exists), `docs/adr/*` | Loop id `discovery`: ⇢ *Product correction* (PO → PM), ⇄ *Revised requirements / Technical correction* (PM ⇄ architect). Leave the loop once the PO says APPROVE and the architect has no P1 findings. Round cap → human |
| `g1` | ⏸ **gate `g1` — PRD + architecture direction (no coding)** | Package: `PRD.md`, `ARCHITECTURE-RESEARCH.md`, `ARCHITECTURE.md`, `BRAND-DIRECTIONS.md` + `brand/directions/` (+ research, BA and threat notes). **The client chooses the visual direction and confirms the tech stack here** (one business question each; the client may name their own stack) | Approved → lane `plan`, **detailed planning only; no coding**. ⇢ *Revise PRD* / *Revise technical overview* → `discovery` |

**Discovery order inside one round:**
1. The PM drafts or revises the PRD (§1–§9). In round 1, the architect researches **in parallel**: drivers → proven reference architectures from authoritative sources → `ARCHITECTURE-RESEARCH.md`.
2. In parallel: the PO reviewer reviews the PRD; the architect does the technical review **and writes or updates PRD §10–§12** (layer-by-layer architecture, folder structure, and **every diagram, D0–D8, inline in the PRD**) plus ARCHITECTURE §12–§13 and its §14 (the same diagrams, mirrored by `sync-diagrams.sh`); cybersecurity adds its threat input if it applies.
3. The orchestrator merges all the findings and `MESSAGES:` into one consolidated list ([collaboration.md](collaboration.md)), then starts the next round.

**Agent communication in every lane:** agents exchange questions, requests and handoffs through the orchestrator ([collaboration.md](collaboration.md)). Blocking questions are answered before the step advances, and no gate is presented while a blocking message is open.

## Lane `plan` — Plan & Design

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `docs-init` | **docs-writer** (`init`, haiku), in parallel with `boundaries` | Approved PRD → `docs/README.md` (index), `docs/FEATURES.md` (feature catalog), `docs/adr/README.md` (ADR index; ADRs accepted at g1) | Living documents, never in a gate package |
| `boundaries` | **solution-architect** | G1 package → `.claude/project.json` (roles to enable, owned paths, shared-file owners, contract format, commands, tracker/CI/deploy kinds) + `.claude/PROJECT.md` | → `design-fork`. Then refresh `system-detector` for tracker/CI/deploy access |
| `design-fork` | **[fork]** **database-architect** (conceptual → logical → physical model, access patterns → indexes, classification and retention, migration strategy → `DATA-MODEL.md`; the D6 diagrams are handed to the architect for PRD §12) · **api-designer** (API contracts in `contracts.paths` + `API-GUIDELINES.md`, mock server, codegen; built on DATA-MODEL) · **integration-engineer** in *plan mode* (`INTEGRATIONS.md`: every external provider, its sandbox, limits, failure modes; cost goes to the gate) · **solution-architect** (modules; diagram updates kept for `prd-sync`; reviews contracts against the layers; realtime/queues only if needed) · **uiux-agent** in *design mode* (structure first: `UI-UX.md` flows and wireframes → design-reviewer; then `BRAND-BRIEF.md`, `tokens.json` (+ themes), `DESIGN-SYSTEM.md`, `docs/delivery/mockups/*`, `docs/delivery/brand/assets/*` → **design-reviewer**, loop id `design-review`) · **qa-agent** (`TEST-CASES.md`) · **devops-engineer** in *plan mode* (`DEVOPS-PLAN.md`) → **architect-reviewer** on the DevOps plan | | ⇢ *DevOps gap* → devops-engineer (loop id `devops-plan`). ⇢ *Design gap* → uiux-agent (loop id `design-review`) |
| `design-join` | **architect-reviewer** in alignment mode; the orchestrator reconciles | All four runners' outputs → a consolidated revision list | ⇢ send each revision to the runner that owns it (loop id `design-align`) |
| `prd-sync` | Orchestrator, then **solution-architect** (design-architecture Step 9b), then **architect-reviewer** | ask the human once, then `cr-open g1 "Lane 2 diagram refinements" --approved-by "<human>" docs/delivery/PRD.md docs/delivery/ARCHITECTURE.md` → the architect folds the refined D3/D4/D6/D7/D8 (and D1/D2/D5 if components changed) from the `handoff` messages into PRD §12, nothing else, then `sync-diagrams.sh` mirrors them into ARCHITECTURE §14; `check-diagrams.sh --mirror` passes. The CR stays open until the human re-confirms g1, then `cr-close`. **Skip** (with a note) when no diagram changed | → `planning`. g1 is re-confirmed by the human together with g2 (gates.md) |
| `planning` | **delivery-planner** | Aligned designs → `DELIVERY-PLAN.md`, `TICKETS.md`, `QUALITY-RELEASE-PLAN.md` + tracker tickets | Register each ticket in state (`delivery-state.sh ticket add …`). If the PRD has `F-LANDING`: the landing ticket, and a landing refresh ticket in the last milestone of every later release (plan-delivery). ⇢ *Ticket dependency revisions* |
| `docs-plan` | **docs-writer** (`plan`), in parallel with `prd-sync` | FEATURES.md + milestones, tickets, screens and operations; `docs/database/DATABASE.md` (the database design, from DATA-MODEL); ADR index | Listed at g2 for information (not hashed) |
| `g2` | ⏸ **gate `g2` — Implementation scope: approval to start coding** (preceded by the g1 re-confirmation if `prd-sync` changed the PRD) | Package: `ARCHITECTURE.md`, `DATA-MODEL.md`, `API-GUIDELINES.md`, `INTEGRATIONS.md`, `UI-UX.md`, `BRAND-BRIEF.md`, `DESIGN-SYSTEM.md`, `tokens*.json`, `docs/delivery/mockups/`, `docs/delivery/brand/assets/`, `docs/delivery/brand/fonts/` (if any), `TEST-CASES.md`, `DEVOPS-PLAN.md`, `DELIVERY-PLAN.md`, `TICKETS.md`, `QUALITY-RELEASE-PLAN.md`, `contracts.paths` | Approved → **contracts frozen**, lane `build`, milestone `ms-1` |

## Lane `build` — Build & Review (repeats for each milestone)

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `foundation` | Orchestrator | Commit `.claude/`, `docs/`, the contracts and `project.json` (worktrees only see committed files). Foundation tickets for `ms-1` (the **local Docker dev environment** for every backing service, scaffold, CI, health, staging skeleton, and the **design foundation**: tokens → web/mobile theme, base components, brand assets wired in) run first, in dependency order. If SYSTEM-PROFILE shows Docker unavailable, ask the human once for remote service URLs (into `.env`; see setup-docker → LOCAL_SERVICES.md) | Once the scaffold exists: run every `project.json` command once. If all are green, `delivery-state.sh set '.validated_at=now'`. If one fails → triage to the role that owns it |
| `dispatch` | Orchestrator | `delivery-state.sh ready <ms>` → tickets whose dependencies are done; each dispatched ticket → `in_progress` | Choose a set with **no file overlap** (see `triage.md` → overlap check) |
| `build-fork` | **[fork]** one Agent call per ready ticket, each with `isolation: "worktree"`: **frontend-engineer**, **backend-engineer**, **mobile-engineer** (if enabled), **devops-engineer** (build mode), **integration-engineer** (integration tickets), **qa-agent** (E2E tickets), **cybersecurity-agent** (security tickets) | Ticket brief → commits on `ms-<n>/<role>/<ticket>` | For each ticket: role reviewer (**frontend-, backend-, mobile-, devops-, integration-, security-reviewer**), plus **database-reviewer** in parallel whenever the diff touches migrations, schema, models or queries. Both must APPROVE. ⇢ *Correction* → same role, same worktree (loop id `ticket:<id>`, cap 3). Status: engineer DONE → `in_review`; CHANGES → `changes_requested` → next attempt `in_progress`; all reviewers APPROVE → `approved` |
| `integrate` | **[join]** **integrator** | Approved branches → `ms-<n>/integration`; combined checks + a real journey. Each merged ticket whose checks pass → `done`; a ticket whose merge or journey fails → `reopened` | **Pass** → if more tickets remain in the milestone, back to `dispatch`; otherwise, in parallel: **uiux-agent** in *design-QA mode* (milestones with UI tickets) → `milestones/<ms>/DESIGN-QA.md`, **performance-specialist** in *milestone mode* (milestones that change user-facing screens or data paths; skipped with a recorded reason otherwise, and in the `lean` profile) → `milestones/<ms>/PERFORMANCE-REVIEW.md`, and **docs-writer** (`milestone`) → FEATURES status, DATABASE.md as built, CODEMAP.md, CHANGELOG, README, ADR index; P1/P2 design mismatches and performance findings → triage (owning role) → `dispatch` → then the milestone package `docs/delivery/milestones/<ms>/` → `mbr`. **Fail** → `triage.md` → new or reopened tickets → `dispatch` |
| `mbr` | ⏸ **gate `mbr:<ms>` — Milestone Build Review** | Package: `BUILD-REVIEW.md`, `COMPLETED-TICKETS.md`, `VERIFICATION-RESULTS.md`, `RUN-GUIDE.md`, `DESIGN-QA.md` (if the milestone has UI), `PERFORMANCE-REVIEW.md` (if it ran), `evidence/` | Approved → merge the integration branch (PR/MR through the `ci` skill) → next milestone (`dispatch`), or lane `verify` once all milestones are done. ⇢ *Request fixes* → triage (the milestone's tickets are reopened, not bugged: they aren't approved yet) |

## Lane `verify` — Verify & Accept

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `verify-fork` | **[fork]** **performance-specialist** (*candidate mode*: the PRD performance budgets on the candidate → `PERFORMANCE-REVIEW.md`) · **qa-agent** (executes every TC and E2E journey → `QA-REPORT.md`, `OPEN-ISSUES.md`) · **quality-security-agent** (automated scans, reviews and assessments → `QUALITY-SECURITY-REPORT.md`) · **security-auditor** (scoped and authorized manual audit: data-flow tracing, adversarial feature analysis, OWASP Top 10 / API Top 10, authorized DAST on owned staging only → `SECURITY-AUDIT-REPORT.md`) | The accepted candidate (default branch at the last MBR) | → `evidence-policy` (Critical/High security findings fail the policy) |
| `evidence-policy` | Orchestrator | Every TC has current evidence (newer than the candidate commit); no open finding above the `QUALITY-RELEASE-PLAN.md` thresholds | **Fail / missing / stale** → triage → lane `build`. **Pass** → `ACCEPTANCE-REVIEW.md` (written by the qa-agent on request) |
| `acceptance` | ⏸ **gate `acceptance` — Client Acceptance + Quality** | Package: `ACCEPTANCE-REVIEW.md`, `QA-REPORT.md`, `OPEN-ISSUES.md`, `QUALITY-SECURITY-REPORT.md`, `PERFORMANCE-REVIEW.md`, evidence | Approved → lane `release`. ⇢ *Bug feedback* → triage. Reuse the real screenshots; no new design concepts. If `F-LANDING`: the client also approves the "Landing page changes" section (copy and features shown) |

## Lane `release` — Release & Operate

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `release-prep` | **devops-engineer** (release mode) → **release-reviewer**; **docs-writer** (`release`) in parallel: CHANGELOG version, README, docs index | → `RELEASE-REVIEW.md`, `DEPLOYMENT-PLAN.md`, `ROLLBACK-RUNBOOK.md`, `OPERATIONS-HANDOFF.md` | ⇢ *Release corrections* (loop id `release`) |
| `g3` | ⏸ **gate `g3` — Named release / environment** | Package: the 4 release docs. Record `release.name`, `release.artifact`, `release.environment` | Approved → `deploy`. ⇢ *Revise* → `release-prep` |
| `deploy` | **devops-engineer** | Triggers the production pipeline through the `ci` skill (`guard-prod.sh` checks G3) | → `smoke` |
| `smoke` | **devops-engineer** | Health path + critical journeys + an observation window | **Fail** → run the *approved recovery procedure* from `ROLLBACK-RUNBOOK.md`, record the outcome, escalate to the human if unresolved |
| `handoff` | **devops-engineer** | → `DEPLOYMENT-RESULT.md` + the final `OPERATIONS-HANDOFF.md` | → `ops_ack` |
| `ops_ack` | ⏸ **gate `ops_ack` — Operations owner acknowledges receipt** | Package: `DEPLOYMENT-RESULT.md`, `OPERATIONS-HANDOFF.md` | Acknowledged → lane `done`: **STOP — handoff complete.** This receipt is **not** another deployment authorization. ⇢ *Corrections* → `handoff` |
