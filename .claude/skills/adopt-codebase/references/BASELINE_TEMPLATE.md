# BASELINE.md template (the state of the codebase when it was adopted)

Written by the quality-security-agent at `baseline-checks`. It is the honest starting line: what works, what doesn't, and what the human decided to do about it. It is part of the baseline package, so after approval it changes only through a change request; later progress on debts is tracked in the tickets, not by rewriting this file.

```markdown
> Status: in-review · Owner: quality-security-agent · Commit: <sha> · Scope: <whole repository | folders> · Updated: <ISO>

# Baseline

## 1. Summary
One paragraph: what the product is, how big the codebase is (files, lines, main languages), its overall health in plain words, and the number of debts by severity.

## 2. Scope and boundaries
| Role | Owned paths | Commands (lint · typecheck · test) | Guides |
|---|---|---|---|
| frontend | `apps/web/**` | … | typescript, react |
**Shared files:** <file → owner>. **Unmapped (not adopted):** <folders, why>. Source: `.claude/project.json`.

## 3. Check results (run on the commit above)
| Check | Command | Exit | Result |
|---|---|---|---|
| Lint | <commands.lint> | 0 | clean |
| Typecheck | <commands.typecheck> | 0 | clean |
| Tests | <commands.test> | 0 | 412 passed, 7 quarantined (D-4) |
| Build | <commands.build> | 0 | — |
| Hygiene | check-hygiene.sh | 1 | 23 findings (D-9) |
| Dependency audit | <tool> | 1 | 2 high, 5 moderate (D-11, D-12) |
| Secret scan | <tool> | 0 | none found |
| Migrations | check-migrations.sh | 0 | — |
| Design tokens | check-tokens.sh | 1 | 3 contrast failures (D-14) |
A check that could not run is listed as "not run" with the reason. Never mark an unrun check as passed.

## 4. Quarantined checks (risks to accept at the gate)
| Debt | What is excluded | How (the project's own mechanism) | Why it fails | Proposed fix |
|---|---|---|---|---|
None, or one row per exclusion. The commands in `project.json` are green **with** these exclusions.

## 5. Debt register
| Id | Area | Severity | What | Evidence (file:line, command output) | Proposal | Decision at the gate |
|---|---|---|---|---|---|---|
| D-1 | security | P1 | API key committed in a config file | `config/prod.yml:14` (name only) | fix now | |
| D-2 | architecture | P2 | Controllers query the database directly (no service layer) | `src/api/orders.ts:40-88` | fix when touched | |
| D-3 | tests | P2 | The checkout journey has no automated test | TEST-INVENTORY §3 | fix when touched | |
Severity: **P1** = security hole, data loss, a secret in the repository, a broken build or deploy · **P2** = missing tests on a main journey, a broken standard that slows every change, a vulnerable dependency without a known exploit path · **P3** = cleanup.
Proposal: **fix now** (a ticket before new work) · **fix when touched** (the next ticket in that area includes it) · **accept** (stays as is; the human owns the risk).
The "Decision at the gate" column is filled from the human's answers. Every P1 needs "fix now" or an explicit acceptance.

## 6. Not covered
What the adoption did not read or could not check, and what would be needed.

## 7. Documents in the baseline package
| Document | Depth | Coverage |
|---|---|---|
| PRD.md | light (summary, features, main journeys) | 18 features found |
| contracts | from routes | 41 of 47 operations |
```

Rules:
- Evidence for every row; secret **names** only, never values.
- Keep the register to real, actionable debts: group repeated findings (e.g. "23 hygiene findings") into one debt with the report attached, instead of 23 rows.
- After the gate, each "fix now" debt becomes a ticket (`ticket add … --type chore`), and the debt id goes into the ticket title. "Fix when touched" debts are added to the next ticket in that area by the delivery-planner.
