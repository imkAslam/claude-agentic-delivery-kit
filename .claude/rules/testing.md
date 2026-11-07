---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/test/**"
  - "**/tests/**"
  - "**/__tests__/**"
  - "**/e2e/**"
---

# Testing rules

- **Test first.** Write the failing test, run it, and confirm it fails *for the expected reason* before you implement. Paste both the red and the green output into your report.
- Test **behavior from the acceptance criteria** (`AC-…`), not implementation details. Each test name says which criterion it proves.
- Never skip, weaken or delete an existing test to get to green (`.skip`, `xit`, `@skip`, loosened assertions). If a test is wrong, report it. The reviewer decides.
- Run only the commands in `.claude/project.json` (`roles.<role>.commands`, or `commands`). Don't invent commands.
- No real network calls, third-party services or production data in unit tests. Use fixtures, factories and contract-generated mocks.
- Integration tests run against disposable local resources (containers, an in-memory or test database) and clean up after themselves.
- E2E tests use stable selectors (test IDs, roles, labels) and save screenshots as evidence under `docs/delivery/evidence/`.
