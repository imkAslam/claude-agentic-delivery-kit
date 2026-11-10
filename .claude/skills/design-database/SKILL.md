---
name: design-database
description: "Database design and standards toolkit: conceptual, logical and physical data modeling (normalization, keys, relationships, constraints), naming conventions, access-pattern-driven indexing and query performance, zero-downtime migrations, integrity, transactions and concurrency, multi-tenancy, audit and soft delete, data classification, retention, encryption and backups, NoSQL modeling, the DATA-MODEL.md template and a migration safety checker."
when_to_use: "Use when designing or changing the data model, writing DATA-MODEL.md or ERDs, writing or reviewing migrations, schema, ORM models or queries, choosing indexes, planning tenancy, audit, retention or backups, or investigating database performance."
---

# Design database

For the **database-architect** (design), **backend-engineer** (implementation), **database-reviewer** (review) and **solution-architect** (data layer L6).

## When to Use
- Lane plan, `design-fork`: `DATA-MODEL.md` (the G2 package) and the D6 diagrams for PRD §12
- Lane build: every ticket that adds or changes migrations, schema, models or queries
- Release prep: checking the migration list and the backup plan
- Performance triage: slow queries, locking, connection exhaustion

## Instructions

### Step 0: Load the inputs
`BA-ANALYSIS.md` (entities, rules, lifecycles, data classes), `PRD.md` (NFRs, volumes, retention, compliance), `ARCHITECTURE.md` (§10 security, §12 the L6 data layer, the chosen engine), contracts (operations → queries), `UI-UX.md` (lists, filters, sorts), `THREAT-MODEL.md`, and `project.json` (`stack.database`, `stack.orm`, the migrations owner in `shared_files`).

### Step 1: Conceptual model
Entities, attributes, relationships with cardinality, and a lifecycle state machine for each stateful entity. Every entity traces to a BA entity or a named technical need. See [DATA_MODELING.md](references/DATA_MODELING.md) §1.

### Step 2: Logical model
Normalize to 3NF/BCNF. Resolve many-to-many relationships with join tables. Choose the keys. Decide the cross-cutting patterns: tenancy, audit, soft delete, temporal, enums, JSON ([DATA_MODELING.md](references/DATA_MODELING.md) §2–§6). Record each significant choice as an ADR.

### Step 3: Physical model
Engine-specific types, constraints (PK, FK with `ON DELETE`, UNIQUE, CHECK, NOT NULL, defaults) and names per [NAMING_CONVENTIONS.md](references/NAMING_CONVENTIONS.md). Money as integer minor units or `numeric`; timestamps as `timestamptz` in UTC.

### Step 4: Access patterns → indexes
List the top queries per journey, with their filters, sorts, joins and expected volumes, and design indexes for them per [INDEXING_AND_PERFORMANCE.md](references/INDEXING_AND_PERFORMANCE.md). Name the pagination strategy for each list.

### Step 5: Integrity, security, privacy
Classify every column, then define its retention and deletion path, encryption and masking, row-level security or tenant scoping, the transaction boundaries and isolation needs, and the concurrency control (optimistic versions, or locks). See [INTEGRITY_SECURITY_PRIVACY.md](references/INTEGRITY_SECURITY_PRIVACY.md).

### Step 6: Migration and operations plan
The tool, file naming, the expand → migrate → contract approach, backfill strategy, seeds and fixtures, backups and PITR, pooling, and the replica and partitioning triggers. See [MIGRATIONS.md](references/MIGRATIONS.md).

### Step 7: Write and hand off
Write `docs/delivery/DATA-MODEL.md` with [DATA_MODEL_TEMPLATE.md](references/DATA_MODEL_TEMPLATE.md). Send `handoff` messages to the solution-architect (the D6-erd and D6-states Mermaid sources for PRD §12; the architect places them in the PRD and mirrors them into ARCHITECTURE §14), the backend (implementation), DevOps (backups, the migration step) and QA (seeds).

### Implementing (backend-engineer)
Write migrations that implement the approved model exactly, one logical change per migration, following MIGRATIONS.md. Run `bash ${CLAUDE_SKILL_DIR}/scripts/check-migrations.sh --base <base>` before committing, and fix every blocking finding.

### Reviewing (database-reviewer)
Run the checker, then apply the Database checklist in `review-checklists`, plus these references.

### NoSQL stores
When the architecture selects a document, key-value or wide-column store, model from the access patterns instead ([NOSQL_PATTERNS.md](references/NOSQL_PATTERNS.md)).

## Rules
- The approved `DATA-MODEL.md` is part of G2. Changing it needs a change request.
- The database enforces invariants (constraints), and the application enforces authorization. Never rely on only one layer for integrity.
- No production data in dev or test. Seeds are synthetic.

## Integration with Other Skills
- **design-architecture:** the L6 data layer, engine choice, the D6 diagrams in PRD §12
- **create-endpoint:** repositories, transactions, idempotency, pagination implement this model
- **threat-model:** data classification, encryption, RLS requirements
- **release-docs:** migration list, backups and data rollback in the release package
- **review-checklists:** the Database section

## File Structure
```
.claude/skills/design-database/
├── SKILL.md
├── scripts/
│   └── check-migrations.sh            # deterministic migration safety scan (exit 1 on blocking findings)
└── references/
    ├── DATA_MODELING.md               # modeling principles and cross-cutting patterns
    ├── NAMING_CONVENTIONS.md          # naming standards
    ├── INDEXING_AND_PERFORMANCE.md    # indexes, query plans, pagination, scaling the data tier
    ├── MIGRATIONS.md                  # zero-downtime migration patterns, backfills, rollback, seeds
    ├── INTEGRITY_SECURITY_PRIVACY.md  # constraints, transactions, concurrency, RLS, encryption, retention, backups
    ├── NOSQL_PATTERNS.md              # access-pattern-driven NoSQL modeling
    └── DATA_MODEL_TEMPLATE.md         # DATA-MODEL.md structure
```
