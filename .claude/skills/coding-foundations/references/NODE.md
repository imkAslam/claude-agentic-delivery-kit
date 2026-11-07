# Node.js guide (Express, Fastify, Hono, workers)

With: TYPESCRIPT.md, OOP_AND_PATTERNS.md. NestJS adds NESTJS.md. Templates: `create-endpoint/references/BACKEND_TEMPLATES.md`.

## Structure
- Feature (module) folders, each with routes → handlers/controllers (thin) → use cases/services → domain → repositories/adapters. Composition root (wiring) in one place at startup.
- Prefer Fastify or Hono for new services (schema validation and speed built in); Express is fine when the team knows it.

## Runtime (must)
- **Never block the event loop:** no sync fs/crypto/zlib or large `JSON.parse` in the request path; move CPU-heavy work to worker threads or a job queue.
- **Config:** read `process.env` once at startup into a typed, validated config object (zod); fail to start on invalid config. Never read env vars deep inside code.
- **Graceful shutdown:** on `SIGTERM`/`SIGINT` stop accepting connections, finish in-flight requests within a deadline, close DB pools and queues, then exit. Health (`/health/live`) and readiness (`/health/ready`) endpoints.
- **Process errors:** log `unhandledRejection` and `uncaughtException` and exit non-zero; the orchestrator restarts the process. Never keep running in an unknown state.
- **Outbound HTTP:** a shared client with keep-alive, timeouts on every call (`AbortSignal.timeout`), retries only for idempotent requests with backoff and jitter.
- **Streams:** use `pipeline()` for streams (handles errors and backpressure); stream large uploads/downloads instead of buffering.

## HTTP layer
- Validate body, params, query and headers against the contract schema; reject unknown fields; limit body size. The server rules mirror the form rules exactly (FORMS_AND_VALIDATION.md).
- One error-mapping middleware: domain errors → the contract's error body and status; unknown errors → 500 with a request id, no stack trace.
- Security middleware: secure headers (helmet or equivalent), CORS allow-list, rate limiting on auth and expensive routes, `trust proxy` set correctly behind a load balancer.
- Request id generated or propagated (`x-request-id`) and attached to every log line (AsyncLocalStorage).

## Data and jobs
- One connection pool per process, sized from config; transactions in the use case, not in handlers.
- Background work through a durable queue (BullMQ, SQS, …) with idempotent handlers, retries with dead-lettering, and visibility of failures.

## Logging
- pino (or the framework's structured logger), JSON in production, redaction for secrets and PII paths; no `console.log`.

## Dependencies
- Few, maintained packages; `npm audit`/OSV in CI; no packages for one-liners.

## Testing
- Unit tests for use cases with faked ports; HTTP tests with the framework's injector or supertest; integration tests against containers (Testcontainers) for the DB and queues.

## Review checklist
- [ ] Nothing blocks the event loop; heavy work offloaded.
- [ ] Config validated at startup; no `process.env` reads in business code.
- [ ] Graceful shutdown and health endpoints present.
- [ ] Every outbound call has a timeout; retries only when idempotent.
- [ ] Input validated against the contract; one error mapper; no stack traces in responses.
- [ ] Structured logs with request id; no `console.log`.
