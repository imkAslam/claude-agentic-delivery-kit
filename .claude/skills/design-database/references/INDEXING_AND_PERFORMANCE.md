# Indexing and query performance

## 1. Start from access patterns
For each journey and contract operation, record: the query shape, filters, sort, joins, expected rows scanned and returned, frequency, and latency target. Indexes exist to serve **these** queries.

| Access pattern | Query | Frequency | Target | Index |
|---|---|---|---|---|
| List my orders, newest first | `WHERE customer_id = ? ORDER BY created_at DESC, id DESC LIMIT 20` | high | p95 < 50 ms | `ix_orders__customer_id_created_at` (customer_id, created_at DESC, id DESC) |

## 2. Index design rules
1. **Every foreign key is indexed** (joins and cascades).
2. **Composite order:** equality columns first, then range or sort columns (`(tenant_id, status, created_at)`). Put the most selective equality column first when there are several.
3. **Covering indexes** (`INCLUDE (...)` where supported) for hot read paths, to avoid table lookups.
4. **Partial indexes** for skewed predicates (`WHERE deleted_at IS NULL`, `WHERE status = 'pending'`).
5. **Expression indexes** to match the query exactly (`lower(email)`).
6. **Unique indexes** enforce business uniqueness. Use partial unique indexes with soft delete.
7. Use GIN/GiST (or the engine's equivalent) for JSON, array, full-text and geospatial queries, and only when those are queried.
8. **Don't over-index.** Each index slows writes and uses memory. Remove unused ones (check the index usage statistics).
9. In a multi-tenant shared schema, `tenant_id` leads every tenant-scoped composite index.

## 3. Query standards
- Select only the needed columns. No `SELECT *` in application code.
- **No N+1:** eager-load relations, or batch them (`WHERE id IN (...)` / dataloader).
- **Pagination:** keyset/cursor (`WHERE (created_at, id) < (?, ?) ORDER BY created_at DESC, id DESC LIMIT n`) for large or infinite lists; offset only for small, bounded sets. There is always a deterministic order with an id tiebreaker.
- Parameterized queries only. Avoid functions on indexed columns in WHERE unless there's an expression index for them.
- Use bulk operations for batches (multi-row insert, `COPY`); never loop single inserts.
- Bound every query: a LIMIT on lists, and statement timeouts configured per role.

## 4. Verify with plans
- Run `EXPLAIN (ANALYZE, BUFFERS)` (or the engine's equivalent) on each new hot-path query against realistic seeded volumes. Look for sequential scans on large tables, row-estimate mismatches, sorts spilling to disk, and nested loops over large sets.
- Keep the plan summary for the top queries in VERIFICATION-RESULTS or the ticket evidence.

## 5. Scaling the data tier (in this order, by trigger)
| Stage | Trigger (metric) | Action |
|---|---|---|
| 1 | — | Correct indexes, connection pooling (pooler sized to the DB's limits), statement timeouts |
| 2 | Read p95 > target, or CPU > 60% on reads | Cache-aside for hot reads (with TTL + invalidation); a read replica for reporting and heavy reads (accept replica lag) |
| 3 | Large tables (≥ 100M rows) or retention purges are slow | Partition by time or tenant; archive cold data |
| 4 | Write throughput or tenant isolation limits | Shard by tenant/key, or move the hot module to its own store |
Always measure before and after. Record the stage changes in an ADR.

## 6. Locking and contention
- Keep transactions short. No network calls inside a transaction.
- Use `SELECT … FOR UPDATE SKIP LOCKED` for job/queue tables.
- Use atomic conditional updates for counters and stock (`UPDATE … SET qty = qty - ? WHERE id = ? AND qty >= ?`).
- Watch for lock waits and deadlocks. Order the updates consistently across code paths.
