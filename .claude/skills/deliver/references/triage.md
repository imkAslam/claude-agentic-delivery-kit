# Findings and ticket triage

Triage turns failures (from the integrator, QA, quality/security, a gate's "request fixes" or "bug feedback", or a hook block) into **routed, actionable tickets**.

## Routing table
| Finding area | Route to | Reviewer |
|---|---|---|
| UI, screens, forms, client-side state, a11y, a mismatch with the mockups (DESIGN-QA) | frontend-engineer (or mobile-engineer for the app) | frontend- / mobile-reviewer |
| The agreed design itself is wrong or incomplete (a missing state, token or component spec; a brand rule that doesn't work) | uiux-agent + CR on `g2` | design-reviewer |
| API behavior, business rules, performance of server code | backend-engineer | backend-reviewer |
| Schema, migrations, query performance, data integrity, data privacy | backend-engineer (implementation); database-architect if the **model** must change (CR on `g2`) | database-reviewer + backend-reviewer |
| Pipeline, build, environments, infra, deploy, monitoring | devops-engineer (build mode) | devops-reviewer |
| Vulnerability, auth/authz flaw, secret exposure, missing control | cybersecurity-agent | security-reviewer |
| E2E test is wrong or flaky (the product is right) | qa-agent | frontend- or backend-reviewer for the area |
| A contract is wrong or incomplete | api-designer + CR on `g2` | architect-reviewer |
| External provider, webhook, sync job, provider limits or outage handling | integration-engineer | integration-reviewer |
| **New scope** (not covered by any AC) | discovery: product-manager + solution-architect, then a CR on `g1`/`g2` | product-owner-reviewer |
| Conflicting merges / shared file | the owner in `project.json → shared_files` | the matching role reviewer |

## Procedure
1. **Normalize** each finding: `area — symptom — evidence path — suspected ticket — severity`.
2. **Deduplicate** by root cause. A single cause gets a single ticket, even if it has several symptoms.
3. **Reopen or create:** if the finding is inside an existing ticket's AC, reopen it (`delivery-state.sh ticket status <id> ready`) and add the finding to its brief. Otherwise create a new ticket `T-<next>` with `role`, `depends_on`, AC refs and owned paths (the `tracker` skill + `delivery-state.sh ticket add`).
4. **Overlap check before the fork:** two tickets in the same `build-fork` batch must not touch the same files. Compare their `owned_paths` and the files they're expected to touch. If they overlap, run them one after the other.
5. **Attempts:** every engineer run increments `attempts` (`delivery-state.sh ticket attempt <id>`). At `$DELIVERY_MAX_ROUNDS` (3), write a failure report and **stop and ask the human**.

## Failure report — `docs/delivery/failures/<ticket-or-loop>.md`
```
# Failure: <ticket id> — <title>
Role: <role>   Attempts: <n>   Loop: <loop id>   Date: <ISO>
## Goal / acceptance criteria
## What each attempt tried (1–2 lines each)
## Latest evidence (errors, failing tests, reviewer findings)
## Suspected root cause
## Options for the human (each with its trade-off)
```
Then run `delivery-state.sh fail <ticket> <role> <attempts> docs/delivery/failures/<file>.md` and comment on the tracker ticket.
