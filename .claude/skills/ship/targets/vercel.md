# Target: Vercel

Best for framework-native web frontends and serverless APIs. Pair it with a managed database (Postgres, KV, blob) from a provider that offers branching or backups.

1. **Files:** `vercel.json` (framework, build output, headers, rewrites, regions), plus `.vercelignore` if needed. Disable Git auto-deploys (`"git": { "deploymentEnabled": false }`) so CI stays the only deployer.
2. **CI steps:**
   ```bash
   npx vercel pull --yes --environment=<preview|production> --token "$VERCEL_TOKEN"
   npx vercel build [--prod] --token "$VERCEL_TOKEN"
   url=$(npx vercel deploy --prebuilt [--prod] --token "$VERCEL_TOKEN")
   curl -fsS "$url$HEALTH_PATH"
   ```
   Staging is a preview deploy (optionally aliased to the staging domain). Production uses `--prod` and runs only in the protected production job. Run migrations in a step before `deploy`, using the environment's `DATABASE_URL`.
3. **Secrets:** `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`, plus app secrets set in the Vercel project's environment variables (by name).
4. **Health:** an API route at `deploy.health_path` that checks database connectivity.
5. **Rollback:** `npx vercel rollback <previous-deployment-url> --token "$VERCEL_TOKEN"`, or promote the previous deployment in CI. For data, restore the provider's point-in-time backup, or run the documented down-migration.
6. **Bootstrap:** create the Vercel project and link the domain; create a token scoped to the team; set the env vars per environment; add the CI secrets; provision the managed database for staging and production.
