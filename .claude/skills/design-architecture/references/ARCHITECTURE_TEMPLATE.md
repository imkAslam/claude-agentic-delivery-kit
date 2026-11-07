# ARCHITECTURE.md template

```markdown
> Status: in-review · Owner: solution-architect · Sources: PRD.md, BA-ANALYSIS.md, THREAT-MODEL.md, docs/adr/* · Updated: <ISO>

# Architecture: <product name>

> Diagrams: **every diagram lives in PRD.md** (D1 in §10, D0 and D2–D8 in §12). This document references them by id and never copies them (DIAGRAMS.md → "Single home").

## 0. Overview
- **Main system diagram:** see PRD §10 · D1. Summarize in 3–5 lines how a request crosses the layers.
- **Why this architecture:** see PRD §10. Add here only the technical detail behind it (the scoring matrix lives in ARCHITECTURE-RESEARCH §4).

## 1. Drivers
Top NFRs and constraints that shape the design (each linked to its PRD section), e.g. p95 latency, data residency, budget, team skills.

## 2. Context
See PRD §12 · D0. List each external system: what it does for us, the protocol, and who owns the relationship.

## 3. Containers
See PRD §10 · D1.
| Container | Responsibility | Technology (ADR) | Owner role |
|---|---|---|---|

## 4. Stack
| Concern | Choice | Alternatives considered | ADR |
|---|---|---|---|

## 5. Deployment topology
The chosen target (`deploy.target`), environments (dev/staging/prod), regions, managed services, and network boundaries. Diagram: PRD §12 · D3.

## 6. Scale, cost, risks
- Expected load (users, requests/s, data growth), and how each container scales.
- Rough monthly cost per environment (with the assumptions).
- Risks: | Risk | Likelihood | Impact | Mitigation |

<!-- §7–§11 are completed in lane plan -->
## 7. Data model
Diagrams: PRD §12 · D6-conceptual, D6-erd, D6-states-<entity> (the database-architect owns DATA-MODEL.md and hands its diagrams to the architect).
Indexes, constraints, personal-data columns (with retention and the deletion path), and migration strategy.

## 8. Modules
| Module | Responsibility | Owns entities | May depend on |
|---|---|---|---|

## 9. Contracts index
| Operation id | Method + path / name | Auth | Module | Consumer roles |
|---|---|---|---|---|

## 10. Security controls
Authn/session, the authorization model, input validation, secrets, encryption, rate limits, audit log (from the threat model). Diagram: PRD §12 · D4.

## 11. Observability and environments
Logs (structured, no PII), metrics, traces, health checks, alerts; per-environment config by **name**.

## 12. Layer-by-layer architecture
One block per layer, L0–L7 plus X1–X3 (format: LAYERED_BLUEPRINT.md), and the scaling-stage table. Diagrams: PRD §12 · D2-overview (dependency rule), D2-<layer> for each layer, D5-<journey> for each critical journey.

## 13. Application folder structure
The full tree (from FOLDER_STRUCTURES.md), the folder → owner-role mapping (it must match `project.json → roles.*.paths` and `shared_files`), and the import-boundary rules with the lint rule that enforces them.
```
```
