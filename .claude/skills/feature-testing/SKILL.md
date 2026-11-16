---
name: feature-testing
description: "How role engineers test their work: build the ticket's whole module first, then prove its acceptance criteria with feature-level tests (API behavior per operation group, screen behavior per state), with unit tests only for complex logic, using the project's one database container and only the commands in project.json."
when_to_use: "Use when implementing or fixing any ticket, when deciding what to test and at which level, or when a reviewer asks for missing tests."
user-invocable: false
---

# Feature testing: build it, then test it

Tests exist to prove the feature works for the user, not to mirror the code. Build the whole module the ticket asks for, then test it where it meets the outside world.

## The order
1. **Build the whole module.** Every operation, screen and state in the ticket's checklist, wired together and running. Do not stop after each function to write a test.
2. **Run it.** Start the app or call the API yourself and walk the main path once. Fix what is obviously broken before writing tests.
3. **Write the feature tests** from the acceptance criteria:
   - **Backend:** one test group per operation group, through the real HTTP layer and the test database: the happy path, each validation and permission rule, each error the contract defines, and concurrency where the rule mentions it.
   - **Frontend / mobile:** one test group per screen, through what the user sees: each state (loading, empty, error, success, no permission), the form rules, and the calls it makes (against the contract mocks).
   - Name each test after the criterion it proves (`AC-ORD-2: missing postcode shows an error`).
4. **Add unit tests only for complex logic:** calculations, permission rules, state machines, parsers, data transformations. A function that only passes data along needs none.
5. **Run the role's `lint`, `typecheck` and `test`** (`project.json → roles.<role>.commands`). All green before you report.
6. **Report:** the test command, its result line (passed / failed counts) and which AC each group covers. No saved logs.

## What is tested elsewhere
- **End-to-end journeys:** once per milestone by QA, after integration. Do not write them inside a feature ticket.
- **Performance, hygiene, design fidelity:** the milestone checks.

## Two cases where the test comes first
- **A bug fix:** first one test that reproduces the bug (it fails), then the fix (it passes).
- **Existing code without tests (adopted codebases):** first characterization tests that pin what the code does today (they pass on the unchanged code), then the change and its feature tests. If today's behavior looks like a bug, pin it anyway and report it as a `finding`.

## The test database
One database container serves development and tests. Tests use a separate database inside it (`<app>_test`), created and migrated by the test setup. Never start another container, a separate compose project or Testcontainers. Without Docker, tests run on SQLite through the ORM (`setup-docker` → `references/NO_DOCKER.md`).

## Don't
- Write a test for every function, getter or mapping.
- Change, skip or delete an existing test to get to green. Report a test you think is wrong.
- Mock the thing under test, or assert on private calls and internal state.
- Call a real network, a third-party service or production data.
- Report "tested" without the command and its result.
