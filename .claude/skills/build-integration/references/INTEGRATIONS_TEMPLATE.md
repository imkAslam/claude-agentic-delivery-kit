# INTEGRATIONS.md template

```markdown
> Status: in-review · Owner: integration-engineer · Sources: PRD, intake decisions, ARCHITECTURE, DATA-MODEL, provider docs (cited) · Updated: <ISO>

# Integrations

## Overview
Diagram: **PRD §12 · D7 integration map** (you refine it; the solution-architect places it). Send the Mermaid source in a `handoff` message; this document keeps only the reference and the tables below.

## Summary
| Id | Provider (category) | Purpose / journeys | Direction | Criticality | Local mock | Staging sandbox | Cost tier (business) |
|---|---|---|---|---|---|---|---|
| INT-1 | <provider> (email) | Assignment and mention notifications (J-3) | outbound async | degrades gracefully | Mailpit | provider sandbox | free tier up to N/month |

## INT-1 <provider> (<category>)
- **Docs fetched:** <urls, dates>
- **Auth:** API key (env `EMAIL_API_KEY`), webhook secret (env `EMAIL_WEBHOOK_SECRET`)
- **Operations used:** send message, events webhook (bounces, complaints)
- **Data sent:** recipient email, name, message body. **Class:** personal. **Residency:** EU endpoint `<region>`
- **Limits:** <rate limits, payload sizes>; client-side limiter set to <x/s>
- **Idempotency:** provider idempotency header = our notification id
- **Resilience:** timeout 5 s (worker), 5 retries with jitter, breaker after 10 failures/1 min, DLQ `email_failed`
- **Webhooks in:** signature scheme <…>, dedup on event id, handler is async
- **Failure behavior for users:** the notification is delayed; the in-app notification still shows
- **Reconciliation / monitoring:** bounce-rate alert; daily delivery report
- **Bootstrap items (human):** account, domain verification (SPF/DKIM), the API key in the secret store
- **Contract tests:** recorded responses in `<path>`; mock adapter `<path>`

## Open business items (for the gate)
| Item | Options | Cost / consequence | Recommendation |
```
