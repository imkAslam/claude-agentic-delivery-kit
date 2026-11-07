# Go guide

With: OOP_AND_PATTERNS.md (structs + small interfaces instead of classes).

## Tooling (must)
- Pinned Go version in `go.mod`; `gofmt`/`goimports`, `go vet`, golangci-lint (errcheck, staticcheck, gocyclo, revive) and `go test -race` in CI.

## Structure
- `cmd/<app>/main.go` as the composition root; `internal/<feature>/` for application code (unexported to other modules); package by feature, not by layer type. Package names short, lowercase, no `util`/`common`.
- No `init()` with side effects; no package-level mutable state; dependencies passed explicitly (constructor functions `NewService(repo Repo, clock Clock) *Service`).

## Interfaces and types
- **Accept interfaces, return structs.** Define small interfaces where they're consumed (the domain's port), not next to the implementation.
- Make the zero value useful or provide a constructor that validates; unexported fields to protect invariants.
- Value types for money and ids; avoid `interface{}`/`any` in APIs; generics only when they remove real duplication.

## Errors (must)
- Return errors, don't panic (panic only for programmer errors at startup). Wrap with context: `fmt.Errorf("load order %s: %w", id, err)`; inspect with `errors.Is`/`errors.As`; sentinel or typed errors for expected cases, mapped to the contract at the HTTP boundary.
- Handle every error once: either handle it or return it, not log-and-return.

## Concurrency (must)
- `context.Context` is the first parameter of every function that does I/O; respect cancellation and deadlines; never store contexts in structs.
- Every goroutine has a known owner and exit path (`errgroup`, `WaitGroup`, cancellation); no goroutine leaks; channels closed by the sender.
- Protect shared state with a mutex or confine it to one goroutine; run tests with `-race`.

## HTTP and data
- `http.Server` with read/write/idle timeouts; `http.Client` with a timeout (never the zero-value default client for remote calls); graceful shutdown with `Shutdown(ctx)`. The server rules mirror the form rules exactly (FORMS_AND_VALIDATION.md).
- `database/sql` (or sqlc/pgx) with parameterized queries, `defer rows.Close()`, checked `rows.Err()`, transactions scoped to the use case.
- Structured logging with `log/slog`.

## Testing
- Table-driven tests with subtests (`t.Run`); fakes for interfaces; `httptest` for handlers; Testcontainers for the database; benchmarks for hot paths.

## Review checklist
- [ ] Errors wrapped with context and handled exactly once; no ignored errors.
- [ ] `ctx` passed through I/O; timeouts on servers and clients.
- [ ] No goroutine leaks; race detector clean.
- [ ] Small consumer-side interfaces; no package-level state or `init()` side effects.
