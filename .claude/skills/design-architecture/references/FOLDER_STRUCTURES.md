# Application folder structures

Choose the template that matches the chosen style, adapt the names to the stack's conventions, then copy the result into the PRD §11 and `ARCHITECTURE.md §13`. **Every top-level folder maps to exactly one owner** in `project.json → roles.*.paths` or `shared_files`.

## A. Monorepo: web + API + mobile, sharing contracts *(the common default)*
```text
.
├── apps/
│   ├── web/                    # L0 web client                → frontend
│   │   └── src/
│   │       ├── app/            # routes/pages (framework routing convention)
│   │       ├── features/       # one folder per business capability
│   │       │   └── <feature>/{components,hooks,api,tests}
│   │       ├── components/ui/  # reusable design-system components
│   │       ├── lib/            # client utilities, API client wiring
│   │       └── styles/         # tokens/theme from BRAND-BRIEF
│   ├── api/                    # L2–L5 backend                → backend
│   │   └── src/
│   │       ├── modules/        # one per capability (modular monolith)
│   │       │   └── <module>/
│   │       │       ├── http/            # L2 controllers/routes, request validation
│   │       │       ├── application/     # L3 use cases, policies
│   │       │       ├── domain/          # L4 entities, value objects, events (no framework imports)
│   │       │       └── infrastructure/  # L5 repositories, adapters
│   │       ├── shared/         # cross-module kernel (ids, errors, time), kept small
│   │       ├── platform/       # X1/X2 auth, logging, config, health
│   │       └── workers/        # L7 queue consumers, schedulers
│   │   ├── migrations/         # L6 schema migrations           → backend (shared_files)
│   │   └── tests/{unit,integration}
│   └── mobile/                 # L0 mobile client             → mobile
│       └── src/{app|screens,features,components,lib,theme}
├── packages/
│   ├── contracts/              # API contracts + generated clients → api-designer (frozen at G2)
│   ├── integrations/           # L5 provider adapters, webhook handlers, mocks → integration (when enabled)
│   ├── ui/                     # shared UI primitives (optional) → frontend
│   └── config/                 # shared lint/ts/test configs     → integrator (shared_files)
├── e2e/                        # cross-app E2E journeys        → qa
├── infra/                      # IaC, container files, platform config → devops
├── .github/ or .gitlab-ci.yml  # CI pipelines                  → devops
├── docs/{intake,delivery,adr}  # delivery artifacts             → per artifact owner
├── <root manifest + lockfile>  #                                → integrator (shared_files)
└── .claude/                    # delivery kit (never edited by roles)
```

## B. Single backend service: clean / hexagonal (Python, Go, Java, .NET, Node)
```text
<service>/
├── src/<package>/
│   ├── api/            # L2 routes, schemas, dependency wiring
│   ├── application/    # L3 use cases, ports (interfaces)
│   ├── domain/         # L4 pure business model
│   ├── infrastructure/ # L5 db, repositories, external clients, messaging
│   └── main.*          # composition root
├── migrations/
└── tests/{unit,integration,contract}
```
Language notes: in Go, use `cmd/<app>/main.go`, `internal/{api,app,domain,infra}`. In Java/.NET, use packages or projects per layer with enforced references. In Python, `src/` layout with import-linter contracts.

## C. Frontend-only web app (feature-based)
```text
src/
├── app/ or pages/       # routing
├── features/<feature>/  # UI + state + API hooks per capability
├── entities/            # shared domain types and widgets (optional)
├── shared/{ui,lib,api,config}
└── tests/
```
Rule: a feature can import from `shared/` and `entities/`, never from another feature directly.

## D. Microservices (only when the ADR justifies it)
```text
services/<service>/      # each with layout B, its own DB schema, its own pipeline job
gateway/ or bff/         # L2 per client
contracts/<service>/     # per-service contracts + events schema
platform/                # shared observability, auth libs (versioned)
infra/
```

## E. Infrastructure folder
```text
infra/
├── docker/              # Dockerfiles, compose files
├── <iac tool>/          # terraform | cdk | pulumi
│   ├── modules/
│   └── envs/{staging,production}
├── platform/            # vercel.json, fly.toml, render.yaml, eas.json, …
└── scripts/             # backup.sh, smoke.sh
```

## Rules
1. **Organize by capability first, then by layer** (inside each module). Avoid top-level `controllers/`, `models/` and `services/` buckets in larger apps.
2. **The domain layer imports no framework or infrastructure code.** Enforce it with a lint rule.
3. **One owner per top-level folder.** Owned paths of enabled roles must not overlap (the hooks enforce them).
4. **Contracts live in one place** and generate the clients for every consumer.
5. **Tests sit next to their unit,** or in a mirrored `tests/` tree. E2E lives in its own QA-owned folder.
6. Keep `shared/` small. When it grows, promote the code to a module or package that has an owner.
