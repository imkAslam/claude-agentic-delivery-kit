# Architecture patterns catalog

Use this catalog to pick candidates, then confirm them with fetched sources ([REFERENCE_SOURCES.md](REFERENCE_SOURCES.md)). Every choice you make lands in an ADR.

## 1. Architecture styles

| Style | Use when | Scales by | Trade-offs | Team / ops fit |
|---|---|---|---|---|
| **Layered (n-tier)** | Simple CRUD, a small team, a short time to market | Stateless app tier behind a load balancer + DB read replicas | Layers can get anaemic; business logic leaks into controllers | 1–5 devs, low ops |
| **Modular monolith** *(default for most new products)* | One deployable, with clear module boundaries per business capability | Horizontal app instances; modules can be extracted later | Needs import-boundary discipline; one DB schema to coordinate | 2–15 devs, low ops |
| **Clean / Hexagonal / Onion** (inside a monolith or a service) | Rich business rules, many integrations, long product life | Same as its host style; swaps adapters without touching the domain | More files and indirection | Any size; best with strong domain rules |
| **Microservices** | Independent teams that need independent deploys, very different scaling or tech needs per capability | Per-service scaling; a database per service | Distributed transactions, network failure modes, observability and DevOps cost | 15+ devs, platform maturity, strong CI/CD |
| **Event-driven** (pub/sub, streaming) | Async workflows, integrations, fan-out, audit trails | Consumers scale independently; partitions | Eventual consistency, ordering and idempotency, harder debugging | Medium–high ops |
| **CQRS** (± event sourcing) | Read and write models differ greatly; heavy read scale; audit/history requirements | Separately scaled read models (replicas, caches, search) | Complexity, eventual consistency; event sourcing is hard to retrofit | Use selectively, per module |
| **Serverless / functions** | Spiky or low traffic, event triggers, small APIs, glue code | The platform scales automatically, per request | Cold starts, execution limits, vendor lock-in, local dev friction | Small teams, low ops |
| **Backend-for-Frontend (BFF)** | Several clients (web, mobile, partners) with different data shapes | Per-client gateway instances | An extra hop; duplication across BFFs | Use when the clients diverge |
| **Micro-frontends** | Many teams own separate parts of a large web app | Independent frontend deploys | Bundle/UX consistency, shared-dependency complexity | Large orgs only |
| **Cell-based / multi-tenant shards** | Very large SaaS; tenant isolation; blast-radius limits | Add cells or shards | Routing layer, operational overhead | Late-stage scale |

**Evolution path (prefer it over big-bang design):**
Stage 1 modular monolith + managed DB → Stage 2 add a cache, queue/workers and read replicas → Stage 3 extract the hot or independent modules into services, behind the same contracts → Stage 4 partitioning, cells, multi-region.

## 2. Framework selection guidance

**Frontend**
| Option | Choose when |
|---|---|
| React + a meta-framework with SSR/SSG (e.g. Next.js, Remix/React Router) | SEO or fast first load, full-stack TypeScript, the largest ecosystem |
| React SPA (e.g. Vite) | Authenticated dashboards with no SEO needs |
| Vue + Nuxt | Team preference for Vue; SSR needs |
| Angular | Large enterprise teams wanting strong conventions and DI |
| SvelteKit / SolidStart | Performance-sensitive UIs with a small bundle, and the team is comfortable with them |
| Astro | Content-heavy sites with islands of interactivity |

**Backend**
| Option | Choose when |
|---|---|
| Node.js: NestJS | Enterprise structure, DI, modules; TypeScript end to end |
| Node.js: Fastify / Express / Hono | Lightweight, high-throughput APIs; edge runtimes (Hono) |
| Python: FastAPI | Typed async APIs with automatic OpenAPI; ML/data-adjacent work |
| Python: Django (+ DRF) | Batteries included: admin, auth, ORM; CRUD-heavy back offices |
| Go (net/http, chi, gin, echo) | High concurrency, low latency, small footprint |
| Java/Kotlin: Spring Boot | Enterprise integration, a mature ecosystem, JVM teams |
| .NET: ASP.NET Core | Microsoft ecosystem, high performance, enterprise teams |

**Mobile**
| Option | Choose when |
|---|---|
| React Native + Expo | Shared TypeScript skills with the web, OTA updates, one codebase |
| Flutter | A pixel-consistent UI across platforms, strong performance |
| Native (Swift/Kotlin) | Deep platform integration, maximum performance or platform-specific UX |

## 3. Data store selection
| Store | Use for | Avoid for |
|---|---|---|
| **PostgreSQL** *(default)* | Relational data, transactions, JSON columns, full-text search at small scale | Massive write-heavy time series without extensions |
| MySQL / MariaDB | Relational workloads where the team or hosting prefers it | — |
| Managed Postgres platforms (with branching, realtime, auth) | Fast MVPs that want those built-in features | Workloads that need full DB control |
| MongoDB / document DB | Truly schemaless or document-shaped aggregates | Relational data needing joins and transactions |
| Redis / KV | Cache, sessions, rate limits, queues, pub/sub | The primary system of record |
| Search engine (OpenSearch, Elasticsearch, Meilisearch, Typesense) | Full-text and faceted search at scale | The system of record |
| Wide-column (Cassandra/Scylla) / DynamoDB | Huge scale with known access patterns | Ad-hoc queries, joins |
| Time-series (TimescaleDB, InfluxDB) | Metrics, IoT, events over time | General OLTP |
| Vector store (pgvector, dedicated vector DBs) | Embeddings / semantic search | — |
| Object storage (S3-compatible) | Files, media, backups, exports | Small structured records |

## 4. API style
| Style | Choose when |
|---|---|
| **REST + OpenAPI** *(default)* | Resource CRUD, public or partner APIs, HTTP caching |
| GraphQL | Many clients with different data needs; complex graph reads (add query cost limits) |
| tRPC / typed RPC | A TypeScript monorepo with first-party clients only |
| gRPC | Internal service-to-service calls, streaming, polyglot back ends |
| Webhooks | Notifying external systems of events (sign and retry them) |

## 5. Realtime
| Need | Choice |
|---|---|
| Server → client updates (feeds, notifications, progress) | **SSE**, simplest over HTTP |
| Bidirectional, low latency (chat, collaboration, presence) | **WebSockets**, or a managed realtime service |
| Audio/video, peer-to-peer | **WebRTC** + a signaling server (+ TURN) |
| Occasional refresh | Polling with backoff |

## 6. Scalability and resilience tactics
Stateless app tier · horizontal autoscaling · connection pooling · read replicas · cache-aside with TTLs and invalidation · CDN for static assets and media · async queues for slow work · pagination everywhere · idempotent consumers · rate limiting and backpressure · timeouts, retries with jitter, circuit breakers · bulkheads (separate pools for critical paths) · database indexing, then partitioning, then sharding · feature flags · graceful degradation.

## 7. Design patterns (use them where they solve a stated problem)
| Pattern | Problem it solves |
|---|---|
| Repository + Unit of Work | Isolate persistence; transactional consistency per use case |
| Service layer / use cases | Keep business logic out of controllers and UI |
| Adapter / Ports-and-adapters | Swap external providers (payment, email, storage) |
| Strategy | Interchangeable algorithms (pricing, routing) |
| Factory / Builder | Complex object creation, test data |
| Observer / domain events | Decouple side effects from core actions |
| **Transactional outbox** | Reliable event/email publishing after a DB commit |
| Saga (orchestrated or choreographed) | Multi-step workflows across services without distributed transactions |
| Circuit breaker / retry | Failing dependencies |
| Specification | Composable business rules and queries |

## 8. Worked decisions (templates for the ADRs)
- **REST vs GraphQL:** REST if the operations are mostly CRUD, HTTP caching matters, or there are public consumers. GraphQL if several clients need different shapes over a rich graph and the team can run query-cost controls.
- **SQL vs NoSQL:** SQL when there are relationships, transactions, reporting or ad-hoc queries (most business apps). NoSQL when the data is document- or key-shaped with known access patterns at a scale SQL struggles with.
- **Monolith vs microservices:** a modular monolith unless there are independent teams that need independent deploys, or capabilities with radically different scaling or compliance needs. Design the module boundaries so services can be extracted later.
- **Serverless vs containers:** serverless for spiky or low traffic and event glue; containers for steady load, long-running work, websockets or predictable cost.
