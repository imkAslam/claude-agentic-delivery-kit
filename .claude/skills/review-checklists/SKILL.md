---
name: review-checklists
description: "Review checklists for independent role reviewers (Common, Frontend, Backend, API, Integration, Database, Mobile, DevOps, Security, Design) with the severity scale and verdict rules. Reviewers judge the diff and the evidence, re-run checks themselves, and never edit."
when_to_use: "Use when reviewing a role engineer's diff, a pipeline/IaC change, or a security fix."
user-invocable: false
---

# Review checklists

**Verdict:** `APPROVE` only when there are no P1 or P2 findings (no CRITICAL/HIGH for security). P3 findings are allowed and get listed. Each finding: `[sev] file:line — problem — required change`.
**Severity:** P1 = wrong behavior, data loss, a security hole, or a broken contract or boundary · P2 = a missing AC/state/test, or a maintainability or performance risk that will bite · P3 = style or a nit.

## Common (every review)
- [ ] Every changed path is inside the role's owned paths. No contract or unowned shared-file edits.
- [ ] Each AC in the ticket is implemented **and** covered by a test that would fail without it.
- [ ] You re-ran the role's lint, typecheck and test yourself, and they're green.
- [ ] No secrets, credentials or personal data in code, config, fixtures or logs.
- [ ] Errors are handled at the boundaries. No swallowed exceptions or silent fallbacks.
- [ ] No dead code, debug output, commented-out blocks or TODOs without a ticket.
- [ ] Comments explain the why (constraints, gotchas, BR-/ADR refs), public APIs have doc comments, and any significant technical decision in the diff has an ADR (`documentation` rule).
- [ ] The **Review checklist** of OOP_AND_PATTERNS.md and of each stack guide in the brief's `GUIDES:` line (`coding-foundations`). A violated *must* is P2 (P1 when it affects correctness, security or data); a *prefer* is P3.
- [ ] Follows `engineering-principles.md` and `coding-standards.md`: domain naming, size and complexity limits, typed and validated boundaries, no swallowed errors, timeouts on remote calls, structured logs without PII, no magic values, no new lint suppressions without a reason and a ticket.
- [ ] The commit message follows the git rules and references the ticket.

## Frontend
- [ ] It matches the approved mockups and the DESIGN-SYSTEM.md component specs (compare the screenshots with `mockups/`).
- [ ] Visual values come only from the generated token theme: no raw colors, sizes, radii, shadows or durations in components.
- [ ] Loading, empty, error, success and no-permission states all exist.
- [ ] Accessibility: labels, focus order and visibility, keyboard operation, contrast, ARIA only where needed.
- [ ] API calls use the generated client, handle every contract error, and don't trust client-side checks for security.
- [ ] No needless re-renders, waterfalls or unbounded lists. Assets are sized.

## Backend
- [ ] It conforms to the contract: paths, schemas, status codes, error model, pagination, idempotency.
- [ ] Authorization is checked server-side on every operation (object-level, not just route-level).
- [ ] Inputs are validated. Queries are parameterized. No N+1 queries. Indexes exist for new filters.
- [ ] Transactions cover multi-step writes. No read-modify-write races on counters or balances.
- [ ] Migrations are safe (backward compatible, reversible or documented) and owned by backend.
- [ ] Logs are structured, with no PII or secrets.

## API (architect-reviewer on contracts; backend-reviewer on implementations)
- [ ] Every operation follows API-GUIDELINES.md (naming, methods, status codes, the standard error body with stable codes)
- [ ] Auth and scopes declared, object-level authorization stated and implemented, no secrets or PII in URLs
- [ ] Lists paginated (cursor, limit capped) with documented filters and sorts; writes document validation errors
- [ ] Idempotency-Key on retried creates; ETag/If-Match (or a version field) where lost updates matter; async uses 202 + a status resource
- [ ] Changes are additive within the version, or have a deprecation plan + a changelog entry; the contract lints clean
- [ ] Responses conform to the contract (contract or schema-validation tests)

## Integration (integration-reviewer)
- [ ] The provider sits behind a port; no provider types in the domain or contracts
- [ ] Timeouts on every call; retries only where safe, with backoff + jitter; circuit breaker + user-facing fallback; limits respected
- [ ] Inbound webhooks: signature over the raw body, timestamp tolerance, event-id dedup, fast ack + async processing
- [ ] Outbound webhooks: signed, retried with backoff, DLQ, delivery log, subscriber URLs validated (SSRF)
- [ ] Responses validated and mapped; only the needed data sent; residency and classification respected
- [ ] Secrets by name; tests use local mocks or recorded responses, never real providers
- [ ] The INTEGRATIONS.md entry is updated with the chosen timeouts, retries and breaker settings

## Database (database-reviewer, plus the backend-reviewer for data-access code)
- [ ] Design principles (`database-standards.md`): constraints in the database, normalized unless an ADR says otherwise, correct types, no EAV or JSON for queried fields, soft delete only where required, migrations tested up/down on a fresh database.
- [ ] `check-migrations.sh` passes: no blocking findings, or justified `migration:allow` markers in contract-phase migrations only.
- [ ] Schema changes match the approved `DATA-MODEL.md` (tables, columns, types, keys, relationships); deviations have a CR.
- [ ] Constraints enforce the invariants: PK, FK with explicit `ON DELETE`, UNIQUE (partial with soft delete), CHECK, NOT NULL.
- [ ] Migrations are zero-downtime (expand → migrate → contract), lock-safe, with separate batched backfills and documented rollback.
- [ ] Every new FK and filter/join/sort column is indexed; hot queries checked with EXPLAIN; no N+1; keyset pagination for large lists.
- [ ] Transactions are short; concurrency is handled (optimistic version, atomic updates, row locks); side effects go through the outbox.
- [ ] Tenant scoping on every tenant-owned query (and RLS where the model requires it).
- [ ] Naming follows the conventions; money isn't stored as float; timestamps are timestamptz in UTC.
- [ ] Personal and sensitive columns are handled per the classification (encryption, masking, retention); no PII in logs or seeds.

## Mobile
- [ ] It matches the mobile mockups. Safe areas and dynamic type are handled.
- [ ] It works offline or on a poor network as the PRD requires (retries, clear messaging).
- [ ] Lifecycle (background/foreground), permissions and deep links are handled.
- [ ] Platform screen readers and touch-target sizes are covered.
- [ ] No secrets in the bundle. The generated API client is used.

## DevOps
- [ ] Stage order runs checks before any deploy, and production is manual or protected.
- [ ] The same immutable artifact is promoted from staging to production.
- [ ] Secrets are referenced by name, with least-privilege credentials (OIDC where possible).
- [ ] Versions and actions/images are pinned. Caching is correct.
- [ ] A health check, smoke test, rollback path and backup exist, matching `DEVOPS-PLAN.md`.
- [ ] Nothing was applied or deployed from the workstation. Only dry-run validation was used.

## Security
- [ ] Authn/session: secure cookie flags or token handling, expiry, rotation, logout.
- [ ] Authz: no IDOR, no privilege escalation. Deny by default.
- [ ] Injection (SQL/NoSQL/command/template/LDAP), XSS, CSRF, SSRF, open redirects, path traversal.
- [ ] File uploads: type and size limits, storage outside the web root, malware scan if the threat model asks for it.
- [ ] Crypto: vetted libraries, no custom crypto, strong password hashing, TLS everywhere.
- [ ] Rate limiting and lockout on sensitive endpoints. Error messages don't leak internals.
- [ ] Dependencies have no known critical or high vulnerabilities, or carry a documented exception.
- [ ] Every fix has a test that fails without it.

## Design (design-reviewer on designs; uiux-agent at milestone design QA)
- [ ] Every journey has a flow, every flow screen is in the inventory, and every `AC-` maps to a screen and a state.
- [ ] `check-tokens.sh` passes for every theme; mockups and code use tokens only.
- [ ] Every component shown is specified in DESIGN-SYSTEM.md, with all its states, and looks the same everywhere.
- [ ] Every screen state exists at desktop and mobile size, as a real render.
- [ ] Copy follows the brand voice, the word list and the BA glossary; client copy is marked.
- [ ] Accessibility: contrast, visible focus, targets, labels, landmarks and headings, no color-only meaning, 320 px reflow, reduced motion.
- [ ] Nothing imitates another company's identity; fonts and images have recorded licenses.
