---
paths:
  - "**/integrations/**"
  - "**/adapters/**"
  - "**/webhooks/**"
  - "**/providers/**"
  - "**/clients/**"
  - "**/connectors/**"
---

# Integration rules

Full standards: the `build-integration` skill (`.claude/skills/build-integration/references/`).

- **Ports and adapters:** the application calls an interface it owns; the adapter translates to and from the provider. Provider SDK types never cross into the domain or the API contracts.
- **Every outbound call has a timeout** (connect + total). Retries only for idempotent requests, or with an idempotency key, using exponential backoff with jitter, at most 3 attempts. Circuit breaker for each provider, plus a user-facing fallback.
- **Respect provider limits:** client-side rate limiting, honor `Retry-After`, batch where the API supports it.
- **Inbound webhooks:** verify the signature over the **raw** body with a constant-time comparison; reject stale timestamps; deduplicate by provider event id; respond 2xx fast; process asynchronously; never trust the payload's claims without a fetch-back when the money or state matters.
- **Outbound webhooks:** sign them (HMAC with a per-subscriber secret), include an event id and a timestamp, retry with backoff, dead-letter after the limit, keep a delivery log; validate subscriber URLs against SSRF rules.
- **Data:** validate and map every response at the boundary; send only the fields the provider needs; classify the data sent (DATA-MODEL) and respect residency constraints.
- **Secrets:** API keys and webhook secrets by environment-variable name only; separate test and production credentials; never in logs.
- **Testing:** no real provider calls in unit tests; use the local mocks/emulators (LOCAL_SERVICES) and recorded contract tests; sandbox/test mode in staging only.
- **Observability:** log provider, operation, latency, status and correlation id (no payload secrets or PII); metrics per provider for errors, latency and breaker state.
- **Cost and accounts** (new provider, paid tier, quota increase) are **business decisions** for the human at a gate. Agents never sign up for or upgrade accounts.
