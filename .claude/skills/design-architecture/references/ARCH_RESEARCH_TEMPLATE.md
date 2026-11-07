# ARCHITECTURE-RESEARCH.md template

```markdown
> Status: in-review · Owner: solution-architect · Sources: PRD.md, BA-ANALYSIS.md, web (cited below) · Updated: <ISO>

# Architecture research

## 1. Drivers (from the PRD)
| Driver | Value | PRD ref | Weight (1–5) |
|---|---|---|---|
| Expected users / growth | 5k MAU → 100k in 18 months | §1, §6 | 4 |
| Latency target | p95 < 300 ms | §6 | 4 |
| Realtime | order status updates | F-3 | 3 |
| Data sensitivity | personal data, payments via provider | §6 | 5 |
| Team skills | TypeScript | intake D-9 | 5 |
| Budget / hosting | < <amount>/month, managed preferred | intake D-4 | 3 |

## 2. Sources fetched
| # | Title | URL | Tier | Fetched | Supports claim |
|---|---|---|---|---|---|
| S1 | <title> | <url> | 1 | <date> | Modular monolith first; extract services when … |
| … (at least 5) | | | | | |

## 3. Candidate architectures
### C1 Modular monolith + managed Postgres + queue for async
- **Fits because:** … (S1, S3)
- **Scales by:** … (S2)
- **Risks:** …
### C2 <alternative>
### C3 <alternative>

## 4. Scoring
| Driver (weight) | C1 | C2 | C3 | Evidence |
|---|---|---|---|---|
| Team skills (5) | 5 | 3 | 3 | — |
| Scalability to target (4) | 4 | 5 | 4 | S2, S4 |
| … | | | | |
| **Weighted total** | | | | |

## 5. Recommendation
**C1**, *evidence-backed* (S1, S2, S4). Scaling path: stages 1→3 (see ARCHITECTURE §12).
Conditions that would change this choice: …

## 6. Technology choices per layer (summary; ADRs follow)
| Layer | Choice | Alternatives | Evidence | ADR |
|---|---|---|---|---|

## 7. Open questions for G1
| Question | Options | Consequence |
```
