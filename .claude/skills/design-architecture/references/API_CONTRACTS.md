# API contracts

Contracts live in `project.json → contracts.paths`, freeze at G2, and generate typed clients and mocks through `contracts.codegen_cmd`.

## Completeness rules (each operation)
1. **Identity:** a stable `operationId` (verbNoun, e.g. `createOrder`), a tag/module, and a summary.
2. **Auth:** the required scheme and the roles or permissions allowed (or `public`).
3. **Request:** path, query and body schemas with types, formats, required fields, limits (min/max length, ranges, enums) and examples.
4. **Responses:** the success schema and status, plus **every** error status with the standard error body.
5. **Lists:** cursor or page pagination, filtering and sorting parameters, and a maximum page size.
6. **Writes:** idempotency (an `Idempotency-Key` header on non-idempotent creates that clients may retry) and optimistic concurrency (`If-Match`/version) where lost updates matter.
7. **Async:** long-running work returns `202` plus a status resource, or emits an event documented in the same contract.
8. **Versioning:** breaking changes need a new version or an expand → contract migration plan.

## Standard error body
```json
{ "error": { "code": "validation_failed", "message": "Human readable summary", "details": [ { "field": "email", "issue": "invalid_format" } ], "requestId": "<id>" } }
```
| Status | When | `code` examples |
|---|---|---|
| 400 | Malformed request | `bad_request` |
| 401 | Not authenticated | `unauthenticated` |
| 403 | Authenticated but not allowed (use 404 when existence itself is secret) | `forbidden` |
| 404 | Not found, or hidden | `not_found` |
| 409 | Conflict / version mismatch / duplicate | `conflict`, `version_mismatch` |
| 422 | Validation failed | `validation_failed` |
| 429 | Rate limited (include `Retry-After`) | `rate_limited` |
| 500/503 | Unexpected / dependency down | `internal`, `unavailable` |

## OpenAPI skeleton (adapt for GraphQL/RPC with the same rules)
```yaml
openapi: 3.1.0
info: { title: <Product> API, version: 1.0.0 }
servers: [{ url: /api/v1 }]
components:
  securitySchemes:
    session: { type: apiKey, in: cookie, name: session }
    bearer:  { type: http, scheme: bearer, bearerFormat: JWT }
  schemas:
    Error:
      type: object
      required: [error]
      properties:
        error:
          type: object
          required: [code, message]
          properties:
            code: { type: string }
            message: { type: string }
            details: { type: array, items: { type: object } }
            requestId: { type: string }
  responses:
    Unauthenticated: { description: Not authenticated, content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } } }
    NotFound:        { description: Not found,         content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } } }
    Validation:      { description: Validation failed, content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } } }
paths:
  /health:
    get: { operationId: getHealth, security: [], responses: { '200': { description: OK } } }
  /items:
    get:
      operationId: listItems
      security: [{ session: [] }]
      parameters:
        - { name: cursor, in: query, schema: { type: string } }
        - { name: limit,  in: query, schema: { type: integer, minimum: 1, maximum: 100, default: 20 } }
      responses:
        '200': { description: Page of items, content: { application/json: { schema: { type: object, required: [data], properties: { data: { type: array, items: { $ref: '#/components/schemas/Item' } }, nextCursor: { type: [string, 'null'] } } } } } }
        '401': { $ref: '#/components/responses/Unauthenticated' }
```

## Contract review checklist (architect-reviewer, consumers)
- [ ] Every PRD story/AC that needs data has an operation, and every screen field maps to a schema field.
- [ ] Every operation defines auth, all its errors, limits and examples.
- [ ] Lists are paginated with a max size. Retried writes are idempotent.
- [ ] Naming is consistent (casing, plural resources, timestamps in ISO-8601 UTC, money as integer minor units + currency).
- [ ] `codegen_cmd` generates clients and mocks without errors.
