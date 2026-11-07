# Release templates

## RELEASE-REVIEW.md
```markdown
> Status: in-review · Owner: devops-engineer · Release: <name> · Updated: <ISO>

# Release review: <name>
| Item | Value |
|---|---|
| Artifact (immutable) | <image digest / build id> |
| Commit | <sha> (= the accepted candidate at the `acceptance` gate) |
| Target environment | production |
| Staging verification | <pipeline link>, smoke green at <time> |

## Changes
Features and fixes (tickets), with links to the milestone build reviews.

## Configuration diff (names only)
| Name | Change | Environments |

## Migrations
| Migration | Type (expand/contract) | Backward compatible | Est. duration | Backup before |

## Open issues and decisions
From OPEN-ISSUES.md: accepted / deferred, with the owners.

## Security
Dependency audit result, secret-scan result, accepted risks (from the threat model).
```

## DEPLOYMENT-PLAN.md
```markdown
# Deployment plan: <release>
1. **Pre-checks:** staging green on the same artifact; backup completed (<id>); on-call available; no conflicting maintenance
2. **Trigger:** CI production job with artifact <digest> (after G3)
3. **Migrations:** run in the CI step <name> before traffic shift
4. **Traffic:** <rolling | blue-green | instant> per the target
5. **Smoke tests:** `<prod_url><health_path>` = 200; journeys: <TC ids, run against prod-safe data>
6. **Observation window:** <30–60> min; watch the error rate (< <x>%), p95 latency (< <y> ms) and logs
7. **Go / no-go:** any smoke failure or threshold breach → ROLLBACK-RUNBOOK
```

## ROLLBACK-RUNBOOK.md
```markdown
# Rollback runbook: <release>
- **Triggers:** failed smoke test · error rate > <x>% for 5 min · p95 > <y> ms for 10 min · data integrity alert
- **Decision owner:** <role>; inform <channel>
## App rollback
Steps through CI (redeploy the previous artifact <digest-prev>), the expected duration, and how to verify.
## Data rollback
<down-migration steps | point-in-time restore to <timestamp>>, the expected data loss window, and how to verify.
## Rehearsal
Rehearsed on staging at <ISO>: result <pass/fail>, duration <min>.
## Escalation
If not resolved within <min>: <who>, <how>.
```

## OPERATIONS-HANDOFF.md
```markdown
# Operations handoff: <system>
- **Service overview:** what it does, its users, the critical journeys
- **Environments and URLs:** …
- **Dashboards and logs:** links, and what "normal" looks like
- **Alerts:** each alert → meaning → first response
- **Runbooks:** deploy, rollback, restore from backup, rotate a secret, scale
- **Backups:** schedule, retention, last restore drill
- **On-call and contacts:** roles, escalation path
- **Known issues and limitations:** from OPEN-ISSUES (accepted/deferred)
- **Credentials:** where they are managed (names and stores only)
```

## DEPLOYMENT-RESULT.md
```markdown
# Deployment result: <release>
| Item | Value |
|---|---|
| Started / finished | <ISO> / <ISO> |
| Artifact deployed | <digest> |
| Pipeline | <link> |
| Migrations | <applied list, durations> |
| Smoke tests | pass/fail with evidence |
| Observation window | error rate, p95, incidents |
| Rollback performed | no / yes (why, outcome) |
| Follow-ups | tickets |
```

## Release review checklist (release-reviewer)
- [ ] Exactly one immutable artifact, whose commit matches the accepted candidate (P1)
- [ ] Staging ran the **same** artifact, and its smoke test passed (P1)
- [ ] Migrations are listed, backward compatible or with approved downtime, and a backup is planned before them (P1)
- [ ] Deployment runs entirely through CI, with explicit go/no-go thresholds (P1)
- [ ] The rollback covers the app **and** the data, was rehearsed on staging, and names a decision owner (P1)
- [ ] The operations handoff has runbooks, alerts, dashboards, backups and on-call (P2)
- [ ] Open issues all carry a decision; the security items are summarized (P2)
- [ ] The config diff contains names only; no secret values appear anywhere (P1)
