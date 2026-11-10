# Stack selection

## 0. The client's preference (read first)
| Intake says | How to treat it |
|---|---|
| **Required** stack (contract, team, existing platform) | A constraint. Design within it; report any must-have it can't meet as a risk at G1 |
| **Preferred** stack | Candidate A in the matrix, scored honestly. **Use it unless it fails a must-have driver** (an NFR, compliance, a hosting constraint, the budget). If it does, say so plainly at G1 with the consequence and the nearest alternative |
| No preference | Recommend from the drivers and the defaults below |
The client always confirms the main stack at G1 (§6). Libraries and tools within the stack stay agent decisions.

## 1. List the drivers (from the PRD and intake)
Team skills · time to market · budget · expected scale · latency targets · realtime needs · offline/mobile needs · data sensitivity and compliance · hosting preference or constraint · integration ecosystem · long-term maintainability.

## 2. Weighted matrix
Weight each driver 1–5, score each candidate 1–5, and compute the weighted total. Show the table in the ADR.

| Driver (weight) | Candidate A | Candidate B | Candidate C |
|---|---|---|---|
| Team skills (5) | 5 | 3 | 2 |
| Time to market (4) | 4 | 4 | 3 |
| … | | | |
| **Weighted total** | | | |

## 3. Sensible defaults (deviate only with a driver)
| Product type | Default shape |
|---|---|
| Content/marketing site with light dynamic parts | Static or SSR meta-framework on an edge/serverless host |
| CRUD business app / internal tool / SaaS MVP | **Modular monolith**: one web app with server-side rendering + API routes, or an SPA + one API service; relational DB; managed hosting |
| Web + mobile app sharing a backend | One API service with a typed contract; web app; cross-platform mobile app consuming generated clients |
| Heavy background processing / integrations | Monolith + a job queue and workers (added by ADR) |
| Realtime collaboration / live updates | Add a websocket/SSE channel to the API only for the realtime features |
| Strict compliance or data residency | Region-pinned managed services; consider AWS or a VPS in the required region |

## 3a. Web UI layer (styling + component library)
Chosen with the frontend framework, recorded in the stack ADR and shown in the G1 stack table. The client can name another library at any time.
| Frontend | Default | Why | Alternatives, and when to prefer them |
|---|---|---|---|
| React / Next.js | **Tailwind CSS + shadcn/ui** (Radix primitives, Lucide icons) | Components are copied into the repo (full control, no version lock-in), accessible primitives, themed by CSS variables that map directly to the design tokens, the current community standard | MUI or Ant Design (dense enterprise tables and forms out of the box), Mantine or Chakra (batteries-included hooks and components), a client design system that already exists |
| Vue / Nuxt | Tailwind CSS + shadcn-vue (Reka UI primitives) | Same model as above | Vuetify, PrimeVue (enterprise widgets) |
| Angular | Angular Material + CDK | First-party, accessible, signals-ready | PrimeNG (data-heavy screens), Tailwind + spartan/ui |
| Svelte / SvelteKit | Tailwind CSS + shadcn-svelte (Bits UI primitives) | Same model as above | Skeleton, Flowbite |
| Any | — | — | Charts: a library that takes token colors (e.g. Recharts, ECharts). Animation: CSS first, a motion library only where the design needs it |
Rules: one component library per app; the library is **themed by the design tokens** (build-design-system → DESIGN_TOKENS.md §8), never by its default palette; a paid library or paid component pack is a business decision for the gate.

## 4. Choices that need explicit justification
Microservices · NoSQL as the primary store for relational data · a self-managed Kubernetes cluster · multiple languages in the backend · custom auth instead of a vetted library/provider · GraphQL for a single client with simple reads.

## 5. Hosting fit (`deploy.target`)
| Target | Good fit | Watch out for |
|---|---|---|
| vercel | Framework-native web apps, serverless APIs | Long-running jobs, websockets; database is external |
| docker-vps | Low cost, full control, steady load | You own TLS, patching, backups, monitoring |
| fly / railway / render | Containers + managed DB with little ops | Platform limits, regions, pricing at scale |
| aws | Compliance, scale, the broadest services | Complexity and cost; IaC is required |
| eas (mobile) | Expo/React Native store builds + OTA | Store review times; native modules need rebuilds |

## 6. Presenting the stack at G1 (PRD §10, "Tech stack (to confirm at G1)")
| Concern | Recommended | Client preference | Why (plain language) | Trade-off / cost |
|---|---|---|---|---|
| Frontend | … | … or — | … | … |
| Web UI layer (styling + component library, §3a) | … | | | |
| Backend | … | | | |
| Database | … | | | |
| Mobile (if any) | … | | | |
| Hosting | … | | | |
- Write for a business reader: what each choice means for cost, speed of delivery, hiring and maintenance, not framework internals.
- If the client's preference differs from the recommendation, show both columns and the deciding driver. If their stack can't meet a must-have, say which one and what would change.
- After G1: the stack ADR records `accepted (g1, <date>) · confirmed by <human>`, with the client's preference and any accepted risk. Changing the confirmed stack later is a change request on g1 (a major decision).
