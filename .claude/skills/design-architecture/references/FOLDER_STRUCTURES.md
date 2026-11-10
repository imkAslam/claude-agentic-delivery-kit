# Application folder structures

Choose the template that matches the chosen style, adapt the names to the stack's conventions, then copy the result into the PRD §11 and `ARCHITECTURE.md §13`. **Every top-level folder maps to exactly one owner** in `project.json → roles.*.paths` or `shared_files`.

## A. Monorepo: web + API + mobile, sharing contracts *(the common default)*
```text
.
├── apps/
│   ├── web/                    # L0 web client                → frontend
│   │   └── src/
│   │       ├── app/            # routes/pages (framework routing convention; Next.js: use tree A1 below)
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

### A1. Next.js App Router web app (the `apps/web` tree when the frontend is Next.js)
Replaces the generic `apps/web/src` block above. Rules: coding-foundations → NEXTJS.md and REACT.md.
```text
apps/web/
├── src/
│   ├── app/                          # routing only: pages stay thin and compose feature components
│   │   ├── (auth)/                   # public sign-in flows; centered layout, no app navigation
│   │   │   ├── login/page.tsx
│   │   │   ├── register/page.tsx
│   │   │   ├── forgot-password/page.tsx
│   │   │   ├── verify-email/page.tsx
│   │   │   ├── layout.tsx  error.tsx  loading.tsx
│   │   ├── (app)/                    # authenticated product (name per shell: (dashboard), (admin)…)
│   │   │   ├── dashboard/{page,loading}.tsx
│   │   │   ├── <feature>/
│   │   │   │   ├── page.tsx          # list
│   │   │   │   ├── [id]/{page,loading}.tsx
│   │   │   │   └── new/page.tsx
│   │   │   ├── settings/page.tsx
│   │   │   ├── layout.tsx            # app shell (sidebar, navbar) + the server-side auth guard
│   │   │   ├── error.tsx  loading.tsx  not-found.tsx
│   │   ├── (marketing)/              # public pages: landing (F-LANDING), pricing, about, legal
│   │   │   ├── page.tsx              # the landing page at "/"
│   │   │   ├── pricing/page.tsx
│   │   │   ├── layout.tsx  error.tsx
│   │   ├── api/                      # route handlers: health, webhooks, BFF endpoints
│   │   │   ├── health/route.ts
│   │   │   └── webhooks/<provider>/route.ts
│   │   ├── layout.tsx                # root layout: fonts, providers, metadata defaults
│   │   ├── global-error.tsx  not-found.tsx
│   │   ├── sitemap.ts  robots.ts
│   │   └── globals.css               # imports the generated token theme
│   ├── components/
│   │   ├── ui/                       # UI-library components (added by its CLI) and base components
│   │   ├── features/<feature>/       # feature components: business logic, forms, API hooks in use
│   │   ├── layout/                   # navbar, sidebar, footer, mobile nav, breadcrumbs
│   │   ├── shared/                   # reused across features: empty state, pagination, error boundary, file upload
│   │   └── providers/                # theme, query client, auth/session, realtime
│   ├── hooks/
│   │   ├── api/                      # server-state hooks over the generated contract client, one file per resource
│   │   └── use-*.ts                  # UI hooks: debounce, media query, intersection observer
│   ├── lib/
│   │   ├── api/                      # generated-client wiring: base URL, auth, error mapping
│   │   ├── auth/                     # session helpers (server-side)
│   │   ├── realtime/                 # the one socket/SSE client and its typed events (only if used)
│   │   └── utils/                    # class-name helper, formatters, constants
│   ├── stores/                       # small client stores, UI state only
│   ├── types/                        # app-level types (contract types come from packages/contracts)
│   ├── config/                       # site, navigation, route constants
│   ├── styles/                       # generated token theme (tokens.json → CSS variables), themes
│   └── middleware.ts                 # cheap checks: auth redirect, locale, headers
├── public/                           # static assets: brand asset kit exports, icons, manifest
├── tests/                            # integration tests; unit tests sit next to their unit
├── components.json                   # UI-library config (when the library uses one)
└── <framework, styling and TypeScript config files>
```
Import rules (enforced by the import-boundary lint where the stack has one):
1. `app/` imports from `components/`, `hooks/`, `lib/`, `config/`; nothing imports from `app/`.
2. `components/ui` imports only `lib/utils` and the UI library. `features/<a>` never imports `features/<b>`.
3. Server-only modules (`lib/auth`, server data access) are never imported by a client component.
4. Server data lives in the query cache or Server Components, never in `stores/`.
5. The whole tree is owned by the frontend role; `packages/contracts` stays with the api-designer.

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
