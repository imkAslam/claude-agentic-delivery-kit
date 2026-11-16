---
name: write-tests
description: "QA toolkit: human-executable test cases traced to acceptance criteria, E2E automation patterns for web (Playwright-style) and mobile (Maestro/Detox-style) with stable selectors and screenshot evidence, and the ACCEPTANCE.md › QA, ACCEPTANCE.md › Open issues and ACCEPTANCE.md › Summary templates with evidence-freshness rules."
when_to_use: "Use when designing PLAN.md › Test cases, automating E2E journeys for QA tickets, executing acceptance testing, or writing ACCEPTANCE.md › QA, ACCEPTANCE.md › Open issues or ACCEPTANCE.md › Summary."
---

# Write tests (QA)

For the **qa-agent** in three modes: **design** (lane plan), **automate** (lane build, QA tickets) and **execute** (lane verify).

## When to Use
- Lane plan: `PLAN.md › Test cases` in parallel with the contracts, UI/UX and DevOps plan
- Lane build: QA tickets that automate the priority journeys
- Lane verify: executing every case, then the acceptance package
- Any time a defect needs a reproducible report

## Instructions

### Step 0: Load the inputs
`PRD.md` (`AC-` ids), `PRD.md › Analysis` (journeys, rules), `DESIGN.md › UX` + mockups (screens, states), contracts (operations, errors), `PLAN.md › Quality` (levels, thresholds), and `project.json` (`stack.e2e`, `stack.mobile_e2e`, `roles.qa.paths`, `commands.e2e`, `dev_url`).

### Step 1: Design mode → PLAN.md › Test cases
Use [TEST_CASE_TEMPLATE.md](references/TEST_CASE_TEMPLATE.md). Write at least one case per `AC-`; add negative, boundary, permission, concurrency and accessibility cases; mark each `manual | e2e | api | mobile` and give its priority (P1 = release-blocking). End with the AC → TC traceability matrix, with no AC left uncovered.

### Step 2: Automate mode (QA tickets)
Follow [E2E_PATTERNS.md](references/E2E_PATTERNS.md): page or screen objects, role- and label-based selectors (test ids as the fallback), data seeded through the API or factories, no dependence on test order, a screenshot at every assertion step under `docs/delivery/milestones/<ms>/screens/<TC-id>/`. Name each test `TC-<n> <title> (AC-…)`. Use the `tdd` skill. A new E2E test must fail against a deliberately broken build or a missing feature before it passes.

### Step 3: Execute mode (lane verify)
1. Record the **candidate commit** (`git rev-parse HEAD`) and the environment (local `dev_url` or staging).
2. Run all the automated suites. Execute the manual cases step by step with browser/device automation, capturing a screenshot per expected result.
3. Write `ACCEPTANCE.md › QA` and add any defects to `ACCEPTANCE.md › Open issues`, per [REPORT_TEMPLATES.md](references/REPORT_TEMPLATES.md).
4. When the orchestrator asks for the acceptance package, write `ACCEPTANCE.md › Summary` (same reference).

## Evidence rules
- A TC without evidence counts as **not run**.
- Evidence older than the candidate commit is **stale**. Re-run it.
- Screenshots must be real captures of the candidate, never mockups.
- Every defect gets steps, expected vs. actual, evidence, severity and the suspected owning role.

## Integration with Other Skills
- **write-requirements:** the `AC-` ids are the source of truth
- **design-inspiration:** visual and accessibility expectations for UI cases
- **tdd / role-boundaries:** QA tickets write only under `roles.qa.paths`
- **gate-review:** ACCEPTANCE.md › QA and ACCEPTANCE.md › Summary form the `acceptance` gate package

## File Structure
```
.claude/skills/write-tests/
├── SKILL.md
└── references/
    ├── TEST_CASE_TEMPLATE.md   # PLAN.md › Test cases format + traceability matrix
    ├── E2E_PATTERNS.md         # web and mobile E2E structure, selectors, data, evidence, flakiness rules
    └── REPORT_TEMPLATES.md     # ACCEPTANCE.md › QA, ACCEPTANCE.md › Open issues, ACCEPTANCE.md › Summary
```
