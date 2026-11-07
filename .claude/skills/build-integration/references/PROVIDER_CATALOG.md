# Provider categories: test modes and local substitutes

The provider itself is chosen per project (an ADR + INTEGRATIONS.md; cost and contracts are business decisions). This table lists what to plan for each **category**.

| Category | Typical needs | Test / sandbox | Local substitute (dev) | Gotchas |
|---|---|---|---|---|
| Payments | Checkout, intents, refunds, subscriptions, payouts | Provider test mode + test cards | Provider mock where one exists (e.g. stripe-mock), plus our mock adapter | Use hosted payment pages/elements to keep card data out of scope; idempotency keys; reconcile settlements; webhooks for async states |
| Transactional email | Notifications, magic links, digests | Provider sandbox/test API keys | **Mailpit** (SMTP capture) | Domain auth (SPF/DKIM/DMARC) is a bootstrap item; bounce/complaint webhooks; rate limits; EU-region endpoints if residency applies |
| SMS / voice / WhatsApp | OTP, alerts | Test credentials/magic numbers | Mock adapter + logged messages | Country rules, sender registration, cost per message (business item) |
| Identity (OIDC/OAuth, social login) | Sign-in, SSO | Dev tenants/test apps | **Keycloak** or a mock OAuth2 server | Redirect URI per environment; PKCE; stable subject ids; account linking |
| Object storage / CDN | Uploads, media, exports | A separate bucket per environment | **MinIO** | Presigned URLs with short expiry; content-type and size limits; private by default; malware scan if needed (ClamAV locally) |
| Maps / geocoding | Address search, distance | Restricted test keys | Mock adapter with fixtures | Key restrictions (HTTP referrer/IP); caching terms of service |
| Search (hosted) | Full-text | A dev index | **Meilisearch/OpenSearch** | Index sync through the outbox; reindex jobs |
| Analytics / product events | Usage tracking | A dev project | A no-op/console adapter | Consent and privacy; no PII in events |
| Error monitoring / APM | Exceptions, traces | A dev project/DSN | Local OTel (grafana/otel-lgtm) | Scrub PII and secrets before sending |
| AI / LLM APIs | Generation, embeddings | Low-quota dev keys | A deterministic mock adapter with fixtures | Cost per token (business item), timeouts, prompt-injection handling, no sensitive data unless approved |
| Calendars / productivity suites | Events, files | Test tenant | Mock adapter | OAuth scopes minimal; token refresh; per-user rate limits |
| Accounting / CRM / ERP (partner systems) | Sync of customers, invoices | Sandbox company | Mock adapter + recorded responses | Field mapping ownership; conflict resolution; reconciliation reports |
| Cloud provider services | Queues, functions, secrets | A separate dev account/project | **LocalStack / Azurite / Firebase emulators** | IAM least privilege; region pinning |

**Rule:** every integration ships with (1) a local substitute for dev and CI, (2) a sandbox plan for staging, (3) secrets listed by name, and (4) a reconciliation or monitoring plan in production.
