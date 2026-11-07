---
paths:
  - "contracts/**"
  - "**/openapi*.yaml"
  - "**/openapi*.yml"
  - "**/openapi*.json"
  - "**/*.graphql"
  - "**/routes/**"
  - "**/controllers/**"
  - "**/http/**"
  - "**/api/**"
---

# API design rules

Full standards: the `design-api` skill (`.claude/skills/design-api/references/`). Contract freeze and ownership: `.claude/rules/contracts.md`.

- **The contract is the source of truth.** Implementations match it exactly: paths, methods, schemas, status codes, error bodies, headers. Codegen produces clients and server types where the stack supports it.
- **Naming:** plural nouns for collections (`/orders`, `/orders/{orderId}/lines`), kebab-case paths, camelCase JSON fields (or the documented convention in API-GUIDELINES.md), verbs only for actions that aren't CRUD (`POST /orders/{id}:cancel` or `/orders/{id}/cancellation`), consistently.
- **Methods:** `GET` is safe and cacheable; `POST` creates or runs an action; `PUT` replaces; `PATCH` partially updates (merge-patch); `DELETE` removes. Never change state with GET.
- **Status codes:** 200/201 (with `Location`)/202/204 for success; 400/401/403/404/409/412/422/429 for client errors; 500/503 for server errors. Always use the standard error body with a stable `code`.
- **Lists:** paginated (cursor; `limit` capped), deterministic order, documented filters and sorts, never unbounded.
- **Writes:** `Idempotency-Key` on retried creates; `ETag`/`If-Match` (or a `version` field) where lost updates matter; validation errors list each field.
- **Security:** every operation declares its auth and scopes; object-level authorization on every id; no secrets or PII in URLs; rate limits documented (`429` + `Retry-After`).
- **Evolution:** additive changes only within a version; breaking changes need a new version or an expand/contract plan, a deprecation (`Deprecation`/`Sunset` headers) and a changelog entry.
- **Docs:** every operation has a summary, examples, and every error response; the contract passes lint before a handoff.
