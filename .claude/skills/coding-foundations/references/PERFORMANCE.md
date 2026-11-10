# Performance guide

Engineering principle 1 applies: **correct, then secure, then simple, then fast.** Performance work starts from a budget in the PRD NFRs and a measurement, never from a hunch. This guide is used by every engineer and reviewer, and by the performance-specialist.

## 1. Budgets (set in PRD §6, checked in every milestone)
| Area | Metric | Default budget when the PRD gives none (label `ASSUMPTION:`) |
|---|---|---|
| Web, loading | LCP (largest contentful paint) | ≤ 2.5 s at the 75th percentile on a mid-range phone, 4G |
| Web, responsiveness | INP (interaction to next paint) | ≤ 200 ms |
| Web, stability | CLS (layout shift) | ≤ 0.1 |
| Web, payload | JavaScript per route (compressed) | ≤ 200 kB first load; a regression over 10% needs a reason |
| API, reads | p95 latency | ≤ 300 ms |
| API, writes | p95 latency | ≤ 500 ms |
| API, efficiency | Queries per request | No N+1; a fixed number per operation |
| Background work | Queue wait and job time | Stated per job in ARCHITECTURE |
| Mobile | Cold start, frame rate | ≤ 2 s; 60 fps on lists |

## 2. Method (must)
1. **Measure** with the tool the project has (browser performance panel, Lighthouse, the bundle analyzer, the APM or query log, `EXPLAIN ANALYZE`, a load test for the NFR target).
2. **Find the biggest cost.** Fix the top item, not the easiest one.
3. **Change one thing, measure again,** and keep the before and after numbers in the ticket report.
4. Stop when the budget is met. Extra tuning is a new ticket with its own reason.
Never claim an improvement without both numbers. Never trade correctness, security or accessibility for speed.

## 3. Frontend
**Load less**
- Split code by route; lazy-load heavy or below-the-fold components (editors, charts, maps) with a sized fallback.
- Watch the bundle: import only what is used, prefer small libraries, check the analyzer when adding a dependency.
- Render on the server where the framework supports it; ship interactivity only where it is needed.
- Images: the framework's image component, correct dimensions, modern formats, lazy below the fold, priority only for the LCP image. Fonts: self-hosted, subset, `font-display: swap`, preloaded when above the fold.
- Resource hints (`preconnect`, `preload`) only for origins and assets used in the first view.
- Cache static assets with content hashes and long lifetimes; cache API reads in the query layer with deliberate stale times.

**Render less**
- Virtualize lists and tables beyond about 100 rows; paginate on the server (cursor-based for feeds).
- Debounce search and filter inputs (250–300 ms); throttle scroll and resize handlers; cancel stale requests.
- Keep state close to where it is used so one change doesn't re-render the page. Memoize only where a measurement or a referential-equality need shows it helps (or the compiler handles it).
- Reserve space for images, ads and async content so nothing shifts.
- Work longer than about 50 ms leaves the main thread ([WORKERS.md](WORKERS.md)); animate with transform and opacity, and respect reduced motion.

## 4. Backend
- **Queries:** select only needed columns; no N+1 (join, batch or a data loader); every frequent filter and sort has an index that a query plan confirms (design-database → INDEXING_AND_PERFORMANCE.md); cursor pagination on large sets; a hard page-size limit.
- **Caching:** cache what is read often and changes rarely; every cache entry has a key scheme, a lifetime and an **invalidation rule written down**; never cache per-user or permission-dependent data under a shared key; protect against stampedes.
- **Connections:** pool database and HTTP connections; size the pool from the database limit and the instance count; a serverless runtime uses a pooler.
- **Slow work off the request path:** email, exports, media processing and third-party calls go to a durable queue; the request returns quickly with a status the client can poll or subscribe to.
- **Network:** compress responses; HTTP caching headers (`ETag`, `Cache-Control`) on cacheable reads; a CDN for static and public content.
- **Protection:** rate limits per user and per IP, timeouts on every outbound call, bounded retries with backoff and jitter, circuit breakers on dependencies (engineering principle 9), request size limits.
- **Statelessness:** no in-process session or cache that breaks with a second instance.

## 5. Heavy data
- **Never load an unbounded set into memory.** Stream or page through it; process in batches with a fixed size; apply backpressure (pause the source when the consumer is behind).
- Imports and exports run as jobs with progress, resumability and a row limit; large files are streamed to object storage, not buffered.
- Bulk writes use batched statements inside size-limited transactions; long transactions and table-wide locks are avoided (database-standards).
- Aggregations over large tables use indexes, pre-computed summaries or a read replica, chosen by ADR.
- Set memory and time limits on jobs, and test with production-like volumes (the PRD scale figures), not ten rows.

## 6. Finding bottlenecks
| Symptom | Look at first |
|---|---|
| Slow first load | LCP element, render-blocking resources, bundle size, server response time |
| Slow interactions | Long tasks on the main thread, re-render scope, large lists |
| Slow endpoint | Query count and plans, missing index, a synchronous external call, serialization of a large payload |
| Slows under load only | Pool exhaustion, lock contention, a missing cache, a single-instance bottleneck, an unbounded queue |
| Memory grows | Unbounded caches, listeners or timers never removed, whole files or result sets in memory |
Load tests model the NFR target (expected users and peak multiple), run only against environments the project owns and has listed in DEVOPS-PLAN, and never against production without the human's approval.

## Review checklist
**Frontend**
- [ ] Route-level code splitting; heavy components lazy-loaded; no large new dependency without a reason.
- [ ] Images and fonts optimized; no layout shift; the LCP element is prioritized.
- [ ] Long lists virtualized or paginated; inputs debounced; stale requests cancelled.
- [ ] No long main-thread work; memoization only where justified.
- [ ] The budgets in PRD §6 hold for the touched routes (numbers in the report).

**Backend**
- [ ] No N+1; frequent queries have an index confirmed by a plan; pagination with a size limit.
- [ ] Caches have keys, lifetimes and invalidation; no shared-key caching of per-user data.
- [ ] Slow or third-party work runs in a durable job; every outbound call has a timeout.
- [ ] Rate limits and payload limits on public endpoints; the service stays stateless.

**Heavy data**
- [ ] Nothing unbounded in memory: streaming or batches with backpressure.
- [ ] Jobs are resumable, limited in time and memory, and tested at the PRD's scale.
