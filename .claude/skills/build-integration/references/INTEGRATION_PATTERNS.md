# Integration patterns

## 1. Ports and adapters (anti-corruption layer)
```text
application (L3)  ── calls ──>  Port: PaymentGateway.charge(Order) -> PaymentResult   (our types)
                                     ▲ implements
infrastructure (L5)            StripePaymentAdapter / LocalMockPaymentAdapter          (provider types stay here)
```
- The port uses **domain language** and our types. The adapter maps both ways, translates errors into our error categories (`provider_unavailable`, `provider_rejected`, `rate_limited`), and hides pagination, auth and retries.
- Select the adapter by configuration (`PAYMENTS_PROVIDER=mock|<provider>`), so dev and tests run on the mock.
- One adapter per provider; never call provider SDKs from controllers or domain code.

## 2. Sync vs. async
| Choose | When |
|---|---|
| **Synchronous** call (short timeout, ~2–5 s) | The user must see the result now (card authorization, address lookup); a provider outage shows a clear fallback |
| **Asynchronous** (outbox → queue → worker) | The user doesn't need to wait (emails, notifications, exports, CRM sync, image processing); retries and DLQ are needed |
| **Hybrid** | Start synchronously, finish via webhook (payment intents, KYC, file scans) |

## 3. Transactional outbox
Write the business change **and** an `outbox_events` row in one DB transaction; a relay/worker publishes or calls the provider afterwards; mark the row published; retry on failure. This guarantees "no email without an order, and no order without its email eventually".

## 4. Inbound data: webhooks, polling, CDC
| Mechanism | Use | Must also have |
|---|---|---|
| Webhooks | The provider pushes events | Signature verification, dedup, async processing (WEBHOOKS.md) |
| Polling | No webhooks; small volumes | A cursor/`updated_since` checkpoint, backoff, rate-limit respect |
| Change data capture / event streams | Internal systems, high volume | Ordering per key, idempotent consumers |
| Batch file import (CSV/SFTP) | Partners, back office | Schema validation, row-level error report, idempotent re-import |
**Always add reconciliation:** a periodic job compares our state with the provider (e.g. payments settled vs. orders paid) and raises discrepancies. Webhooks get lost.

## 5. Idempotency across the boundary
- Outbound: send the provider's idempotency key (derived from our operation id) on every create/charge, so retries can't double-charge or double-send.
- Inbound: store processed provider event ids (unique constraint) and skip duplicates.
- Jobs: make each job handler idempotent (an upsert by external id).

## 6. Data mapping and validation
Validate provider responses against the schema we expect (zod/pydantic-style) at the adapter; treat unknown enum values safely; store external ids (`provider_customer_id`) in dedicated columns; never store whole provider payloads with PII unless DATA-MODEL classifies and retains them.

## 7. Identity and auth integrations
OIDC/OAuth providers: authorization-code + PKCE flow through the vetted library; validate the `state` and `nonce`; map provider identities to local users by a stable subject id (not by email alone); handle account linking explicitly.

## 8. Configuration
Every integration is configured by environment-variable **names** (base URL, keys, webhook secret, timeouts) listed in `.env.example`, `project.json → deploy.required_secrets` and INTEGRATIONS.md. Use separate test and live credentials per environment.
