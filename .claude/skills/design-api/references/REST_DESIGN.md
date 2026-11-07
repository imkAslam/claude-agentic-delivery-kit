# REST design standards

## 1. Resources and URLs
- Collections are plural nouns: `/projects`, `/projects/{projectId}/tasks`. Nest at most **one** level deep. Beyond that, use a top-level resource with a filter (`/comments?taskId=…`).
- Use kebab-case paths and opaque ids in paths (UUIDv7/ULID strings, never database sequences).
- Actions that aren't CRUD: either a sub-resource noun (`POST /orders/{id}/cancellation`) or a custom method (`POST /orders/{id}:cancel`). Choose one style and record it in the guidelines.
- No verbs in resource paths (`/getTasks` ✗). No file extensions. No trailing slashes.

## 2. Methods and semantics
| Method | Use | Idempotent | Success |
|---|---|---|---|
| GET | Read (safe, cacheable) | yes | 200 |
| POST | Create, or run an action | no (make it so with `Idempotency-Key`) | 201 + `Location` (create), 200/202 (action) |
| PUT | Replace the whole resource | yes | 200 / 204 |
| PATCH | Partial update (`application/merge-patch+json`) | conditional, with `If-Match` | 200 |
| DELETE | Remove | yes | 204 |

## 3. Status codes
200 OK · 201 Created · 202 Accepted (async, with `Location` of the status resource) · 204 No Content · 400 Bad Request (malformed) · 401 Unauthenticated · 403 Forbidden · 404 Not Found (also for hidden resources) · 409 Conflict (state or duplicates) · 412 Precondition Failed (`If-Match` mismatch) · 415 Unsupported Media Type · 422 Validation failed · 429 Too Many Requests (+ `Retry-After`) · 500 Internal · 503 Unavailable (+ `Retry-After`).

## 4. Errors
Use the standard error body from API_CONTRACTS.md (`error.code`, `message`, `details[]`, `requestId`). Codes are stable, documented strings (`validation_failed`, `not_found`, `conflict`, `version_mismatch`, `rate_limited`, …). Never leak stack traces, SQL or internal paths. (RFC 9457 `application/problem+json` is acceptable if chosen in the guidelines; use one format everywhere.)

## 5. Representations
- JSON fields in camelCase (or snake_case, consistently). ISO-8601 UTC timestamps (`2026-11-06T15:00:00Z`). Money as `{ "amount": 1200, "currency": "EUR" }`, in minor units. Enums as lowercase strings. `null` vs. absent is documented.
- Booleans are named `is…`/`has…`. Ids are strings.
- Responses return the resource representation; collections return `{ "data": [...], "nextCursor": "…" | null }`.

## 6. Pagination, filtering, sorting, fields
- **Cursor pagination:** `?limit=20&cursor=<opaque>`, with `limit` capped at 100 and a documented default. The order is deterministic (sort keys + id).
- **Filtering:** `?status=open&assigneeId=…`; ranges `?dueBefore=…&dueAfter=…`; multiple values `?status=open,in_review`. Only documented, indexed fields.
- **Sorting:** `?sort=-createdAt,title` (`-` means descending); only allow-listed fields.
- **Sparse fields / expansion** (only if needed): `?fields=id,title` · `?expand=assignee`.
- **Search:** `?q=` on a dedicated search endpoint when full-text is involved.

## 7. Concurrency, idempotency, caching
- `ETag` on resources; `If-Match` required on PUT/PATCH/DELETE where lost updates matter → `412` on mismatch.
- `Idempotency-Key` header on POST creates that clients may retry; the server stores the key → response for 24h per caller.
- `Cache-Control` on GETs (private by default for authenticated data); `ETag` + `If-None-Match` → `304`.

## 8. Bulk and async
- Bulk: `POST /tasks:batch` with per-item results (`207`-style body listing the status of each item), a maximum batch size, and partial-failure semantics documented.
- Long-running: `202` + `Location: /jobs/{jobId}`; the job resource shows `status`, `progress`, `result`/`error`. Optionally a webhook on completion.

## 9. Security in the contract
Auth scheme per operation (cookie session or bearer); roles or scopes listed; object-level authorization noted ("caller must be a member of the project"); request size limits; rate limits per operation class; never put tokens or PII in query strings; CORS policy documented for browser clients.

## 10. API-GUIDELINES.md template
```markdown
> Status: in-review · Owner: api-designer · Updated: <ISO>
# API guidelines
1. Style and base URL (/api/v1) · 2. Naming and casing · 3. Ids, timestamps, money, enums
4. Methods and status codes · 5. Error model (codes catalogue) · 6. Pagination / filter / sort / fields
7. Auth, scopes, object-level rules · 8. Idempotency and concurrency (ETag/If-Match) · 9. Rate limits and headers
10. Async jobs and bulk · 11. Webhooks/events (see INTEGRATIONS) · 12. Versioning and deprecation · 13. Mocks, docs, codegen commands
```
