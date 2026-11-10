# docs/database/DATABASE.md: database design and as-built reference

Two halves: the **design** (summarized from the approved `DATA-MODEL.md`, written at `plan`) and the **as-built** reference (generated from the real migrations at every milestone). The ERD lives in the PRD (§12 · D6-erd, mirrored in ARCHITECTURE §14); link to it.

```markdown
# Database
> Engine: <engine + version> · ORM / migrations: <tool> · Design: delivery/DATA-MODEL.md (approved g2) · ERD: PRD §12 · D6-erd · Updated: <ISO> after <ms>

## 1. Design summary
- **Tenancy:** <shared schema + tenant_id + RLS | schema per tenant | …> (ADR-…)
- **Keys and identifiers:** <uuid v7 | bigint identity>; public ids
- **Deletes and history:** <soft delete + partial unique | hard delete + audit table>; retention (business decision D-…)
- **Conventions:** snake_case plural tables, `created_at`/`updated_at` timestamptz UTC, money as integer minor units
- **Classification:** which tables hold personal or sensitive data, and how they're protected
- **Key decisions:** ADR-… (engine), ADR-… (tenancy), ADR-… (audit)

## 2. Tables (as built)
### <table>  ·  BA entity: <Entity> · class: <public|internal|personal|sensitive> · retention: <rule>
| Column | Type | Null | Default | Constraints / FK | Notes |
|---|---|---|---|---|---|
**Indexes:** <name (columns) — the access pattern it serves> · **Row-level security:** <policy or n/a>

## 3. Relationships
| From | To | Cardinality | On delete | Why |
|---|---|---|---|---|

## 4. Migrations log
| # | File | What it does | Ticket | Phase (expand / migrate / contract) | Reversible | Milestone |
|---|---|---|---|---|---|---|

## 5. Operations
- **Run locally:** <the project.json command>, against the Docker database (setup-docker → LOCAL_SERVICES.md)
- **Seed:** <command>; seeds contain synthetic data only
- **Migrate in CI/CD:** the pipeline step and its order relative to the deploy (DEVOPS-PLAN)
- **Backups and restore:** schedule, retention, the restore drill and its last result
- **Performance notes:** hot queries, their indexes, and any EXPLAIN findings worth keeping

## 6. Drift from the approved design
None, or one line per difference with the CR id that approved it.
```

How to build §2–§4: read the migration files in order (and the ORM schema if it exists); never connect to a shared or remote database to introspect. Any difference from DATA-MODEL.md without a CR goes in §6 **and** is reported as a finding for the database-reviewer.
