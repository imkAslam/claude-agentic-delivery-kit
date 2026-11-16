# Agentic Software Delivery Workflow — Orchestrator playbook

Legend: **→** progress · **⇢** correction loop · **[fork]/[join]** parallel steps · **(cond.)** runs only when warranted · **⏸** human gate (STOP & WAIT).
Each step below shows its `step id` for `delivery-state.sh set-step <lane> <step>`. Artifact paths are relative to the repo root.

**Rules for every lane**
0. **Few documents.** A run writes only the lean set in [documents.md](documents.md); `X.md › Name` is a section of X.md. Evidence is shown in return blocks and summarized in `REVIEW.md`, never stored as files. Agents that write sections of the same file run one after another.
1. The latest **agreed** decision wins; a newer draft or a later timestamp alone does not. Gate approvals are tied to file hashes.
2. At most `$DELIVERY_MAX_ROUNDS` (3) consolidated review rounds per loop; anything still unresolved goes to the human.
3. No claim without evidence. Reuse real screenshots and logs. A badge or a score is not evidence.
4. Each role writes only to its own paths (`project.json → roles.<role>.paths`). Contracts freeze at G2.
5. Only the orchestrator forks, joins, triages and runs gates. Subagents never ask the human directly.

---

## Lane `adopt` — Adopt an existing codebase (instead of lanes `understand` and `plan`)
Entered with `/deliver adopt [folders]` → `delivery-state.sh init --mode adopt`. Only for a repository that already has product code and no delivery run. Every step is documents-only (`guard-coding.sh` stays on until the baseline). Rules and per-agent detail: the `adopt-codebase` skill; every brief carries `MODE: adopt`.

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `detect` | **system-detector** | The repository → `SYSTEM-PROFILE.md` with the **Existing code** section | No product code found → stop: this is a new project, use `/deliver start`. A dirty working tree → ask the human to commit or stash |
| `map` | **solution-architect** | SYSTEM-PROFILE + the code → `.claude/project.json`, `.claude/PROJECT.md`, `ARCHITECTURE.md` (as built), the derivable diagrams in `PRD.md` §10–§12 + `sync-diagrams.sh`, inherited ADRs | → `as-built-fork`. Commit `project.json` before forking |
| `as-built-fork` | **[fork]** **database-architect** (`DATA-MODEL.md` from migrations) · **api-designer** (contracts from the existing API, coverage stated) · **ba-agent** → **product-manager** (`PRD.md › Analysis`, a light `PRD.md`) · **uiux-agent** (*audit*: `tokens.json` from the theme, component inventory, real screenshots) · **qa-agent** (`BASELINE.md › Tests`) · **devops-engineer** (`ARCHITECTURE.md › Operations` as built) · **cybersecurity-agent** (cond.; a light `THREAT-MODEL.md`) | The code → the as-built documents | A P1 security or data-loss finding → tell the human immediately (major decision), then continue |
| `baseline-checks` | **quality-security-agent** | `project.json` commands, hygiene, audits, the agents' debts → `BASELINE.md` (check results + debt register) | A command that can't be made green → `NEEDS_HUMAN` with the proposed quarantine |
| `as-built-docs` | **docs-writer** (`MODE: adopt`) | → `PLAN.md › Features`, `database/DATABASE.md`, `SYSTEM-FLOWS.md`, `CODEMAP.md` | → `as-built-review` |
| `as-built-review` | **architect-reviewer** | Accuracy review of every as-built document against the code (loop id `as-built-review`) | ⇢ *Corrections* to the owning agent → re-review the diff |
| `baseline` | ⏸ **gate `baseline` — Adopt baseline** | Package: `PRD.md`, `ARCHITECTURE.md`, `BASELINE.md`, `DATA-MODEL.md`, the contracts, `DESIGN.md` + `tokens.json` (+ `THREAT-MODEL.md` for sensitive data) | Approved → commit the package, `delivery-state.sh approve-baseline …` (records `baseline`, `g1`, `g2`; tags `delivery-baseline`), register the "fix now" debts as chore tickets → `build / increment-wait`. ⇢ *Revise* → the owning agent |

### Increments (every change after the baseline)
An adopted product has no "milestone 1". Work arrives as evidence in `docs/intake/` (a feature brief, a bug list, a change), and each batch runs this loop:

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `increment-wait` (lane `build`) | Orchestrator | "Fix now" debt tickets run first (`dispatch`). New evidence in `docs/intake/` → `increment-discovery` | Nothing to do → report and stop |
| `increment-discovery` (lane `understand`) | **intake-agent** (the new evidence only) → **product-manager** ⇄ **product-owner-reviewer** → **solution-architect** (technical review) · **uiux-agent**, **api-designer**, **database-architect** only when the change touches their area | The PRD change for this scope with full acceptance criteria; the as-built documents **deepened for the touched areas** (contract operations, data model, screens and states) | Ask the human to approve the change (new scope is a major decision), then `cr-open g1` and/or `cr-open g2` listing the files that change |
| `increment-plan` (lane `plan`) | **qa-agent** (test cases for the new AC) · **delivery-planner** (a milestone `ms-<n>` for the increment, tickets, "characterization tests first" where the touched code has none, "fix when touched" debts attached) | → `PLAN.md › Test cases`, `PLAN.md › Milestones`, `PLAN.md › Tickets` | Re-present the invalidated gate(s) with the change only → approve → `cr-close` → lane `build`, `dispatch` |
| then | Lanes `build` → `verify` → `release` exactly as below | `check-hygiene.sh --base delivery-baseline` (standards apply to new and changed code) | After `ops_ack` (or after `mbr` when releases are batched) → `increment-wait` |

## Lane `understand` — Understand & Agree

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `intake` | **intake-agent** | `docs/intake/**` → `docs/delivery/Intake-Readiness.md` (score, gaps, consequences, questions) | → `intake-gate`. ⇢ *Update*: ask the human for missing evidence, then re-run intake |
| `intake-gate` | ⏸ **gate `intake`** | Package: `Intake-Readiness.md` | 80% or more: Start / Update / Hold. Below 80%: Update / Provisional scope / Hold. A critical gap: resolve the work that depends on it first |
| `research` | **researcher-agent** (cond.) | Intake → `docs/delivery/PRD.md › Research notes` (5 comparable products) | For a known or narrow change: skip and record the reason (`delivery-state.sh note`) |
| `ba` | **ba-agent** | Intake + research → `docs/delivery/PRD.md › Analysis` | → `discovery` |
| `discovery` | **product-manager** → **product-owner-reviewer**; **solution-architect** (technical review ⇄ PM, **architecture research**, layered architecture + folder structure); **cybersecurity-agent** (cond.) → threat input; **uiux-agent** in *brand mode* (round 1, in parallel) → **design-reviewer** (loop id `brand-directions`) | → `docs/delivery/PRD.md` (PM sections + the architect-owned §10 *Solution architecture (layer by layer)* and §11 *Application folder structure*), `docs/delivery/ARCHITECTURE.md › Research`, `docs/delivery/ARCHITECTURE.md` (overview + §12 layers + §13 folders), `docs/delivery/THREAT-MODEL.md` (cond.), `docs/delivery/DESIGN.md › Directions` + `docs/delivery/brand/directions/*` (2–3 visual directions, or a brand audit when a full brand exists), `docs/adr/*` | Loop id `discovery`: ⇢ *Product correction* (PO → PM), ⇄ *Revised requirements / Technical correction* (PM ⇄ architect). Leave the loop once the PO says APPROVE and the architect has no P1 findings. Round cap → human |
| `g1` | ⏸ **gate `g1` — PRD + architecture direction (no coding)** | Package: `PRD.md`, `ARCHITECTURE.md`, `DESIGN.md › Directions` + `brand/directions/` (+ `THREAT-MODEL.md` for sensitive data). **The client chooses the visual direction and confirms the tech stack here** (one business question each; the client may name their own stack) | Approved → lane `plan`, **detailed planning only; no coding**. ⇢ *Revise PRD* / *Revise technical overview* → `discovery` |

**Discovery order inside one round:**
1. The PM drafts or revises the PRD (§1–§9). In round 1, the architect researches **in parallel**: drivers → proven reference architectures from authoritative sources → `ARCHITECTURE.md › Research`.
2. In parallel: the PO reviewer reviews the PRD; the architect does the technical review **and writes or updates PRD §10–§12** (layer-by-layer architecture, folder structure, and **every diagram, D0–D8, inline in the PRD**) plus ARCHITECTURE §12–§13 and its §14 (the same diagrams, mirrored by `sync-diagrams.sh`); cybersecurity adds its threat input if it applies.
3. The orchestrator merges all the findings and `MESSAGES:` into one consolidated list ([collaboration.md](collaboration.md)), then starts the next round.

**Agent communication in every lane:** agents exchange questions, requests and handoffs through the orchestrator ([collaboration.md](collaboration.md)). Blocking questions are answered before the step advances, and no gate is presented while a blocking message is open.

## Lane `plan` — Plan & Design

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `docs-init` | — | Removed in the lean set: there is no docs index, feature file or ADR index to create. The feature status table is `PLAN.md › Features`, written at `docs-plan` | — |
| `boundaries` | **solution-architect** | G1 package → `.claude/project.json` (roles to enable, owned paths, shared-file owners, contract format, commands, tracker/CI/deploy kinds) + `.claude/PROJECT.md` | → `design-fork`. Then refresh `system-detector` for tracker/CI/deploy access |
| `design-fork` | **[fork]** **database-architect** (conceptual → logical → physical model, access patterns → indexes, classification and retention, migration strategy → `DATA-MODEL.md`; the D6 diagrams are handed to the architect for PRD §12) · **api-designer** (API contracts in `contracts.paths` + `ARCHITECTURE.md › API conventions`, mock server, codegen; built on DATA-MODEL) · **integration-engineer** in *plan mode* (`ARCHITECTURE.md › Integrations`: every external provider, its sandbox, limits, failure modes; cost goes to the gate) · **solution-architect** (modules; diagram updates kept for `prd-sync`; reviews contracts against the layers; realtime/queues only if needed) · **uiux-agent** in *design mode* (structure first: `DESIGN.md › UX` flows and wireframes → design-reviewer; then `DESIGN.md › Brand`, `tokens.json` (+ themes), `DESIGN.md › Components`, `docs/delivery/mockups/*`, `docs/delivery/brand/assets/*` → **design-reviewer**, loop id `design-review`) · **qa-agent** (`PLAN.md › Test cases`) · **devops-engineer** in *plan mode* (`ARCHITECTURE.md › Operations`) → **architect-reviewer** on the DevOps plan | | ⇢ *DevOps gap* → devops-engineer (loop id `devops-plan`). ⇢ *Design gap* → uiux-agent (loop id `design-review`) |
| `design-join` | **architect-reviewer** in alignment mode; the orchestrator reconciles | All four runners' outputs → a consolidated revision list | ⇢ send each revision to the runner that owns it (loop id `design-align`) |
| `prd-sync` | Orchestrator, then **solution-architect** (design-architecture Step 9b), then **architect-reviewer** | ask the human once, then `cr-open g1 "Lane 2 diagram refinements" --approved-by "<human>" docs/delivery/PRD.md docs/delivery/ARCHITECTURE.md` → the architect folds the refined D3/D4/D6/D7/D8 (and D1/D2/D5 if components changed) from the `handoff` messages into PRD §12, nothing else, then `sync-diagrams.sh` mirrors them into ARCHITECTURE §14; `check-diagrams.sh --mirror` passes. The CR stays open until the human re-confirms g1, then `cr-close`. **Skip** (with a note) when no diagram changed | → `planning`. g1 is re-confirmed by the human together with g2 (gates.md) |
| `planning` | **delivery-planner** | Aligned designs → `PLAN.md › Milestones`, `PLAN.md › Tickets`, `PLAN.md › Quality` + tracker tickets | Register each ticket in state (`delivery-state.sh ticket add …`). If the PRD has `F-LANDING`: the landing ticket, and a landing refresh ticket in the last milestone of every later release (plan-delivery). ⇢ *Ticket dependency revisions* |
| `docs-plan` | **docs-writer** (`plan`), in parallel with `prd-sync` | `PLAN.md › Features` (one row per PRD feature: milestone, tickets, status); `docs/database/DATABASE.md` (the database design, from DATA-MODEL) | Living sections, updated at every milestone |
| `g2` | ⏸ **gate `g2` — Implementation scope: approval to start coding** (preceded by the g1 re-confirmation if `prd-sync` changed the PRD) | Package: `ARCHITECTURE.md`, `DATA-MODEL.md`, `DESIGN.md`, `tokens*.json`, `mockups/` (key screens), `brand/`, `PLAN.md`, `contracts.paths` | Approved → **contracts frozen**, lane `build`, milestone `ms-1` |

## Lane `build` — Build & Review (repeats for each milestone)

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `foundation` | Orchestrator | Commit `.claude/`, `docs/`, the contracts and `project.json` (worktrees only see committed files). Foundation tickets for `ms-1` (the **local Docker dev environment** for every backing service, scaffold, CI, health, staging skeleton, and the **design foundation**: tokens → web/mobile theme, base components, brand assets wired in) run first, in dependency order. If SYSTEM-PROFILE shows Docker unavailable, ask the human once for remote service URLs (into `.env`; see setup-docker → LOCAL_SERVICES.md) | Once the scaffold exists: run every `project.json` command once. If all are green, `delivery-state.sh set '.validated_at=now'`. If one fails → triage to the role that owns it |
| `dispatch` | Orchestrator | `delivery-state.sh plan-check <ms>` must pass (independent tickets, no file overlap); `delivery-state.sh ready <ms>` → **every** ticket whose dependencies are done, started together up to `DELIVERY_MAX_PARALLEL`; each dispatched ticket → `in_progress` | Choose a set with **no file overlap** (see `triage.md` → overlap check) |
| `build-fork` | **[fork]** one Agent call per ready ticket, each with `isolation: "worktree"`: **frontend-engineer**, **backend-engineer**, **mobile-engineer** (if enabled), **devops-engineer** (build mode), **integration-engineer** (integration tickets), **cybersecurity-agent** (security tickets) | Ticket brief → commits on `ms-<n>/<role>/<ticket>` | For each ticket: role reviewer (**frontend-, backend-, mobile-, devops-, integration-, security-reviewer**), plus **database-reviewer** in parallel whenever the diff touches migrations, schema, models or queries. Both must APPROVE. ⇢ *Correction* → same role, same worktree (loop id `ticket:<id>`, cap 3). Status: engineer DONE → `in_review`; CHANGES → `changes_requested` → next attempt `in_progress`; all reviewers APPROVE → `approved` |
| `integrate` | **[join]** **integrator** | Approved branches → `ms-<n>/integration`; combined checks + the hygiene check (`check-hygiene.sh`: leftovers → one chore ticket per owning role) + a real journey. Each merged ticket whose checks pass → `done`; a ticket whose merge or journey fails → `reopened` | **Pass** → if more tickets remain in the milestone, back to `dispatch`; otherwise, in parallel: **qa-agent** runs the milestone's end-to-end journeys once (results in `REVIEW.md › Checks`), **uiux-agent** in *design-QA mode* (milestones with UI tickets) → `milestones/<ms>/REVIEW.md › Design QA`, **performance-specialist** in *milestone mode* (milestones that change user-facing screens or data paths; skipped with a recorded reason otherwise, and in the `lean` profile) → `milestones/<ms>/REVIEW.md › Performance`, and **docs-writer** (`milestone`) → FEATURES status, DATABASE.md as built, SYSTEM-FLOWS.md as built, CODEMAP.md, CHANGELOG, README, ADR index, stale entries removed; P1/P2 design mismatches and performance findings → triage (owning role) → `dispatch` → then the milestone package `docs/delivery/milestones/<ms>/` → `mbr`. **Fail** → `triage.md` → new or reopened tickets → `dispatch` |
| `mbr` | ⏸ **gate `mbr:<ms>` — Milestone Build Review** | Package: `milestones/<ms>/REVIEW.md` and `milestones/<ms>/screens/` | Approved → merge the integration branch (PR/MR through the `ci` skill) → next milestone (`dispatch`), or lane `verify` once all milestones are done. ⇢ *Request fixes* → triage (the milestone's tickets are reopened, not bugged: they aren't approved yet) |

## Lane `verify` — Verify & Accept

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `verify-fork` | **[fork]** **performance-specialist** (*candidate mode*: the PRD performance budgets on the candidate → `REVIEW.md › Performance`) · **qa-agent** (executes every TC and E2E journey → `ACCEPTANCE.md › QA`, `ACCEPTANCE.md › Open issues`) · **quality-security-agent** (automated scans, reviews and assessments → `ACCEPTANCE.md › Quality and security`) · **security-auditor** (scoped and authorized manual audit: data-flow tracing, adversarial feature analysis, OWASP Top 10 / API Top 10, authorized DAST on owned staging only → `ACCEPTANCE.md › Security audit`) | The accepted candidate (default branch at the last MBR) | → `evidence-policy` (Critical/High security findings fail the policy) |
| `evidence-policy` | Orchestrator | Every TC has current evidence (newer than the candidate commit); no open finding above the `PLAN.md › Quality` thresholds | **Fail / missing / stale** → triage → lane `build`. **Pass** → `ACCEPTANCE.md › Summary` (written by the qa-agent on request) |
| `acceptance` | ⏸ **gate `acceptance` — Client Acceptance + Quality** | Package: `ACCEPTANCE.md` | Approved → lane `release`. ⇢ *Bug feedback* → triage. Reuse the real screenshots; no new design concepts. If `F-LANDING`: the client also approves the "Landing page changes" section (copy and features shown) |

## Lane `release` — Release & Operate

| step id | Who | Input → Output | Next / loop |
|---|---|---|---|
| `release-prep` | **devops-engineer** (release mode) → **release-reviewer**; **docs-writer** (`release`) in parallel: CHANGELOG version, README, docs index | → `RELEASE.md › Review`, `RELEASE.md › Deployment plan`, `RELEASE.md › Rollback`, `RELEASE.md › Operations handoff` | ⇢ *Release corrections* (loop id `release`) |
| `g3` | ⏸ **gate `g3` — Named release / environment** | Package: `RELEASE.md`. Record `release.name`, `release.artifact`, `release.environment` | Approved → `deploy`. ⇢ *Revise* → `release-prep` |
| `deploy` | **devops-engineer** | Triggers the production pipeline through the `ci` skill (`guard-prod.sh` checks G3) | → `smoke` |
| `smoke` | **devops-engineer** | Health path + critical journeys + an observation window | **Fail** → run the *approved recovery procedure* from `RELEASE.md › Rollback`, record the outcome, escalate to the human if unresolved |
| `handoff` | **devops-engineer** | → `RELEASE.md › Result` + the final `RELEASE.md › Operations handoff` | → `ops_ack` |
| `ops_ack` | ⏸ **gate `ops_ack` — Operations owner acknowledges receipt** | Package: `RELEASE.md › Result`, `RELEASE.md › Operations handoff` | Acknowledged → lane `done`: **STOP — handoff complete.** This receipt is **not** another deployment authorization. ⇢ *Corrections* → `handoff` |
