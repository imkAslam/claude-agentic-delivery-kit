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

The full standards and rationale are in the `design-database` skill (`.claude/skills/design-database/references/`). These rules always apply when touching database code.

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
