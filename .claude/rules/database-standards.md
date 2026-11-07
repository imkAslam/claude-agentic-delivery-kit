---
paths:
  - "**/migrations/**"
  - "**/migration/**"
  - "**/schema.*"
  - "**/db/**"
  - "**/models/**"
  - "**/repositories/**"
  - "**/*.sql"
---

# Database standards

The full standards and rationale are in the `design-database` skill (`.claude/skills/design-database/references/`). These rules always apply when touching database code. General principles: `engineering-principles.md`.

## Design principles
- **The database protects its own integrity.** Every invariant that can be a constraint (NOT NULL, FK, UNIQUE, CHECK, exclusion) is one; application checks are in addition, never instead.
- **Normalize by default (3NF).** One fact in one place. Denormalize (summary columns, materialized views, read models) only for a measured read need, with the refresh rule and an ADR.
- **Surrogate keys, natural uniqueness.** Opaque primary keys, plus a UNIQUE constraint on the real-world key (email per tenant, order number).
- **Types say what the data is:** `timestamptz` (UTC), `date` for dates without time, `numeric`/integer minor units for money, `boolean NOT NULL` (no three-state booleans), length-checked text, `uuid` for ids.
- **Enumerations:** a CHECK constraint for small, stable sets; a lookup table for sets that change or carry attributes. Avoid native enum types that need a migration for every new value.
- **JSON columns** only for data that is genuinely schemaless and never filtered, joined or constrained. Anything queried gets a real column.
- **No EAV** (entity-attribute-value), no polymorphic FKs without a CHECK, no comma-separated lists in a column.
- **Soft delete only where the PRD requires recovery or audit** (`deleted_at` + partial unique indexes + every query scoped). Otherwise delete, or archive to a history table.
- **History and audit:** append-only audit/history tables for regulated or disputed data (who, what, when, before/after), never in-place overwrites of what must be provable.
- **Design for the access patterns** listed in DATA-MODEL: every hot query has a matching index, every list a stable sort key.

## Model
- Implement the approved `docs/delivery/DATA-MODEL.md` **exactly**. Deviations need a change request on g2 and the database-architect.
- Every table has a primary key, `created_at`/`updated_at` (timestamptz, UTC), and constraints for its invariants: FK with an explicit `ON DELETE`, UNIQUE, CHECK, NOT NULL.
- Names follow NAMING_CONVENTIONS (snake_case, plural tables, `<entity>_id` FKs, `ix_/uq_/fk_/ck_` prefixes), unless DATA-MODEL documents an ORM convention.
- Money is integer minor units + currency, or `numeric`, **never float**. Timestamps are `timestamptz`. Public ids are opaque (UUIDv7/ULID).
- Multi-tenant tables carry `tenant_id NOT NULL`, lead their composite indexes with it, and are always scoped (repository scope + row-level security where the model requires it).

## Migrations
- **Migrations belong to the backend role** (`project.json → shared_files`). They're forward-only and timestamped, with one logical change each. Never edit a merged migration.
- **Zero-downtime:** expand → migrate → contract. No drop, rename, type change or NOT NULL-without-default in one step. Use lock-safe DDL (concurrent index builds, `NOT VALID` then `VALIDATE`), with `lock_timeout`/`statement_timeout` set.
- Backfills are batched, idempotent and resumable, and kept separate from DDL.
- Run `bash .claude/skills/design-database/scripts/check-migrations.sh --base <base>` before committing. Blocking findings must be fixed, or (contract phase only) carry `-- migration:allow <reason + runbook step>`, and the database-reviewer must approve them.
- Each migration documents its rollback (a `down` migration, or a step in `ROLLBACK-RUNBOOK.md`).
- Production migrations run **only in the CI deploy job after G3**, after a fresh backup. `guard-prod.sh` blocks local runs against non-local databases.

## Queries
- Parameterized only. Select only the needed columns. Bound every list (LIMIT, keyset pagination with an id tiebreaker).
- No N+1: eager-load or batch. Index every FK and every new filter, join or sort column. Check the `EXPLAIN` of hot-path queries.
- Short transactions, with no network calls inside. Atomic conditional updates or row locks for counters, stock and balances. Optimistic `version` checks for concurrent edits.
- Side effects after the commit, through the outbox.

## Data protection
- Classify personal and sensitive columns in DATA-MODEL, each with a retention period and a deletion path. Encrypt sensitive columns as specified.
- Never store plaintext passwords, tokens or card numbers. Never log query parameters that contain PII.
- Seeds and fixtures are synthetic. Never copy production data into dev or test.
- The application connects with a DML-only role, never the owner or superuser.

## Performance and operations
- Connection pooling sized to the database's limits (pool size × instances < max connections, with headroom for migrations and admin).
- Index deliberately: each index serves a named query; review unused and duplicate indexes each milestone; mind write amplification on hot tables.
- `statement_timeout` and `lock_timeout` on the application role; slow-query logging on in every environment.
- Partitioning, read replicas, sharding and caching layers come only with a measured need and an ADR.
- Backups are automated, encrypted and **restore-tested** (the rehearsal is in ROLLBACK-RUNBOOK.md); point-in-time recovery where the RPO requires it.

## Testing
- Every migration runs up (and down, where defined) on a fresh database in CI, and against a copy of the previous release's schema.
- Repository and query tests run against a real database of the same engine and version (a container), never a different engine or an in-memory fake.
- Seeds and fixtures are deterministic, synthetic and created through the same constraints as production data.
