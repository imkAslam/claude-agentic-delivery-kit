# Linear tracker (MCP)

Requires a connected Linear MCP server. Find its tools by searching the available tools for `linear`. Tool names vary by server version, so look for the issue create, update, list/search, comment and label operations. If no Linear tools are available, fall back to **local** and report `BLOCKED: Linear MCP not connected`.

## Mapping
| Ticket field | Linear |
|---|---|
| `id` (T-nnn) | Title prefix `[T-nnn]`, which keeps the stable id searchable |
| `role` | Label `role:<role>` (create the label if it's missing) |
| `milestone` | Project milestone, or cycle, named `ms-<n>` in project `tracker.project`, team `tracker.team` |
| `depends_on` | A "blocked by" relation to the issue for each dependency |
| `type`, `size`, `severity` | Labels `type:<type>` (bugs also use the team's Bug label), `size:<S|M|L>`, `severity:<P1|P2|P3>` (or the Linear priority: P1 → Urgent, P2 → High, P3 → Medium) |
| `bug_of` | A "related" relation from the bug to the original issue, a `Bug of: <ORIGINAL-ID> (T-…)` line in the description, and a comment on the original |
| `acceptance`, `test_cases`, `contracts`, `owned_paths` | A description section in the format of `local.md` |
| `tracker_ref` | The Linear issue identifier or URL |

## Status mapping
`backlog` → Backlog · `ready` → Todo · `in_progress` → In Progress · `in_review` / `changes_requested` / `approved` → In Review (with a `changes-requested` or `approved` label) · `done` → Done · `verified` → Done + `verified` label · `reopened` → Todo + `reopened` label · `blocked` → the team's blocked state, or a `blocked` label plus a comment · `cancelled` → Canceled. Post a comment for every status change (`status: <from> → <to> (<note>)`).

## Notes
- Create the tickets in dependency order, so the blocking relations can reference existing issues.
- Still mirror every ticket to `docs/delivery/TICKETS.md` (id, title, role, milestone, status, tracker_ref). That file goes into the G2 package.
