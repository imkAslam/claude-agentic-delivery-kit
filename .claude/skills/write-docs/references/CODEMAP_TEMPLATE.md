# docs/CODEMAP.md: where the code lives

The map agents read **before** opening code, so they go straight to the right files instead of exploring. Built from the real tree (`git ls-files`, the entry points in `project.json`, the folder structure in PRD §11) at every `milestone` run. Keep it to about 150 lines: point, don't describe.

```markdown
# Code map
> Updated: <ISO> after <ms-n> · Maintained by docs-writer · Planned structure: PRD §11

## Modules
| Path | Role (owner) | Purpose | Entry point | Depends on |
|---|---|---|---|---|
| <apps/web/> | frontend | <web app> | <src/main.tsx> | <contracts client> |
| <services/api/> | backend | <HTTP API> | <src/server.ts> | <db, queue> |
| <contracts/> | api-designer (frozen at g2) | <OpenAPI + generated clients> | <openapi.yaml> | — |

## Features → code
| Feature | Screens / routes | API operations | Backend module | Tables | Tests |
|---|---|---|---|---|---|
| F-1 <name> | <path> | <operationId> | <path> | <table> | <path> |

## Shared files (single owner)
| File | Owner | Change by |
|---|---|---|
| <lockfile> | integrator | regenerated at merge |
| <migrations/> | backend | backend ticket + database-reviewer |
| <CI config> | devops | devops ticket |

## Conventions that save searching
- <where tests live next to code, naming>
- <where config and env names are read>
- <generated code: never edit; regenerate with commands.codegen>
```

**Rules:** paths must exist (verify with `git ls-files`); no code excerpts; a path that moved is updated, not left dead; a module with no owner in `project.json` is a finding for the solution-architect.
