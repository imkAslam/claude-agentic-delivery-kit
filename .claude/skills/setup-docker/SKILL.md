---
name: setup-docker
description: "Containerizes any stack: writes a multi-stage Dockerfile (pinned base, non-root user, healthcheck, minimal runtime image), a compose file for local development with the services the app needs (database, cache, queue), and .dockerignore, using the stack and commands from project.json."
when_to_use: "Use when a project needs Docker for local development, for CI builds, or for the docker-vps, Fly, Railway, Render or AWS container targets."
---

# Setup Docker

Inputs: `.claude/project.json` (`stack`, `commands`, `deploy.health_path`). If it's missing, detect the stack with the `detect-system` skill's tables. Write the files only inside the devops role's paths.

## Dockerfile rules
1. **Multi-stage:** `deps` (install with the lockfile only, cached) → `build` (compile/bundle) → `runtime` (only the built output and production dependencies).
2. **Pin the base images** to a specific version tag (and a digest for production). Prefer the official slim/alpine/distroless variants that fit the runtime.
3. Install with the frozen lockfile command from `project.json → commands.install` (or its production-only form).
4. Run as a **non-root** user, set `NODE_ENV`/`PYTHONUNBUFFERED`/the equivalent production flags, `EXPOSE` the app port.
5. `HEALTHCHECK` calls `deploy.health_path` with a tool that exists in the runtime image (or a tiny binary/script that's copied in).
6. No secrets in build args or layers. Runtime configuration comes from environment variables only.
7. Make the start command the process itself (exec form), so signals reach it.

## Free local services (always first)
Every backing service for development and testing runs locally in Docker, using the free substitutes in [LOCAL_SERVICES.md](references/LOCAL_SERVICES.md) (database, cache, object storage, mail capture, queues, search, antivirus, mock OIDC, cloud emulators). Use the remote fallback only when Docker isn't running (per SYSTEM-PROFILE) or a service has no local substitute. Then the human supplies URLs in `.env`, asked once by the orchestrator.

## compose for development (`compose.yml`)
- `app`: build target `build` or a dev stage, with a source bind mount and the dev command from `commands.dev`.
- Add only the services that `stack` implies (for example a database, cache, queue or object storage). Each one gets a healthcheck, a named volume and `depends_on: condition: service_healthy`.
- Credentials for local services come from an `.env` file that's git-ignored, plus a committed `.env.example` with placeholder values.

## .dockerignore
VCS metadata, dependency folders, build outputs, test coverage, local env files (keep `.env.example`), logs, editor folders, `docs/`, and `.claude/`.

## Verify
`docker build --target runtime .` succeeds, `docker compose up -d --wait` brings every service up healthy, and `curl -fsS http://localhost:<port><health_path>` returns 200. Paste the output into the ticket report.
