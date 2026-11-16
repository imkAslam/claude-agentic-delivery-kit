---
name: build-webhooks
description: "Webhook toolkit: receiving webhooks from providers (signature verification over the raw body, replay protection, deduplication, fast acknowledge and background processing, out-of-order handling) and sending webhooks to subscribers (signing, queued delivery, retries with backoff, dead letters, delivery log, SSRF-safe URLs, secret rotation, versioned events), with the contract format, table shapes, handler templates per stack, a provider signature table and a test matrix."
when_to_use: "Use when designing, building or reviewing any inbound webhook endpoint or outbound webhook delivery, when adding a provider that sends events (payments, email, messaging, source control, commerce), when writing webhook events into the API contracts, or when a webhook is failing, duplicated or arriving out of order."
user-invocable: false
---

# Build webhooks

For the **integration-engineer** (or the backend-engineer when no integration role is enabled), the **api-designer** (event contracts) and the **integration-** and **security-reviewer**. The musts are in `.claude/rules/webhooks.md`; this skill is the how.

## When to Use
- A provider will call the product (payment succeeded, email bounced, repository pushed, order created)
- The product will notify other systems of its own events
- Reviewing or debugging webhook code

## Instructions

### Step 0: Decide and record
In `ARCHITECTURE.md › Integrations`, one row per webhook: direction, provider or audience, the events, the signature scheme, the secret's environment-variable name, the timeout the provider allows, and what happens on failure. A webhook that changes money, access or personal data is a threat-model item.

### Step 1: Contract first
Add the events to the contracts before coding ([WEBHOOK_STANDARDS.md](references/WEBHOOK_STANDARDS.md) §5): inbound events under the provider adapter's types; outbound events in the API contract's `webhooks` section with a versioned type and payload schema. Contracts freeze at G2 like every other.

### Step 2: Data shapes
Create the two tables through the normal migration path ([WEBHOOK_STANDARDS.md](references/WEBHOOK_STANDARDS.md) §4): `webhook_events` (inbound, unique on provider + event id) and, for sending, `webhook_subscriptions` and `webhook_deliveries`.

### Step 3: Build the receiver (inbound)
Follow WEBHOOK_STANDARDS §1 and the template for your stack in [WEBHOOK_TEMPLATES.md](references/WEBHOOK_TEMPLATES.md):
1. Read the **raw body** before any parser touches it.
2. Verify the signature and the timestamp. Stop on failure.
3. Insert the event id; on a duplicate, return 2xx.
4. Enqueue the processing job; return 2xx.
5. In the job: map the provider payload to the application's own types (the adapter), re-fetch from the provider when the state matters, apply the change idempotently, record the outcome.

### Step 4: Build the sender (outbound)
Follow WEBHOOK_STANDARDS §2: subscriptions with a per-subscriber secret shown once; events written to the outbox in the same transaction as the change; a delivery worker that signs, sends with a timeout, records the attempt, and retries with backoff; dead letters and automatic disabling; a redeliver action.

### Step 5: Test it
Build the whole flow, then test it (`feature-testing` skill) with the matrix in WEBHOOK_STANDARDS §6. Use fixture requests signed with a development secret, and the provider's CLI or sandbox triggers in staging. Never expose a development machine publicly without the human's approval.

### Step 6: Operate it
Logs, metrics and alerts per WEBHOOK_STANDARDS §7; the secret rotation steps go in `ARCHITECTURE.md › Operations`.

## Rules
- Verification is never skipped, mocked away in production code paths, or made optional by a flag.
- No business logic in the HTTP handler: verify, record, enqueue, answer.
- Provider SDK and payload types stay inside the adapter; the application sees its own events.
- A new provider or a paid plan is a business decision for the human.

## Integration with Other Skills
- **build-integration:** the adapter, resilience and provider catalog around the webhook
- **design-api:** the event contracts and versioning
- **threat-model / security-audit:** webhook endpoints as trust boundaries
- **coding-foundations → WORKERS.md, REALTIME.md:** the background job; pushing the result to clients
- **feature-testing / review-checklists:** tests and the reviewer's checklist

## File Structure
```
.claude/skills/build-webhooks/
├── SKILL.md
└── references/
    ├── WEBHOOK_STANDARDS.md   # inbound and outbound standards, provider signature table, tables, contracts, test matrix, operations, review checklist
    └── WEBHOOK_TEMPLATES.md   # handler and delivery-worker skeletons per stack
```
