# Milestone package templates (`docs/delivery/milestones/<ms>/`)

## REVIEW.md › Build
```markdown
> Status: in-review · Owner: integrator · Milestone: <ms> · Branch: <ms>/integration @ <sha> · Updated: <ISO>

# Build review: <ms>
## Goal
<the usable journey from PLAN.md › Milestones>

## What was built
| Feature | AC met | Tickets | Evidence |
|---|---|---|---|
| <feature> | AC-…, AC-… | T-…, T-… | evidence/<file>.png |

## Not done / deviations
Items moved out of scope, deviations from the mockups (with reasons), known issues.

## Codebase hygiene
The `check-hygiene.sh` summary line; the chore tickets that removed leftovers (ticket, role, what was removed); open warnings and allow-list entries with their reasons.

## Reviewers' notes
A summary of the role reviewers' P3 findings that are still open.
```

## REVIEW.md › Tickets
```markdown
| Ticket | Role | Title | Commit | Reviewer verdict | Attempts |
|---|---|---|---|---|---|
| T-005 | backend | createOrder | <sha> | APPROVE | 1 |
```

## REVIEW.md › Checks
```markdown
| Check | Command | Exit | Summary |
|---|---|---|---|
| Ownership | check-ownership.sh (per ticket) | 0 | all clean |
| Lint | <commands.lint> | 0 | — |
| Typecheck | <commands.typecheck> | 0 | — |
| Tests | <commands.test> | 0 | 214 passed |
| Build | <commands.build> | 0 | artifact size … |
| Hygiene | check-hygiene.sh | 0 | 0 findings, 2 warnings (listed in REVIEW.md › Build) |
| E2E journey | <commands.e2e> / manual walk | 0 | TC-001..TC-007 passed |
| CI (if pushed) | pipeline <link> | green | — |
```

## REVIEW.md › Run guide
```markdown
# How to run and try <ms>
1. Prerequisites: <runtime versions, docker>
2. `<commands.install>`
3. Copy `.env.example` to `.env` and fill in the local values (no production secrets)
4. `<commands.dev>` → open <dev_url>
5. Seed demo data: `<seed command>`; demo accounts are listed in the seed file (local only)
6. Try it: <step-by-step journey with the expected results>
```
