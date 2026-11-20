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

- **Build the feature, then test it.** Finish the ticket's whole module first; then write tests at **feature level** before review: API behavior per operation group, screen behavior per state. Do not write a test for every function.
- **Unit tests only where logic is complex:** calculations, permissions, state machines, parsers, data transformations.
- **End-to-end journeys are tested once per milestone,** by QA after integration, not inside each ticket.
- A bug fix starts with one test that reproduces the bug. Code adopted without tests is pinned with characterization tests before it changes.
- A ticket without feature tests for its acceptance criteria is not approved. Put the test command and its result line in your report.
- Test **behavior from the acceptance criteria** (`AC-…`), not implementation details. Each test name says which criterion it proves.
- Never skip, weaken or delete an existing test to get to green (`.skip`, `xit`, `@skip`, loosened assertions). If a test is wrong, report it. The reviewer decides.
- Run only the commands in `.claude/project.json` (`roles.<role>.commands`, or `commands`). Don't invent commands. While building, you may narrow the role's test command with its own runner's filter (a test file or test name) for fast feedback. **Before you report, run the role's full lint, typecheck and test commands unnarrowed**; that result line goes in the return block. `commit-gate.sh` runs them again before every commit.
- No real network calls, third-party services or production data in unit tests. Use fixtures, factories and contract-generated mocks.
- **One database container.** Tests use a separate **database inside the same container** as development (`<app>_test`, created and migrated by the test setup; one per parallel worker when needed) and clean up after themselves. Never start a second database container, a separate compose project or Testcontainers. Without Docker: SQLite files through the ORM (`setup-docker` → NO_DOCKER.md).
- E2E tests use stable selectors (test IDs, roles, labels). Results go in the return block; save one screenshot per screen to `docs/delivery/milestones/<ms>/screens/`, never logs or per-test folders.
