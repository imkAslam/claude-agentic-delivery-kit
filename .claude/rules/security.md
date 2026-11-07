# Security rules (always on)

- Never write secrets, tokens, private keys, passwords or connection strings with credentials into any file, commit, ticket, log or chat. Reference them by **environment-variable name** only, and list the names in `.env.example` and `.claude/project.json → deploy.required_secrets`.
- Never print, read back or `echo` secret values, including from CI secret stores or `.env` files.
- **Deployments run only through CI.** Don't run hosting or IaC deploy commands from the workstation. `guard-prod.sh` blocks them.
- Production pipeline triggers and release-tag pushes need a valid **G3** approval in `.claude/delivery/state.json`.
- Validate all external input at the trust boundary, use parameterized queries only, and enforce authorization server-side on every operation.
- Don't add a dependency without a stated reason in the ticket report. Prefer maintained packages with no known critical vulnerabilities.
- Dynamic security testing runs only against environments the project owns and has listed in `DEVOPS-PLAN.md`, and only with authorization recorded in the brief.
- A line that intentionally contains a fake credential for a test must carry the marker `delivery:allow-secret` and use an obviously fake value.
