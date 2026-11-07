---
name: design-api
description: "API design toolkit: consumer-first resource modeling, REST conventions (URLs, methods, status codes, error model, pagination, filtering, sorting, caching, bulk and async operations), GraphQL, typed RPC, gRPC and event/webhook schema design, auth and scopes, idempotency and concurrency, versioning, evolution and deprecation, API guidelines, docs, linting, mock servers, contract tests and SDK generation."
when_to_use: "Use when designing or changing API contracts, writing API-GUIDELINES.md, reviewing an API for consistency, planning a breaking change or deprecation, setting up mocks or contract tests, or answering API semantics questions."
---

# Design API

For the **api-designer** (owner of the contracts), plus the **solution-architect** (style, L2 layer), the **backend-engineer** (implementation), and the **frontend, mobile and QA roles** (consumers).

## When to Use
- Lane plan, `design-fork`: contracts + `API-GUIDELINES.md`, after the architect's boundaries and alongside the DATA-MODEL
- Contract change requests after G2
- Reviewing contracts at the design join (architect-reviewer) or diffs that implement them (backend-reviewer)

## Instructions

### Step 0: Load the inputs
PRD (stories and `AC-`), UI-UX (screen inventory and states), DATA-MODEL (entities, access patterns), ARCHITECTURE (style ADR, L2 layer, §10 security), THREAT-MODEL (auth, rate limits), INTEGRATIONS (webhooks and events), `project.json → contracts`.

### Step 1: Inventory the consumers' needs
For each screen, journey and integration, list the data read and the actions taken. Group them into resources and operations. **One screen shouldn't need N+1 calls**: add expansions or a BFF view where it justifies itself.

### Step 2: Write the API guidelines
`docs/delivery/API-GUIDELINES.md` (template in REST_DESIGN §10): naming and casing, URL shape, ids, timestamps, money, the error model, pagination, filtering and sorting syntax, auth and scopes, idempotency, concurrency, rate-limit headers, versioning. Decide these yourself (decision policy) and record the significant ones as ADRs.

### Step 3: Design the operations
REST per [REST_DESIGN.md](references/REST_DESIGN.md), or GraphQL, RPC or events per [GRAPHQL_AND_RPC.md](references/GRAPHQL_AND_RPC.md). Every operation is complete per the architect's [API_CONTRACTS.md](../design-architecture/references/API_CONTRACTS.md): auth, request, responses, every error, limits, examples.

### Step 4: Security and reliability semantics
Auth scheme and scopes per operation; object-level authorization stated; idempotency keys; `ETag`/`If-Match`; async `202` patterns; rate limits; webhook signing for anything the product sends out.

### Step 5: Evolution plan
Versioning strategy and deprecation policy per [VERSIONING_AND_EVOLUTION.md](references/VERSIONING_AND_EVOLUTION.md). Start `docs/delivery/API-CHANGELOG.md`.

### Step 6: Docs, lint, mocks, contract tests
Per [DOCS_MOCKS_AND_CONTRACT_TESTS.md](references/DOCS_MOCKS_AND_CONTRACT_TESTS.md): lint the contracts, generate docs, provide a **mock server** command (so frontend and mobile can start against it the moment G2 passes), set `codegen_cmd`, and define the contract-test approach for the backend and for consumers.

### Step 7: Hand off
Send `handoff` messages to the frontend, mobile, backend, QA and integration roles with the contract paths, the mock-server command and the codegen command.

## Rules
- After G2, contracts change only through a CR on g2 plus a ticket for you.
- Contracts never expose internal tables, sequential ids or internal flags.
- Every list is paginated; every write documents its validation errors; every operation documents auth.

## Integration with Other Skills
- **design-architecture:** style ADR, the L2 layer, API_CONTRACTS completeness rules
- **design-database:** resource ↔ model mapping, pagination keys, query feasibility
- **create-endpoint / create-component / create-screen:** the implementers and consumers
- **build-integration:** webhook and event contracts
- **threat-model / security-audit:** API Top 10 controls

## File Structure
```
.claude/skills/design-api/
├── SKILL.md
└── references/
    ├── REST_DESIGN.md                     # REST conventions + the API-GUIDELINES.md template
    ├── GRAPHQL_AND_RPC.md                 # GraphQL, typed RPC, gRPC, events/AsyncAPI
    ├── VERSIONING_AND_EVOLUTION.md        # breaking vs. additive, versioning, deprecation, changelog
    └── DOCS_MOCKS_AND_CONTRACT_TESTS.md   # lint, docs, mock server, contract tests, SDKs
```
