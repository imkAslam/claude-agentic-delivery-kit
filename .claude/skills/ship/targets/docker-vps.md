# Target: Docker on a VPS

Best for full control at low cost. You own TLS, backups, patching and monitoring.

1. **Files:** a `Dockerfile` (multi-stage, non-root, healthcheck; see the `setup-docker` skill), `compose.prod.yml` (app + database + reverse proxy, images referenced by **digest**), a reverse-proxy config with automatic TLS (e.g. Caddy), and `infra/backup.sh` (database dump to off-host storage).
2. **CI steps:**
   ```bash
   docker build -t "$REGISTRY/$IMAGE:$GIT_SHA" . && docker push "$REGISTRY/$IMAGE:$GIT_SHA"
   digest=$(docker inspect --format='{{index .RepoDigests 0}}' "$REGISTRY/$IMAGE:$GIT_SHA")
   # deploy: copy compose + set IMAGE_REF=$digest, then on the host:
   ssh -i key "$VPS_USER@$VPS_HOST" "cd /srv/app && IMAGE_REF=$digest docker compose -f compose.prod.yml pull && \
     docker compose -f compose.prod.yml run --rm app <migrate cmd> && \
     IMAGE_REF=$digest docker compose -f compose.prod.yml up -d --wait"
   curl -fsS "$URL$HEALTH_PATH"
   ```
   Load the SSH key from a CI secret into a temporary file with mode 600, and pin the host key with `known_hosts`. Use a separate host, or a separate compose project, for staging.
3. **Secrets:** `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `VPS_KNOWN_HOSTS`, registry credentials, and the app secrets in an env file on the host (`chmod 600`, never committed).
4. **Health:** a container `HEALTHCHECK` plus the `deploy.health_path` endpoint. `up --wait` fails the job if the container is unhealthy.
5. **Rollback:** redeploy the previous digest (`IMAGE_REF=<previous> docker compose up -d --wait`). For data, restore from the last `backup.sh` dump, taken automatically before every migration.
6. **Bootstrap:** provision the VPS (non-root deploy user, SSH keys only, firewall open on 22/80/443 only, unattended security updates); install Docker; point DNS at it; create the registry; schedule backups and test a restore; add the CI secrets.
