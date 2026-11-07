# BA-ANALYSIS.md template

```markdown
> Status: in-review · Owner: ba-agent · Sources: Intake-Readiness.md (D-…), RESEARCH.md · Updated: <ISO>

# Business analysis

## 1. Personas and roles
| Role | Goals | Key permissions | Frequency | Source |
|---|---|---|---|---|
| <role> | <goals> | create X, approve Y | daily | D-3 |

## 2. Feature map
| Epic | Feature | Priority (M/S/C/W) | Personas | Source |
|---|---|---|---|---|
| <epic> | <feature> | M | <role> | D-1 |

## 3. Journeys
### J-1 <journey name> (persona: <role>)
1. <step> → system shows <result>
2. …
- **Alternative paths:** J-1a <when …> → <steps>
- **Error paths:** J-1e1 <invalid input / timeout / no permission> → <expected handling>

## 4. Business rules
| Id | Rule (precise, testable) | Applies to | Source |
|---|---|---|---|
| BR-1 | An order can be cancelled only while its status is `pending` or `confirmed` | Order | D-5 |

## 5. Entities (conceptual)
| Entity | Key attributes | Relationships | Lifecycle / states | Data class |
|---|---|---|---|---|
| <Entity> | id, …, status | belongs to <Entity> | draft → active → archived | personal / internal / public |

State machine for each stateful entity (Mermaid `stateDiagram-v2`).

## 6. Acceptance criteria
`AC-<area>-<n>` Given/When/Then, grouped by feature (see ACCEPTANCE_CRITERIA.md).

## 7. Non-functional needs
| Area | Requirement | Target | Source |
|---|---|---|---|
| Performance | p95 API latency | < 300 ms | D-8 |
| Accessibility | WCAG | 2.2 AA | D-9 |

## 8. Out of scope
- <item>, with the reason and the source

## 9. Open questions
| Id | Question | Consequence if unanswered | Blocks |
|---|---|---|---|
| Q-1 | … | … | J-2 |
```
