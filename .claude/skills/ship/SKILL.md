---
name: ship
description: "Hosting deploy contract for Vercel, Docker on a VPS, Fly.io/Railway/Render, AWS and Expo EAS mobile releases: the IaC/config files, CI deploy job steps, required secret names, health check, rollback procedure and one-time bootstrap checklist for each target. Deploys always run through CI."
when_to_use: "Use when planning hosting, writing deploy config or IaC, preparing BOOTSTRAP.md, a deployment plan or rollback runbook, or adding the deploy steps to a CI pipeline."
---

# Ship: hosting targets

Target: `.claude/project.json → deploy.target` (plus `deploy.mobile_target` for apps).

| target | Reference |
|---|---|
| `vercel` | [vercel.md](targets/vercel.md) |
| `docker-vps` | [docker-vps.md](targets/docker-vps.md) |
| `fly` / `railway` / `render` | [paas.md](targets/paas.md) |
| `aws` | [aws.md](targets/aws.md) |
| `eas` (mobile) | [mobile-eas.md](targets/mobile-eas.md) |

## Deploy contract: each target defines all six
1. **Config / IaC files** checked into the devops role's paths.
2. **CI deploy steps** for the `ci` skill's deploy job, building or promoting **one immutable artifact**.
3. **Required secret names** → `project.json → deploy.required_secrets`.
4. **Health check:** `deploy.health_path` returns 200 and checks its dependencies (database reachable). The CI smoke step curls it.
5. **Rollback:** concrete commands or console steps for app **and** data, written into `ROLLBACK-RUNBOOK.md` and rehearsed on staging.
6. **Bootstrap checklist:** the one-time human steps (accounts, projects, DNS, secrets, protected environments), written into `docs/delivery/BOOTSTRAP.md`.

## Rules
- Never run deploy, apply or submit commands from the workstation. `guard-prod.sh` blocks them. Local validation is allowed only in dry-run form (`docker build`, `terraform validate`/`plan`, `cdk synth`).
- Staging mirrors production (same artifact, same migrations, a smaller size).
- Database migrations run as a separate CI step **before** the new version takes traffic, and are backward compatible (expand → migrate → contract).
- Take a backup or snapshot before every production migration.
