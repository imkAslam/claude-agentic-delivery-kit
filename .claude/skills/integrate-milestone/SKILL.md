---
name: integrate-milestone
description: "Integration procedure at the accepted-lanes join: squash-merge approved ticket branches in dependency order into their target (the milestone integration branch, or the release branch for late bug fixes), enforce ownership, regenerate lockfile and contract clients, run combined checks and a real end-to-end journey, emit triage findings on failure, and write the Milestone Build Review package on success."
when_to_use: "Use when a set of approved tickets in a milestone is ready to be joined, or when re-running integration after triage fixes."
---

# Integrate milestone

For the **integrator** in lane `build`, step `integrate`. On success, it produces the **mbr:<ms>** gate package.

## When to Use
- Every time the orchestrator has a batch of `approved` tickets for the current milestone
- After triage fixes are approved, to re-integrate
- Before the Milestone Build Review gate, to build the package

## Instructions

### Step 0: Prepare
1. Inputs from the brief: the **target** branch (`ms-<n>/integration`, or `release/<version>` for bug tickets found in verify or release), the approved tickets with their recorded branches (`delivery-state.sh ticket show <id>` → `branch`, `base`; every base must equal the target), and the merge order (topological by `depends_on`).
2. `git fetch` (if a remote exists); check out the target. The orchestrator created it at dispatch (`delivery-state.sh branch milestone` / `branch release`); if it is missing, stop and report. The working tree must be clean.

### Step 1: Ownership check, then squash-merge (per ticket, in order)
```bash
bash .claude/skills/deliver/scripts/check-ownership.sh <branch> <role>   # exit 1 → stop, report the violation
git checkout -q <branch> && bash .claude/skills/design-database/scripts/check-migrations.sh --base <target>; git checkout -q <target>   # only if the branch touches migrations; exit 1 → stop, report
first=$(git rev-list --reverse <target>..<branch> | head -n 1)           # the ticket's Conventional Commit
git merge --squash <branch>                                               # conflict → git reset --merge, report
git commit -C "$first"                                                    # one commit per ticket (git.md); commit-gate.sh runs the checks
```
The squash keeps the history to one commit per ticket, whatever the number of correction rounds. Never resolve a conflict by editing another role's code. Report `FINDING: conflict — <files> — <ticket A> vs <ticket B>`.

### Step 2: Regenerate shared artifacts
Run `commands.install` (you own the lockfile and the root manifest), then `contracts.codegen_cmd`. Commit the regenerated files: `chore(integration): regenerate lockfile and clients` with `Refs: <ms>`.

### Step 3: Combined checks
Run `commands.lint`, `typecheck`, `test`, `build`. Capture each exit code and an output summary.

### Step 3b: Hygiene check (keep the codebase clean)
```bash
bash ${CLAUDE_SKILL_DIR}/scripts/check-hygiene.sh        # whole tree; exit 1 = leftovers found
bash ${CLAUDE_SKILL_DIR}/scripts/check-hygiene.sh --base delivery-baseline   # adopt runs (run summary shows "Mode: adopt"): only code changed since the baseline
```
It reports scaffold leftovers, stray files, debug output, TODOs without a ticket, unused code (through `commands.unused` when the architect pinned one), and dead links in the living docs. **You never delete another role's files.** Each finding becomes `FINDING: hygiene — <check> — <file:line> — <owning role>`; the orchestrator opens one chore ticket per owning role, fixed before `mbr`. Warnings (commented-out code, empty folders) are listed in REVIEW.md › Build. A deliberate exception goes into `project.json → hygiene.allow` with a reason (a request to the solution-architect, who owns that file).

### Step 4: Real journey
Start the app with `bash .claude/skills/deliver/scripts/app.sh start` (it starts the one set of local services, prepares the database and waits for `dev_url`); stop it with `app.sh stop --app` afterwards (the app only: the local services keep running for everyone). If `app.sh start`, `test` or `build` does not work as a single command, that is a finding for the devops role. Walk the milestone's journey from PLAN.md › Milestones across the UI → API → database: use `commands.e2e` where QA has automated it, otherwise browser automation. Save screenshots and logs to `docs/delivery/milestones/<ms>/screens/`. Stop the dev server afterwards.

### Step 5: Outcome
- **Fail:** return one finding per issue: `FINDING: <UI|API|data|pipeline|security|scope> — <symptom> — <evidence path> — <suspected ticket>`. The orchestrator triages.
- **Pass:** write the package from [MILESTONE_TEMPLATES.md](references/MILESTONE_TEMPLATES.md) into `docs/delivery/milestones/<ms>/`.

## Rules
- Edit only the files you own (the `shared_files` mapped to `integrator`) and the milestone docs.
- No force-push, no history rewrite, no `--no-verify`.
- You merge only into the target. `ms-<n>/integration` reaches `develop` after the `mbr` gate, and `release/<version>` reaches `main` after `g3`, both through a PR/MR with a merge commit (the **ci** skill), never by you.

## Integration with Other Skills
- **deliver** (`references/triage.md`): how the findings get routed
- **ci:** `open-pr` after the gate
- **gate-review:** presents the milestone package

## File Structure
```
.claude/skills/integrate-milestone/
├── SKILL.md
├── references/
│   └── MILESTONE_TEMPLATES.md   # REVIEW.md › Build, REVIEW.md › Tickets, REVIEW.md › Checks, REVIEW.md › Run guide
└── scripts/
    └── check-hygiene.sh         # leftovers: scaffold files, stray files, debug output, ticketless TODOs, unused code, dead doc links
```
