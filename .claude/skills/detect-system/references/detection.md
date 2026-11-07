# Detection tables

## Architecture
| Type | Indicators |
|---|---|
| Monorepo | `nx.json`, `turbo.json`, `lerna.json`, `pnpm-workspace.yaml`, `rush.json`, a `workspaces` field in the root `package.json`, a Cargo `[workspace]`, `go.work` |
| Services | several deployable units, each with its own manifest and Dockerfile |
| Monolith | a single manifest at the root, no workspace indicators |

## Language and package manager
| Signal | Language / manager |
|---|---|
| `package.json` + `pnpm-lock.yaml` / `yarn.lock` / `package-lock.json` / `bun.lock*` | JS/TS with pnpm / yarn / npm / bun (`tsconfig.json` → TypeScript) |
| `pyproject.toml` + `uv.lock` / `poetry.lock`, or `requirements*.txt` | Python with uv / poetry / pip |
| `go.mod` | Go modules |
| `Cargo.toml` | Rust / cargo |
| `pom.xml` / `build.gradle*` | Java or Kotlin with Maven / Gradle |
| `*.csproj` / `*.sln` | .NET |
| `Gemfile` | Ruby / bundler |
| `composer.json` | PHP / composer |
| `pubspec.yaml` | Dart / Flutter |

## Frameworks (read the dependency manifests)
| Kind | Look for |
|---|---|
| Web meta-frameworks | next, nuxt, @sveltejs/kit, @remix-run/*, astro, @tanstack/start, @solidjs/start, @angular/core |
| UI libraries | react, vue, svelte, solid-js |
| Node backends | express, fastify, @nestjs/core, hono, koa, elysia, @trpc/server |
| Python backends | fastapi, django, flask, litestar |
| Go / Rust backends | gin, echo, fiber, chi / axum, actix-web, rocket |
| Mobile | expo, react-native, flutter (pubspec), native iOS (`*.xcodeproj`) / Android (`build.gradle` with `com.android.application`) |
| ORM / DB | prisma, drizzle-orm, typeorm, sequelize, mongoose, kysely, sqlalchemy, sqlmodel, gorm, diesel, sqlx |
| Tests | vitest, jest, mocha, pytest, go test, cargo test, junit |
| E2E | @playwright/test, cypress, maestro (`.maestro/`), detox |

## Infra, CI and hosting files
| Signal | Meaning |
|---|---|
| `.github/workflows/` | GitHub Actions |
| `.gitlab-ci.yml` | GitLab CI |
| `Dockerfile`, `compose*.yml`, `docker-compose*.yml` | containers |
| `vercel.json` | Vercel |
| `fly.toml` · `railway.toml`/`railway.json` · `render.yaml` | Fly.io · Railway · Render |
| `cdk.json` · `*.tf` · `serverless.yml` · `template.yaml` (SAM) | AWS via CDK · Terraform · Serverless · SAM |
| `eas.json` · `app.json`/`app.config.*` with expo | Expo EAS |

## Toolchain to probe
`git`, `jq`, `docker`, `node`, `pnpm`/`npm`/`yarn`/`bun`, `python3`/`uv`/`poetry`, `go`, `cargo`, `java`, `gh`, `glab`, `gitleaks`, `npx playwright --version`, `actionlint`, the deploy CLI for the target (`vercel`, `flyctl`, `railway`, `render`, `aws`, `cdk`, `terraform`, `eas`), and `claude`.

## Access commands (status only)
| Service | Command |
|---|---|
| GitHub | `gh auth status` |
| GitLab | `glab auth status` |
| Vercel | `vercel whoami` |
| Fly.io | `flyctl auth whoami` |
| Railway | `railway whoami` |
| AWS | `aws sts get-caller-identity --query Arn --output text` |
| Expo | `eas whoami` |
| Linear | an MCP tool list containing linear tools (check `claude mcp list`) |

## Ambiguity
If detection finds several candidates (for example two backends) or none, report every candidate with its evidence. **Don't choose.** The solution-architect decides and records it in `project.json`.
