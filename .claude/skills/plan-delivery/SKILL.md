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
Use the [DELIVERY_PLAN_TEMPLATE.md](references/DELIVERY_PLAN_TEMPLATE.md). **ms-1 always starts with the foundation tickets:** **one foundation ticket per enabled role** (scaffold, lint/format/typecheck/test config, health endpoint, contract codegen wired up, env example), one CI pipeline ticket, and a walking skeleton deployed to **staging** through CI. Workspace files, ignore rules, config files and pins are checklist items inside these tickets, never tickets of their own. Every milestone ends with one usable journey, demoable end to end.
**Design foundation (when the product has a UI), also in ms-1, before any screen ticket:** frontend `T-…` tokens.json → the web theme (CSS variables / library theme, light + dark if in scope) + a lint or test that fails on raw color literals; frontend base components from DESIGN-SYSTEM.md used by the ms-1 screens; frontend brand assets wired in (favicon set, manifest icons, social preview, error pages); mobile (if enabled) the theme, app icon and splash; backend email templates using the email header asset. Every screen ticket depends on its role's design-foundation ticket and lists `mockups:` and `components:`.
**Landing page (only when the PRD has `F-LANDING`):** one frontend ticket *"frontend · Landing page"* (M) in the milestone that ships the sign-up or contact journey; and in **every later release**, the **last milestone of that release** gets *"frontend · Landing page refresh for <release>"* (S), depending on every feature ticket of the release, so the refresh is inside the accepted candidate. Re-planning after an approved change request that changes user-visible features adds the same refresh ticket (build-design-system → LANDING_PAGE.md §6).

### Step 2: Tickets
Use [TICKET_TEMPLATE.md](references/TICKET_TEMPLATE.md). Planning rules:
1. **One role per ticket.** Split cross-role work: backend operation → frontend screen → QA E2E, linked with `depends_on`.
2. **Right-size every ticket: one cohesive capability of one module, for one role** ([TICKET_TEMPLATE.md](references/TICKET_TEMPLATE.md) → "Sizing"). Example: *backend · Auth API* covers signup, login, logout, refresh, email verification, OTP send/verify and forgot/reset password in **one** ticket; *frontend · Auth screens* covers all the auth screens in another.
   - Sizes: **S** ≤ 1 day (bugs, chores, small changes only), **M** 1–2 days (the default), **L** 2–4 days (the maximum, with a checklist). Anything bigger is split **by capability** (Auth core vs MFA), never by layer (no "auth DTOs" or "auth migrations" ticket).
   - **Too small, merge it:** a single endpoint, screen, component or config file whose siblings in the same module ship in the same milestone; a ticket with one AC; setup chores (fold into the role's foundation ticket).
   - **Too big, split it:** more than about 8 API operations or 6 screens, more than about 15 AC, more than one module, or more than 4 days.
   - **Sanity check before publishing:** typically 2–6 tickets per role per milestone and 20–60 for a whole MVP. More than 8 per role in a milestone means the slicing is too fine; merge before publishing.
3. **Parallel safety:** tickets in the same milestone with no dependency between them **must not touch the same files**. Each shared file (`shared_files`) gets its own ticket for its owner, sequenced first.
4. Every ticket cites its `AC-`, `TC-`, contract operation ids and the owned-path subset.
6. **Type every ticket:** `feature` (a capability from the PRD), `chore` (foundation, tooling, upgrades), `spike` (time-boxed research; its output is an ADR or notes, never production code). Bugs are created later by triage, always linked to their original ticket.
7. **Checklist:** every M or L ticket lists its parts (each operation, screen or state) as a `## Checklist`, which the engineer ticks, so progress is visible inside the ticket.
5. Contract consumers depend on the contract being frozen at G2, not on the backend implementation. They build against the generated mocks, so frontend and backend can run in parallel.

### Step 3: Publish
Create the tickets through the **tracker** skill (`project.json → tracker.kind`) in dependency order. Record each `tracker_ref` in `TICKETS.md`. The orchestrator then registers them with `delivery-state.sh ticket add <id> <role> <ms> "<title>" <deps> --type <type> --size <S|M|L>`. Statuses then move only along the lifecycle in the `tracker` skill.

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
