---
name: tdd
description: "Test-first loop for role engineers: derive tests from the ticket's acceptance criteria, prove they fail for the right reason, implement the minimum to pass, refactor, and report red/green evidence using only the commands in project.json."
when_to_use: "Use when implementing or fixing any ticket, or when a reviewer asks for missing tests."
user-invocable: false
---

# Test-driven development

1. **Map** each `AC-`/`BR-` id in the ticket to one or more test cases: happy path, boundaries, invalid input, permissions, empty/error states, and concurrency where it applies.
2. **Red:** write the tests and run the role's `test` command (`project.json → roles.<role>.commands.test`). Each new test must **fail for the expected reason** (an assertion or a missing behavior, not a syntax or import error). Save the output.
3. **Green:** implement the smallest change that makes them pass. Re-run. Save the output.
4. **Refactor:** clean up while staying green. Then run `lint` and `typecheck` too.
5. **Regression:** for a bug fix, the first test you write reproduces the bug.
6. **Report:** in `EVIDENCE`, include the red output excerpt, the green output excerpt, and the commands with their exit codes.

## Don't
- Write the implementation before its test exists.
- Change, skip or delete existing tests to make them pass. Report a test you think is wrong.
- Mock the unit under test, or assert on implementation details (private calls, internal state).
- Use a real network, third-party services or production data in unit tests.
