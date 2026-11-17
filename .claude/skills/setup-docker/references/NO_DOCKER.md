# No Docker: run on SQLite

When `SYSTEM-PROFILE.md` shows Docker missing or not running, a project with a relational database develops and tests on **SQLite files**. Nobody has to install anything or provide a remote database to start working. When Docker (or the real database) is available later, the switch is a configuration change.

## 1. How it is set up
- `DATABASE_URL` selects the database. Local default without Docker: `file:./.data/dev.sqlite`; tests: `file:./.data/test.sqlite` (deleted and recreated by the test setup). `.data/` is git-ignored.
- `project.json → services` records `{ "name": "db", "kind": "<real engine>", "provider": "sqlite-fallback" }`, so everyone can see the project is on the fallback.
- `app.sh start` chooses the mode by itself: Docker running → the one database container; otherwise SQLite. It says which one it used.
- Other services: cache and queue use the in-memory or in-process driver of the same library; mail is written to a local folder; object storage uses a local folder. Each is chosen by an environment variable, never by a code branch.

## 2. Rules that make the switch free of rework (must)
1. **All data access goes through the ORM or query builder, behind the repository port.** No hand-written SQL in services or handlers.
2. **No dialect-specific SQL outside one marked adapter file** per module (`*.dialect.*`). If a query needs the real engine, it lives there with a portable fallback or a clear "not available on SQLite" error.
3. **Portable column types only** in the shared schema: text, integer, real, boolean, timestamp (UTC), JSON as text. Money as integer minor units. Ids generated in the application (UUID/ULID), not by database functions.
4. **Migrations come from the ORM's schema,** generated for both dialects and kept in separate folders (`migrations/sqlite`, `migrations/<engine>`). Never copy one dialect's migration to the other by hand.
5. **Enforce rules in the application as well as the database** when SQLite cannot enforce them (for example tenancy filters in the repository, as well as row-level security on the real engine).
6. **Same tests, both engines.** The feature tests never mention the engine. CI runs them on the real database.

## 3. What SQLite cannot prove
The solution-architect lists these in `ARCHITECTURE.md › Operations` under "Verify on the real database", and each gets a test that runs in CI (which has the real engine) before the milestone review:

| Feature | Why SQLite is not enough |
|---|---|
| Row-level security, roles and grants | SQLite has none |
| Extensions, full-text or vector search, generated columns of the real engine | Different or missing |
| Concurrency: locks, isolation levels, `SELECT … FOR UPDATE`, advisory locks | SQLite locks the whole file |
| Performance and query plans, indexes used | Not comparable |
| Types: native JSON operators, arrays, enums, exact decimals, time zones | Stored and compared differently |
| Online migrations and zero-downtime changes | Not comparable |

**Say this plainly at the gate:** the switch needs no code rework for everything written by the rules above; the features in this table cannot be proven on SQLite and are proven in CI or on staging.

## 4. Switching to the real database
1. Start Docker (or provide the database) and set `DATABASE_URL`.
2. `app.sh start` now uses the container; it runs the engine's migrations and the seeds.
3. Run the tests. Fix only what the "Verify on the real database" list predicted.
4. Set `project.json → services[db].provider` back to `docker` (or `remote`).

## 5. When SQLite is not an option
Document stores, graph or time-series databases, and products whose core feature depends on a real-engine capability from the table above. Then use the remote fallback in LOCAL_SERVICES.md: the human provides a database address in the git-ignored `.env`.
