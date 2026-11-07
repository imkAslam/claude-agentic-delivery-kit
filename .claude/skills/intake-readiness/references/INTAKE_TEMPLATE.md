# Intake-Readiness.md template

```markdown
> Status: in-review · Owner: intake-agent · Sources: docs/intake/* · Updated: <ISO date> · Round: <n>

# Intake readiness

## Summary
- **Readiness:** <nn>%   **Recommendation:** Start | Update | Provisional scope | Hold
- **Critical gaps:** <count>, blocking: <work items>
- **Stack preference:** none stated (architect recommends) | preferred: <stack> (E-<n>) | required: <stack> (E-<n>, why). Confirmed at G1
- One paragraph: what the client wants, for whom, and why now.

## Evidence inventory
| Id | File | Type | Date | Owner | Summary |
|---|---|---|---|---|---|
| E-1 | docs/intake/<file> | brief | <date> | <name/role> | <one line> |

## Decision log
| Id | Decision | Source | Status |
|---|---|---|---|
| D-1 | <decision> | E-2 §3 | agreed |
| D-2 | ~~<older decision>~~ | E-1 | superseded by D-1: <reason> |

## Readiness score
| Dimension | Weight | Score (0–10) | Weighted | Evidence |
|---|---|---|---|---|
| Problem & goals | 10 | 7 | 7 | E-1, D-1 |
| … | | | | |
| **Total** | 100 | | **<nn>%** | |

## Gaps
| Id | Dimension | Gap | Consequence if unresolved | Severity |
|---|---|---|---|---|
| G-1 | Integrations | Payment provider unknown | Checkout design and contracts blocked | critical |

## Questions for the client (by impact)
1. **Q-1 (closes G-1):** Which payment provider should we use: A, B or the client's existing one?
2. …

## Assumptions
- ASSUMPTION: <assumption> (to confirm at the gate)

## Recommendation
<Start / Update / Provisional scope / Hold>, with the reasons. For a provisional scope, state exactly what is in it and which gaps must close before G1.
```
