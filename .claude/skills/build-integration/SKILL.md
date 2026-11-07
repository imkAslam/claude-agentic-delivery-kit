---
name: build-integration
description: "Third-party and system integration toolkit: integration catalog (INTEGRATIONS.md), adapters behind ports with an anti-corruption layer, sync vs async patterns, outbox, polling, CDC and reconciliation, inbound and outbound webhooks (signatures, idempotency, retries, delivery logs), resilience (timeouts, retries with jitter, circuit breakers, rate limiting, bulkheads, DLQ), provider categories with sandbox/test modes and local mocks, data minimization and contract testing."
when_to_use: "Use when planning or building any integration with an external system (payments, email, SMS, identity providers, storage, maps, AI or SaaS APIs, partner systems), implementing webhooks, sync or import jobs, or reviewing integration code."
---

# Build integration

For the **integration-engineer** (plan and build), the **integration-reviewer**, and the solution-architect and devops-engineer as collaborators.

## When to Use
- Lane plan, `design-fork`: `docs/delivery/INTEGRATIONS.md`
- Lane build: integration tickets (adapters, webhooks, sync jobs)
- Triage: external API failures, webhook issues, provider limits
- Reviews of any code under `**/integrations/**`, `**/adapters/**` or `**/webhooks/**`

## Instructions

### Step 0: Load the inputs
PRD (journeys that touch external systems, NFRs), intake decisions (any providers the client named, residency, budget), ARCHITECTURE (L5/L7 layers, ADRs), DATA-MODEL (classification of the data exchanged), contracts (webhooks and events the product exposes), THREAT-MODEL, `SYSTEM-PROFILE.md`.

### Step 1: Identify each integration (plan mode)
List each external system: purpose, journeys, direction (outbound call / inbound webhook / both / batch sync), and how critical it is (blocks a journey, or degrades gracefully).

### Step 2: Catalog it (plan mode)
Fill [INTEGRATIONS_TEMPLATE.md](references/INTEGRATIONS_TEMPLATE.md) for each provider. **Fetch the provider's official docs** for auth, limits, idempotency, webhook signing and the sandbox. Choose the provider category's local mock from [PROVIDER_CATALOG.md](references/PROVIDER_CATALOG.md) and LOCAL_SERVICES. Cost or tier differences are business items, recorded for the gate. Refine the **D7 integration map**: Diagrams live only in the PRD (`design-architecture/references/DIAGRAMS.md` → "Single home"): send the Mermaid source to the solution-architect in a `handoff` message, and never create a separate diagram file or a copy in your document.

### Step 3: Design the adapter (build mode)
Following [INTEGRATION_PATTERNS.md](references/INTEGRATION_PATTERNS.md): the port interface (owned by the application, in domain terms) → the adapter (provider SDK/HTTP, mapping, error translation) → registration through configuration. Choose sync or async per the user-wait rule.

### Step 4: Write the tests first (tdd)
Adapter tests against the local mock or recorded responses (happy path, provider errors, timeouts, rate limiting, malformed responses); webhook tests (valid signature, invalid signature, stale timestamp, duplicate event); a contract test that the mapping matches the provider schema.

### Step 5: Implement resilience
Per [RESILIENCE.md](references/RESILIENCE.md): timeouts, retry policy, circuit breaker, client-side rate limiting, bulkhead, fallback, DLQ for async work.

### Step 6: Webhooks
Inbound and outbound per [WEBHOOKS.md](references/WEBHOOKS.md).

### Step 7: Verify and evidence
Run the role's checks; exercise the integration end to end against the local mock (and the sandbox, if the brief allows and it's configured); record the settings chosen (timeouts, retries, breaker thresholds) in the INTEGRATIONS.md entry.

## Rules
`.claude/rules/integrations.md` always applies. No real provider calls with production credentials outside the production runtime. No sign-ups or paid tiers by agents.

## Integration with Other Skills
- **design-architecture:** adapters live in L5, async work in L7; provider choices get ADRs
- **design-api:** the webhook and event contracts the product exposes
- **create-endpoint:** the use cases call the ports; transactional outbox
- **setup-docker:** local mocks and emulators in `compose.yml`
- **threat-model / secure-coding:** SSRF, signature verification, data minimization

## File Structure
```
.claude/skills/build-integration/
├── SKILL.md
└── references/
    ├── INTEGRATION_PATTERNS.md   # ports/adapters, ACL, sync vs async, outbox, polling, CDC, reconciliation, idempotency
    ├── WEBHOOKS.md               # inbound verification and processing, outbound signing and delivery
    ├── RESILIENCE.md             # timeouts, retries, breakers, rate limits, bulkheads, DLQ, fallbacks
    ├── PROVIDER_CATALOG.md       # provider categories, test modes, local substitutes, gotchas
    └── INTEGRATIONS_TEMPLATE.md  # INTEGRATIONS.md structure
```
