# Application folder structures

Choose the template that matches the chosen style, adapt the names to the stack's conventions, then copy the result into the PRD §11 and `ARCHITECTURE.md §13`. **Every top-level folder maps to exactly one owner** in `project.json → roles.*.paths` or `shared_files`.

## A. Monorepo: web + API + mobile, sharing contracts *(the common default)*
```text
.
├── apps/
│   ├── web/                    # L0 web client                → frontend
│   │   └── src/
│   │       ├── app/            # routes in the framework's own convention: Next.js → tree A1, React + Vite (React Router) → tree A2
│   │       ├── features/       # one folder per business capability
│   │       │   └── <feature>/{components,hooks,api,tests}
│   │       ├── components/ui/  # reusable design-system components
│   │       ├── lib/            # client utilities, API client wiring
│   │       └── styles/         # tokens/theme from DESIGN.md › Brand
│   ├── api/                    # L2–L5 backend                → backend
│   │   └── src/
│   │       ├── modules/        # one per capability (modular monolith)
│   │       │   └── <module>/
│   │       │       ├── http/            # L2 controllers/routes, request validation
│   │       │       ├── application/     # L3 use cases, policies
│   │       │       ├── domain/          # L4 entities, value objects, events (no framework imports)
│   │       │       └── infrastructure/  # L5 repositories, adapters
│   │       ├── integrations/   # L5 provider adapters behind ports, their webhook routes, fixtures and mocks → integration when enabled (rule 8), else backend
│   │       │   └── <provider>/
│   │       ├── shared/         # cross-module kernel (ids, errors, time), kept small
│   │       ├── platform/       # X1/X2 auth, logging, config, health
│   │       └── workers/        # L7 queue consumers, schedulers
│   │   ├── migrations/         # L6 schema migrations           → backend (shared_files)
│   │   └── tests/{unit,integration}
│   └── mobile/                 # L0 mobile client             → mobile
│       └── src/{app|screens,features,components,lib,theme}
├── packages/                   # reusable, non-deployable libraries used by 2+ apps (rule 7)
│   ├── contracts/              # API/event contracts + generated clients, types, validators → api-designer (frozen at G2)
│   ├── ui/                     # design-system components, only when 2+ apps use them → frontend
│   ├── utils/                  # pure shared helpers (money, dates, ids), only when shared → owner named in project.json
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

### A2. React + Vite single-page app with React Router (the `apps/web` tree when the frontend is not Next.js)
Replaces the generic `apps/web/src` block above. Areas are **plain folders** and **layout routes**: parentheses in folder names mean nothing to Vite or React Router (that is Next.js syntax, rule 9). Rules: coding-foundations → REACT.md and TYPESCRIPT.md.
```text
apps/web/
├── index.html
├── vite.config.ts                    # build, aliases, dev proxy to the API
├── src/
│   ├── main.tsx                      # mounts the app: providers + the router
│   ├── app/                          # routing only: route modules stay thin and compose feature components
│   │   ├── router.tsx                # the route table (createBrowserRouter), lazy() per route module
│   │   ├── layouts/
│   │   │   ├── auth-layout.tsx       # public sign-in area: split screen with the brand panel (AUTH_SCREENS.md)
│   │   │   ├── app-layout.tsx        # app shell (sidebar, navbar) wrapped in the sign-in guard
│   │   │   └── marketing-layout.tsx  # public pages (only with F-LANDING)
│   │   ├── guards/require-auth.tsx   # redirects to sign-in; the API still enforces every permission
│   │   └── routes/
│   │       ├── auth/                 # login.tsx, register.tsx, forgot-password.tsx, verify-email.tsx
│   │       ├── app/                  # dashboard.tsx, settings.tsx, <feature>/{list,detail,new}.tsx
│   │       ├── marketing/            # landing.tsx, pricing.tsx (prerendered for SEO when F-LANDING)
│   │       └── not-found.tsx · error-boundary.tsx
│   ├── components/{ui,features/<feature>,layout,shared,providers}/   # as in A1
│   ├── hooks/{api,use-*.ts}          # server state over the generated contract client; UI hooks
│   ├── lib/{api,auth,utils}/         # client wiring, session helpers, formatters
│   ├── stores/  types/  config/      # UI state only · app-level types · site, navigation, route constants
│   └── styles/                       # generated token theme (tokens.json → CSS variables), themes
├── public/                           # brand asset kit exports, icons, manifest
└── tests/                            # integration tests; unit tests sit next to their unit
```
Notes:
1. A single-page app has no server: the sign-in guard is a convenience, and the API enforces every permission (L2/L3).
2. With `F-LANDING`, prerender the `marketing/` routes at build time (React Router's prerender option, or the Vite SSG plugin the architect pins), so the landing page meets LANDING_PAGE §4 (SEO, LCP).
3. When the architect picks React Router's **framework mode** instead, follow its own `app/routes.ts` route config and file layout, and record it in the stack ADR. The A1 import rules apply unchanged.

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
6. Keep `shared/` small. When it grows, promote the code to a module, or to a package when rule 7 applies, with an owner.
7. **`packages/` holds only reusable, non-deployable libraries that two or more apps use.** Deployable apps and services live in `apps/`. Each package has one job and one owner; code starts in the app that owns it and moves to `packages/` only when a second app needs it; apps import packages, never the other way round; no catch-all `common` package. A provider adapter that two deployables need (for example `apps/api` and `apps/worker`) becomes `packages/integration-<provider>/`, with an ADR. Provider emulators for local work (for example Mailpit) are services in `infra/docker` compose, not packages.
8. **Nested owners are listed folder by folder.** When the integration role is enabled, the backend's `paths` name its folders under `apps/api` (`src/modules/**`, `src/shared/**`, `src/platform/**`, `src/workers/**`, `migrations/**`, `tests/**`, plus its manifest files) and the integration role owns `apps/api/src/integrations/**`, so no two roles' paths overlap (`deliver/references/manifest.md`).
9. **Routing follows the confirmed framework only.** Next.js route groups (`(auth)/`), dynamic segments (`[id]/`) and file names (`page.tsx`, `layout.tsx`) exist only in Next.js (A1). React Router uses a route table or its framework-mode config (A2); other frameworks use their own convention. Never mix them; `check-architecture.sh` fails Next.js route groups in a stack that isn't Next.js.
10. **The tree shows everything project.json owns:** every role path and shared file (root config files, hooks, per-app manifests) appears in the tree, and every top-level folder has an owner (`check-architecture.sh`).
