# QA report templates

## QA-REPORT.md
```markdown
> Status: in-review · Owner: qa-agent · Candidate: <commit sha> · Environment: <dev_url | staging_url> · Run: <ISO>

# QA report

## Summary
| Total | Passed | Failed | Blocked | Not run | Flaky |
|---|---|---|---|---|---|
| 48 | 44 | 2 | 1 | 1 | 0 |
Release-blocking (P1) failures: <count>, listed in OPEN-ISSUES.md

## Results
| TC | Title | AC | Type | Result | Evidence | Notes |
|---|---|---|---|---|---|---|
| TC-001 | Create order | AC-ORD-1 | e2e | pass | evidence/TC-001/ | |
| TC-002 | Missing postcode | AC-ORD-2 | e2e | **fail** | evidence/TC-002/ | OI-3 |

## Non-functional
| Check | Result | Evidence |
|---|---|---|
| Accessibility scan (P1 screens) | 0 serious / 2 moderate | evidence/a11y/ |

## Coverage
Every AC has at least one executed TC: yes / no (list the gaps)
```

## OPEN-ISSUES.md
```markdown
> Status: in-review · Owner: qa-agent (+ quality-security-agent) · Updated: <ISO>

| Id | Title | Severity | Area / suspected role | TC / finding | Bug ticket → original | Status | Decision |
|---|---|---|---|---|---|---|---|
| OI-3 | Postcode error not announced to screen readers | P2 | UI / frontend | TC-002 | T-077 → T-041 | open | fix before release |

### OI-3 Postcode error not announced to screen readers
- **Steps:** 1. … 2. …
- **Expected:** … **Actual:** …
- **Evidence:** evidence/TC-002/2-error.png
- **Environment / commit:** staging / <sha>
```
The Decision column is filled at the gate: fix before release · accept (owner, reason) · defer (target milestone).

## ACCEPTANCE-REVIEW.md
```markdown
> Status: in-review · Owner: qa-agent · Candidate: <commit sha> · Updated: <ISO>

# Acceptance review

## What is being accepted
Scope (milestones, features), the candidate commit, and the environment it ran in.

## Acceptance criteria status
| AC | Result | Evidence (real screenshots) |
|---|---|---|

## Quality and security
A summary from QUALITY-SECURITY-REPORT.md: tools run, findings by severity, accepted risks.

## Landing page changes (only if `F-LANDING`)
The features added to or removed from the landing page in this candidate, the changed copy (`CLIENT COPY (draft)` strings for the client to approve) and the Lighthouse scores, with screenshots.

## Open issues
The P1/P2 items with the decision requested from the client.

## Recommendation
Accept / Accept with listed exceptions / Do not accept, with the reasons.
```
