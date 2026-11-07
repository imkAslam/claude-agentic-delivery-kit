# Memory and context: how a long run remembers

**Files are the memory; context is scratch space.** Anything that must survive a compaction, a restart or a new session is written to disk at the moment it happens. Nothing important lives only in a conversation.

## 1. Three layers
| Layer | Where | Holds | Survives compaction / restart |
|---|---|---|---|
| **Run state** | `.claude/delivery/state.json` (only via `delivery-state.sh`) | Lane, step, milestone, gates + hashes, tickets + attempts, rounds, CRs, messages, failures, usage, agent ids, notes | Yes (local, git-ignored) |
| **Project knowledge** | `docs/` (PRD, architecture, data model, contracts, tickets, ADRs, FEATURES, DATABASE, CODEMAP, LESSONS, GATE-LOG, MESSAGES) | Every decision, requirement and design, and why | Yes (committed) |
| **Working context** | The orchestrator's conversation; each subagent's own context window | The current step only | No, by design |

The kit does **not** rely on Claude Code's personal auto memory for project facts. That memory belongs to one user on one machine; project knowledge belongs in `docs/` where every agent and teammate can read it.

## 2. Keeping each context small
- **One window per agent.** A subagent loads its brief, the sections it names and its primary skill. When it returns, its context is discarded; the orchestrator keeps only the return block (SUMMARY ≤ 5 lines).
- **Briefs point, never paste** ([cost.md](cost.md) §3): `PRD §4 F-3`, not the PRD.
- **The orchestrator routes from summaries:** return blocks, `delivery-state.sh summary`, `msg open`. It never reads whole artifacts to decide what to do next.
- **Scripts before reasoning:** checks run as commands; only their exit code and a short excerpt enter context.
- **Worktrees isolate build work:** one worktree per ticket, so parallel agents never share files or context.

## 3. Append-only logs: never read them whole
`docs/delivery/MESSAGES.md`, `GATE-LOG.md`, `LESSONS.md`, `failures/` and `git log` only grow. Read them by query:
- open messages: `delivery-state.sh msg open`; one thread: `grep -n "M-012" docs/delivery/MESSAGES.md`
- recent gate decisions: `tail -n 30 docs/delivery/GATE-LOG.md`
- lessons for one role: `grep -n "\[backend\]\|\[all\]" docs/delivery/LESSONS.md`
- history: `git log --oneline -20`, `git log --oneline -- <path>`

## 4. Checkpoints
- Run state changes **when the event happens** (`set-step`, `ticket status`, `round`, `agent set`, `usage add`), never in a batch at the end of a step.
- Before a step that spans many agent calls (a build fork, a long correction loop), write one checkpoint: `delivery-state.sh note "checkpoint: <step> — done: <ids>; next: <ids>"`. `summary` shows the last note, so a resumed session knows where inside the step it was.

## 5. Compaction and new sessions
1. Claude Code compacts the orchestrator's conversation automatically when it fills up. The human can also run `/compact` (the orchestrator can't run it itself); the gate summary suggests it after each decision, which is the cheapest moment.
2. The SessionStart hook (`startup|resume|compact`) prints the run summary, the last checkpoint, the coding status and the lessons count.
3. The orchestrator re-reads **only** the current step in [workflow.md](workflow.md) and continues. Approved gates are never redone.

## 6. Continuing agents, and when that fails
- Correction rounds and follow-ups continue the same agent (`delivery-state.sh agent get <key>` → SendMessage), so it doesn't re-read everything.
- **Fallback:** an agent id from an earlier session, or one whose context was itself compacted away, may not be reachable. If SendMessage fails or the agent no longer knows the task, start a fresh agent of the same type with the **original brief + its last return block + the open findings**, then `agent set <key> <new-id>`. Nothing is lost: the work is on disk.
- Don't continue one agent forever. After 3 correction rounds or a changed ticket scope, start fresh with a clean brief.

## 7. Lessons log: learning across tickets
`docs/delivery/LESSONS.md` (owner: orchestrator) stops the team repeating the same mistake.
- **When to add:** a reviewer finding of the same kind appears in **2 or more tickets**; a P1/CRITICAL finding; a triage root cause; an environment gotcha that cost an attempt. Agents can propose one with the optional `LESSON:` line of the return block.
- **Format:** one line, `- [<role>|all] <rule, phrased as what to do> (from <ticket/finding ids>, <date>)`. Example: `- [backend] Check tenant ownership in the service layer for every by-id read (T-014 P1, T-019 P2, 2026-03-04)`.
- **Use:** each build or review brief carries `LESSONS:` with at most 5 lines for that role (grep, never the whole file).
- **Keep it short:** at most 30 active lines. At each milestone close, merge duplicates, move lines that became a checklist item or rule to `## Retired`, and keep the reason.
- Lessons are technical guidance, never business decisions, never secrets.

## 8. Code map: finding code without exploring
`docs/CODEMAP.md` (owner: docs-writer, `milestone` mode; [CODEMAP_TEMPLATE.md](../../write-docs/references/CODEMAP_TEMPLATE.md)) lists modules, entry points, where each feature lives, and the shared files with their owners, in at most about 150 lines.
- Before milestone 1 there is no code: engineers use the planned folder structure in PRD §11.
- Build briefs list `docs/CODEMAP.md` in INPUTS. Engineers read it first, then open only the files it points to; they search (`grep`) instead of reading whole directories.
- A stale map is a finding for the docs-writer, not a reason to explore the whole repository.
