# THREAT-MODEL.md template

```markdown
> Status: in-review · Owner: cybersecurity-agent · Sources: PRD.md, BA-ANALYSIS.md, ARCHITECTURE.md · Updated: <ISO>

# Threat model

## 1. Assets and data classes
| Asset | Data class | Why it matters | Retention |
|---|---|---|---|
| User accounts | personal + credentials | account takeover | life of account + 30 days |
| Payments | payment (via provider) | fraud, PCI scope | provider-held |

## 2. Actors
Anonymous visitor · authenticated user (by role) · admin/back-office · external systems · CI/CD · operators.

## 3. Data flow and trust boundaries
Diagram: **PRD §12 · D4 trust boundaries** (the solution-architect draws it with your input). Send your boundary and data-class corrections to the solution-architect as a `handoff` message. Here, list each boundary: | Boundary | Crossed by (flow) | Data classes | Controls |

## 4. Entry points
| Entry point | Auth | Exposure | Contract ops |
|---|---|---|---|

## 5. Threats (STRIDE)
| Id | Flow / component | STRIDE | Threat | Likelihood | Impact | Priority | Controls | Owner | Verification |
|---|---|---|---|---|---|---|---|---|---|
| T-1 | U → W login | S | Credential stuffing | H | H | High | C-AUTH-3, C-RATE-1 | backend | AC-SEC-1 test, rate-limit test |
| T-2 | W → D orders | I | IDOR on order read | M | H | High | C-AUTHZ-2 | backend | AC-SEC-2 test |

## 6. Security acceptance criteria
AC-SEC-1 Given 10 failed logins for one account within 10 minutes, When another attempt is made, Then it's rejected with `rate_limited` and the account owner is notified.
…

## 7. Compliance notes
Regulations in scope (e.g. privacy law for personal data, card-industry scope minimized by using a hosted payment page), data residency, data-subject rights (export, deletion).

## 8. Accepted risks
| Risk | Reason | Accepted by (gate) | Revisit |
```
