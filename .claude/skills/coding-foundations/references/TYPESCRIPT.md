# TypeScript guide

With: `coding-standards.md`, OOP_AND_PATTERNS.md. Applies to frontend, backend and mobile TypeScript.

## Compiler and tooling (must)
- `strict: true`, plus `noUncheckedIndexedAccess`, `noImplicitOverride`, `noFallthroughCasesInSwitch`, `useUnknownInCatchVariables`. Prefer `exactOptionalPropertyTypes` on new projects.
- ESLint with `@typescript-eslint` (recommended-type-checked), import-boundary rules, `complexity`, `max-depth`, `max-params`; Prettier for formatting. Typecheck (`tsc --noEmit`) runs in CI.
- Pin the Node version (`engines`, `.nvmrc`) and use the lockfile (`npm ci` / `pnpm install --frozen-lockfile`).

## Types
- `unknown` instead of `any`; narrow before use. `any` needs a comment and a ticket.
- Model states with **discriminated unions** and finish every `switch` with an exhaustive `never` check.
- `as const` objects or string-literal unions instead of `enum`.
- `satisfies` to check an object against a type without widening it.
- Type assertions (`as X`) only right after runtime validation, never to silence the compiler; no non-null `!` except where a comment explains why it can't be null.
- **Runtime validation at boundaries** with a schema library (zod, valibot) or the contract-generated validators; derive the static type from the schema (`z.infer`), not the other way round.
- Branded types for ids and units (`type UserId = string & { readonly __brand: 'UserId' }`).
- `readonly` properties and `ReadonlyArray` for data that shouldn't change.
- Public functions declare their return types.

## Modules
- Named exports (searchable, refactor-safe); default exports only where a framework requires them (pages, routes).
- One feature per folder with a public `index.ts`; no deep imports into another feature. Avoid huge barrel files that re-export everything (they hurt tree-shaking and cause cycles).
- No circular imports (lint: `import/no-cycle`).

## Errors and async
- Throw `Error` subclasses with a `cause`, never strings. For expected failures in domain code, a `Result<T, E>` type is fine if the project uses it consistently.
- Every promise is awaited, returned or explicitly handled (`no-floating-promises`); `Promise.all` for independent work, `Promise.allSettled` when partial failure is OK.
- Pass `AbortSignal` for cancellation and timeouts (`AbortSignal.timeout(ms)`).
- Dates: store and transmit ISO-8601 UTC; use a date library or `Temporal` polyfill for arithmetic, never manual string math.

## Testing
Vitest or Jest; tests are typed too. Factories for test data; no `as any` in tests to force shapes.

## Review checklist
- [ ] No new `any`, `@ts-ignore`, unsafe `as` or `!` without a reason.
- [ ] Boundary input validated with a schema; types derived from it.
- [ ] Unions handled exhaustively; no magic strings.
- [ ] No floating promises; timeouts on I/O.
- [ ] Named exports, no cross-feature deep imports, no cycles.
