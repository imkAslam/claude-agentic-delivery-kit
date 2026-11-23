# The test database

Tests use the project's **one running database container**. They never start their own: no `docker run`, no Testcontainers, no `compose up` from test code or test scripts. Each extra container costs memory, start-up time and disk, and parallel agents multiply it (agents × test workers × test files); containers from killed runs keep running. (`check-hygiene.sh` › `services` fails on docker calls in test code; `guard-services.sh` blocks agents from starting containers.)

## How it works
1. **The services are already running.** The orchestrator starts them once from the main checkout (`app.sh services` → `infra:up`) before parallel work; every agent's worktree uses them. In CI, the pipeline's service container is the one container.
2. **One template, built once.** The test global setup connects with `TEST_DATABASE_URL` (a local role allowed to create databases; a placeholder in `.env.example`) and, under a lock so parallel runs don't race, makes sure `<app>_test_template` exists and is migrated. Rebuild it only when the migrations change: keep a hash of the migrations folder as the database comment and compare it.
3. **One database per worker, copied from the template.** `CREATE DATABASE <app>_test_<run>_<worker> TEMPLATE <app>_test_template` takes a moment, because it is a file copy, not a migration run.
   - `<run>`: 8 characters of a hash of the checkout's path, so parallel agents in different worktrees never share a database.
   - `<worker>`: the runner's worker id (`VITEST_POOL_ID`, `JEST_WORKER_ID`, `PYTEST_XDIST_WORKER`, or `0`).
   - Close every connection to the template before copying (PostgreSQL refuses a template that is in use).
4. **Clean up.** Teardown drops the worker databases. At start-up, the setup also drops this checkout's databases left by a crashed run (`<app>_test_<run>_%`).
5. **Between tests:** roll back a transaction per test where the framework supports it; otherwise truncate the tables the test touched (`TRUNCATE … RESTART IDENTITY CASCADE`).
6. **Special cases, same container:**
   - Roles, grants and row-level security: create the roles in the template (roles are cluster-wide: `IF NOT EXISTS`, names prefixed `<app>_`).
   - Migration tests: their own database from an empty template (`<app>_test_<run>_migrations`), never their own server.
   - A superuser for the harness only: the local admin role from `.env.example`, never given to application code.
7. **Other engines and services:**
   - MySQL/MariaDB: no `TEMPLATE`; create the worker database and load a schema dump made once per run.
   - SQLite (no Docker): one file per worker in `.data/`, copied from a migrated template file.
   - MongoDB: one database per worker. Redis: a database index or key prefix per worker.
   - Mail catcher, object storage and queues: the running container, with a per-worker mailbox, bucket, queue or prefix.

## Where it lives
| Stack | Global setup |
|---|---|
| Vitest / Jest | `globalSetup` (template) + a setup file per worker (worker database) |
| pytest | session fixture in `conftest.py`; `pytest-xdist` worker id |
| Go | `TestMain` in a shared test package |
| JUnit / Kotlin | an extension or a base class with `@BeforeAll` |
| .NET | a collection fixture |

The **backend foundation ticket** builds it as part of "the tests run with one command" (plan-delivery), and every later ticket uses it. Reviewers reject a test that starts a container or connects anywhere other than `TEST_DATABASE_URL`.
