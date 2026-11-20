# Git rules (always on)

The kit uses **Git Flow**: `main` holds released code, `develop` holds integrated milestones, and every ticket, milestone and release has its own short-lived branch. Branches are created only by `delivery-state.sh branch …`, so names and bases never depend on an agent's guess.

## Branches
| Branch | Created from | By | Merged into | How |
|---|---|---|---|---|
| `main` (or `ci.default_branch`) | the first commit | the human / bootstrap | — | protected; changes only through a PR/MR |
| `develop` | `main`, at the first `branch milestone ms-1` | the orchestrator | — | protected; changes only through a PR/MR |
| `ms-<n>/integration` | `develop`, at `dispatch` (`branch milestone ms-<n>`) | the orchestrator | `develop`, after gate `mbr:ms-<n>` | PR/MR, **merge commit** |
| `feature/<id>-<slug>`, `chore/<id>-<slug>`, `spike/<id>-<slug>` | `ms-<n>/integration` (`branch ticket <id>`) | the orchestrator, at dispatch | `ms-<n>/integration`, by the integrator | **squash**: one commit per ticket |
| `bugfix/<id>-<slug>` | the branch the bug was found on: `ms-<n>/integration`, or `release/<version>` in verify and release (`branch ticket <id> --base release/<version>`) | the orchestrator | the same branch, by the integrator | **squash** |
| `release/v<X.Y.Z>` | `develop`, at the start of lane `verify` (`branch release v<X.Y.Z>`): the feature freeze | the orchestrator | `main` after **g3**, then back into `develop` | PR/MR, **merge commit**; tag `v<X.Y.Z>` on `main` |
| `hotfix/<id>-<slug>` | `main`, for a defect in production (`branch ticket <id> --base main`) | the orchestrator | `main` after its own **g3** (a patch release), then `main` back into `develop` | PR/MR; tag `v<X.Y.Z+1>` |

- Names are lowercase with hyphens: `feature/t-004-auth-api`. The ticket id keeps its case in commits (`Refs: T-004`).
- **The next milestone starts only after the previous one is merged into `develop`.** `branch milestone` refuses otherwise.
- While a `release/` branch is open, `develop` takes no merges (the next release starts after `ops_ack`), so staging holds the candidate.
- **Clean up after merging:** once `ms-<n>/integration` is in `develop`, `branch cleanup ms-<n>` removes that milestone's ticket worktrees and branches. Integration and release branches stay until the release is merged into `main`.

## Commits
- **One ticket = one Conventional Commit** on the target branch. The engineer may add correction commits on the ticket branch; the integrator squashes them into one commit that reuses the ticket's first commit message.
- Format: `<type>(<scope>): <subject>`, a blank line, the body, a blank line, the footer.
  - **Types:** feat, fix, docs, style (formatting only), refactor, perf, test, build, ci, chore, revert.
  - **Scope:** the module or area, lowercase and consistent across commits (`auth`, `api`, `ui`, `db`).
  - **Subject:** imperative and present tense ("add", not "added"), lowercase first letter, no period, at most 72 characters.
  - **Body:** what changed and why, not how; wrapped at 72 characters; bullets for several changes.
  - **Footer:** `Refs: <ticket-id>` always; `Closes #<n>` when the tracker is GitHub or GitLab issues; `BREAKING CHANGE: <what and how to migrate>` for an incompatible change.
- `commit-gate.sh` runs the role's lint, typecheck and test before every `git commit`. The product's **pre-push hook** (installed by the devops foundation ticket) runs lint, typecheck, test and build before every push. Never pass `--no-verify`; `guard-prod.sh` blocks it.

```
feat(auth): add signup, login and password reset

- signup with email verification and OTP
- login with refresh tokens; logout revokes them
- forgot and reset password with a single-use link

Refs: T-004
```

## Pull requests and protection
- **PR/MR titles** follow Conventional Commits, so the title reads as a changelog line. The body follows `ci/references/PR_TEMPLATE.md`.
- `main` and `develop` are protected on the remote: a PR/MR with review, the CI `checks` job green, every thread resolved, the branch up to date, no force-push and no deletion. `guard-prod.sh` also blocks a direct push to either branch once it exists on the remote.
- **Merge requirements:** the gate is approved (`mbr:<ms>` for a milestone, `g3` for a release or hotfix), CI is green, every thread is resolved, and the branch is up to date with its target. Without a remote, the orchestrator merges locally after the gate, with the same strategy.
- Never force-push, `reset --hard`, `clean -f`, or rewrite shared history. `guard-prod.sh` blocks these.
- Stage only files inside your role's owned paths. The integrator checks this with `.claude/skills/deliver/scripts/check-ownership.sh`.
- **Worktrees see only committed files.** The orchestrator commits the kit (`.claude/`), `docs/delivery/` and the contracts before Lane 3 starts any parallel work.
- Release tags (`v<X.Y.Z>`) are pushed only after **g3**; `guard-prod.sh` checks it.
