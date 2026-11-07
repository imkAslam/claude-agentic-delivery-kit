# Architecture decision records

ADRs record **why** a significant technical decision was made, which alternatives were rejected, and what it costs us. They stop agents and engineers from re-deciding the same thing.

## When an ADR is required
- Language, framework, major library, ORM, build tool
- Architecture style, module boundaries, monorepo vs. multi-repo
- Database engine, tenancy, data model patterns (audit, soft delete, temporal), migration strategy
- API style, versioning, auth and session strategy, the authorization model
- Hosting target, CI/CD design, any queue, cache, realtime or search addition
- A third-party provider choice
- Any deviation from a kit default or an approved artifact (with its CR id)
- Anything expensive to reverse

## Template: `docs/adr/ADR-<nnn>-<kebab-slug>.md` (numbers are sequential, never reused)
```markdown
# ADR-<nnn>: <decision as a short statement, e.g. "Use PostgreSQL with row-level security for tenant isolation">

- **Status:** proposed | accepted (<gate>, <date>) | superseded by ADR-<mmm> | deprecated
- **Date:** <ISO> · **Deciders:** <agent role>; accepted at <gate> by <approver>
- **Drivers:** <PRD/NFR ids, constraints, business decisions D-…>
- **Supersedes:** ADR-<kkk> (if any)

## Context
The forces at play: requirements, constraints, team, cost, timeline. Facts, not opinions.

## Decision
We will <decision>. One paragraph; specific enough to act on.

## Alternatives considered
### <Option B>
- Pros: …
- Cons: …
- **Rejected because:** <the deciding reason, tied to a driver>
### <Option C>
- …

## Consequences
- **Positive:** …
- **Negative / accepted trade-offs:** …
- **Follow-ups:** tickets, spikes, monitoring
- **Revisit when:** <a measurable trigger, e.g. "p95 > 500 ms at 1k rps", "> 50 tenants">
```

## Lifecycle
`proposed` (written during design) → `accepted (<gate>)` (when the gate that contains it is approved; gate-review updates the status) → `superseded by ADR-<mmm>` or `deprecated`.
- Never delete or rewrite an accepted ADR. To change a decision, write a new ADR that supersedes it, and update the old one's Status line only.
- A superseding ADR after a gate needs a change request on that gate (a major decision for the human).

## Index: `docs/adr/README.md`
```markdown
# Architecture decisions
| ADR | Decision | Status | Date | Gate | Supersedes / superseded by | Area |
|---|---|---|---|---|---|---|
| [ADR-001](ADR-001-modular-monolith.md) | Modular monolith on managed services | accepted (g1) | 2026-… | g1 | — | architecture |
```
