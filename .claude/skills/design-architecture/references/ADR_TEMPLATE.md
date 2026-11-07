# ADR template: `docs/adr/ADR-<nnn>-<slug>.md`

```markdown
# ADR-<nnn>: <decision title>

- **Status:** proposed | accepted (<gate>, <date>) | superseded by ADR-<mmm> | deprecated
- **Date:** <ISO>   **Deciders:** solution-architect; approved at <gate>
- **Drivers:** <PRD/NFR ids, constraints>

## Context
What forces are at play: requirements, constraints, team, cost, timeline.

## Options
| Option | Pros | Cons | Score (from STACK_SELECTION) |
|---|---|---|---|
| A | | | |
| B | | | |
| C | | | |

## Decision
We choose **<option>** because <the reasons, tied to the drivers>.

## Alternatives rejected
- **<Option>:** rejected because <the deciding reason, tied to a driver>.

## Consequences
- Positive: …
- Negative / accepted trade-offs: …
- Follow-ups: tickets, spikes, revisit triggers ("revisit if p95 > 500 ms at 1k rps")
```

**Write an ADR for:** language/framework, database, hosting target, auth approach, API style, monorepo vs. multi-repo, any queue/cache/realtime addition, and any deviation from a kit default.

**Lifecycle and index:** never delete or rewrite an accepted ADR; supersede it with a new one. Every ADR is listed in `docs/adr/README.md` (write-docs → ADR_GUIDE.md).
