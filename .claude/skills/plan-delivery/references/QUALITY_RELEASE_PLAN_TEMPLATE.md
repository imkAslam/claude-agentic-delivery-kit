# QUALITY-RELEASE-PLAN.md template

```markdown
> Status: in-review · Owner: delivery-planner · Sources: PRD.md (NFRs), DEVOPS-PLAN.md, SYSTEM-PROFILE.md · Updated: <ISO>

# Quality and release plan

## Definition of done (every ticket)
Test first · role checks green · AC evidence · independent review APPROVE · one commit per ticket.

## Test levels per milestone
| Level | Tool (from project.json) | Scope | Gate |
|---|---|---|---|
| Unit | <stack.test> | rules, components | commit gate |
| Integration | <stack.test> + disposable DB | operations, contracts | commit gate + CI |
| E2E web | <stack.e2e> | P1 TCs per milestone | integration step + CI |
| E2E mobile | <stack.mobile_e2e> | P1 mobile TCs | integration step |
| Accessibility | automated scan + keyboard walkthrough | P1 screens | verify lane |
| Performance | load test tool if available | the main operations vs. PRD targets | verify lane |

## Quality and security checks (only the tools detected in SYSTEM-PROFILE)
| Check | Tool | Detected? | When | Threshold |
|---|---|---|---|---|
| Dependency audit | package-manager audit | yes | CI + verify | no critical/high |
| Secret scan | hook regex / gitleaks | yes / no | commit + CI | zero findings |
| Static analysis | SonarQube (MCP/scanner) | no → skipped | verify | quality gate pass |
| AI code review | CodeRabbit | no → skipped | MR | no unresolved blockers |
| Dynamic assessment | Strix | no → skipped | verify (staging only, authorized) | no high/critical |

## Release criteria
- All P1 TCs pass on the candidate; no open P1 issues; P2 issues accepted or deferred at the `acceptance` gate
- Staging deploy and smoke test green with the same artifact
- Rollback rehearsed on staging; backup taken before migrations

## Rollback expectations
Max time to roll back: <minutes>. Data rollback strategy: <down-migration | point-in-time restore>. Decision owner: <role>.
```
