# Project commands and scripts

Every task a developer does has **one named script in the project's own manifest** (`package.json` scripts, or a `Makefile`/`justfile` for stacks without one), so anyone can run, test and build the project without the kit. `project.json → commands` only **names** those scripts; `app.sh`, CI, the commit gate and the agents all call the same ones. The devops foundation ticket creates them; the docs-writer lists them in the README.

## Standard names
| Task | `package.json` script | `Makefile` / `justfile` target | `project.json` key |
|---|---|---|---|
| Start everything for development | `dev` | `dev` | `dev` |
| Start one app | `dev:<app>` (`dev:web`, `dev:api`) | `dev-<app>` | — |
| Build | `build` | `build` | `build` |
| Unit and feature tests | `test` | `test` | `test` |
| End-to-end tests | `test:e2e` | `test-e2e` | `e2e` |
| Lint | `lint` | `lint` | `lint` |
| Type check | `typecheck` | `typecheck` | `typecheck` |
| Format | `format` | `format` | — |
| Migrations | `db:migrate` | `db-migrate` | `migrate` |
| Sample data | `db:seed` | `db-seed` | `seed` |
| Generated code (ORM, contract client) | `db:generate`, `contracts:generate` | `db-generate`, `contracts-generate` | `contracts.codegen_cmd` |
| Start / stop the local services | `infra:up` / `infra:down` | `infra-up` / `infra-down` | `services_up` / `services_down` |
| Service status and logs | `infra:status` / `infra:logs` | `infra-status` / `infra-logs` | — |
| Remove leftover containers | `infra:clean` (runs `app.sh clean`) | `infra-clean` | — |

## Example (a Node monorepo; use the workspace tool the architect pinned: pnpm, nx or turbo)
```json
"scripts": {
  "dev": "pnpm infra:up && pnpm -r --parallel --filter './apps/*' dev",
  "dev:web": "pnpm --filter @app/web dev",
  "dev:api": "pnpm --filter @app/api dev",
  "build": "pnpm -r build",
  "test": "pnpm -r test",
  "test:e2e": "pnpm --filter @app/e2e test",
  "lint": "pnpm -r lint",
  "typecheck": "pnpm -r typecheck",
  "format": "prettier --write .",
  "db:generate": "pnpm --filter @app/database generate",
  "db:migrate": "pnpm --filter @app/database migrate",
  "db:seed": "pnpm --filter @app/database seed",
  "infra:up": "docker compose up -d --wait",
  "infra:down": "docker compose down",
  "infra:status": "docker compose ps",
  "infra:logs": "docker compose logs -f",
  "infra:clean": "bash .claude/skills/deliver/scripts/app.sh clean"
}
```
`project.json` then says `"test": "pnpm test"`, `"services_up": "pnpm infra:up"`, and a role says `"test": "pnpm --filter @app/web test"`. A Python service inside a Node monorepo gets scripts too (`"test:ai": "cd services/ai && uv run pytest"`), and the root `test` runs it. A single-stack Python or Go project uses `make test` (or `uv run pytest`, `go test ./...` when that tool call is the whole task).

## Rules
1. **One name per task, from the table.** A `project.json` command is a **single call**: a script (`pnpm test`, `make test`) or the stack's own tool (`go test ./...`). Never a chain with `&&`, `||`, `;`, `|`, `$(…)` or a subshell; a chain belongs in a named script. (`check-hygiene.sh` › `commands`)
2. **The root manifest has a script for every `project.json` command**, under the standard name. (`check-hygiene.sh` › `commands`)
3. **Tools before scripts.** Use the package manager's workspace commands, the framework and ORM CLIs, and compose itself. Write a shell script only for what they can't do: backups and restores, secret rotation, a container entrypoint.
4. **Every shell script is used by something:** a named script, a CI job, a compose file, a Dockerfile, or one line in the README of the folder it lives in (`scripts/` or `infra/scripts/`). A script nothing uses fails. (`check-hygiene.sh` › `scripts`)
5. **No proof, evidence or one-off scripts.** Evidence goes in the return block; a one-off check is a command you run, not a file. (`check-hygiene.sh` › `scripts`)
6. **Few scripts.** More than 12 shell scripts warns: look for the tool that replaces them.
