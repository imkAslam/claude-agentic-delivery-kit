---
name: role-boundaries
description: "Ownership rules for role engineers: where a role may write (project.json roles.<role>.paths), who owns shared files, why contracts are frozen after G2, and the exact report lines to use when work needs a change outside the role's paths."
when_to_use: "Use when a ticket seems to need edits outside your role's paths, a shared file, a dependency, or a contract."
user-invocable: false
---

# Role boundaries

## Find your boundary
- Your paths: `.claude/project.json → roles.<your role>.paths` (the brief also lists `OWNED PATHS`).
- Shared files: `shared_files` maps each glob to exactly one owner (a role, or `integrator`).
- Contracts: `contracts.paths`. These are **read-only after G2** for everyone.

`guard-boundary.sh` blocks writes outside your paths, and `check-ownership.sh` re-checks your branch at the join. Neither one can be bypassed.

## When you need something outside your boundary
Stop working on that part and add a line to your return block:

| Need | Report line |
|---|---|
| A contract change | `RESULT: CONTRACT_CHANGE_NEEDED` + `NEEDS: contract <operation> — <exact change> — <reason>` |
| A new dependency or a root-manifest change | `NEEDS: dependency <name>@<range> — <reason>` (the integrator owns the root manifest and the lockfile) |
| A change in another role's paths | `NEEDS: <role> — <file or area> — <change> — <reason>` |
| A migration (if you're not the backend role) | `NEEDS: backend — migration — <change> — <reason>` |
| A product or design decision | `RESULT: NEEDS_HUMAN` + the question and its consequence |

Finish everything else in the ticket that doesn't depend on the request, and state clearly what remains blocked.

## Also
- Find code through `docs/CODEMAP.md` (before milestone 1 is integrated: PRD §11) and `grep`. Open only the files you need; never read whole directories.
- Follow the coding guides in your brief's `GUIDES:` line (`coding-foundations`) and run their review checklist on your diff before returning.
- Apply the `LESSONS:` lines in your brief; they are mistakes the team already made once.
- Use generated contract clients and mocks. Never copy types by hand across roles.
- Stage only your own paths. Never `git add -A` in a shared tree.
