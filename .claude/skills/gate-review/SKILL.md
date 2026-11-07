---
name: gate-review
description: "Presents a human gate's review package, asks the human for a decision, and records the approval tied to the package's file hashes. Covers intake, g1, g2, milestone build review, acceptance, g3 and ops_ack. Also opens and closes change requests on approved artifacts."
when_to_use: "Use when the delivery workflow reaches a gate step, when the user asks to approve, reject or review a gate, or when an approved artifact needs a change request."
argument-hint: "<gate-id> [cr-open|cr-close]"
allowed-tools: Bash(bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/delivery-state.sh *)
---

# Gate review

Gate definitions, packages and reviewers: [gates.md](../deliver/references/gates.md).
State helper: `bash ${CLAUDE_PROJECT_DIR}/.claude/skills/deliver/scripts/delivery-state.sh`.

## Procedure
1. **Identify the gate** (`$ARGUMENTS`, or the current step in the run state). Look up its package in `gates.md`. For `mbr:<ms>`, use the current milestone folder.
2. **Check the package:** every listed file exists and is non-empty. Each artifact header says `Status: in-review`. No `QUESTION:` marked critical is unanswered. If anything is missing, don't present the gate. Send it back to the owning agent.
3. **Filter the questions** with `.claude/rules/decision-policy.md`. Collect the queued business questions for this gate, drop any technical ones (send them back to their agent to decide), merge duplicates, and keep **at most 5**, each in plain language with options, the consequences and a recommended default.
4. **Present** a summary of no more than about 25 lines:
   - **Decisions made (for information):** the key technical choices by the agents, one line each with the ADR link. Not asked about, but the human may override them.
   - What's being decided, and what approval unlocks
   - Key content: scope or stack, or milestone results, or release identity, depending on the gate. For `g1`, point the human to the diagrams **inside the PRD** (§10 D1 main system diagram and "Why this architecture", §12 the rest) and quote the latest `check-diagrams.sh` result. Also show the brand directions: the board PNG paths from `BRAND-DIRECTIONS.md`, one line per direction and the recommendation, asked as one business question ("Which visual direction?")
   - Open questions and assumptions, risks and their consequences
   - Evidence links (paths) and reviewer verdicts from the AI reviews
   - The package file list, plus the living documents for information (not approved, not frozen): `docs/FEATURES.md`, `docs/database/DATABASE.md`, `docs/adr/README.md`
   - One line of cost: tokens used in this lane and in total (`delivery-state.sh usage summary`), and any `BUDGET_WARNING`
5. **Ask** with AskUserQuestion: the gate decision plus the filtered business questions (at most 5 questions in all, each with its recommended default as the first option). For the gate decision, use the gate's decision options from `gates.md` (for example *Approve*, *Revise PRD*, *Revise architecture*), plus an "Other" for notes. Name the gate in the question. **For `g2`, the question says it plainly: "Approve the plan and start coding?"**, and the summary lists what will be built first (milestone 1 tickets) and the expected cost drivers. For `g1`, say that approving it does **not** start coding. Ask for the approver's name or role in the same question's notes, or in a second question if the reviewers listed for the gate include more than one party.
6. **Record:**
   - For an approve/start/accept/acknowledge decision: `delivery-state.sh approve <gate> <decision> "<approver>" "<notes>" <package paths…>`, then set the artifact headers to `Status: approved (<gate>)`, and set every `proposed` ADR the package relies on to `accepted (<gate>, <date>)` (the docs-writer updates the ADR index at its next run).
   - For `g3`, run `delivery-state.sh release "<name>" "<artifact>" "<environment>"` **before** approving, so the release identity is part of the record.
   - For a revise/hold/fixes/bug-feedback decision: `delivery-state.sh reject <gate> <decision> "<approver>" "<notes>"`, then hand the human's notes to the orchestrator as findings for the correction loop named in `workflow.md`.
7. **Confirm** by running `delivery-state.sh verify <gate>` after an approval. Report the result.

## Change requests (`cr-open` / `cr-close`)
- Open one when an approved artifact must change, **only after the human says yes** (AskUserQuestion: what changes, why, the impact on scope, cost and timeline, the recommendation): `delivery-state.sh cr-open <gate> "<reason>" --approved-by "<human>" <paths…>`. This invalidates the gate. The owning agent edits the files, and then this gate is presented again (steps 2–6).
- Close it after the re-approval: `delivery-state.sh cr-close <CR-id>`.
- **g1 re-confirmation after `prd-sync`:** present it right before g2, in the same sitting, as a short list of the changed diagram ids with "no requirement change" (gates.md). It counts toward the 5-question limit as one question.

## Never
- Approve without an explicit human answer in this session, for this gate.
- Reuse an earlier approval for a different gate or milestone.
- Edit the package while it's being presented.
