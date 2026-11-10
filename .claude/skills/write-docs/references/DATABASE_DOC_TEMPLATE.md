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
**Indexes:** <names; detail in §5> · **Row-level security:** <policy name or n/a; detail in §6>

## 3. Relationships
| From | To | Cardinality | On delete | Why |
|---|---|---|---|---|

## 4. Migrations log
| # | File | What it does | Ticket | Phase (expand / migrate / contract) | Reversible | Milestone |
|---|---|---|---|---|---|---|

## 5. Index catalog
| Index | Table (columns) | Type (btree, unique, partial, GIN…) | The query or operation it serves | Added in |
|---|---|---|---|---|
Every index names the access pattern that needs it (DATA-MODEL access patterns). An index no query uses, or a frequent query with no index, is a finding for the database-reviewer. Full-text or vector search indexes are listed here with their configuration.

## 6. Access, tenancy and row-level security (as built)
| Table | Policy / rule | Applies to (role) | Condition | Enforced where (database policy, repository filter) |
|---|---|---|---|---|
Which database roles the application and the migrations use (names only), and which code paths use a privileged connection that bypasses the policies.

## 7. Connections and pooling
The client or ORM and its pool settings (max connections, idle and connection timeouts), how the pool size was derived (database limit ÷ instances), the pooler in front of the database if any, and statement and lock timeouts. Values by environment-variable **name**.

## 8. Seed data
| Set | Command (from project.json) | Contents | Where it may run |
|---|---|---|---|
| Development | <cmd> | synthetic users per role, sample records for each journey | local Docker and test only |
| Reference (production) | <cmd or migration> | lookup tables, default roles and settings | every environment, idempotent |
Seeds never contain real personal data or real credentials. Demo accounts are local only.

## 9. Capacity and scaling
| Table | Rows now / expected in 12 months (PRD scale figures) | Growth driver | Hot queries | Plan when it grows (archive, partition, replica) |
|---|---|---|---|---|
The scaling stage from ARCHITECTURE (single instance → pooler → read replica → partitioning) and the trigger for the next step.

## 10. Operations
- **Run locally:** <the project.json command>, against the Docker database (setup-docker → LOCAL_SERVICES.md)
- **Migration workflow:** create → review (`check-migrations.sh`, database-reviewer) → apply, with the exact commands from `project.json`; expand → migrate → contract for breaking changes; never edit an applied migration
- **Migrate in CI/CD:** the pipeline step and its order relative to the deploy (DEVOPS-PLAN)
- **Backups:** method, schedule, retention, where they are stored, encryption (DEVOPS-PLAN)
- **Restore:** the step-by-step procedure, the recovery time and recovery point targets, and **the last restore drill: date and result**
- **Performance notes:** hot queries, their plans, and any EXPLAIN findings worth keeping

## 11. Drift from the approved design
None, or one line per difference with the CR id that approved it.
```

How to build §2–§6: read the migration files in order (and the ORM schema if it exists); never connect to a shared or remote database to introspect. §7–§10 come from the code's database configuration, `project.json`, DATA-MODEL and DEVOPS-PLAN: link to them where they already say it, and write "not set yet" instead of guessing a value. No connection strings, passwords or hostnames, only environment-variable names. Any difference from DATA-MODEL.md without a CR goes in §11 **and** is reported as a finding for the database-reviewer.
