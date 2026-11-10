# Findings and ticket triage

Triage turns failures (from the integrator, QA, quality/security, a gate's "request fixes" or "bug feedback", or a hook block) into **routed, actionable tickets**.

## Routing table
| Finding area | Route to | Reviewer |
|---|---|---|
| UI, screens, forms, client-side state, a11y, a mismatch with the mockups (DESIGN-QA) | frontend-engineer (or mobile-engineer for the app) | frontend- / mobile-reviewer |
| A hygiene finding from `check-hygiene.sh` (scaffold leftover, stray file, debug output, ticketless TODO, unused code, dead doc link) | The role that owns the path, as one **chore ticket per role per milestone** (docs links → docs-writer) | The role reviewer; the integrator re-runs the check |
| A missed performance budget or a PERFORMANCE-REVIEW finding (slow route, N+1, unbounded read, oversized bundle) | The role that owns the code (frontend-, backend-, mobile-engineer); an index or model change → database-architect + CR on `g2`; an architectural bottleneck → solution-architect | The role reviewer; the performance-specialist re-measures |
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
3. **Reopen, file a bug, or create new work** (tracker skill → "Reopen or file a bug?"):
   - **Inside an existing ticket's AC, before that milestone's `mbr` approved it** (integration, design QA, `mbr` "request fixes"): reopen it, `delivery-state.sh ticket status <id> reopened --note "<finding>"`, then `ready`, and add the finding to its next brief.
   - **Inside an existing ticket's AC, after `mbr` approved it** (QA, acceptance, quality/security, staging, production): **create a bug ticket linked to the original**: find the original through the AC id (`TICKETS.md`, `docs/FEATURES.md`), then `delivery-state.sh ticket add T-<next> <role> <ms> "<symptom>" --type bug --of <original> --severity <P1|P2|P3> --found-in "<where>"` and the tracker's `create-bug`. Use the bug template (reproduction, expected vs actual, evidence, regression test). Untraceable defects (environment, config): `--of none` with the reason in `--found-in`.
   - **Not covered by any AC:** new scope → `backlog` + discovery (major decision), never a bug.
   Severity: P1 blocks a journey, loses data or is a security flaw; P2 breaks an AC with a workaround; P3 is minor. P1 bugs are fixed before the next gate.
4. **Overlap check before the fork:** two tickets in the same `build-fork` batch must not touch the same files. Compare their `owned_paths` and the files they're expected to touch. If they overlap, run them one after the other.
5. **Attempts:** every engineer run increments `attempts` (`delivery-state.sh ticket attempt <id>`). At `$DELIVERY_MAX_ROUNDS` (3), write a failure report and **stop and ask the human**.
6. **Lessons:** when a finding of the same kind has appeared in 2 or more tickets, or is P1/CRITICAL, or a root cause is found, add one line to `docs/delivery/LESSONS.md` and include it in that role's next briefs ([memory.md](memory.md) §7). Also add the root cause of every failure report.

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
