# Release notes and versioning

Used by the devops-engineer in lane release (`release-prep`), with the release package in [RELEASE_TEMPLATES.md](RELEASE_TEMPLATES.md).

## Version number (semantic versioning)
- **MAJOR:** a breaking change to a contract, an API or data that users or integrations must act on.
- **MINOR:** a new user-visible feature that keeps existing behavior working.
- **PATCH:** fixes only.
- The version is set by the CI release job from the accepted candidate. Nobody edits the version by hand, and the tag is created by CI after G3 (`guard-prod.sh` blocks tag pushes from a workstation).

## Release notes template
```markdown
# Release <version> — <date>

## New features
- <what users can now do, in plain language> (ticket <id>)

## Fixes
- <what was wrong and what changed for the user> (ticket <id>)

## Improvements
- <speed, clarity or reliability change>

## Breaking changes
- <what changed> — <what users or integrations must do> (migration steps linked)

## Known issues
- <issue> — <workaround or impact>, from ACCEPTANCE.md › Open issues

## Links
- Changelog: CHANGELOG.md
- Runbook: RELEASE.md › Rollback
```

Write the notes for the people who use the product, not for the developers. Every line names a user-visible effect or it is left out of the notes and kept in the changelog.
