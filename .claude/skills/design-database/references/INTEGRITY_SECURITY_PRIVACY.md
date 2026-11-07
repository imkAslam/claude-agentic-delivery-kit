# Integrity, security and privacy

## 1. Constraints (the database enforces the invariants)
| Invariant | Constraint |
|---|---|
| Every row is identifiable | PRIMARY KEY |
| A reference exists | FOREIGN KEY, with an explicit `ON DELETE` |
| A business identifier is unique | UNIQUE (partial with soft delete) |
| A value is in range or in a set | CHECK (`total_cents >= 0`, `status IN (...)`) |
| Required by the business | NOT NULL |
| Cross-row rules (no overlapping bookings) | Exclusion constraints, or serializable transactions plus a check |
Application validation gives good error messages; constraints guarantee correctness. You need both.

## 2. Transactions and isolation
- One transaction per use case (the application layer). Keep it short, with no external calls inside.
- The default isolation (e.g. READ COMMITTED) is fine for most operations.
- Use **SERIALIZABLE** (with retries) or explicit row locks for invariants that span rows (balances, inventory, scheduling).
- Use the outbox pattern for side effects that must happen only if the commit succeeds.

## 3. Concurrency control
| Situation | Technique |
|---|---|
| Users editing the same record | Optimistic locking (`version` column → `409 version_mismatch`) |
| Counters, stock, balances | Atomic conditional `UPDATE … WHERE qty >= ?`, or `SELECT … FOR UPDATE` |
| Job and queue consumption | `FOR UPDATE SKIP LOCKED` |
| Duplicate submissions | Idempotency keys + unique constraints |

## 4. Access control in the database
- Separate DB roles: the migrator (DDL), the app (DML on its schema only), readonly (reporting). Never use an owner or superuser at runtime.
- **Row-level security** for multi-tenant shared schemas: a policy on `tenant_id = current_setting('app.tenant_id')` (or the engine's equivalent), set per request or transaction by the app. It's defense in depth on top of repository scoping.
- Credentials come from the secret store, by name. Rotate them; use separate credentials per environment.
- Network: the database is not publicly reachable. TLS is required for connections.

## 5. Data classification (every column, in DATA-MODEL)
| Class | Examples | Handling |
|---|---|---|
| Public | Product names | — |
| Internal | Order status, internal ids | Normal access control |
| Personal (PII) | Name, email, phone, address, IP | Minimize; restricted reads; masked in logs and exports; a deletion path; a retention period |
| Sensitive | Health, financial, government ids, precise location | Encryption at the column/app level, or tokenization; strict access; audited reads |
| Secret | Password hashes, API tokens, keys | Password → a memory-hard hash only. Tokens → hashed, or in a secrets store. Never plaintext; never in logs or seeds |
Payment card data: don't store it. Use the provider's tokens and hosted pages.

## 6. Retention and deletion
- Every personal/sensitive table has a retention period (from the PRD or compliance) and a purge job.
- Data-subject deletion: delete or anonymize across all tables, plus backups as they expire. Document the anonymization rules (what's kept for accounting or legal reasons).
- Exports for data-subject access requests come from the same classification map.

## 7. Encryption
- At rest: platform encryption for the DB, backups and object storage (on by default).
- In transit: TLS for all connections.
- Application-level encryption for sensitive columns, with keys in a KMS or secrets store, and key-rotation steps documented.

## 8. Backups and recovery (with DevOps)
- Automated daily backups plus **PITR** (point-in-time recovery) for production, retained per policy, with an encrypted copy kept off-site or in another region.
- A backup is taken before every production migration (the CI step).
- A **restore drill** at least monthly (and before the first release): restore to a scratch instance and verify the row counts and app health. Record the result in the DEVOPS-PLAN.
- Targets: RPO (data-loss window) and RTO (restore time) agreed in the DEVOPS-PLAN.

## 9. Logging and auditing
- Never log query parameters that contain PII or secrets. Log ids and outcomes.
- Audit security-relevant data actions (exports, permission changes, deletions, admin edits) in `audit_events`.
