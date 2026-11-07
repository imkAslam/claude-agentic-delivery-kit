# Targets: Fly.io · Railway · Render

Managed container platforms with managed databases. A middle ground between Vercel and a VPS.

## Fly.io (`fly`)
1. **Files:** `fly.toml` (app, primary region, `[http_service]` with a health check, `[deploy] release_command = "<migrate cmd>"`), plus the `Dockerfile`.
2. **CI:** `flyctl deploy --remote-only --config fly.toml --app <app-staging|app-prod> --image-label "$GIT_SHA"`. For production, deploy the same image: `flyctl deploy --image registry.fly.io/<app>:<label>`.
3. **Secrets:** `FLY_API_TOKEN` (a deploy token scoped to the app); app secrets through `flyctl secrets set` by the human, or from CI with values taken from the CI store.
4. **Health:** a `[[http_service.checks]]` entry on `deploy.health_path`.
5. **Rollback:** `flyctl releases --app <app>`, then redeploy the previous image with `flyctl deploy --image <previous>`. For data, restore a managed Postgres snapshot.
6. **Bootstrap:** create the staging and production apps and the Postgres clusters, attach them, create deploy tokens, set DNS and certificates.

## Railway (`railway`)
1. **Files:** `railway.toml` or `railway.json` (build, start command, health check path, pre-deploy migrate command).
2. **CI:** `railway up --service <service> --environment <staging|production> --detach`, using `RAILWAY_TOKEN` (a project token scoped to the environment).
3. **Secrets:** `RAILWAY_TOKEN` per environment; app variables set in Railway.
4. **Health:** `healthcheckPath` = `deploy.health_path`.
5. **Rollback:** redeploy the previous deployment (the dashboard, or `railway redeploy` where supported). For data, restore a database backup.
6. **Bootstrap:** create the project, the environments and the database; create the environment tokens.

## Render (`render`)
1. **Files:** a `render.yaml` blueprint (services, `healthCheckPath`, `preDeployCommand` for migrations, databases). Turn auto-deploy off.
2. **CI:** call the service's **deploy hook URL** (stored as a secret) or the Render API with an image reference. Then poll the deploy status.
3. **Secrets:** `RENDER_DEPLOY_HOOK_STAGING`, `RENDER_DEPLOY_HOOK_PRODUCTION` (or `RENDER_API_KEY` + service IDs).
4. **Health:** `healthCheckPath` = `deploy.health_path`.
5. **Rollback:** roll back to the previous deploy in the dashboard or through the API. For data, restore a database backup.
6. **Bootstrap:** apply the blueprint once from the dashboard, create the deploy hooks, set the env groups.
