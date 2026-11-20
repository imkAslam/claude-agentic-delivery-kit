# Cost and token efficiency (orchestrator playbook)

Every subagent run costs tokens: its prompt, the skills it preloads, every file it reads and every tool result. The rules below keep a full run affordable without skipping gates, reviews or evidence.

## 1. Profiles (`DELIVERY_PROFILE` in `.claude/settings.json`)
| Setting | `lean` | `standard` (default) | `thorough` |
|---|---|---|---|
| Researcher | Only for an unfamiliar domain | When the scope is broad or unfamiliar | Always |
| Brand directions | 2 (or the audit, if a brand exists) | 3 (or the audit) | 3 + a refinement round |
| Mockups | Key screens: default + one unhappy state; other states described in the states matrix | The same (key screens only) | Every screen and state, desktop + mobile + dark |
| Review rounds cap | 2 | `DELIVERY_MAX_ROUNDS` (3) | 3 |
| Ticket review | One reviewer (the role reviewer); the database or security reviewer only when the diff touches their area | Role reviewer + specialist reviewers by area | Same + a second opinion on P1 areas |
| Performance review | The candidate only (Lane 4) | Each milestone that changes screens or data paths + the candidate | Every milestone + the candidate |
| Security audit (Lane 4) | Automated scans; manual audit only with personal/payment data or public APIs | As the threat model warrants | Always |
| Parallel agents | 2 | `DELIVERY_MAX_PARALLEL` (3) | 4 |
| Documents | The lean set ([documents.md](documents.md)) in every profile | | |
The profile never changes the gates, the hooks or the testing rule.

## 2. Model policy (the `model:` in each agent; override per call only as below)
| Tier | Agents | Why |
|---|---|---|
| **opus** | solution-architect, security-auditor | Decisions that are expensive to reverse; adversarial reasoning |
| **sonnet** | every engineer, designer, analyst, planner and reviewer (including the performance-specialist) | Strong, much cheaper; the default |
| **haiku** | system-detector, docs-writer | Mechanical detection and documentation upkeep |
**Escalate** to opus for one call (the Agent tool's `model` parameter) only when the same task failed twice on sonnet, or the reviewer reports a P1 design flaw. **De-escalate** to haiku for mechanical reruns (re-rendering, re-running a checker, status updates).

## 3. Context discipline
1. **Briefs carry paths and IDs, never pasted documents** (briefs.md). Name the sections to read (`PRD §4 F-3, §6`), not whole files.
2. **Agents read only what their step needs:** the sections named in INPUTS, plus the references their skill points to for this step. Preloaded skills are limited to each agent's primary skill; the others are listed under Skills & Resources and read on demand.
3. **Return blocks stay short** (SUMMARY ≤ 5 lines). The work lives in files; the orchestrator keeps only return blocks in context.
4. **The orchestrator never reads whole artifacts** to decide routing. It reads return blocks, `delivery-state.sh summary`, and at gates only the summary sections it presents.
5. **Continue, don't respawn.** For correction rounds and follow-up questions, continue the same agent (SendMessage with the id from `delivery-state.sh agent get`); it keeps its context and doesn't re-read everything. If the id can't be reached (an earlier session), start a fresh agent with the original brief, its last return block and the open findings ([memory.md](memory.md) §6).
6. **Re-review only what changed.** A correction round's reviewer gets the diff since its last verdict and the open findings, not the whole package again.
7. **Batch small work:** one agent call for related small tickets of the same role in the same files (max 3), instead of one call each.
8. **Skip conditional steps** whose condition doesn't hold, and record why (`delivery-state.sh note`).
9. **Scripts before agents:** deterministic checks (check-tokens, check-diagrams, check-migrations, check-ownership, lint/test commands) run as commands, not as agent reasoning.
10. **Compact at boundaries:** each gate summary ends by suggesting `/compact` to the human (the orchestrator can't run it); automatic compaction covers the rest. The SessionStart hook restores the run summary and the last checkpoint ([memory.md](memory.md) §5).
11. **Query logs, never read them whole:** GATE-LOG.md, LESSONS.md, `failures/` and `git log` only grow; use `msg open`, `grep -n <id>`, `tail` ([memory.md](memory.md) §3).
12. **Code map before code:** build briefs point to `docs/CODEMAP.md`; engineers open only the files it names and search with `grep` instead of reading directories ([memory.md](memory.md) §8).

## 4. Usage ledger and budget
The ledger records the **tokens the provider reported**, not an estimate. Claude Code writes the API's `usage` on every assistant line of its transcripts. The `record-usage.sh` hook reads them whenever the main session ends a turn (`Stop`), a subagent finishes (`SubagentStop`) and a session ends (`SessionEnd`), then runs `delivery-state.sh usage sync`. Nobody types a number.
- **What is counted:** every API call of the main session (the orchestrator) and of every subagent, each response once (Claude Code writes one response as several lines), from the moment the run started (`started_at` in the state). It counts the four numbers the provider bills separately: **input, cache writes, cache reads and output**. The total is their sum.
- **Why not the Agent result's token count:** that number is the size of the agent's last turn, not what the agent used across all its calls. It also leaves out the orchestrator. On a real run it was under 1% of the provider's total.
- **Attribution:** usage goes to the lane and step the run is on when it is synced. A continued agent adds only what it used since its last sync. A repeated sync adds nothing.
- **Catch-up:** `delivery-state.sh usage sync --all` re-reads every session of this project since the run started, for example after the hooks were off. `--since <ISO>` sets the start time for runs created before `started_at` existed.
- **Reading it:** `usage summary` shows the total with its four parts and the API calls, then by model, agent (with its runs) and lane. `/delivery-status` and `stats` show it too. Cache reads are usually most of the total; they cost about a tenth of fresh input, so give the human the four parts next to the total.
- **Budget:** the one the human approved (`usage budget <tokens> --approved-by "<name>"`, recorded with a note), else `DELIVERY_TOKEN_BUDGET` (0 = none), counted on the same total. At 80% the helper prints `BUDGET_WARNING` (mention it in the next gate summary). At 100%, `guard-budget.sh` blocks every new or continued agent (Agent, Task, SendMessage) and the helper exits 4 with `BUDGET_REACHED`. The orchestrator **stops and asks the human**: raise the budget, switch to `lean`, or pause. That is a major decision.
- Each gate summary includes one line: tokens used in this lane and in total, with the four parts.
