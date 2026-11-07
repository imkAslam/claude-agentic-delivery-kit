# Docs, linting, mocks, contract tests and SDKs

Use the tools that fit the stack and are available; record the commands in `project.json` and API-GUIDELINES §13.

## Lint (before every handoff)
- OpenAPI: a Spectral-style ruleset (e.g. `npx @stoplight/spectral-cli lint contracts/openapi.yaml`) with rules for operationId presence, summaries, examples, error responses, pagination parameters on list operations, and casing.
- GraphQL: schema lint (naming, descriptions, deprecations). Protobuf: buf lint.
- Lint runs in CI on every contract change (the devops-engineer adds the job).

## Docs
Generate human-readable docs from the contract (e.g. Redocly or Scalar for OpenAPI; GraphQL docs from the SDL). Every operation has a description, its auth, examples for requests and responses, and every error. Keep the docs out of production builds unless the API is public.

## Mock server (unblocks parallel work)
- OpenAPI: a contract-driven mock (e.g. `npx @stoplight/prism-cli mock contracts/openapi.yaml`) that returns the examples and validates requests.
- GraphQL: a mock from the schema (mocked resolvers). In tests: MSW-style handlers generated from the contract.
- The mock-server command goes in API-GUIDELINES §13 and in the `handoff` message. Frontend and mobile tickets build against it until the backend is ready.

## Contract tests
| Side | What | How |
|---|---|---|
| Provider (backend) | The implementation conforms to the contract | Validate real responses against the schema in integration tests (e.g. an OpenAPI response validator), or run a schema-based fuzzing tool (e.g. Schemathesis) against the local server |
| Consumer (web/mobile) | The consumer only uses what the contract defines | Generated clients (type errors on drift) + mocks generated from the contract |
| Cross-team / external consumers | Expectations recorded by consumers | Consumer-driven contracts (e.g. Pact) when there are independent consumers |
| Breaking-change check | Spec diff against the last release | An OpenAPI diff / buf breaking / a GraphQL schema diff in CI |

## Codegen and SDKs
- `contracts.codegen_cmd` generates typed clients for each consumer (e.g. openapi-typescript + a fetch client, an OpenAPI generator for other languages, GraphQL codegen, protoc/buf).
- Generated code is committed or produced at build time, but never hand-edited.
- Public SDKs (only if the PRD needs them) are versioned with the API, from the same contract.
