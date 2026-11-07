---
name: plan-delivery
description: "Delivery planning: slices aligned designs into demoable milestones, writes single-role, parallel-safe tickets with dependencies, acceptance criteria, contract operations and owned paths, publishes them through the tracker adapter, and writes the quality and release plan."
when_to_use: "Use at the planning step after the design join, when ticket dependencies must be revised, or when triage creates new tickets that need planning rules."
---

# Plan delivery

For the **delivery-planner** in lane `plan`, step `planning`. Its output joins the **g2** package.

## When to Use
- After the design join (contracts, UI/UX, test cases and DevOps plan aligned)
- Revising ticket dependencies (*ticket dependency revisions*)
- Re-planning a milestone after a change request

## Instructions

### Step 0: Load the inputs
`PRD.md` (release slicing, AC), `ARCHITECTURE.md` (modules, contracts index), `UI-UX.md` (the screen inventory), `TEST-CASES.md`, `DEVOPS-PLAN.md`, `project.json` (roles, owned paths, shared files, tracker), and `SYSTEM-PROFILE.md` (which quality tools actually exist).

### Step 1: Milestones
Use the [DELIVERY_PLAN_TEMPLATE.md](references/DELIVERY_PLAN_TEMPLATE.md). **ms-1 always starts with the foundation tickets:** a scaffold for each enabled role, the CI pipeline (checks), a health endpoint, contract codegen wired up, and a walking skeleton deployed to **staging** through CI. Every milestone ends with one usable journey, demoable end to end.
**Design foundation (when the product has a UI), also in ms-1, before any screen ticket:** frontend `T-…` tokens.json → the web theme (CSS variables / library theme, light + dark if in scope) + a lint or test that fails on raw color literals; frontend base components from DESIGN-SYSTEM.md used by the ms-1 screens; frontend brand assets wired in (favicon set, manifest icons, social preview, error pages); mobile (if enabled) the theme, app icon and splash; backend email templates using the email header asset. Every screen ticket depends on its role's design-foundation ticket and lists `mockups:` and `components:`.

### Step 2: Tickets
Use [TICKET_TEMPLATE.md](references/TICKET_TEMPLATE.md). Planning rules:
1. **One role per ticket.** Split cross-role work: backend operation → frontend screen → QA E2E, linked with `depends_on`.
2. **Size S or M** (about half a day to two days of focused work). Split anything larger.
3. **Parallel safety:** tickets in the same milestone with no dependency between them **must not touch the same files**. Each shared file (`shared_files`) gets its own ticket for its owner, sequenced first.
4. Every ticket cites its `AC-`, `TC-`, contract operation ids and the owned-path subset.
5. Contract consumers depend on the contract being frozen at G2, not on the backend implementation. They build against the generated mocks, so frontend and backend can run in parallel.

### Step 3: Publish
Create the tickets through the **tracker** skill (`project.json → tracker.kind`) in dependency order. Record each `tracker_ref` in `TICKETS.md`. The orchestrator then registers them with `delivery-state.sh ticket add`.

### Step 4: Quality and release plan
Use [QUALITY_RELEASE_PLAN_TEMPLATE.md](references/QUALITY_RELEASE_PLAN_TEMPLATE.md): the definition of done, test levels for each milestone, only the quality and security tools that were detected, thresholds, release criteria and rollback expectations.

## Integration with Other Skills
- **tracker:** publishing and status
- **design-architecture:** modules, contracts and owned paths
- **write-tests:** the TC ids per ticket
- **deliver:** the orchestrator dispatches ready tickets from this plan

## File Structure
```
.claude/skills/plan-delivery/
├── SKILL.md
└── references/
    ├── DELIVERY_PLAN_TEMPLATE.md
    ├── TICKET_TEMPLATE.md
    └── QUALITY_RELEASE_PLAN_TEMPLATE.md
```
