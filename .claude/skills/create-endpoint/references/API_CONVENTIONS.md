# API implementation conventions

## Validation
- Validate at the boundary with the schema generated from (or matching) the contract. Reject unknown fields on writes.
- Normalize inputs (trim, case-fold emails) before validating. Enforce the contract's limits (lengths, ranges, page size).
- Respond with `422 validation_failed` and `details[]` per field. Never echo raw input back in error messages.

## Authentication and authorization
- Authentication middleware on every non-public operation. Public ones are explicit in the contract.
- Authorize in the **service layer**: the role/permission check **and** object-level ownership or tenancy (filter queries by owner or tenant; never trust ids sent by the client).
- Return `404` instead of `403` when revealing existence would leak information (per the contract).
- Multi-tenant: every query is scoped by the tenant id from the session, never from the request body.

## Errors
- One application error type with a `code` from the contract's catalogue. A central handler maps it to the standard error body plus a `requestId`.
- Unexpected errors → `500 internal`, with the details logged server-side only.
- Dependency failures → `503 unavailable`, plus `Retry-After` when it's known.

## Pagination, filtering, sorting
- Use cursor pagination for feeds or large tables, page/offset only for small, stable sets. Enforce the maximum `limit`.
- Accept only the filter and sort fields the contract lists, mapped to indexed columns. Make the sort deterministic (add the id as a tiebreaker).

## Idempotency and concurrency
- Creates the client may retry accept `Idempotency-Key`. Store key → response per actor for 24h, and return the stored response on a repeat.
- Lost-update protection with a version column + `If-Match`, or a conditional update. A mismatch → `409 version_mismatch`.
- Counters, stock and balances use atomic conditional updates or row locks inside one transaction.

## Transactions
- One transaction per use case in the service layer. Keep them short: no network calls inside a transaction.
- External side effects (emails, webhooks, queues) run after the commit, through an outbox or an after-commit hook.

## Data access
- Parameterized queries only. Select only the needed columns. Eager-load relations to avoid N+1.
- Index the columns used in WHERE, JOIN and ORDER BY for new queries. Check the query plan for hot paths.

## Time, money, ids
- Timestamps in UTC, ISO-8601 on the wire. Money as integer minor units plus an ISO currency code. Opaque, non-sequential public ids (UUID/ULID) where enumeration matters.

## Logging and metrics
- A structured JSON log with `requestId`, `actorId`, `operationId`, `durationMs` and `outcome`. **No passwords, tokens, full card numbers or personal data** (mask or omit them).
- An audit log entry for security-relevant actions (login, permission change, export, delete) when the threat model requires it.

## Rate limiting
- Apply it to authentication, password reset, OTP, search and any expensive operation, per IP and per account. Return `429` with `Retry-After`.
