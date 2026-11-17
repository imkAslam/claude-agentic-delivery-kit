---
name: test-app
description: "Runs the product's tests on this machine with one command, using the test database inside the one local database container (or SQLite when Docker is not running), and reports in plain words what passed and what failed."
when_to_use: "Use when the user wants to test the app or check that everything still works (\"run the tests\", \"test the app\", \"is anything broken?\")."
allowed-tools: Bash(bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/app.sh *)
---

# Test the app

1. Run `bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/app.sh test`.
2. Tell the user the result in plain words, in at most five lines:
   - **All passed:** how many tests ran.
   - **Some failed:** which features are affected (name the feature, not only the test file), and whether it looks like a real defect or a setup problem (Docker stopped, database not prepared).
   - **No tests yet:** say so, and when they arrive (with the first feature tickets).
3. Never change or skip a test to make it pass, and never fix product code yourself. A failing test becomes a bug for the owning role through the orchestrator.

The same script works without Claude: `bash .claude/skills/deliver/scripts/app.sh test`.
