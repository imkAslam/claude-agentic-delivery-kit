# Free local services for development and testing

**Default: every backing service runs locally in Docker** (free, isolated, reproducible). Remote services are used for development only when Docker is unavailable, or when a service has no local substitute. Then the human provides the URLs (see "Remote fallback"). Paid services are always a budget decision for the human.

## Catalog (pin the version tag; add a healthcheck and a named volume)
| Need | Local substitute (free) | Image / tool | Typical port |
|---|---|---|---|
| PostgreSQL | PostgreSQL | `postgres:16-alpine` | 5432 |
| MySQL / MariaDB | MySQL / MariaDB | `mysql:8.4` / `mariadb:11` | 3306 |
| MongoDB | MongoDB | `mongo:7` | 27017 |
| Redis (cache, sessions, queues) | Valkey or Redis | `valkey/valkey:8-alpine` / `redis:7-alpine` | 6379 |
| S3-compatible object storage | MinIO | `minio/minio` (+ `mc` to create buckets) | 9000 / 9001 |
| Email (SMTP) | Mailpit (catches all mail, web UI) | `axllent/mailpit` | 1025 / 8025 |
| Full-text search | Meilisearch / OpenSearch | `getmeili/meilisearch` / `opensearchproject/opensearch` | 7700 / 9200 |
| Message queue | RabbitMQ / Redpanda (Kafka API) / ElasticMQ (SQS API) | `rabbitmq:3-management` / `redpandadata/redpanda` / `softwaremill/elasticmq` | 5672 / 9092 / 9324 |
| AWS APIs (S3, SQS, SNS, Lambda…) | LocalStack (community) | `localstack/localstack` | 4566 |
| Azure Storage | Azurite | `mcr.microsoft.com/azure-storage/azurite` | 10000–10002 |
| Firebase / Firestore / Auth | Firebase Emulator Suite | `firebase emulators:start` (CLI) | 4000 |
| Supabase stack | Supabase local | `supabase start` (CLI, Docker) | 54321 |
| OIDC / OAuth provider | Keycloak (dev mode) or a mock OAuth2 server | `quay.io/keycloak/keycloak` / `ghcr.io/navikt/mock-oauth2-server` | 8080 |
| Payments | The provider's **test mode** + a local mock where it exists | e.g. `stripe/stripe-mock` | 12111 |
| Antivirus scanning | ClamAV | `clamav/clamav` | 3310 |
| Observability | Grafana + OTel LGTM all-in-one | `grafana/otel-lgtm` | 3000 / 4317 |
| Scheduled jobs / workers | The app image, run with a worker command | — | — |

Social sign-in (e.g. Google) has no local substitute. In development, use the mock OIDC server; real provider test credentials are a **remote fallback** item.

## Standards for the development compose file
- One `compose.yml` (devops-owned) starts **all** dev services. `project.json → commands.dev` starts it (or the app depends on it).
- Pinned tags, healthchecks, `depends_on: condition: service_healthy`, named volumes, ports bound to `127.0.0.1` only.
- Local credentials are obvious dev placeholders defined in `.env.example` (for example `postgres`/`postgres` on localhost). The real `.env` is git-ignored.
- Seed scripts create synthetic data and buckets/queues on startup (idempotently).
- Tests use their **own** disposable instances (Testcontainers, or a separate compose project/database). They never share the dev database.
- Document every service in DEVOPS-PLAN §0 and `project.json → services`.

## Remote fallback (ask the human once)
Use it when `SYSTEM-PROFILE.md` shows Docker missing or not running, or when a service has no local substitute.
1. The orchestrator lists the services needed, with the **environment-variable names** and what each is for, plus a free-tier option where one exists (for example a free managed Postgres tier). This goes to the human once, at the next gate (or at foundation if it blocks the work).
2. The human puts the values in the **git-ignored `.env`** themselves (never in chat or tickets) and confirms.
3. The devops-engineer verifies connectivity with a health command that never prints values (e.g. `pg_isready`, or an app health check), and records "provider: remote" in `project.json → services`.
4. Agents never sign up for accounts or choose a paid tier. Costs are the human's decision.

## Staging and production
Hosting is planned separately (the `ship` skill, DEVOPS-PLAN §1–§7) within the budget the human approved. Prefer free or low-cost tiers where they meet the NFRs, and present any recurring cost at G1/G2 as a business decision.
