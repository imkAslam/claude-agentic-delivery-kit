# docs/SYSTEM-FLOWS.md: how the built system actually works

The PRD and ARCHITECTURE say what was **planned** (journeys, sequence diagrams D5, state diagrams D6-states). This living document says what was **built**: for every delivered journey, the real path a request takes through the client, the API, the data store and the integrations, with the rules applied at each step. Engineers and operators read it to understand or debug a flow without opening ten files.

Written by the docs-writer in `milestone` mode (flows the milestone delivered or changed) and checked in `release` mode. Built from the **code and contracts as merged** (routes, handlers, use cases, migrations, the generated client), never from memory or from the plan alone.

```markdown
# System flows
> As built at <ms> (<integration sha>) · Planned flows: PRD §12 / ARCHITECTURE §14 · D5-<journey> · Contracts: <contracts path> · Updated: <ISO>

## Index
| # | Flow | Journey | Feature | Diagram | Since |
|---|---|---|---|---|---|
| 1 | Sign up and verify email | J-1 | F-1 | D5-signup | ms-1 |

## 1. <Flow name>  ·  J-<n>  ·  F-<n>
**Who:** <persona / role> · **Entry point:** <screen S-… or API operation> · **Diagram:** D5-<journey> (PRD §12, mirrored in ARCHITECTURE §14)

| Step | Where | What happens | Operation / code | Rules and checks |
|---|---|---|---|---|
| 1 | Web (`(auth)/register`) | The form validates with the shared schema and submits | `createAccount` | AC-AUTH-1; field rules from the contract |
| 2 | API | Validates the request, checks the email is unused | `POST /v1/accounts` → `<module>/application/<use-case>` | BR-3 unique email → 409 `email_taken` |
| 3 | Database | Inserts the account in one transaction; writes the outbox event | `accounts`, `outbox` | — |
| 4 | Worker | Sends the verification email | `<job name>` → email adapter | retried 3×, idempotent by event id |
| 5 | Web | Shows "check your inbox"; the session cookie is set | — | httpOnly session; no token in web storage |

**Permissions:** who may start it and what a wrong role sees.
**Errors:** each error code the flow can return, what the user sees, and whether it is retried.
**Side effects:** events emitted, notifications sent, audit entries, cache keys invalidated.
**Differences from the plan:** none, or one line per difference with the CR or ADR that approved it.

## State machines (as built)
### <Entity> status
| From | To | Trigger (operation) | Who | Side effects |
|---|---|---|---|---|
| submitted | reviewed | `updateApplicationStatus` | reviewer role | notification to the applicant |
Transitions not in this table are rejected with `<error code>`. Diagram: D6-states-<entity>.

## Cross-cutting behavior
- **Request validation:** where and with which schema library; the shape of a validation error.
- **Error shape:** the contract's error model, with one example.
- **Authentication and session lifecycle:** sign-in, refresh, expiry, sign-out, where the session lives.
- **Authorization:** where role and ownership checks run (the choke point and the service layer).
- **Rate limits and CORS:** the limits per route group and the allowed origins per environment (names, not secrets).
- **Realtime and background work (if used):** channels and events, queues and schedules, retry policy.
- **Observability:** the request id, where to find a flow's logs and traces.
```

Rules:
- One section per journey the product actually delivers; a flow that isn't built yet is not listed.
- Tables and short lines, not prose. **No new diagrams here:** reference the diagram id; the diagrams live in the PRD and are mirrored into ARCHITECTURE §14.
- Every operation, table, job and file named must exist (`check-hygiene.sh` checks the links). Remove a flow or step when the code that implements it is removed.
- A difference between the built flow and the approved journey without a CR goes under "Differences from the plan" **and** is reported as a finding to the product-manager and the solution-architect. Never fix it by editing the PRD.
- No secrets, tokens, personal data or internal hostnames: environment-variable names only.
