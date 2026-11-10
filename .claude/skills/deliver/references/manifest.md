# Project manifest: `.claude/project.json`

The **solution-architect** writes this file at the `boundaries` step (lane plan). It is validated at the `foundation` step (lane build). Every agent, hook and adapter reads it. **Commands and paths are never hardcoded in the kit.** They always come from here. Until the architect creates it, the hooks fall back to safe defaults.

## Schema
```jsonc
{
  "version": 1,
  "name": "<project-slug>",
  "stack": {                          // a free choice; one ADR per significant choice in docs/adr/
    "architecture": "<monolith|modular-monolith|services|monorepo>",
    "package_manager": "<…>",
    "languages": ["<…>"],
    "frontend": "<framework|null>", "backend": "<framework|null>", "mobile": "<framework|null>",
    "orm": "<…|null>", "database": "<…|null>",
    "test": "<unit test runner>", "e2e": "<web e2e tool|null>", "mobile_e2e": "<…|null>"
  },
  "roles": {                          // enable only the roles the PRD needs
    "frontend": { "enabled": true,  "agent": "frontend-engineer", "reviewer": "frontend-reviewer",
                  "paths": ["<frontend-root>/**"], "guides": ["typescript", "react", "nextjs"],
                  "commands": { "lint": "<cmd>", "typecheck": "<cmd>", "test": "<cmd>" } },
    "backend":  { "enabled": true,  "agent": "backend-engineer",  "reviewer": "backend-reviewer",
                  "paths": ["<backend-root>/**"], "guides": ["typescript", "node", "nestjs"],   // coding-foundations guides (file names, lowercase); OOP_AND_PATTERNS and PERFORMANCE always apply; add "realtime" / "workers" only when the architecture uses them
                  "commands": { "lint": "<cmd>", "typecheck": "<cmd>", "test": "<cmd>" } },
    "mobile":   { "enabled": false, "agent": "mobile-engineer",   "reviewer": "mobile-reviewer",
                  "paths": ["<mobile-root>/**"], "commands": {} },
    "integration": { "enabled": false, "agent": "integration-engineer", "reviewer": "integration-reviewer",
                  "paths": ["<integrations-root>/**"], "commands": { "test": "<cmd>" } },   // enable when the product talks to external providers
    "devops":   { "enabled": true,  "agent": "devops-engineer",   "reviewer": "devops-reviewer",
                  "paths": ["<ci-config-path>", "<infra-root>/**", "<container-files>"],
                  "commands": { "lint": "<pipeline/IaC validate cmd>" } },
    "qa":       { "enabled": true,  "agent": "qa-agent",          "reviewer": "frontend-reviewer",
                  "paths": ["<e2e-root>/**"], "commands": { "test": "<e2e cmd>" } },
    "security": { "enabled": false, "agent": "cybersecurity-agent", "reviewer": "security-reviewer",
                  "paths": [], "commands": {} }
  },
  "shared_files": {                   // glob → the single owner (a role name or "integrator")
    "<root dependency manifest>": "integrator",
    "<lockfile>": "integrator",
    "<migrations-root>/**": "backend"
  },
  "contracts": { "type": "<openapi|graphql|rpc|…>", "paths": ["contracts/**"], "codegen_cmd": "<cmd>" },
  "pre_build_paths": ["<extra globs allowed before g2, e.g. mock-server config>"],   // optional; guard-coding.sh
  "commands": {                       // repo-wide; used by the integrator and by the commit gate on main-session commits
    "install": "<cmd>", "dev": "<cmd>", "lint": "<cmd>", "typecheck": "<cmd>",
    "test": "<cmd>", "e2e": "<cmd>", "build": "<cmd>", "migrate": "<cmd>",
    "perf": "<optional: Lighthouse / load-test cmd used by the performance-specialist>",
    "unused": "<optional: unused files/exports/dependencies check, e.g. knip, vulture; used by check-hygiene.sh>"
  },
  "dev_url": "http://localhost:<port>",
  "services": [                        // backing services for dev/test (see setup-docker → LOCAL_SERVICES.md)
    { "name": "db",   "kind": "postgres", "provider": "docker", "image": "postgres:16-alpine", "env": ["DATABASE_URL"] },
    { "name": "mail", "kind": "smtp",     "provider": "docker", "image": "axllent/mailpit",    "env": ["SMTP_HOST", "SMTP_PORT"] }
    // "provider": "remote" only when Docker is unavailable or there's no local substitute; the human sets the values in .env
  ],
  "tracker": { "kind": "local|linear|github", "project": "<key or repo>", "team": "<team|null>" },
  "ci":      { "kind": "github|gitlab", "default_branch": "main" },
  "deploy": {
    "target": "vercel|docker-vps|fly|railway|render|aws",
    "mobile_target": "eas|null",
    "staging_url": "<url>", "prod_url": "<url>", "health_path": "/health",
    "required_secrets": ["<SECRET_NAME>", "…"],      // names only, never values
    "prod_markers": ["prod", "production"]           // words that mark a production pipeline trigger
  },
  "tools": { "gitleaks": false, "sonarqube": false, "coderabbit": false, "strix": false },   // detected, never assumed
  "validated_at": null
}
```

## Rules
- `paths` globs are relative to the repo root and use `*`, `**` and `?` only (no `{a,b}` braces). Hooks and the ownership check match against them.
- Owned paths of enabled roles **must not overlap**, except through `shared_files`, which names one owner per glob.
- After G2, `contracts.paths` are read-only for every role, and for the solution-architect too unless a change request on `g2` is open.
- `deploy.required_secrets` are checked by **name** only (`gh secret list` / `glab variable list`).
- Whenever this file changes, the solution-architect also refreshes `.claude/PROJECT.md` (the short summary that `CLAUDE.md` imports).
