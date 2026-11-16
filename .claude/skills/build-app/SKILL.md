---
name: build-app
description: "Builds the product on this machine with one command (the same production build the pipeline runs) and reports in plain words whether it succeeded and what failed."
when_to_use: "Use when the user wants to build the app or check that it builds (\"build the app\", \"does it build?\")."
allowed-tools: Bash(bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/app.sh *)
---

# Build the app

1. Run `bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/app.sh build`.
2. Tell the user the result in plain words, in at most five lines:
   - **Succeeded:** say so. A local build is a check only; releases still go through the pipeline after the release approval.
   - **Failed:** which part failed and the one or two lines that explain why.
   - **No build yet:** say so, and when it arrives (with the foundation tickets).
3. Never deploy from this machine, and never fix product code yourself. A build failure becomes a ticket for the owning role through the orchestrator.

The same script works without Claude: `bash .claude/skills/deliver/scripts/app.sh build`.
