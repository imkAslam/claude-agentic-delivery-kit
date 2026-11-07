# docs/README.md: the documentation map

```markdown
# Documentation
> Updated: <ISO> · Maintained by docs-writer · Run status: `/delivery-status`

## Start here
- **What we're building:** [PRD](delivery/PRD.md) (approved at g1) · [Features](FEATURES.md)
- **How it's built:** [Architecture](delivery/ARCHITECTURE.md) · diagrams in [PRD §10–§12](delivery/PRD.md) · [Decisions (ADRs)](adr/README.md)
- **Data:** [Database](database/DATABASE.md) · [Data model (approved design)](delivery/DATA-MODEL.md)
- **APIs:** [API guidelines](delivery/API-GUIDELINES.md) · contracts: <contracts.paths> · [Integrations](delivery/INTEGRATIONS.md)
- **Design:** [Brand](delivery/BRAND-BRIEF.md) · [Design system](delivery/DESIGN-SYSTEM.md) · [UI/UX](delivery/UI-UX.md) · [Mockups](delivery/mockups/)
- **Run it:** [README](../README.md) · [Changelog](../CHANGELOG.md) · [Operations handoff](delivery/OPERATIONS-HANDOFF.md)

## All documents
| Document | Purpose | Owner | Status | Gate |
|---|---|---|---|---|
| delivery/PRD.md | Requirements, architecture, diagrams | product-manager + solution-architect | approved | g1 |
| FEATURES.md | Feature catalog and progress | docs-writer | living | — |
| database/DATABASE.md | Database design + as-built dictionary | docs-writer (from database-architect) | living | — |
| adr/README.md | Decision index | docs-writer | living | — |
| … | | | | |
```
Status values: `draft`, `in-review`, `approved (<gate>)`, `living` (updated continuously, never in a gate package), `superseded`.
