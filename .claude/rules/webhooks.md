---
paths:
  - "**/webhooks/**"
  - "**/webhook/**"
  - "**/*webhook*"
  - "**/hooks/inbound/**"
  - "**/hooks/outbound/**"
---

# Webhook rules

Full standards, templates and the test matrix: the `build-webhooks` skill. A webhook endpoint is a **public, unauthenticated door**; the signature is its only lock.

## Receiving (a provider calls us)
- **Verify the signature first,** over the **raw request body** (never the parsed and re-serialized JSON), with the provider's scheme and a constant-time comparison. Invalid or missing → reject (400/401) and log it. No other work happens before verification.
- **Reject old requests:** check the signed timestamp (about 5 minutes tolerance) so a captured request cannot be replayed.
- **Process each event once:** store the provider's event id with a unique constraint; a duplicate returns 2xx and does nothing.
- **Answer fast, work later:** save the event, return 2xx within the provider's timeout, and process it in a background job. Never do slow work or call other services inside the request.
- **Do not trust the payload for money or status:** fetch the current object from the provider's API when the value matters. Handle events that arrive out of order.
- One endpoint per provider (`POST /webhooks/<provider>`), excluded from session and CSRF checks but never from verification. Limit body size and rate.

## Sending (we call subscribers)
- **Sign every delivery** (HMAC-SHA256 with a per-subscriber secret, over id + timestamp + body), and send an event id and a timestamp. Prefer the Standard Webhooks headers.
- **Deliver from a queue,** never from the request that caused the event. Emit after the transaction commits (outbox).
- **Retry with exponential backoff and jitter** for about a day; then dead-letter, disable the subscription after repeated failures and tell its owner.
- **Validate subscriber URLs:** HTTPS only; block private, loopback and link-local addresses, on registration and on every delivery (SSRF).
- **Keep a delivery log** (attempts, status, latency) and offer a manual redeliver.
- Events are versioned and documented in the contracts; payloads carry only what the subscriber may see.

## Always
- Secrets by environment-variable name only; support two valid secrets during rotation; never log secrets, signatures or full payloads with personal data.
- Tests cover: valid, bad signature, missing signature, stale timestamp, duplicate, out of order, oversized body, and (sending) retry, dead letter and a blocked private URL.
- Log provider, event type, event id, outcome and latency; alert on signature failures and on a growing backlog.
