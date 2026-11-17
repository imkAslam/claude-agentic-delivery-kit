# FastAPI guide

With: [PYTHON.md](PYTHON.md) (async rules, SQLAlchemy 2.x style, testing), OOP_AND_PATTERNS.md, FORMS_AND_VALIDATION.md. Endpoint templates: `create-endpoint/references/BACKEND_TEMPLATES.md`.

## Layout (must)
- One router per feature (`routers/orders.py`), kept thin: HTTP in, one service call, response model out. Business rules live in services or use cases, not in routers.
- Routers are mounted in one app factory. Do not create the app or its clients at import time.

## Dependencies (must)
- Define `Annotated[..., Depends(...)]` aliases once for the database session, the current user and permission checks. Reuse the aliases everywhere.
- Authentication is a dependency that raises a domain error. Authorization for a specific object is checked in the service, not only in the dependency.
- In tests, replace dependencies with `app.dependency_overrides`; do not patch internals.

## Models and validation (must)
- Pydantic v2 models for every request and response. Every route declares its response model (`response_model=` or the return annotation). Never return ORM objects.
- Separate input models (create, update) from output models. For PATCH, use optional fields and `exclude_unset=True`.
- Validation rules mirror the form rules exactly ([FORMS_AND_VALIDATION.md](FORMS_AND_VALIDATION.md)): one rule, one schema, shared with the frontend contract.
- Settings come from `pydantic-settings`, validated at startup. A missing required variable stops the app before it serves traffic.

## Status codes and errors (must)
- Set the status on the route: `201` for creates, `204` for deletes with no body. Never return `200` for a failure.
- Map domain exceptions to the contract's error body in one exception handler. Never return tracebacks, SQL or internal paths.

## Async (must)
- Use `async def` only when everything the function awaits is async (async driver, `httpx.AsyncClient`). Blocking work uses a plain `def`, which FastAPI runs in a thread pool, or goes to a queue.
- Pools and clients are created in the lifespan handler (`lifespan=` with an async context manager) and closed on shutdown.
- Every outbound HTTP call sets a timeout.

## Database (must)
- Async SQLAlchemy 2.x: `create_async_engine` and `async_sessionmaker`. One session per request, provided by a dependency that commits or rolls back. Use `expire_on_commit=False` only when data is returned after commit, and say why in a comment.
- Migrations use Alembic and follow the expand → migrate → contract rule in `design-database`.
- Choose eager loading per query (`selectinload`) to avoid N+1 queries. See PYTHON.md.

## Lists, uploads and background work
- Every list endpoint has a default limit and a maximum. Use cursor pagination for large or changing lists.
- Uploads are streamed to storage through an adapter, with size and type limits checked before the body is read in full.
- `BackgroundTasks` is only for best-effort work that may be lost on a crash. Real jobs go to a queue (see [WORKERS.md](WORKERS.md)) as idempotent tasks.

## Testing (must)
- Endpoint tests use `httpx.AsyncClient` with `ASGITransport` (or `TestClient` for sync code).
- Async tests use `pytest-asyncio`, configured once for the project. Integration tests run against the database container (testing rule).
- For each failure path, assert the status code, the response shape and the error body.

## Review checklist
- [ ] Routers are thin; business rules sit in services.
- [ ] Every route has a response model and an explicit status code.
- [ ] Dependencies use `Annotated` aliases; object-level authorization is in the service.
- [ ] No ORM objects in responses; PATCH uses `exclude_unset`.
- [ ] Domain errors mapped in one handler; no tracebacks in responses.
- [ ] No blocking calls in `async def`; timeouts on outbound calls; clients created in the lifespan.
- [ ] Settings validated at startup; no secrets in code.
- [ ] Lists paginated with a maximum; uploads size-limited.
- [ ] Endpoint tests cover each contract status and error body.
