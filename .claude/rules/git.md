# Git rules (always on)

- **One ticket = one Conventional Commit**: `<type>(<scope>): <subject>` with the footer `Refs: <ticket-id>`. Types: feat, fix, test, refactor, docs, chore, ci, build, perf.
- Branch names: `ms-<n>/<role>/<ticket-id>-<slug>` for role work, `ms-<n>/integration` for the milestone join, and `release/<name>` for releases.
- `commit-gate.sh` runs the role's lint, typecheck and test before every `git commit`. Never pass `--no-verify`; `guard-prod.sh` blocks it.
- Never force-push, `reset --hard`, `clean -f`, or rewrite shared history. `guard-prod.sh` blocks these.
- Stage only files inside your role's owned paths. The integrator checks this with `.claude/skills/deliver/scripts/check-ownership.sh`.
- **Worktrees see only committed files.** The orchestrator commits the kit (`.claude/`), `docs/delivery/` and the contracts before Lane 3 starts any parallel work.
- Merges to the default branch happen only after the Milestone Build Review gate, through a PR/MR when the CI adapter supports it.
