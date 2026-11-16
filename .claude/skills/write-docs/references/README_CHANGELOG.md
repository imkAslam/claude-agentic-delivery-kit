# Root README.md and CHANGELOG.md

## README.md
```markdown
# <Product name>
One paragraph: what it does and for whom (from PRD §1).

## Quick start
1. Prerequisites: <from SYSTEM-PROFILE / BOOTSTRAP: runtime versions, Docker>
2. `cp .env.example .env` (fill values locally; never commit them)
3. **Run it locally** (three commands, the same on every project; inside Claude Code: `/start-app`, `/test-app`, `/build-app`):
   - `bash .claude/skills/deliver/scripts/app.sh start`: starts the local services (one database container; SQLite when Docker is not running), prepares the database and starts the app
   - `bash .claude/skills/deliver/scripts/app.sh test`: runs the tests
   - `bash .claude/skills/deliver/scripts/app.sh build`: runs the production build
   - `… app.sh stop` and `… app.sh status`
4. Open <local URL>; sign in with the sample accounts listed here (local only): <role → email>
5. **How this app is organised:** five to ten plain lines: the main folders, what lives where, and where to start reading (details: docs/CODEMAP.md)

## Commands
| Command | What it does |
|---|---|
<one row per project.json command: install, dev, lint, typecheck, test, e2e, build, migrate, seed>

## Architecture
3–5 lines, then links: PRD §10 (layers and D1), docs/adr/, docs/database/DATABASE.md, the contracts.

## Project structure
The top-level folders and their owners (PRD §11).

## Contributing
Branches, commits and reviews (the git rules), test-first, and where tickets live (the tracker).

## Documentation
Link to docs/CODEMAP.md and docs/SYSTEM-FLOWS.md.
```
Only commands from `project.json`; a quick start that doesn't match `REVIEW.md › Run guide` is a finding.

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
