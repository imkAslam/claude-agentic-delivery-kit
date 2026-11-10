---
name: integrate-milestone
description: "Integration procedure at the accepted-lanes join: merge approved role branches in dependency order into the milestone integration branch, enforce ownership, regenerate lockfile and contract clients, run combined checks and a real end-to-end journey, emit triage findings on failure, and write the Milestone Build Review package on success."
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
1. Inputs from the brief: milestone `ms-<n>`, the approved tickets with their branches, and the merge order (topological by `depends_on`).
2. `git fetch` (if a remote exists); check out `ms-<n>/integration`, creating it from the default branch if it's missing. The working tree must be clean.

### Step 1: Ownership check, then merge (per ticket, in order)
```bash
bash .claude/skills/deliver/scripts/check-ownership.sh <branch> <role>   # exit 1 → stop, report the violation
git checkout -q <branch> && bash .claude/skills/design-database/scripts/check-migrations.sh --base ms-<n>/integration; git checkout -q ms-<n>/integration   # only if the branch touches migrations; exit 1 → stop, report
git merge --no-ff --no-edit <branch>                                      # conflict → git merge --abort, report
```
Never resolve a conflict by editing another role's code. Report `FINDING: conflict — <files> — <ticket A> vs <ticket B>`.

### Step 2: Regenerate shared artifacts
Run `commands.install` (you own the lockfile and the root manifest), then `contracts.codegen_cmd`. Commit the regenerated files: `chore(integration): regenerate lockfile and clients` with `Refs: <ms>`.

### Step 3: Combined checks
Run `commands.lint`, `typecheck`, `test`, `build`. Capture each exit code and an output summary.

### Step 3b: Hygiene check (keep the codebase clean)
```bash
bash ${CLAUDE_SKILL_DIR}/scripts/check-hygiene.sh        # whole tree; exit 1 = leftovers found
```
It reports scaffold leftovers, stray files, debug output, TODOs without a ticket, unused code (through `commands.unused` when the architect pinned one), and dead links in the living docs. **You never delete another role's files.** Each finding becomes `FINDING: hygiene — <check> — <file:line> — <owning role>`; the orchestrator opens one chore ticket per owning role, fixed before `mbr`. Warnings (commented-out code, empty folders) are listed in BUILD-REVIEW. A deliberate exception goes into `project.json → hygiene.allow` with a reason (a request to the solution-architect, who owns that file).

### Step 4: Real journey
Start `commands.dev` (in the background) and wait for `dev_url` + the health path. Walk the milestone's journey from DELIVERY-PLAN across the UI → API → database: use `commands.e2e` where QA has automated it, otherwise browser automation. Save screenshots and logs to `docs/delivery/milestones/<ms>/evidence/`. Stop the dev server afterwards.

### Step 5: Outcome
- **Fail:** return one finding per issue: `FINDING: <UI|API|data|pipeline|security|scope> — <symptom> — <evidence path> — <suspected ticket>`. The orchestrator triages.
- **Pass:** write the package from [MILESTONE_TEMPLATES.md](references/MILESTONE_TEMPLATES.md) into `docs/delivery/milestones/<ms>/`.

## Rules
- Edit only the files you own (the `shared_files` mapped to `integrator`) and the milestone docs.
- No force-push, no history rewrite, no `--no-verify`.
- The default branch changes only after the `mbr` gate (PR/MR through the **ci** skill).

## Integration with Other Skills
- **deliver** (`references/triage.md`): how the findings get routed
- **ci:** `open-pr` after the gate
- **gate-review:** presents the milestone package

## File Structure
```
.claude/skills/integrate-milestone/
├── SKILL.md
├── references/
│   └── MILESTONE_TEMPLATES.md   # BUILD-REVIEW, COMPLETED-TICKETS, VERIFICATION-RESULTS, RUN-GUIDE
└── scripts/
    └── check-hygiene.sh         # leftovers: scaffold files, stray files, debug output, ticketless TODOs, unused code, dead doc links
```
