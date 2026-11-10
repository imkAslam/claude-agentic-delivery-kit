---
name: design-architecture
description: "Solution architecture toolkit: researches proven, scalable reference architectures from authoritative sources and scores candidates against PRD drivers; selects style, frameworks, data stores, API style and realtime approach with ADRs; designs the system layer by layer (clients, edge, API/BFF, application, domain, infrastructure, data, async, cross-cutting) with the application folder structure and the complete diagram set, written into the PRD (the single home of every diagram) and ARCHITECTURE.md; defines project.json boundaries, ERD, modules and complete API contracts. Also the architect-reviewer's checklists."
when_to_use: "Use when researching or choosing an architecture or stack, writing ARCHITECTURE-RESEARCH.md, ARCHITECTURE.md, PRD §10–§12 (architecture, folders, diagrams) or ADRs, defining contracts or project.json, reviewing a PRD technically, reviewing the DevOps plan or design alignment, or handling a contract change request."
---

# Design architecture

Lane `understand`: research, technical review, layered architecture and folder structure, leading to **g1**. Lane `plan`: boundaries, then detailed design, leading to **g2**.

## When to Use
- Discovery round 1: **architecture research** (in parallel with the first PRD draft)
- Every discovery round: the PRD technical review, plus PRD §10–§12 (including **all diagrams**) and ARCHITECTURE §1–§6, §12–§13
- Lane plan, `boundaries`: `project.json` and `.claude/PROJECT.md`, before the other designers start
- Lane plan, `design-fork`: ERD, modules and contracts (ARCHITECTURE §7–§11)
- Lane plan, `prd-sync`: fold the Lane 2 diagram refinements into PRD §12 under a change request (Step 9b)
- A `CONTRACT_CHANGE_NEEDED` ticket (only under a change request on g2)
- **architect-reviewer:** DevOps plan, design alignment, layer and folder conformance

## Instructions

### Step 0: Load the inputs
`PRD.md` (NFRs, release slicing), `BA-ANALYSIS.md` (entities, rules), `RESEARCH.md`, `THREAT-MODEL.md` (if present), `docs/delivery/SYSTEM-PROFILE.md` (tools, accounts, hosting), the existing `docs/adr/*`, and the INBOX messages in your brief.

### Step 1: Research the architecture (round 1, then whenever the drivers change)
Follow [REFERENCE_SOURCES.md](references/REFERENCE_SOURCES.md):
0. Read the client's **stack preference** (Intake-Readiness Summary, `docs/intake/`). A *required* stack is a constraint; a *preferred* one is candidate A in the matrix, scored honestly ([STACK_SELECTION.md](references/STACK_SELECTION.md) §0).
1. List the PRD **drivers** with weights.
2. Shortlist **3 candidates** from [ARCHITECTURE_PATTERNS.md](references/ARCHITECTURE_PATTERNS.md), one of them the simplest that could work.
3. Search and **fetch at least 5 authoritative sources**: at least 2 cloud architecture frameworks, at least 1 pattern source, plus the official docs for each chosen technology. Record the claim each one supports.
4. Score them in the weighted matrix ([STACK_SELECTION.md](references/STACK_SELECTION.md)) with an evidence column.
5. Write `docs/delivery/ARCHITECTURE-RESEARCH.md` ([ARCH_RESEARCH_TEMPLATE.md](references/ARCH_RESEARCH_TEMPLATE.md)) and an ADR for the chosen style ([ADR_TEMPLATE.md](references/ADR_TEMPLATE.md)).

### Step 2: Technical review of the PRD (every discovery round)
Return findings `[P1|P2|P3] §section — technical issue — proposed requirement change` covering feasibility, hidden complexity, NFR conflicts, cost drivers and integration risk. Questions for the PM or BA go out as `MESSAGES:`. Never edit the PM's sections.

### Step 3: Choose the technology per concern
Using the catalog in ARCHITECTURE_PATTERNS §2–§6, choose the frontend, backend and mobile frameworks, the data stores, the API style, the realtime approach and the scalability tactics, and write one ADR per significant choice. Default bias: a **modular monolith** on managed services, with an explicit evolution path. Then write the main stack into PRD §10 as **Tech stack (to confirm at G1)**: the recommendation, the client's preference if any, and the trade-offs in plain language ([STACK_SELECTION.md](references/STACK_SELECTION.md) §6). The client confirms it, or names their own, at G1.

### Step 4: Design layer by layer
Fill [LAYERED_BLUEPRINT.md](references/LAYERED_BLUEPRINT.md): blocks L0–L7 and X1–X3 (responsibility, components, technology/ADR, owner role, folders, talks-to, scaling, failure handling, key NFRs), the **dependency rule**, a **request-flow** sequence for each critical journey, and the **scaling stages**. Draw the **D2 diagrams** (overview + one per layer) and the **D5 sequence diagrams** for the critical journeys ([DIAGRAMS.md](references/DIAGRAMS.md)), with the same node names as D1, **directly into PRD §12**. Write the full text version to `ARCHITECTURE.md §12`, which references the diagrams by id. Never create separate diagram files.

### Step 5: Application folder structure
Choose and adapt a template from [FOLDER_STRUCTURES.md](references/FOLDER_STRUCTURES.md). Give every top-level folder exactly one owner, and define the import-boundary rules. Write the full version to `ARCHITECTURE.md §13`.

### Step 6: Write the PRD architecture sections
Between `<!-- architect:begin -->` and `<!-- architect:end -->` in `PRD.md`, write **§10 Solution architecture (layer by layer)**, **§11 Application folder structure** and **§12 Architecture diagrams**, using the "PRD section format" in LAYERED_BLUEPRINT.md. §10 opens with D1 and "Why this architecture". §12 holds the index and the rest of the set, **D0 and D2–D8, complete at G1** (D6 conceptual, D7 and D8 as drafts that Lane 2 refines). Touch nothing outside the markers. Changes to the PM's sections are requested through `MESSAGES:`.
After Step 7 has written ARCHITECTURE.md, mirror the diagrams into it and check both copies; put the result in your report (exit 3 = "syntax not checked"; say so):
```bash
bash ${CLAUDE_SKILL_DIR}/scripts/sync-diagrams.sh docs/delivery/PRD.md docs/delivery/ARCHITECTURE.md
bash ${CLAUDE_SKILL_DIR}/scripts/check-diagrams.sh --require "D0 D1 D2 D3 D4 D5 D6 D7 D8" --mirror docs/delivery/ARCHITECTURE.md docs/delivery/PRD.md
```

### Step 7: Architecture overview (for G1)
[ARCHITECTURE_TEMPLATE.md](references/ARCHITECTURE_TEMPLATE.md) §0–§6: the overview (linking PRD §10 · D1 and the rationale), drivers, context and containers (referencing D0 and D1), stack, deployment topology for `deploy.target` (D3), scale/cost/risks. ARCHITECTURE.md **carries the full diagram set in §14**, generated from the PRD by `sync-diagrams.sh` (never typed or edited there); its text sections reference the ids ([DIAGRAMS.md](references/DIAGRAMS.md) → "Two homes, one source"). Re-run the sync whenever a PRD diagram changes.

### Step 8: Shared boundaries (lane plan, first step)
Write `.claude/project.json` per `.claude/skills/deliver/references/manifest.md`. The roles' `paths` and `shared_files` **must match the §13 folder tree exactly**. Use real `commands`, including the import-boundary lint rule and the formatter, linter (complexity limits) and strict type checker per `.claude/rules/coding-standards.md`, and set `roles.<role>.guides` to the `coding-foundations` stack guides that apply (write a short guide in the same format into PROJECT.md for a stack without one). Also write the `.claude/PROJECT.md` summary (the confirmed stack, the **coding conventions and tools for this stack** (including the **form and validation libraries**: one form library and one schema library per app, with an ADR; FORMS_AND_VALIDATION.md §2) and the "Coding guides" per role, layers, roles → folders, commands, ADR links). Send a `handoff` message to the design runners.

### Step 9: Detailed design (lane plan)
The **database-architect** owns the data model (`DATA-MODEL.md`, via the `design-database` skill) and hands you the ERD for ARCHITECTURE §7. You design the modules mapped to layers and folders, on top of that model, and complete contracts in `contracts.paths` per [API_CONTRACTS.md](references/API_CONTRACTS.md), with a `codegen_cmd`. Fill ARCHITECTURE §7–§11.

### Step 9b: PRD diagram sync (lane plan, `prd-sync`, before G2)
The PRD is approved at G1, so the orchestrator first opens a change request limited to it (after the human approves it: `delivery-state.sh cr-open g1 "Lane 2 diagram refinements" --approved-by "<human>" docs/delivery/PRD.md docs/delivery/ARCHITECTURE.md`).
1. Collect the `handoff` messages with Mermaid sources: D6-erd and D6-states-* (database-architect), D7 (integration-engineer), D8 and D3 changes (devops-engineer), D4 corrections (cybersecurity-agent), plus your own D1/D2/D5 updates from the module design.
2. Replace the matching blocks in PRD §12 (and D1 in §10 only if a component changed). Keep the ids and node names consistent. Add one revision-log row: "Lane 2 diagram refinements; no requirement change".
3. Change **nothing else** in the PRD. If a refinement implies a requirement change, stop and report it as `NEEDS_HUMAN` with a business-framed decision.
4. Run `sync-diagrams.sh` so ARCHITECTURE §14 gets the same refinements, then `check-diagrams.sh … --mirror docs/delivery/ARCHITECTURE.md` and report the result. Delete any diagram copies the *other* artifacts still hold, replacing them with the diagram id.

### Step 10: Architect-reviewer checklists
- **DevOps plan:** environments match the topology; checks gate every deploy; production is protected and promotes one artifact; secrets are referenced by name with least privilege; every stateful component has a backup and rollback; cost is consistent.
- **Design alignment:** every screen field ↔ a contract field; every `AC-` ↔ a TC plus a screen or operation; the naming, error model and auth agree across the artifacts.
- **Layer and folder conformance:** components sit in their declared layer, dependencies point inward, the folders match `project.json`, and no owned paths overlap.
- **Diagrams:** the full D0–D8 set is in the PRD (D1 in §10, the rest in §12) **and identically in ARCHITECTURE §14**; `check-diagrams.sh --mirror` passes (or reports "not checked"), names match D1, each diagram has a purpose line and "What to notice", and no diagram exists in a separate file or as a copy in any other artifact.

## Rules
- Use evidence, not habit. Each major choice cites fetched sources or is labeled *judgment*.
- Add realtime, queues, caches or services only when a requirement needs them, and record why in an ADR.
- After G2, contracts change only through a change request plus a ticket.
- No implementation code. Scaffolding is Lane 3 work for the role engineers.

## Integration with Other Skills
- **write-requirements:** discovery partner (technical corrections ⇄ revised requirements); the PRD hosts §10–§12, including every diagram
- **threat-model:** threats feed X1 (identity and security) and ARCHITECTURE §10
- **design-inspiration / write-tests / release-docs:** the design runners consume the boundaries, layers and contracts
- **plan-delivery:** tickets map to layers, folders and contract operations
- **deliver / collaboration.md:** how questions and handoffs move between agents

## File Structure
```
.claude/skills/design-architecture/
├── SKILL.md
└── references/
    ├── REFERENCE_SOURCES.md      # authoritative sources + research procedure
    ├── ARCHITECTURE_PATTERNS.md  # styles, frameworks, data stores, API/realtime, scalability, design patterns, worked decisions
    ├── STACK_SELECTION.md        # drivers, weighted matrix, defaults, hosting fit
    ├── ARCH_RESEARCH_TEMPLATE.md # ARCHITECTURE-RESEARCH.md
    ├── LAYERED_BLUEPRINT.md      # L0–L7 + X1–X3 blocks, dependency rule, flows, scaling stages, PRD section format
    ├── DIAGRAMS.md               # diagrams in the PRD (source) and mirrored in ARCHITECTURE §14, the required set D0–D8, and the 'Why this architecture' template
    ├── FOLDER_STRUCTURES.md      # monorepo, clean service, frontend, microservices, infra templates
    ├── ARCHITECTURE_TEMPLATE.md  # ARCHITECTURE.md §1–§13
    ├── ADR_TEMPLATE.md
    └── API_CONTRACTS.md          # contract rules, error model, OpenAPI skeleton
└── scripts/
    ├── check-diagrams.sh         # every diagram id present in the PRD + the ARCHITECTURE copy identical (--mirror) + every Mermaid block renders (temp dir)
    └── sync-diagrams.sh          # copies every PRD diagram section into ARCHITECTURE.md §14 (--check: report missing or different diagrams)
```
