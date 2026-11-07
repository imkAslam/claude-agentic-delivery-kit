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

## Pipeline contract (every backend)
1. **On every push / PR / MR:** `install → lint → typecheck → test → build`. The commands come from `project.json → commands`. Cache dependencies.
2. **E2E** against a preview or ephemeral environment when the target supports one; otherwise against the dev server started in CI.
3. **deploy-staging:** automatic on the default branch after all checks pass. Then a smoke test of `deploy.staging_url + deploy.health_path`.
4. **deploy-production:** **manual only**, through a protected environment (GitHub Environments with required reviewers, or a GitLab protected environment with a manual job), and it deploys **the same artifact** that staging got (an image digest or build id), never a rebuild.
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
| `open-pr <branch> <title>` | PR/MR from the integration branch into the default branch, after the Milestone Build Review |
