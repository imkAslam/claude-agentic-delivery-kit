# Versioning and API evolution

## Breaking vs. non-breaking
| Non-breaking (allowed within a version) | Breaking (needs a new version or expand/contract) |
|---|---|
| Adding an optional request field, a response field, a new operation, a new enum value that clients are told to tolerate, a new error code with a documented fallback | Removing or renaming a field, operation or enum value; changing a type or format; making an optional field required; changing default behavior, status codes or auth requirements; tightening validation |
Rule for consumers (in the guidelines): **ignore unknown fields, and handle unknown enum values gracefully.**

## Strategy
| API audience | Strategy |
|---|---|
| First-party only (our web and mobile apps) | One version, additive changes; expand → migrate consumers → contract. Mobile needs a long tail (old app versions in the field): keep old fields until analytics shows the old versions have gone |
| Public or partner | A URL major version (`/v1`, `/v2`); at least 2 versions live during migration; a published deprecation timeline |
| Events / webhooks | Version in the event type (`task.assigned.v2`); publish v1 and v2 in parallel during migration |

## Deprecation process
1. Mark it in the contract (`deprecated: true`, or the GraphQL `@deprecated`) with the replacement.
2. Send the `Deprecation` and `Sunset: <date>` headers (plus a `Link` to the migration guide) on deprecated operations.
3. Add an API-CHANGELOG entry plus a migration note; notify the consumers (the orchestrator raises client-facing deprecations at a gate when external consumers exist).
4. Monitor usage; remove only after the sunset date **and** zero (or accepted) usage.

## API-CHANGELOG.md
```markdown
## <date> — v1.4.0
### Added
- `GET /projects/{projectId}/activity` (AC-AUD-2)
### Deprecated
- `task.assigneeEmail` → use `task.assignee.id` (sunset 2027-06-01)
### Fixed
- `PATCH /tasks/{id}` returns 412 on a version mismatch (was 409)
```

## In the kit's workflow
- After G2, every contract change is a CR on g2 plus a ticket for the api-designer. It must state: breaking or not, the affected consumers, the migration plan.
- CI runs a breaking-change check against the last released contract (an OpenAPI diff, buf breaking, GraphQL schema diff) when such a tool is available.
