---
name: create-endpoint
description: "Implements backend API operations exactly as the frozen contract defines them, adapted to the project's framework (Express, Fastify, NestJS, Hono, FastAPI, Django/DRF, Go, and others): validation at the boundary, server-side authorization, transactions, idempotency, the standard error model, migrations, structured logging and contract-conformance tests, test-first."
when_to_use: "Use when a backend ticket adds or changes an API operation, business rule, persistence, migration or background job, or when the backend-reviewer checks API conventions."
---

# Create endpoint

For the **backend-engineer** in lane `build`. The contract is the spec, so implement it exactly.

## When to Use
- New or changed API operations (REST, GraphQL resolvers, RPC procedures)
- Business rules (`BR-`), persistence, migrations, background jobs
- Backend fixes routed by triage

## Instructions

### Step 0: Detect the stack
Read `.claude/project.json`: `stack.backend`, `stack.orm`, `stack.database`, `roles.backend.paths`, `roles.backend.commands`, `contracts`. In the owned paths, find the existing layering (routes/controllers → services → repositories), the validation library, the auth middleware, the error handler, and the test setup (unit vs. integration, test database). **Follow the existing conventions.**

### Step 1: Load the spec
- The ticket's contract operations, from `contracts.paths` (request/response schemas, errors, auth, pagination, idempotency)
- `BR-` rules and `AC-` criteria from the PRD and BA analysis
- The data model (ARCHITECTURE §7) and the security controls (ARCHITECTURE §10, THREAT-MODEL)

### Step 2: Write the tests first (tdd skill)
1. **Contract conformance:** status codes, response shape and error bodies for each operation (validate against the schema where tooling allows).
2. **Rules:** one unit test per `BR-`, including boundaries.
3. **Authorization:** each role allowed and denied; object-level access (user A can't read user B's resource → 404/403 per the contract).
4. **Validation:** missing, invalid and over-limit inputs → `validation_failed` with field details.
5. **Concurrency / idempotency:** a repeated `Idempotency-Key` returns the original result; a version mismatch → `conflict`.
6. Integration tests run against a disposable database (a container or a test schema), not mocks of the ORM.

### Step 3: Implement (layered)
Follow [BACKEND_TEMPLATES.md](references/BACKEND_TEMPLATES.md) for the framework, and [API_CONVENTIONS.md](references/API_CONVENTIONS.md) for the rules:
- **Route/controller:** parse and validate the input (the schema from the contract) → call the service → map the result and errors to the contract.
- **Service:** business rules, authorization decisions, transactions.
- **Repository / data access:** parameterized queries through the ORM or query builder; no N+1.

### Step 4: Persistence and migrations
Migrations follow `.claude/rules/database-standards.md` (forward-only; expand → migrate → contract for breaking changes). Add indexes for new filters and foreign keys. Seed and test data comes from factories.

### Step 5: Observability
A structured log line for each significant action (with the request id, actor id and operation; **no PII or secrets**); metrics for latency and errors per operation where the stack has them; the health endpoint stays green.

### Step 6: Verify
Run the role's `lint`, `typecheck` and `test`. Start the server and exercise each operation once (example request and response in your report). Commit once.

## Integration with Other Skills
- **design-architecture:** the source of the contracts and the error model ([API_CONTRACTS.md](../design-architecture/references/API_CONTRACTS.md))
- **threat-model:** the controls to implement (authn/z, rate limits, audit)
- **tdd / role-boundaries / review-checklists:** the loop, the ownership rules, and what the backend-reviewer checks

## File Structure
```
.claude/skills/create-endpoint/
├── SKILL.md
└── references/
    ├── BACKEND_TEMPLATES.md   # handler/service/repository skeletons per framework + test skeleton
    └── API_CONVENTIONS.md     # validation, authz, errors, pagination, idempotency, transactions, logging
```
