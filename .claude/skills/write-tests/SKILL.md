---
name: write-tests
description: "QA toolkit: human-executable test cases traced to acceptance criteria, E2E automation patterns for web (Playwright-style) and mobile (Maestro/Detox-style) with stable selectors and screenshot evidence, and the QA-REPORT, OPEN-ISSUES and ACCEPTANCE-REVIEW templates with evidence-freshness rules."
when_to_use: "Use when designing TEST-CASES.md, automating E2E journeys for QA tickets, executing acceptance testing, or writing QA-REPORT.md, OPEN-ISSUES.md or ACCEPTANCE-REVIEW.md."
---

# Write tests (QA)

For the **qa-agent** in three modes: **design** (lane plan), **automate** (lane build, QA tickets) and **execute** (lane verify).

## When to Use
- Lane plan: `TEST-CASES.md` in parallel with the contracts, UI/UX and DevOps plan
- Lane build: QA tickets that automate the priority journeys
- Lane verify: executing every case, then the acceptance package
- Any time a defect needs a reproducible report

## Instructions

### Step 0: Load the inputs
`PRD.md` (`AC-` ids), `BA-ANALYSIS.md` (journeys, rules), `UI-UX.md` + mockups (screens, states), contracts (operations, errors), `QUALITY-RELEASE-PLAN.md` (levels, thresholds), and `project.json` (`stack.e2e`, `stack.mobile_e2e`, `roles.qa.paths`, `commands.e2e`, `dev_url`).

### Step 1: Design mode → TEST-CASES.md
Use [TEST_CASE_TEMPLATE.md](references/TEST_CASE_TEMPLATE.md). Write at least one case per `AC-`; add negative, boundary, permission, concurrency and accessibility cases; mark each `manual | e2e | api | mobile` and give its priority (P1 = release-blocking). End with the AC → TC traceability matrix, with no AC left uncovered.

### Step 2: Automate mode (QA tickets)
Follow [E2E_PATTERNS.md](references/E2E_PATTERNS.md): page or screen objects, role- and label-based selectors (test ids as the fallback), data seeded through the API or factories, no dependence on test order, a screenshot at every assertion step under `docs/delivery/evidence/<TC-id>/`. Name each test `TC-<n> <title> (AC-…)`. Use the `tdd` skill. A new E2E test must fail against a deliberately broken build or a missing feature before it passes.

### Step 3: Execute mode (lane verify)
1. Record the **candidate commit** (`git rev-parse HEAD`) and the environment (local `dev_url` or staging).
2. Run all the automated suites. Execute the manual cases step by step with browser/device automation, capturing a screenshot per expected result.
3. Write `QA-REPORT.md` and add any defects to `OPEN-ISSUES.md`, per [REPORT_TEMPLATES.md](references/REPORT_TEMPLATES.md).
4. When the orchestrator asks for the acceptance package, write `ACCEPTANCE-REVIEW.md` (same reference).

## Evidence rules
- A TC without evidence counts as **not run**.
- Evidence older than the candidate commit is **stale**. Re-run it.
- Screenshots must be real captures of the candidate, never mockups.
- Every defect gets steps, expected vs. actual, evidence, severity and the suspected owning role.

## Integration with Other Skills
- **write-requirements:** the `AC-` ids are the source of truth
- **design-inspiration:** visual and accessibility expectations for UI cases
- **tdd / role-boundaries:** QA tickets write only under `roles.qa.paths`
- **gate-review:** QA-REPORT and ACCEPTANCE-REVIEW form the `acceptance` gate package

## File Structure
```
.claude/skills/write-tests/
├── SKILL.md
└── references/
    ├── TEST_CASE_TEMPLATE.md   # TEST-CASES.md format + traceability matrix
    ├── E2E_PATTERNS.md         # web and mobile E2E structure, selectors, data, evidence, flakiness rules
    └── REPORT_TEMPLATES.md     # QA-REPORT, OPEN-ISSUES, ACCEPTANCE-REVIEW
```
