# Webhooks

## Inbound (a provider calls us)
1. **A dedicated endpoint per provider** (`POST /webhooks/<provider>`), excluded from the session/CSRF middleware but **not** from verification.
2. **Verify the signature** over the **raw request body**, using the provider's scheme (usually HMAC-SHA256 with a shared secret, or an asymmetric signature). Use a constant-time comparison. Reject with 400/401 when it's invalid.
3. **Reject stale or replayed requests:** check the signed timestamp (tolerance ~5 minutes).
4. **Deduplicate:** insert the provider event id into `webhook_events` (unique). If it already exists, return 2xx and stop.
5. **Acknowledge fast:** persist the event, return 2xx within the provider's timeout, and process it asynchronously (a worker).
6. **Process idempotently:** fetch the current object from the provider API when the state matters (amounts, statuses), rather than trusting the payload alone. Handle out-of-order events by comparing timestamps or versions.
7. **Observe:** log the provider, event type, id, outcome and latency; alert on signature failures or backlogs.
8. **Test:** valid, invalid-signature, stale, duplicate and out-of-order cases; use the provider's CLI or sandbox event triggers in staging.

## Outbound (we call subscribers)
1. **Subscriptions:** the URL, the event types, a per-subscriber secret (shown once), and an active flag. Validate subscriber URLs: HTTPS only, block private, loopback and link-local addresses (SSRF), re-validate on each delivery.
2. **Payload:** the event envelope (`id`, `type`, `occurredAt`, `data`, versioned type) as defined in the contracts.
3. **Signature:** a header with `t=<timestamp>,v1=<HMAC-SHA256(secret, t + "." + body)>`; document the verification for subscribers.
4. **Delivery:** from a queue worker; a timeout of ~5–10 s; retries with exponential backoff + jitter over ~24 h; after the final failure, a dead letter + disable-after-N-failures + notify the owner.
5. **Delivery log:** attempts, response codes and latency per event; a manual redeliver action for admins.
6. **Ordering:** not guaranteed (documented); subscribers deduplicate by `id`.

## Local development
Simulate inbound webhooks with the provider CLI/forwarders in sandbox mode, or with fixture-based test requests signed using a dev secret. Never expose a dev machine publicly without the human's approval.
