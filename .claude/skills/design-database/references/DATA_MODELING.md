# Data modeling principles

## 1. Modeling levels
| Level | Question | Output |
|---|---|---|
| Conceptual | Which business things exist, and how are they related? | Entities, relationships, cardinality, lifecycles (from BA-ANALYSIS) |
| Logical | How do we structure them correctly, independent of the engine? | Normalized tables, keys, attributes, constraints |
| Physical | How does this engine store and serve them efficiently? | Types, indexes, partitioning, storage parameters |

Every table traces to a BA entity, or to a named technical need (a join table, an outbox, an audit log, idempotency keys).

## 2. Normalization (default: 3NF; BCNF where it's practical)
| Form | Rule | Typical violation |
|---|---|---|
| 1NF | Atomic values, no repeating groups | `tags = "a,b,c"`, or `phone1, phone2, phone3` |
| 2NF | Every non-key attribute depends on the whole key | A join table that also stores a product name |
| 3NF | No transitive dependency between non-key attributes | `orders.customer_email` copied from customers |
| BCNF | Every determinant is a candidate key | Overlapping candidate keys in scheduling tables |

**Denormalize deliberately**, never by accident. Only for a **measured** read hotspot, and preferably as a derived structure (a materialized view, read model, cache or search index) that is rebuilt from the normalized source. Document the source of truth and the refresh mechanism.
**Snapshots are not denormalization:** values that must not change after the fact (the price on an order line, the address on an invoice) are copied on purpose. Name them as snapshots.

## 3. Keys
| Choice | Use | Notes |
|---|---|---|
| Time-ordered UUID (v7) / ULID | Public or external ids, distributed inserts | Non-enumerable; index-friendly because they're time-ordered |
| bigint identity | Internal tables, join tables, high-volume logs | Compact; never expose it if enumeration matters |
| Natural key | Only when it's truly immutable and unique (ISO country code) | Still add a UNIQUE constraint if you use a surrogate key |
| Composite PK | Pure join tables `(a_id, b_id)` | Add an index on the second column for reverse lookups |

Every table has a primary key. Expose the opaque id in the API, never the internal sequence.

## 4. Relationships
- **1:N:** a foreign key on the N side, **indexed**, with explicit `ON DELETE` (`RESTRICT` by default, `CASCADE` only for owned children, `SET NULL` for optional references).
- **M:N:** a join table with a composite PK or unique constraint, plus its own attributes when the relationship has data (`role`, `added_at`).
- **1:1:** a shared PK or a unique FK; split it only for optional, large or differently-secured attributes.
- **Polymorphic associations** (a `target_type` + `target_id` pair): avoid them. They can't have FKs. Prefer separate FK columns with a CHECK that exactly one is set, or separate join tables.
- **Hierarchies:** an adjacency list (`parent_id`) + recursive CTE by default; materialized path or closure table for heavy subtree reads.

## 5. Cross-cutting patterns
| Pattern | Default design |
|---|---|
| **Timestamps** | `created_at`, `updated_at` (timestamptz, UTC, DB default, updated by trigger or the ORM) on every table |
| **Optimistic concurrency** | A `version` integer, incremented on each update; the update `WHERE id = ? AND version = ?` |
| **Soft delete** (only when recovery or legal holds need it) | `deleted_at timestamptz NULL`; **partial unique indexes** `WHERE deleted_at IS NULL`; default scopes in repositories; a purge job per the retention policy |
| **Audit trail** | An append-only `audit_events` (actor, action, entity, entity_id, before/after diff, request_id, at); written in the same transaction, or through the outbox |
| **Temporal / history** | A `<table>_history` populated by trigger, or valid-from/valid-to columns when queries need point-in-time views |
| **Multi-tenancy** | Shared schema + `tenant_id NOT NULL` on every tenant-owned table, a leading `tenant_id` in composite indexes, and **row-level security** or mandatory repository scoping. Schema-per-tenant or DB-per-tenant for strict isolation |
| **Enumerations** | A CHECK constraint or native enum for small stable sets; a lookup table when the values change, have labels or translations, or carry attributes |
| **JSON columns** | Only for variable, rarely-queried attributes (provider payloads, user preferences). Anything filtered, joined or constrained becomes real columns. Validate the shape in the app; index with expression or GIN indexes only when it's queried |
| **Outbox** | `outbox_events` (id, aggregate, type, payload, created_at, published_at) written in the business transaction |
| **Idempotency** | `idempotency_keys` (actor_id, key, request_hash, response, created_at), unique on (actor_id, key), with a TTL purge |

## 6. Types and values
| Data | Type |
|---|---|
| Money | Integer minor units (`amount_cents bigint`) + `currency char(3)`, or `numeric(19,4)`. **Never float** |
| Timestamps | `timestamptz` stored in UTC; convert at the edges |
| Dates without a time | `date` |
| Durations | `interval`, or integer seconds |
| Booleans | `boolean NOT NULL DEFAULT false` (avoid three-state nullable booleans) |
| Short text | `text` + a CHECK on the length, or `varchar(n)` when a real limit exists |
| Email | `citext`, or lower-cased `text` + a unique index on `lower(email)` |
| Status | A constrained enum/check, plus the state machine documented in DATA-MODEL |
| Files | Object storage; store the key, size, content type and checksum in a row |

## 7. Anti-patterns
- EAV (entity-attribute-value) tables for core data
- Comma-separated ids in a column
- "God tables" with 80 nullable columns for every subtype (split them, or use table-per-subtype)
- Missing FKs "for performance" (index them instead)
- Using `NULL` to mean several different things (add an explicit status)
- Business logic that relies on row order without an `ORDER BY`
