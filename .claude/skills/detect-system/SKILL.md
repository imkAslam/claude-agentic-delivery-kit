---
name: detect-system
description: "Builds a factual system profile: repository state and stack, installed toolchain, tracker/CI/hosting access by status only, CI secret names, and available Claude agents, skills and MCP servers. Writes docs/delivery/SYSTEM-PROFILE.md."
when_to_use: "Use before planning or building, after scaffolding, when a tool or login may have changed, or when the user asks what is installed or available."
---

# Detect system

Tables of indicators: [detection.md](references/detection.md).

## Procedure
1. **Repository:** `git rev-parse --is-inside-work-tree`, the commit count, and whether there's any source beyond `.claude/` and `docs/`. If source exists, detect the stack with the tables in `detection.md`. When `.claude/project.json` exists, its `stack` wins over detection; just report any drift between the two.
2. **Toolchain:** for each tool in the toolchain table, run `command -v <tool>` and `<tool> --version` (first line only). Mark each one present or missing.
3. **Access (status only):** `gh auth status`, `glab auth status`, and the status/whoami command of the deploy target from `project.json`. **Never print token values.** Redact anything that looks like a token in the output before writing it.
4. **CI secrets by name:** if a CI CLI is authenticated and `project.json` exists, list the secret or variable **names**. Compare them with `deploy.required_secrets` and list the missing ones.
5. **Claude capabilities:** list `.claude/agents/*.md` (names) and `.claude/skills/*/SKILL.md` (names). For MCP servers, run `claude mcp list` if it's available. Otherwise note "MCP list unavailable from shell". Flag tracker (e.g. Linear) and quality (e.g. SonarQube) integrations.
6. **Gaps and user actions:** for the chosen tracker, CI and deploy target, list what's missing, plus the exact command the user should run (an install or login). Never run installs or logins yourself.

## Output: `docs/delivery/SYSTEM-PROFILE.md`
```
> Status: draft · Owner: system-detector · Updated: <ISO>
## Repository        state, commits, architecture, languages, frameworks, package manager, tests
## Existing code     (adopt runs, or whenever product code exists) frameworks + versions, package manager, test runner, CI,
##                   migrations tool, API specs, theme/token source, UI library, size per top-level folder, and for each
##                   candidate command: ran? exit code
## Toolchain         | tool | version | status |
## Access            | service | status | command used |
## CI secrets        present names · missing required names
## Claude            agents · skills · MCP servers
## Gaps & user actions   numbered, each with a command
```
