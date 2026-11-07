# Root README.md and CHANGELOG.md

## README.md
```markdown
# <Product name>
One paragraph: what it does and for whom (from PRD §1).

## Quick start
1. Prerequisites: <from SYSTEM-PROFILE / BOOTSTRAP: runtime versions, Docker>
2. `cp .env.example .env` (fill values locally; never commit them)
3. Start local services: <project.json command, e.g. docker compose up -d>
4. Install and run: <project.json commands.install>, <commands.dev>
5. Open <local URL>; sign in with the seeded test user from the seed file

## Commands
| Command | What it does |
|---|---|
<one row per project.json command: install, dev, lint, typecheck, test, e2e, build, migrate, seed>

## Architecture
3–5 lines, then links: PRD §10 (layers and D1), docs/adr/README.md, docs/database/DATABASE.md, the contracts.

## Project structure
The top-level folders and their owners (PRD §11).

## Contributing
Branches, commits and reviews (the git rules), test-first, and where tickets live (the tracker).

## Documentation
Link to docs/README.md.
```
Only commands from `project.json`; a quick start that doesn't match `RUN-GUIDE.md` is a finding.

## CHANGELOG.md (Keep a Changelog + semantic versioning)
```markdown
# Changelog
All notable changes to this project are documented here.

## [Unreleased]
### Added
- Guests can open a shared project board (F-1, T-012)
### Changed
### Fixed
### Security

## [1.0.0] - <date>
…
```
One line per **user-visible** change, written for the client, with the feature and ticket ids. `[Unreleased]` is updated each milestone; at release it becomes the version named at g3.
