---
name: write-docs
description: "Project documentation toolkit: the documentation map and index (docs/README.md), the feature catalog (docs/FEATURES.md), the database design and as-built data dictionary (docs/database/DATABASE.md), ADR authoring, lifecycle and index (docs/adr/README.md), the root README and CHANGELOG, and inline-documentation rules. Documents decisions and the why, not just the what, so future engineers and agents can work without re-deciding."
when_to_use: "Use when creating or updating the feature list, the database document, ADRs or the ADR index, the README, the CHANGELOG or the docs index; after G1, after planning, after each milestone and at release; and when a significant technical decision needs an ADR."
argument-hint: "[init | plan | milestone <ms> | release <version> | adr]"
---

# Write docs

Living documentation, kept current at fixed points of the workflow. **Approved artifacts are the source of truth** (PRD, DATA-MODEL, contracts, ADRs); these documents index, summarize and track them. They are never part of a gate package, so they can be updated freely.

## When to Use
| Mode | When (workflow step) | Output |
|---|---|---|
| `init` | After **g1** is approved (lane plan, first step) | `docs/README.md` (index), `docs/FEATURES.md` (from PRD §4/§7), `docs/adr/README.md` (ADR index) |
| `plan` | After `planning`, before **g2** | FEATURES.md + milestones, tickets, screens, operations; `docs/database/DATABASE.md` (design, from DATA-MODEL); ADR index |
| `milestone` | After `integrate` passes, before **mbr** | FEATURES.md status; DATABASE.md as built (from the real migrations); CHANGELOG `[Unreleased]`; README quick start and commands; ADR index |
| `release` | Lane release, `release-prep` | CHANGELOG version section; README badges/links; final docs index |
| `adr` | Any agent making a significant technical decision | `docs/adr/ADR-<nnn>-<slug>.md` + index row |

## Instructions

### Step 0: Inputs (read only the sections you need)
PRD §1–§4 and §7 (features, slicing), `TICKETS.md`, `DELIVERY-PLAN.md`, `DATA-MODEL.md`, the migration files under the backend's paths, `docs/adr/*`, `project.json → commands`, `milestones/<ms>/COMPLETED-TICKETS.md` and `RUN-GUIDE.md`, `git log` since the last docs update.

### Step 1: Map and index
Keep `docs/README.md` per [DOCS_MAP.md](references/DOCS_MAP.md): one table of every document, its purpose, owner, status and link. Add new documents as they appear; never leave a dead link.

### Step 2: Feature catalog
Maintain `docs/FEATURES.md` with [FEATURES_TEMPLATE.md](references/FEATURES_TEMPLATE.md). Every PRD feature appears once with its id, priority, release, AC, screens, operations, tickets and status. The PRD stays the authority; a mismatch is reported as a finding to the product-manager, never "fixed" here.

### Step 3: Database document
Maintain `docs/database/DATABASE.md` with [DATABASE_DOC_TEMPLATE.md](references/DATABASE_DOC_TEMPLATE.md): the design summary (from DATA-MODEL), then the **as-built** data dictionary from the migrations, the migration log, and how to run, seed, back up and restore. A difference between as built and the approved DATA-MODEL is a finding for the database-reviewer.

### Step 4: ADRs
Follow [ADR_GUIDE.md](references/ADR_GUIDE.md): when an ADR is required, the template (context, decision, alternatives with pros/cons/why rejected, consequences), the lifecycle (proposed → accepted → superseded/deprecated; never deleted or rewritten), and the index in `docs/adr/README.md`.

### Step 5: README and CHANGELOG
Use [README_CHANGELOG.md](references/README_CHANGELOG.md). The README's commands come **only** from `project.json`, and its quick start is tested against `RUN-GUIDE.md`. The CHANGELOG follows Keep a Changelog, one line per user-visible change with the ticket id.

### Step 6: Verify
Every link resolves; every feature, table and ADR in the sources appears in the documents; nothing contradicts an approved artifact. Report the counts in the return block.

## Rules
- Document the **why**: decisions, constraints, trade-offs and rejected alternatives. Don't restate code.
- Never edit approved artifacts (PRD, DATA-MODEL, contracts, accepted ADRs). Supersede an ADR with a new one.
- No secrets, personal data or internal hostnames in any document.
- Diagrams stay in the PRD; documents link to them by id.
- Keep it short. A table row beats a paragraph.

## Integration with Other Skills
- **design-architecture / design-database / design-api / build-integration:** authors of ADRs (template here and in ADR_TEMPLATE.md)
- **plan-delivery:** milestones and tickets feed FEATURES.md
- **integrate-milestone:** the milestone package triggers the `milestone` mode
- **release-docs:** the release version feeds the CHANGELOG

## File Structure
```
.claude/skills/write-docs/
├── SKILL.md
└── references/
    ├── DOCS_MAP.md               # docs/README.md: the document map and index
    ├── FEATURES_TEMPLATE.md      # docs/FEATURES.md: the feature catalog
    ├── DATABASE_DOC_TEMPLATE.md  # docs/database/DATABASE.md: design summary + as-built dictionary + operations
    ├── ADR_GUIDE.md              # when to write an ADR, template, lifecycle, index
    └── README_CHANGELOG.md       # root README.md and CHANGELOG.md formats
```
