---
name: start-app
description: "Starts the product on this machine with one command: local services (one database container, or SQLite when Docker is not running), dependencies, migrations, sample data and the app itself, then gives the address to open. Also stops it and shows what is running."
when_to_use: "Use when the user wants to start, run, open, try, stop or check the app locally (\"start the app\", \"run it\", \"is it running?\", \"stop the app\")."
argument-hint: "[start | stop | status]"
allowed-tools: Bash(bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/app.sh *)
---

# Start the app

1. Run `bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/app.sh start` (or `stop` / `status` when the user asked for that).
2. Tell the user the result in plain words, in at most five lines:
   - **Started:** the address to open, which mode it runs in (Docker or SQLite), and where the sample accounts are (README, "Run it locally").
   - **No app yet:** say so, and what has to happen first (the run reaches the first build milestone).
   - **Failed:** which step failed, the one or two lines that explain why, and the most likely fix (start Docker, a port already in use, a missing value in `.env`).
3. Never fix product code yourself. A real defect goes to the owning role as a ticket through the orchestrator.

The same script works without Claude: `bash .claude/skills/deliver/scripts/app.sh start`.
