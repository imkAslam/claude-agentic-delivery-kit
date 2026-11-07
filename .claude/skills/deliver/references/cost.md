# Cost and token efficiency (orchestrator playbook)

Every subagent run costs tokens: its prompt, the skills it preloads, every file it reads and every tool result. The rules below keep a full run affordable without skipping gates, reviews or evidence.

## 1. Profiles (`DELIVERY_PROFILE` in `.claude/settings.json`)
| Setting | `lean` | `standard` (default) | `thorough` |
|---|---|---|---|
| Researcher | Only for an unfamiliar domain | When the scope is broad or unfamiliar | Always |
| Brand directions | 2 (or the audit, if a brand exists) | 3 (or the audit) | 3 + a refinement round |
| Mockups | Key screens: default + one unhappy state each; other states described in the states matrix | Every screen × every state that applies | Every state, desktop + mobile + dark |
| Review rounds cap | 2 | `DELIVERY_MAX_ROUNDS` (3) | 3 |
| Ticket review | One reviewer (the role reviewer); the database or security reviewer only when the diff touches their area | Role reviewer + specialist reviewers by area | Same + a second opinion on P1 areas |
| Security audit (Lane 4) | Automated scans; manual audit only with personal/payment data or public APIs | As the threat model warrants | Always |
| Parallel agents | 2 | `DELIVERY_MAX_PARALLEL` (3) | 4 |
The profile never changes the gates, the hooks, test-first or the evidence rules.

## 2. Model policy (the `model:` in each agent; override per call only as below)
| Tier | Agents | Why |
|---|---|---|
| **opus** | solution-architect, security-auditor | Decisions that are expensive to reverse; adversarial reasoning |
| **sonnet** | every engineer, designer, analyst, planner and reviewer | Strong, much cheaper; the default |
| **haiku** | system-detector, docs-writer | Mechanical detection and documentation upkeep |
**Escalate** to opus for one call (the Agent tool's `model` parameter) only when the same task failed twice on sonnet, or the reviewer reports a P1 design flaw. **De-escalate** to haiku for mechanical reruns (re-rendering, re-running a checker, status updates).

## 3. Context discipline
1. **Briefs carry paths and IDs, never pasted documents** (briefs.md). Name the sections to read (`PRD §4 F-3, §6`), not whole files.
2. **Agents read only what their step needs:** the sections named in INPUTS, plus the references their skill points to for this step. Preloaded skills are limited to each agent's primary skill; the others are listed under Skills & Resources and read on demand.
3. **Return blocks stay short** (SUMMARY ≤ 5 lines). The work lives in files; the orchestrator keeps only return blocks in context.
4. **The orchestrator never reads whole artifacts** to decide routing. It reads return blocks, `delivery-state.sh summary`, and at gates only the summary sections it presents.
5. **Continue, don't respawn.** For correction rounds and follow-up questions, continue the same agent (SendMessage with the id from `delivery-state.sh agent get`); it keeps its context and doesn't re-read everything.
6. **Re-review only what changed.** A correction round's reviewer gets the diff since its last verdict and the open findings, not the whole package again.
7. **Batch small work:** one agent call for related small tickets of the same role in the same files (max 3), instead of one call each.
8. **Skip conditional steps** whose condition doesn't hold, and record why (`delivery-state.sh note`).
9. **Scripts before agents:** deterministic checks (check-tokens, check-diagrams, check-migrations, check-ownership, lint/test commands) run as commands, not as agent reasoning.
10. **Compact at boundaries:** after each gate, the orchestrator's context can be compacted; the SessionStart hook restores the run summary.

## 4. Usage ledger and budget
After every Agent result, record its token count (shown in the tool result) and model:
```bash
bash .claude/skills/deliver/scripts/delivery-state.sh usage add <agent> <model> <tokens>
```
- `usage summary` shows tokens by model, agent and lane; `/delivery-status` shows the total.
- `DELIVERY_TOKEN_BUDGET` (0 = no budget): at 80% the helper prints `BUDGET_WARNING` (mention it in the next gate summary); at 100% it exits 4 with `BUDGET_REACHED`, and the orchestrator **stops and asks the human** (continue with a new budget, switch to `lean`, or pause). That is a major decision.
- Each gate summary includes one line: tokens used in this lane and in total.
