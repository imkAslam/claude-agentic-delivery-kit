# Pull and merge request template

Used by `open-pr` (the ci skill) for every PR or MR: `ms-<n>/integration` → `develop`, `release/<version>` → `main` and → `develop`, `hotfix/<id>-<slug>` → `main`. The title is a Conventional Commit line, so the merged history reads as a changelog.

## Title
`<type>(<scope>): <subject>`, for example `feat(orders): add refund request`. Types as in `.claude/rules/git.md`.

## Body

```markdown
## Summary
What changed and why, in two or three sentences, in plain language.

## Tickets
- Refs: <ticket-id>, <ticket-id>

## Type of change
- [ ] Feature
- [ ] Fix
- [ ] Refactor, performance or docs (no behavior change)
- [ ] Breaking change (describe the migration step below)

## How it was tested
- Commands run (from `project.json → commands`): lint, typecheck, test, build
- End-to-end journeys run: <list or "none, see the milestone review">
- Migrations checked with `check-migrations.sh`: <yes, no findings | not applicable>

## Screenshots or mockups (UI changes)
Before and after, or the mockup the build matches (`docs/delivery/mockups/`).

## Checklist
- [ ] No secrets, tokens or personal data in code, fixtures or logs
- [ ] `check-hygiene.sh` is clean for this diff
- [ ] Every acceptance criterion of the tickets has a test
- [ ] Significant decisions have an ADR
- [ ] Breaking changes list their migration steps below

## Breaking changes and migration steps
None, or the steps for users and operators.
```

## Merge requirements
- The gate is approved: `mbr:<ms>` for a milestone into `develop`, `g3` for a release or hotfix into `main`.
- The CI `checks` job is green on the PR.
- Every review thread is resolved.
- The branch is up to date with its target (`develop` or `main`).
- Merged with a **merge commit**, as `.claude/rules/git.md` says.
