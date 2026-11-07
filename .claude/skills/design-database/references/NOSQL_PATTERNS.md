# NoSQL modeling (when the architecture selects a non-relational store)

NoSQL is modeled from **access patterns**, not from entities. List every read and write pattern first; the model follows from them.

## Document stores
| Principle | Rule |
|---|---|
| Embed vs. reference | **Embed** data that's read together and owned by the parent (order lines in an order), with bounded size. **Reference** data that's shared, large, unbounded or updated independently (a customer referenced by many orders) |
| Bounded arrays | Never let an embedded array grow without a bound (comments, events). Move them to their own collection |
| Schema | Define a schema/validator per collection plus a `schema_version` field; migrate lazily on read, or with a batch job |
| Indexes | Index every query predicate and sort; compound in equality → sort → range order; TTL indexes for expiry |
| Transactions | Use multi-document transactions sparingly; design the aggregates so single-document atomicity is enough |

## Key-value / wide-column (single-table design)
1. Enumerate the access patterns (e.g. "get order by id", "list orders by customer newest first", "list orders by status for admin").
2. Design the **partition key** for even distribution and the **sort key** to serve range queries (`CUSTOMER#<id>` / `ORDER#<timestamp>#<id>`).
3. Add secondary indexes (GSIs) only for the patterns the primary key can't serve.
4. Avoid hot partitions (a monotonically increasing partition key, celebrity tenants). Use write sharding if you must.
5. Denormalize deliberately, and document which writes keep the copies in sync (streams, or a transactional write).

## Caches (Redis/KV)
- Use them for cache-aside, sessions, rate limits, locks and queues. **They're never the system of record.**
- Key naming: `<app>:<entity>:<id>[:<facet>]`; a TTL on every key; explicit invalidation on writes; stampede protection (locking or early refresh).

## Search indexes
- A derived copy of the relational data for full-text or faceted search. The source of truth stays in the primary DB.
- Index them through the outbox or change-data-capture; reindex jobs must be idempotent; mappings are versioned.

## Checklist
- [ ] Every access pattern is listed, with the key or index that serves it
- [ ] No unbounded embedded arrays; item-size limits respected
- [ ] Partition keys distribute load evenly
- [ ] A consistency model is stated for each denormalized copy
- [ ] Backups/PITR and retention are configured for the store
