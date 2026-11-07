# Migrations standard

## Principles
1. **Forward-only and versioned.** Every schema change is a migration in version control; never change the schema by hand in any environment.
2. **Never edit a migration that has been merged.** Fix forward with a new one.
3. **One logical change per migration**, small enough to review and to roll back.
4. **Zero-downtime by default:** the previous app version must keep working while the migration runs, and right after it.
5. **Schema and data changes are separate:** DDL in one migration, backfills as batched data migrations or jobs.
6. **Production migrations run only in the CI deploy job, after G3,** after a fresh backup. Locally, use disposable databases only.

## Expand → migrate → contract (for every breaking change)
| Change | Expand (release N) | Migrate | Contract (release N+1 or later) |
|---|---|---|---|
| Rename a column | Add the new column; write to both (app or trigger) | Backfill in batches; switch reads to the new column | Stop writing the old one; drop it |
| Change a type | Add a new column of the new type; dual-write | Backfill and verify | Switch reads; drop the old column |
| Add NOT NULL | Add it nullable (or with a default) | Backfill; validate | `SET NOT NULL` (or validate the check constraint) |
| Split a table | Create the new table; dual-write | Backfill | Switch reads; remove the old columns |
| Drop a column/table | Stop reading and writing it in the app (release N) | — | Drop it (release N+1) |

## Lock-safe DDL (PostgreSQL examples; check your engine's equivalents)
| Instead of | Do |
|---|---|
| `CREATE INDEX` on a large table | `CREATE INDEX CONCURRENTLY` (outside a transaction) |
| `ADD CONSTRAINT … FOREIGN KEY` | `ADD CONSTRAINT … NOT VALID`, then `VALIDATE CONSTRAINT` separately |
| `ADD COLUMN … NOT NULL` with no default | Add it nullable, backfill, then add a `CHECK (col IS NOT NULL) NOT VALID` → validate → `SET NOT NULL` |
| A volatile default on a big table | Add the column without a default, backfill in batches |
| `ALTER COLUMN TYPE` | Expand/contract via a new column |
Set `lock_timeout` and `statement_timeout` in migration sessions, so a migration fails fast instead of blocking traffic.

## Backfills
Run them in batches (by primary-key range, 1–10k rows per batch), idempotently and resumably; throttle under load; record progress; verify counts and checksums at the end. Large backfills run as jobs, not inside the deploy-blocking migration.

## Rollback
- Each migration states its rollback: a `down` migration where the tool supports it, or the documented manual steps in `ROLLBACK-RUNBOOK.md`.
- Destructive steps (drops) happen only in the contract phase, after a backup, once the previous app version no longer needs the object.
- Data rollback = restore from a backup or PITR. Its time and data-loss window are documented in DEVOPS-PLAN.

## Seeds and fixtures
- **Dev seeds:** synthetic, deterministic and idempotent; they create demo accounts that work locally only.
- **Test fixtures/factories:** live with the tests; each test creates its own data.
- **Reference data** (countries, plans): migrations or a dedicated idempotent seed, versioned.
- **Never** copy production data into dev or test. If realistic volume is needed, generate it.

## The checker
`bash .claude/skills/design-database/scripts/check-migrations.sh --base <ref>` flags dangerous statements. A blocking finding can be accepted **only** in a contract-phase migration, with the marker `-- migration:allow <reason + runbook reference>` on the statement, and with the database-reviewer's approval.
