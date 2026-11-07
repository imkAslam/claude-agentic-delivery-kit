---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/*.py"
  - "**/*.go"
  - "**/*.java"
  - "**/*.kt"
  - "**/*.swift"
  - "**/*.dart"
  - "**/*.rb"
  - "**/*.php"
  - "**/*.cs"
  - "**/*.rs"
---

# Coding standards and best practices

These apply to every language. The stack-specific conventions (formatter, linter, type checker, their configuration) are pinned by the solution-architect in `.claude/PROJECT.md` and enforced by `project.json → commands.lint` / `typecheck`. Principles: `engineering-principles.md`.

**Foundation layer:** the `coding-foundations` skill holds the how-to for each stack and for design. Read `OOP_AND_PATTERNS.md` (SOLID, class design, domain modeling, design patterns and anti-patterns) and the stack guides listed in your brief's `GUIDES:` line: TypeScript, Node.js, NestJS, React/Next.js, React Native, Python (FastAPI, Django), Go, Java/Kotlin Spring, .NET. Each ends with a review checklist that engineers run before returning and reviewers apply.

## Readability and naming
- Names say what a thing is or does, in the domain's language (the PRD glossary): `invoiceTotal`, not `val2`. Booleans read as questions (`isActive`, `hasAccess`). Functions are verbs; types and modules are nouns.
- One naming convention per language, as its standard style guide says; no mixed casing in one codebase.
- No abbreviations except universal ones (`id`, `url`, `api`). No single-letter names outside tiny scopes (loop indexes, lambdas).
- Code reads top-down: public API first, helpers below; early returns instead of deep nesting.

## Size and complexity (lint-enforced where the stack allows)
| Measure | Target | Hard limit (needs a reason in review) |
|---|---|---|
| Function length | ≤ 30 lines | 60 |
| Parameters | ≤ 3 | 5 (use an options object beyond) |
| Nesting depth | ≤ 2 | 3 |
| Cyclomatic complexity | ≤ 10 | 15 |
| File length | ≤ 300 lines | 500 |

## Types and data
- Strict typing on: no implicit `any` / untyped public functions; no type-check suppression without a comment and a ticket.
- **Parse, don't validate:** convert untrusted input into typed, validated values once, at the boundary (contract schemas, DTOs), and pass the typed value inward.
- Value types for domain concepts that carry rules: money (integer minor units + currency), ids, email, dates with time zones. Never floats for money.
- Make invalid states unrepresentable: enums/unions over magic strings, required fields over nullable ones, constructors that enforce invariants.
- Handle absence explicitly (optional/nullable types, `Option`/`Result` where idiomatic). No `null` as an error signal.
- Prefer immutable data; never mutate function arguments.

## Errors
- Never swallow an error: handle it, add context and re-throw, or return it. No empty `catch`, no `catch` that only logs and continues as if nothing happened.
- Domain errors are typed (`OrderNotFound`, `InsufficientStock`) and mapped to the contract's error body **at the boundary** (one place), never leaked as stack traces.
- Throw or return error objects, never strings. Keep the original cause.
- Distinguish expected failures (validation, not found, conflict) from bugs; only bugs page someone.

## Functions, modules and architecture
- A function does one thing at one level of abstraction. A module exposes a small public surface; everything else is private.
- Inject dependencies (constructor or parameters); no hidden globals or singletons holding state; no `new` of infrastructure inside domain code.
- No circular dependencies; no imports across layer or feature boundaries except through their public entry point (the import-boundary lint rule).
- No magic numbers or strings: named constants, or typed config read once at startup and validated.
- Side effects (I/O, time, randomness) are passed in or isolated, so logic is testable without mocks of the world.

## Async, concurrency and resources
- Await or handle every promise/future; no fire-and-forget without an explicit, logged, supervised job.
- Every network, database and queue call has a timeout and supports cancellation where the stack does.
- No shared mutable state between requests. Guard real races (double submit, counters, stock) with atomic updates, locks or idempotency keys.
- Close what you open (connections, files, streams): `using`/`with`/`defer`/`finally`.

## Logging and observability
- Structured logs (JSON) with level, message, request id and the relevant entity ids. `error` for failures that need action, `warn` for degraded but handled, `info` for business events, `debug` off in production.
- Never log secrets, tokens, passwords, full card numbers or unnecessary PII.
- Emit a metric or span for every external call and every business-critical operation.

## Performance (measure first)
- No N+1 queries, no unbounded lists, no work inside loops that could be done once outside them.
- Cache only with a named owner, a TTL or invalidation rule, and a metric for its hit rate.
- Respect the NFR budgets (latency, bundle size, memory); measure before and after any optimization and put the numbers in the ticket report.

## Formatting, linting and hygiene
- Code is formatted by the project formatter; CI fails on unformatted code. Zero lint warnings on changed files.
- Disabling a lint rule inline needs a comment with the reason and a ticket id, and the reviewer's approval.
- No dead code, commented-out code, debug output or leftover feature flags. `TODO` only with a ticket id (`documentation.md`).
- Generated code is never edited by hand; regenerate it (`commands.codegen`).

## Tests and reviews
- Test first, behavior from the AC, no weakened tests (`testing.md`). New logic has unit tests; boundaries have integration tests; critical journeys have E2E.
- A diff is review-ready when: it does one ticket, builds, passes lint/typecheck/tests locally with the `project.json` commands, and its report explains any new dependency, pattern or deviation (with an ADR when it's significant).

## Stack notes (the architect fills the actual tools into PROJECT.md; details in the stack guides)
| Stack | Typical enforcement |
|---|---|
| TypeScript / JavaScript | `tsc --strict`, ESLint (incl. import boundaries, complexity), Prettier |
| Python | type hints + mypy/pyright (strict), Ruff (lint + format) |
| Go | `gofmt`, `go vet`, golangci-lint; errors wrapped with `%w` |
| Java / Kotlin | Checkstyle or ktlint, SpotBugs/detekt, null-safety annotations |
| C# / .NET | nullable reference types on, analyzers as errors, `dotnet format` |
| Ruby / PHP | RuboCop / PHP-CS-Fixer + PHPStan (high level) |
| Rust | `rustfmt`, `clippy -D warnings` |
| Swift / Dart | SwiftLint / `dart analyze` with strict mode, `dart format` |
