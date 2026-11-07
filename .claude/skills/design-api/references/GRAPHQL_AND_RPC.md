# GraphQL, typed RPC, gRPC and events

Use these only when the architecture ADR selected them. REST is the default.

## GraphQL
- **Schema-first.** The SDL lives in `contracts.paths` and is the contract; codegen produces resolver and client types.
- **Naming:** types in PascalCase, fields in camelCase, enums in UPPER_SNAKE. Mutations are verbs (`createTask`, `assignTask`); each takes a single `input` argument and returns a payload type `{ task, errors }`.
- **Pagination:** Relay-style connections (`first/after`, `edges { node cursor }`, `pageInfo`), with `first` capped.
- **Errors:** expected business errors go in the payload's `errors` field (typed, with codes); unexpected ones in the top-level `errors` with an extension code. No stack traces.
- **Nullability:** non-null by default for fields that always exist; nullable for fields that can fail independently.
- **Performance and security:** dataloaders (no N+1), query **depth and complexity limits**, persisted queries for first-party clients, introspection disabled in production for private APIs, field-level authorization in resolvers.
- **Evolution:** add fields freely; deprecate with `@deprecated(reason: …)`; remove only after the deprecation window and once usage telemetry shows zero.

## Typed RPC (e.g. tRPC)
- First-party TypeScript clients only. Procedures are named `domain.action` (`task.create`), with input validated by a schema (shared validators), and outputs typed.
- Still document the operations (generate OpenAPI if partners will ever need access). Same auth, error-code and pagination rules as REST.

## gRPC (internal service-to-service)
- Protobuf in `contracts.paths`; package `<org>.<service>.v1`; services and RPCs in PascalCase; field numbers never reused; `reserved` for removed fields.
- Use standard status codes (`INVALID_ARGUMENT`, `NOT_FOUND`, `ALREADY_EXISTS`, `FAILED_PRECONDITION`, `UNAVAILABLE`…) with rich error details.
- Deadlines on every call; retries per the service config only for idempotent methods; lint with buf-style rules (and check for breaking changes in CI).

## Events and async messaging (AsyncAPI-style)
- An event schema per type in `contracts.paths` (JSON Schema/Avro/Protobuf), with a version in the type name or in schema metadata.
- An **envelope** on every event: `id` (unique), `type` (`task.assigned.v1`), `occurredAt`, `source`, `subject` (the resource id), `data`. A CloudEvents-compatible shape is a good default.
- Delivery is **at-least-once**: consumers are idempotent (deduplicate by `id`); ordering is guaranteed only per key, and only if the broker partitions by it.
- Events are facts in the past tense (`order.confirmed`), not commands. Payloads carry the needed data, or a reference plus a fetch-back for sensitive data.
- Webhooks to third parties use the same envelope plus a signature (see build-integration → WEBHOOKS.md).
