# Stack selection

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
