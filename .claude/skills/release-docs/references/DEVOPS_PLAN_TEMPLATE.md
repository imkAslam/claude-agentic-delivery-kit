# DEVOPS-PLAN.md template

```markdown
> Status: in-review · Owner: devops-engineer · Sources: ARCHITECTURE.md, project.json, ship/<target> · Updated: <ISO>

# DevOps plan

## 0. Development environment (free-first)
| Service | Purpose | Provider (docker / remote) | Image or remote source | Env var names | Port |
|---|---|---|---|---|---|
| Database | primary store | docker | postgres:16-alpine | DATABASE_URL | 5432 |
| Mail | capture outgoing email | docker | axllent/mailpit | SMTP_HOST, SMTP_PORT | 1025/8025 |
Start: `<commands.dev>` · Seeds: `<seed command>` · Remote fallback items (human-provided in `.env`): <list, or "none">

## 1. Environments
| Env | Purpose | URL | Host / target | Data | Deploy trigger |
|---|---|---|---|---|---|
| dev | local development | <dev_url> | docker compose / local | seeds | — |
| staging | pre-production, mirrors prod | <staging_url> | <target> | synthetic | automatic on default branch |
| production | live | <prod_url> | <target> | real | manual, protected, after G3 |

## 2. Pipeline (ci.kind = <github|gitlab>)
Diagram: **PRD §12 · D8 CI/CD flow** (you refine the architect\'s outline; send the Mermaid source to the solution-architect in a `handoff` message). Deployment changes go to **D3** the same way.
Stages: install → lint → typecheck → test → build (one immutable artifact) → e2e → deploy-staging → smoke → deploy-production (manual, protected, same artifact) → smoke.
Branch protection: required checks; PR/MR review; no direct pushes to the default branch.

## 3. Infrastructure as code
Files and their location (within `roles.devops.paths`), state management (remote state + locking where it applies), and how changes are reviewed (plan output attached to the MR/PR).

## 4. Secrets and configuration (names only)
| Name | Envs | Stored in | Used by | Rotation |
|---|---|---|---|---|
| DATABASE_URL | staging, prod | CI secret store / platform env | app, migrations | on compromise + yearly |

## 5. Database
Migrations run as a CI step before traffic shifts (expand → migrate → contract). Backups: frequency, retention, encryption, off-site copy. Restore drill: how and how often, plus the last result.

## 6. Observability
Logs (where, retention, no PII), metrics (latency, error rate, saturation), traces (if any), uptime check on `health_path`, alerts (threshold → channel → on-call).

## 7. Recovery
| Scenario | RTO | RPO | Procedure (link to the runbook) |
|---|---|---|---|
| Bad release | 15 min | 0 | redeploy the previous artifact |
| Data corruption | 4 h | 15 min | point-in-time restore |
| Region / host outage | per SLA | per backup | restore to a new host from IaC + backup |

## 8. Cost estimate
Per environment, with the assumptions (sizes, traffic).

## 9. Security
Least-privilege deploy credentials (OIDC where possible), pinned actions/images, dependency audit in CI, network exposure (only the web entry point is public).
```
