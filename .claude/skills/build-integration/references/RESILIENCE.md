# Resilience for external calls

| Tactic | Standard |
|---|---|
| **Timeouts** | Always set connect (~1–2 s) and total (~2–5 s sync; up to 30 s in workers) timeouts. Never rely on library defaults (often infinite) |
| **Retries** | Only for idempotent requests or ones with an idempotency key; on network errors, 429, 502, 503, 504; exponential backoff with full jitter (e.g. 200 ms × 2^n); at most 3 attempts synchronously, more in workers; honor `Retry-After` |
| **Circuit breaker** | Per provider: open after N consecutive failures or an error rate > X% in a window; half-open probe after a cool-down; while open, fail fast with the fallback |
| **Rate limiting (client side)** | A token bucket per provider and key, below the provider's documented limit; queue or shed load past it |
| **Bulkhead** | Separate connection pools or worker queues per provider, so one slow provider can't starve the others |
| **Fallback / degradation** | A clear user message ("Payment provider is busy, try again in a minute"); cached data with a "last updated" note; queue-and-notify for non-urgent work |
| **Dead-letter queue** | Async jobs that exhaust their retries go to a DLQ with the error and context, plus alerting and an admin replay tool |
| **Hedging** (rare) | Only for idempotent, latency-critical reads with very good reasons |

## Error translation
Map the provider's errors into our categories at the adapter:
| Category | Examples | Behavior |
|---|---|---|
| `provider_rejected` | Validation failed, card declined | No retry; show the user a specific message |
| `provider_unavailable` | 5xx, timeout, breaker open | Retry per policy, then fall back |
| `rate_limited` | 429 | Back off per `Retry-After` |
| `auth_failed` | 401/403 from the provider | No retry; alert ops (credential problem) |

## Observability
Metrics per provider: request count, error rate by category, latency percentiles, breaker state, retry count, DLQ depth. Alert on breaker-open, rising error rates and DLQ growth. Dashboards are listed in OPERATIONS-HANDOFF.
