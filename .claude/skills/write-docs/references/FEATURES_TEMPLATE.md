# docs/FEATURES.md: the feature catalog

```markdown
# Features
> Source of truth: PRD §4 (features and stories) and §7 (release slicing) · Updated: <ISO> after <step> · Maintained by docs-writer

## Summary
| Status | Count |
|---|---|
| planned · in progress · built · accepted · released · deferred | n · n · n · n · n · n |

## Catalog
| Id | Feature | For (persona) | Priority | Release / milestone | AC | Screens | API operations | Tickets | Open bugs | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| F-1 | Invite a guest to a project | Project owner | Must | MVP / ms-1 | AC-INV-1..4 | S-04, S-12 | createInvite, acceptInvite | T-010, T-011, T-012 | T-077 (P2) | built |
| F-2 | Export tasks as CSV | Admin | Could | Later | AC-EXP-1 | — | — | — | — | deferred (g1 decision D-7) |

## Feature details (one block per feature, short)
### F-1 · Invite a guest to a project
- **Value:** the client's goal it serves (PRD §1 G-…)
- **Behavior:** 2–4 lines in plain language; business rules BR-…
- **Out of scope:** what this feature deliberately doesn't do
- **Evidence:** the E2E test and screenshots once built (`milestones/<ms>/evidence/…`)
- **Changes:** CR ids that changed it, if any
```

Rules: priority uses MoSCoW from the PRD; status moves only forward on evidence (built = the ticket is merged after the milestone review; accepted = the acceptance gate; released = g3 + deployment result). A deferred feature keeps its row and the decision that deferred it.
