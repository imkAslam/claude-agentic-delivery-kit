# PRD.md template

```markdown
> Status: in-review · Owner: product-manager · Sources: Intake-Readiness.md, BA-ANALYSIS.md, RESEARCH.md · Updated: <ISO>

# Product Requirements Document: <product name>

## 1. Problem and goals
- **Problem:** <one paragraph, cited>
- **Goals:** G-1 <goal>, …
- **Success metrics:** | Metric | Baseline | Target | How it's measured |

## 2. Users
Personas and jobs-to-be-done (link to the BA §1).

## 3. Scope
| In (MVP) | Later | Out (with reason) |
|---|---|---|

## 4. Features and stories
### F-1 <feature> (priority M)
- **US-1.1** As a <role> I want <capability> so that <benefit>.
  - AC-<area>-1 Given … When … Then …
  - AC-<area>-2 (error) …
  - AC-<area>-3 (permission) …
- Business rules: BR-1, BR-4
- Journeys: J-1, J-1e1

### F-LANDING Public landing page (only if the client wants one: Intake-Readiness "Landing page")
- **US-L.1** As a prospective <primary persona> I want to understand what <product> does for me so that I decide to sign up or get in touch.
  - AC-LAND-1 Given the page, Then every section comes from its source in build-design-system → LANDING_PAGE.md §1, and only released (or accepted-for-this-release) features are shown
  - AC-LAND-2 Given a crawler or a link preview, Then the title, meta description, canonical URL, Open Graph image, JSON-LD, sitemap and robots are present (LANDING_PAGE §4)
  - AC-LAND-3 Given a mobile Lighthouse run, Then performance, accessibility, best practices and SEO are each ≥ 90
  - AC-LAND-4 Given the primary CTA, When it is used, Then the visitor reaches the sign-up or contact journey
  - AC-LAND-5 Given the footer, Then the legal links (privacy, terms) open the client-provided pages; marketing and legal copy is client-approved
- Refreshed at every release from `docs/FEATURES.md` (LANDING_PAGE §6)

## 5. UX principles
Key flows, tone, accessibility target (WCAG 2.2 AA), supported devices and locales.

## 6. Non-functional requirements
| Area | Requirement | Target |
|---|---|---|
| Security / privacy | … | AC-SEC-… |
| Performance | … | p95 < … |
| Availability | … | … % monthly |
| Data retention | … | … |

## 7. Release slicing
| Milestone | Usable journey delivered | Features | Exit criteria |
|---|---|---|---|
| ms-1 | <journey end to end> | F-1, F-2 (partial) | AC-… pass in staging |

## 8. Risks, assumptions, dependencies
| Type | Item | Impact | Owner | Mitigation |

## 9. Open decisions (for G1)
| Id | Decision needed | Options | Consequence of each | Owner |

## 10. Solution architecture (layer by layer)
<!-- architect:begin -->
Written by the solution-architect (format: design-architecture/references/LAYERED_BLUEPRINT.md → "PRD section format").
The D1 main system diagram (whole app), the plain-language "Why this architecture" summary, an evidence link (ARCHITECTURE-RESEARCH.md), a layer table (L0 clients … L7 async, plus cross-cutting X1–X3),
the dependency rule, and the critical request flow.

## 11. Application folder structure
The folder tree (from FOLDER_STRUCTURES.md, adapted) plus a folder → owner-role table matching project.json.

## 12. Architecture diagrams
The complete visual set, inline as Mermaid (design-architecture/references/DIAGRAMS.md): a diagrams index, then D0 context · D2 layers (overview + one per layer) · D3 deployment ·
D4 trust boundaries · D5 critical-journey sequences · D6 data · D7 integration map · D8 CI/CD flow. Each one has a heading `### D<n> · <title>`, a purpose line and legend,
and "What to notice". These are the only copies of the diagrams; there are no separate diagram files.
<!-- architect:end -->
The product-manager never edits between the architect markers. To change them, send the architect a MESSAGES request.

## Revision log
| Round | Finding | Change made / rejected (reason) |
```

## Review checklist
The product-owner-reviewer checks each item and reports a P1/P2/P3 finding for every failure.
- [ ] Every agreed decision (D-…) and every must-have from the BA appears in the PRD. Nothing appears without a source or an `ASSUMPTION:` label. (P1)
- [ ] Goals are measurable and each success metric has a baseline and a target. (P2)
- [ ] In/Later/Out is explicit, and ms-1 delivers a usable end-to-end journey. (P1)
- [ ] Every story has happy, error and permission AC in Given/When/Then with stable ids. (P1)
- [ ] There are no contradictions with business rules, NFRs or superseded decisions. (P1)
- [ ] NFRs have numeric targets where it's possible. (P2)
- [ ] Open decisions list their options and consequences, and nothing is decided silently. (P2)
- [ ] A developer and a tester could act on it without asking. (P2)
- [ ] §10–§12 (architect-owned) exist; every layer's owner role and every top-level folder map to an enabled role. (P2, routed to the architect)
- [ ] §10 opens with D1 and "Why this architecture"; §12 holds D0 and D2–D8, each with a purpose line and "What to notice", readable by a non-technical client. No diagram exists only as a separate file. (P2, routed to the architect)
- [ ] Wording is clear and consistent with the BA glossary. (P3)
