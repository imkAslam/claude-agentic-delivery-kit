# Python guide (FastAPI, Django/DRF, SQLAlchemy, workers)

With: OOP_AND_PATTERNS.md. Templates: `create-endpoint/references/BACKEND_TEMPLATES.md`.

## Tooling (must)
- Pinned Python version; `pyproject.toml`; a lockfile (uv or Poetry); `src/` layout.
- Ruff (lint + format) and a strict type checker (mypy `--strict` or pyright strict) in CI.

## Code
- **Type hints everywhere** in application code; `Protocol` for ports; `dataclass(frozen=True)` or Pydantic models for value objects and DTOs; `Enum`/`Literal` instead of magic strings.
- No mutable default arguments; no wildcard imports; no module-level side effects (connections, network) on import.
- Errors: a small hierarchy of domain exceptions; never bare `except:`; `except Exception` only at the outermost boundary to log and map; `raise … from err` to keep the cause.
- Resources with context managers (`with`, `async with`).
- Logging through `logging.getLogger(__name__)` (or structlog) configured once; no `print`; lazy formatting (`log.info("order %s", order_id)`).
- Config with `pydantic-settings`, validated at startup.
- Time: timezone-aware `datetime` in UTC only.

## Async (must)
- Never call blocking code (requests, sync DB drivers, `time.sleep`, heavy CPU) inside `async def`; use async libraries (httpx, asyncpg, async SQLAlchemy) or run blocking work in a thread pool.
- Every outbound call has a timeout (`httpx.Client(timeout=…)`); retries with backoff only for idempotent calls.

## FastAPI
- Routers per feature, thin; logic in services/use cases; dependencies (`Depends`) for the DB session, the current user and permissions.
- Request and response models (`response_model`) from Pydantic; never return ORM objects directly; schemas match the contract.
- Lifespan handler for startup/shutdown (pools, clients); one exception handler mapping domain errors to the contract error body.
- Sync `def` endpoints run in a thread pool (fine for sync drivers); `async def` only when everything inside is async.
- `BackgroundTasks` only for best-effort trivia; real jobs go to a queue (Celery, RQ, Dramatiq, arq) with idempotent tasks.

## Django / DRF
- Business logic in a services/use-case layer, not in views or serializers; models hold invariants and simple domain methods.
- Query discipline: `select_related` (FK/one-to-one) and `prefetch_related` (many) to prevent N+1; `only()`/`values()` for heavy lists; `F()` expressions and `select_for_update()` for concurrent updates; `transaction.atomic` per use case, `on_commit` for side effects.
- Settings from the environment (split by environment, no secrets in the repo); `DEBUG=False` outside dev; security middleware and settings (`SECURE_*`, CSRF) on.
- DRF: serializers validate input; permissions classes plus object-level checks; pagination on every list; throttling on sensitive endpoints.
- Migrations reviewed like code (database-standards: expand → migrate → contract).

## SQLAlchemy (2.x style)
- `select()` API, explicit sessions per request/use case (unit of work), no global session; eager loading options (`selectinload`, `joinedload`) chosen per query; repositories map rows to domain objects.

## Testing
- pytest with fixtures and factories (factory_boy, polyfactory); `freezegun`/`time-machine` for time; tests against a real database container; `pytest-asyncio`/anyio for async code; coverage of every AC.

## Review checklist
- [ ] Fully typed; type checker and Ruff clean.
- [ ] No blocking calls in async code; timeouts on I/O.
- [ ] No bare `except`; domain errors mapped in one place; causes preserved.
- [ ] No ORM objects in responses; input validated by schemas/serializers.
- [ ] No N+1 (eager loading); atomic updates for concurrent writes; side effects on commit.
- [ ] Config from validated settings; no secrets in code.
