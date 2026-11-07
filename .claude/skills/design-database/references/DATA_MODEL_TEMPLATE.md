# DATA-MODEL.md template

```markdown
> Status: in-review · Owner: database-architect · Sources: BA-ANALYSIS.md, PRD.md, ARCHITECTURE.md, contracts, THREAT-MODEL.md · Updated: <ISO>

# Data model

## 1. Summary
Engine and version (ADR), ORM/migration tool, tenancy approach, key strategy, delete strategy, the number of entities.

## 2. Conventions
Naming (NAMING_CONVENTIONS, or the documented ORM convention), key type, timestamps, money, enums, JSON usage.

## 3. ERD
Diagram: **PRD §12 · D6-erd** (you author it; the solution-architect places it). Send the Mermaid `erDiagram` source in a `handoff` message; this document keeps only the reference plus the tables below.

## 4. Tables
### orders  (BA entity: Order · class: internal · retention: 7 years, accounting)
| Column | Type | Null | Default | Constraint | Class | Notes |
|---|---|---|---|---|---|---|
| id | uuid (v7) | no | generated | pk_orders | internal | public id |
| tenant_id | uuid | no | — | fk_orders__tenants | internal | RLS key |
| customer_id | uuid | no | — | fk_orders__customers (RESTRICT) | internal | |
| status | text | no | 'pending' | ck_orders__status (pending, confirmed, shipped, cancelled) | internal | state machine §5 |
| total_cents | bigint | no | 0 | ck_orders__total_non_negative | internal | snapshot at confirmation |
| currency | char(3) | no | — | — | internal | ISO 4217 |
| version | integer | no | 1 | — | — | optimistic locking |
| created_at / updated_at | timestamptz | no | now() | — | — | UTC |
**Indexes:** ix_orders__tenant_id_customer_id_created_at (tenant_id, customer_id, created_at DESC, id DESC), serving "my orders" · ix_orders__tenant_id_status__open (partial WHERE status IN ('pending','confirmed')), serving the admin queue

## 5. State machines
Diagrams: **PRD §12 · D6-states-<entity>**, one `stateDiagram-v2` per entity with a lifecycle (sent to the solution-architect in the same `handoff`). List the allowed transitions here as a table: | From | To | Who | Rule (BR-…) |
Disallowed transitions are enforced in the application (BR-…), and covered by AC and tests.

## 6. Access patterns
| Id | Operation / screen | Query shape | Frequency | Target | Index |
|---|---|---|---|---|---|
| AP-1 | listOrders (S-03) | tenant + customer, newest first, keyset | high | p95 < 50 ms | ix_orders__tenant_id_customer_id_created_at |

## 7. Data classification and retention
| Table.column | Class | Retention | Deletion / anonymization | Encryption | Access roles |
|---|---|---|---|---|---|

## 8. Integrity and concurrency
Constraints beyond the column definitions, transaction boundaries per use case, the isolation needs, the locking strategy (from INTEGRITY_SECURITY_PRIVACY).

## 9. Multi-tenancy and security
The tenancy model, RLS policies, DB roles (migrator / app / readonly), connection security.

## 10. Migrations and seeds
The tool, naming, the expand/contract plan for any known evolution, seed and fixture strategy, reference data.

## 11. Operations
Backups/PITR (RPO/RTO with DevOps), the restore drill, pooling, the read-replica and partitioning triggers, archiving.

## 12. Decisions
| Decision | Choice | ADR |
```
