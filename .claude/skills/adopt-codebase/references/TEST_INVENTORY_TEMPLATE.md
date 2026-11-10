# TEST-INVENTORY.md template (what the existing tests cover)

Written by the qa-agent in an adopt run, instead of TEST-CASES.md (which is written later, per increment, for the acceptance criteria that increment adds). It tells engineers what safety net exists before they change anything.

```markdown
> Status: in-review · Owner: qa-agent · Commit: <sha> · Updated: <ISO>

# Test inventory

## 1. How to run
| Level | Tool | Command (project.json) | Where the tests live | Duration | Result at the baseline |
|---|---|---|---|---|---|
| Unit | <runner> | <cmd> | `src/**/*.test.ts` | 40 s | 412 passed |
| Integration | | | | | |
| E2E | | | | | not present |
Services the tests need (database, queues) and how they start locally (setup-docker → LOCAL_SERVICES.md, if it exists).

## 2. Coverage by area
| Area / module | Feature (F-…) | Unit | Integration | E2E | Coverage % (if the tool reports it) | Confidence |
|---|---|---|---|---|---|---|
| orders | F-3 | 34 tests | 6 | — | 71% | medium |
Confidence: **high** = the main paths and error cases are tested · **medium** = the happy path only · **low** = little or nothing; change with characterization tests first.

## 3. Journeys without an automated test
| Journey | Feature | Risk if it breaks | Proposed (debt id) |
|---|---|---|---|

## 4. Test quality notes
Flaky or slow tests, skipped tests found in the code (with file and line), tests that hit real external services, missing fixtures or seeds. Each real problem gets a debt id.

## 5. What the tests prove (source for acceptance criteria)
| Behavior | Test (file · name) | Feature |
|---|---|---|
The PRD may cite these as acceptance criteria. Behavior without a test here has no proven AC yet.
```

Rules:
- Run the commands; don't estimate. A suite that could not run is "not run" with the reason.
- Count skipped and quarantined tests separately; they are debt, not coverage.
- Do not write or change tests in lane `adopt`.
