# Architecture decision records

ADRs record **why** a significant technical decision was made, which alternatives were rejected, and what it costs us. They stop agents and engineers from re-deciding the same thing.

## When an ADR is required (major decisions only)
Write an ADR only for a decision that is **expensive to reverse** or that the client confirms:
- the main stack (language, framework, database engine) and the hosting target
- the architecture style and module boundaries
- the authentication and authorization approach
- tenancy and the handling of sensitive data
- a paid or hard-to-replace third-party provider
- a deviation from an approved artifact (with its change-request row)

Everything else (a library inside the stack, a naming or folder choice, a tool, a pattern used in one module) is **one line in `ARCHITECTURE.md`** under the section it belongs to: "Decision: X, because Y." No ADR. A typical product has 5 to 10 ADRs, not dozens.

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

## No index file
The `docs/adr/` folder lists the decisions; file names carry the number and the subject. Do not maintain an index.
