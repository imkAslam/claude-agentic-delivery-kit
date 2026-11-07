---
name: delivery-status
description: "Read-only report of the delivery run: current lane and step, gate decisions and whether their hashes still match, tickets by role and status, open change requests, failures and the next action."
when_to_use: "Use when the user asks where the delivery run is, what is blocked, which gates are approved, or what happens next."
allowed-tools: Bash(bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/delivery-state.sh summary) Bash(bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/delivery-state.sh verify *) Bash(bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/delivery-state.sh usage summary) Bash(bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/delivery-state.sh bugs *)
---

# Delivery status

1. Run `bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/delivery-state.sh summary`. If there's no state file, say no run has started and suggest `/deliver start`. Then run `… delivery-state.sh usage summary` and show the token use by model and lane, and whether coding is approved (g2). Then run `… delivery-state.sh bugs open` and list the open bugs with severity, status and the original ticket each one belongs to.
2. For each approved gate, run `… delivery-state.sh verify <gate>` and flag any gate whose package changed since its approval.
3. If `.claude/project.json` exists, read `tracker.kind` and use the `tracker` skill's `list` operation to compare ticket status with the state file. Report any mismatches.
4. Report, in this order: **Lane / step / milestone** · **Gates** (status, decision, approver, date, hash check) · **Tickets** (count by role × status; list blocked tickets with the reason) · **Open change requests** · **Failures** (the report paths) · **Next action** (from `.claude/skills/deliver/references/workflow.md`).

This skill is read-only: it changes no state, no files and no tickets.
