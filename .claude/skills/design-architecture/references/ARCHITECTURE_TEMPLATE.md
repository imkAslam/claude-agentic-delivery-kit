# ARCHITECTURE.md template

```markdown
> Status: in-review · Owner: solution-architect · Sources: PRD.md, BA-ANALYSIS.md, THREAT-MODEL.md, docs/adr/* · Updated: <ISO>

# Architecture: <product name>

> Diagrams: **the full set D0–D8 is in §14 of this document**, an identical copy of the PRD's diagrams (D1 in PRD §10, D0 and D2–D8 in PRD §12). The PRD is the source: change a diagram there, then run `sync-diagrams.sh`; never edit §14 by hand (DIAGRAMS.md → "Two homes, one source").

## 0. Overview
- **Main system diagram:** §14 · D1 (source: PRD §10). Summarize in 3–5 lines how a request crosses the layers.
- **Why this architecture:** see PRD §10. Add here only the technical detail behind it (the scoring matrix lives in ARCHITECTURE-RESEARCH §4).

## 1. Drivers
Top NFRs and constraints that shape the design (each linked to its PRD section), e.g. p95 latency, data residency, budget, team skills.

## 2. Context
Diagram: §14 · D0. List each external system: what it does for us, the protocol, and who owns the relationship.

## 3. Containers
Diagram: §14 · D1.
| Container | Responsibility | Technology (ADR) | Owner role |
|---|---|---|---|

## 4. Stack
> Confirmed at g1 by <human> on <date> · Client preference: <none | preferred | required: …>
| Concern | Choice | Client preference | Alternatives considered | ADR |
|---|---|---|---|---|

## 5. Deployment topology
The chosen target (`deploy.target`), environments (dev/staging/prod), regions, managed services, and network boundaries. Diagram: §14 · D3.

## 6. Scale, cost, risks
- Expected load (users, requests/s, data growth), and how each container scales.
- Rough monthly cost per environment (with the assumptions).
- Risks: | Risk | Likelihood | Impact | Mitigation |

<!-- §7–§11 are completed in lane plan -->
## 7. Data model
Diagrams: §14 · D6-conceptual, D6-erd, D6-states-<entity> (the database-architect owns DATA-MODEL.md and hands its diagrams to the architect, who places them in the PRD and re-syncs §14).
Indexes, constraints, personal-data columns (with retention and the deletion path), and migration strategy.

## 8. Modules
| Module | Responsibility | Owns entities | May depend on |
|---|---|---|---|

## 9. Contracts index
| Operation id | Method + path / name | Auth | Module | Consumer roles |
|---|---|---|---|---|

## 10. Security controls
Authn/session, the authorization model, input validation, secrets, encryption, rate limits, audit log (from the threat model). Diagram: §14 · D4.

## 11. Observability and environments
Logs (structured, no PII), metrics, traces, health checks, alerts; per-environment config by **name**.

## 12. Layer-by-layer architecture
One block per layer, L0–L7 plus X1–X3 (format: LAYERED_BLUEPRINT.md), and the scaling-stage table. Diagrams: §14 · D2-overview (dependency rule), D2-<layer> for each layer, D5-<journey> for each critical journey.

## 13. Application folder structure
The full tree (from FOLDER_STRUCTURES.md), the folder → owner-role mapping (it must match `project.json → roles.*.paths` and `shared_files`), and the import-boundary rules with the lint rule that enforces them.

## 14. Architecture diagrams
The full diagram set (D0–D8), mirrored from the PRD. The PRD is the source: change a diagram there, then run `sync-diagrams.sh`.

<!-- diagrams:begin (generated from PRD.md by sync-diagrams.sh; edit diagrams in the PRD, never here) -->
<!-- diagrams:end -->
```
```
