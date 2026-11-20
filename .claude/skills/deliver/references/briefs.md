# Delegation briefs and the return block

## Brief (orchestrator → subagent)
Every Agent call's prompt follows this shape. A brief tells the agent **exactly** what to deliver: numbered scope, what is out of scope, and how "done" is checked (`.claude/rules/agent-conduct.md`). A vague brief produces a vague result; write it so a stranger could do it. Keep it short: paths, section anchors and IDs, never pasted documents ([cost.md](cost.md) §3). Correction rounds continue the same agent with only the new findings.

```
ROLE: <agent name>   MODE: <plan|build|release|review|alignment|adopt|…>   STEP: <lane>/<step id>   ROUND: <n of max>
GOAL: <one sentence: what "done" means for this call>
SCOPE: 1. <deliverable> 2. <deliverable> 3. …   (numbered; each one checkable)
NOT IN SCOPE: <what must not be touched or added, even if it looks useful>
DONE WHEN: <the checks that must pass: commands, states visible, files present>
INPUTS: <artifact paths + the sections/IDs that matter>
TICKET: <id, title, AC-/BR-/TC- refs, contract operations, depends_on>          (build steps only)
OWNED PATHS: <the globs from project.json roles.<role>.paths>                    (build steps only)
BRANCH: <branch> from <base>   (from `delivery-state.sh branch ticket <id>`; the engineer runs `git switch <branch>` first; reviewers diff `<base>...<branch>`)   (build + review steps)
PRIOR FINDINGS: <numbered findings from the last round, verbatim>               (correction rounds)
INBOX: <M-id from <agent>: message body>, one per line                         (when messages are waiting)
LESSONS: <≤5 lines for this role from docs/delivery/LESSONS.md>                (build + review steps, when any apply)
CODEMAP: docs/CODEMAP.md (read first; before milestone 1 is integrated: PRD §11) (build + review steps)
GUIDES: .claude/skills/coding-foundations/references/OOP_AND_PATTERNS.md + <GUIDE>.md for each roles.<role>.guides  (build + review steps)
COLLABORATORS: <agents you may message for this step, from collaboration.md>
CONSTRAINTS: frozen contracts · no secrets · deploys only via CI · stay in owned paths · engineering-principles + coding-standards (+ database-standards for data work)
RETURN: end with the return block from .claude/skills/deliver/references/briefs.md
```

Each agent preloads only its primary skill(s). Any other skill named in its Skills & Resources table is read on demand from `.claude/skills/<name>/SKILL.md` (and its references), only for the step that needs it.

Reviewer briefs also include the engineer's return block and the diff base. Reviewers never get the engineer's reasoning. They judge the artifact and the evidence only.

## Return block (subagent → orchestrator)
Every subagent ends its final message with exactly this block:

```
RESULT: DONE | CHANGES_REQUESTED | BLOCKED | CONTRACT_CHANGE_NEEDED | NEEDS_HUMAN
VERDICT: APPROVE | CHANGES            (reviewers only)
SUMMARY: <≤5 plain lines>
SCOPE CHECK:                            (one line per numbered SCOPE item)
  1. done — <where: file, command or screen> | not done — <why>
EXTRA: none | <anything outside SCOPE, as a suggestion; it must not have been built>
ARTIFACTS: <paths written or changed>
EVIDENCE: <each command run, its exit code and result line; screenshot paths in milestones/<ms>/screens/ for UI. No saved logs>
FINDINGS:                               (reviewers, the integrator, QA, quality/security)
  - [P1|P2|P3 or CRITICAL|HIGH|MEDIUM|LOW] <file:line or artifact §> — <problem> — <required change>
NEEDS: <dependency/shared-file/contract/human requests, one per line>   (optional)
LESSON: <one reusable rule, phrased as what to do, with the finding ids>  (optional; memory.md §7)
MESSAGES:                               (optional; to other agents through the orchestrator)
  - TO: <agent|role|human> | TYPE: question|request|handoff|finding|info|decision-needed | RE: <id> | BLOCKING: yes|no
    BODY: <one focused message>
ANSWERS:                                (optional; replies to INBOX items)
  - RE: <M-id>
    BODY: <answer>
```
Message types, routing and rules: [collaboration.md](collaboration.md). In a fresh worktree, a role engineer runs `project.json → commands.install` before anything else.

## How the orchestrator reads it
| RESULT | What the orchestrator does |
|---|---|
| `DONE` with artifacts + evidence | Accept, then send it to the step's reviewer (if any) or advance |
| `DONE` with no evidence | Treat it as `BLOCKED: no evidence` and re-brief once, then go to triage |
| `DONE` but the `SCOPE CHECK` is missing, has an unanswered or "not done" item, a "done" with nothing behind it, or `EXTRA` work that was built | **Do not send it to review.** Return it to the same agent with the exact gap (`delivery-state.sh ticket attempt <id>`); it must finish the scope or remove the extra (`.claude/rules/agent-conduct.md`) |
| `CHANGES_REQUESTED` (reviewer) | Send the FINDINGS to the same role, then `delivery-state.sh round <loop>` |
| `CONTRACT_CHANGE_NEEDED` | Pause the dependent tickets and **ask the human** (one question: the change, why, the impact, the recommendation). On yes: `cr-open g2 … --approved-by "<human>"` and a ticket for the api-designer. On no: send it back to the engineer to work within the contract |
| `LESSON` line | Add it to `docs/delivery/LESSONS.md` when it recurs or is P1/CRITICAL ([memory.md](memory.md) §7) |
| `NEEDS` lines | Shared-file/dependency requests become a ticket for the owner listed in `shared_files` |
| `BLOCKED` | Fix the cause if it's within the kit (missing input, wrong path), otherwise stop and ask the human |
| `NEEDS_HUMAN` | Apply the decision policy. A **technical** question goes back to the agent to decide and record. A **business** question with a reasonable default: continue on the default, and queue it for the next gate. Only a blocking business question with no default: ask the human now (AskUserQuestion, plain language, options + recommendation) |
| `MESSAGES` / `ANSWERS` | Log each with `delivery-state.sh msg add|answer`, deliver it per [collaboration.md](collaboration.md) (continue the recipient by agent id, or use the INBOX of its next brief), and route the answers back |
