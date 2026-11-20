---
name: ci
description: "CI/CD adapter for GitHub Actions or GitLab CI, selected by project.json ci.kind: writes the pipeline (install, lint, typecheck, test, build, e2e, deploy-staging, protected deploy-production), checks required secrets by name, triggers environment deploys, watches runs, and opens PR/MRs."
when_to_use: "Use when creating or changing pipelines, checking CI secrets, triggering a staging or production deploy through CI, reading pipeline status, or opening a pull/merge request."
---

# CI adapter

Backend: `.claude/project.json → ci.kind`.

| kind | Reference |
|---|---|
| `github` | [github.md](references/github.md) |
| `gitlab` | [gitlab.md](references/gitlab.md) |
| PR/MR body and title (any kind) | [PR_TEMPLATE.md](references/PR_TEMPLATE.md), used by `open-pr` |

## Pipeline contract (every backend)
1. **On every push / PR / MR** (pushes to `main`, `develop`, `release/**`, `hotfix/**`; every PR/MR into `main` or `develop`): `install → lint → typecheck → test → build`. The commands come from `project.json → commands`. Cache dependencies.
2. **E2E** against a preview or ephemeral environment when the target supports one; otherwise against the dev server started in CI.
3. **deploy-staging:** automatic on `develop`, `release/**` and `hotfix/**` after all checks pass (Git Flow, `.claude/rules/git.md`: while a release branch is open, `develop` takes no merges, so staging holds the candidate). Then a smoke test of `deploy.staging_url + deploy.health_path`.
4. **deploy-production:** **manual only**, through a protected environment (GitHub Environments with required reviewers, or a GitLab protected environment with a manual job), and it deploys **the same artifact** that staging got from the `release/` or `hotfix/` branch (an image digest or build id, recorded at G3), never a rebuild.
5. The deploy jobs come from the `ship` skill target (the IaC/CLI steps for each host).
6. Secrets are referenced by name from the CI secret store. Jobs get least-privilege credentials (OIDC where the platform supports it).
7. **Security stages (DevSecOps):** secrets scan, SAST, dependency scan + SBOM, container and IaC scans on every PR/MR, and a DAST baseline after the staging deploy. New high/critical findings block. Stages, tools and policies are in `.claude/skills/security-audit/references/DEVSECOPS_PIPELINE.md`; use only tools available to the project.

## Operations
| Operation | Notes |
|---|---|
| `write-pipeline` | Writes the files above. Validate locally where possible (`actionlint`, `glab ci lint`) |
| `check-secrets` | Lists secret names and compares them with `deploy.required_secrets`. **Names only** |
| `trigger <staging\|production> <artifact>` | Production is allowed only after G3. `guard-prod.sh` blocks the command otherwise |
| `status [run]` / `logs <run>` | Watch a run and fetch the logs of failed jobs for triage |
| `open-pr <branch> <base> <title>` | `ms-<n>/integration` → `develop` after `mbr:<ms>`; `release/<version>` → `main`, then → `develop`, after `g3`; `hotfix/<id>-<slug>` → `main` after its `g3`, then `main` → `develop`. Always a **merge commit** (tickets were already squashed by the integrator). Title and body from PR_TEMPLATE.md |
| `wait-merged <pr>` | Poll the PR/MR until it is merged (or report why it is blocked: checks, review, conflicts). The next milestone or the tag waits for it |
| `pre-push-hook` | The devops foundation ticket installs a git **pre-push** hook in the product repo that runs `commands.lint`, `typecheck`, `test` and `build` (the same as CI), with the stack's usual tool: **husky** for Node (`.husky/pre-push`), **pre-commit** for Python (`default_install_hook_types: [pre-push]`), **lefthook** otherwise (`lefthook.yml` → `pre-push`). Installed by `commands.install`, so every clone and every agent worktree gets it |
| `protect-branches` | The bootstrap step for `main` and `develop`: PR/MR required with one review, the `checks` job required, up to date before merging, no force-push, no deletion, merge commits allowed. Listed in BOOTSTRAP.md for the human (admin rights) |
