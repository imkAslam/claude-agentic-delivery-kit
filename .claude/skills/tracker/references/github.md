# GitHub Issues tracker (gh CLI)

Requires `gh auth status` to succeed in a repo that has a GitHub remote. Otherwise fall back to **local** and report `BLOCKED: gh not authenticated`.

## Mapping
| Ticket field | GitHub |
|---|---|
| `id` | Title prefix `[T-nnn]` |
| `role` | Label `role:<role>` (`gh label create role:<role> --force`) |
| `milestone` | Milestone `ms-<n>` (`gh api repos/{owner}/{repo}/milestones -f title=ms-<n>` if it's missing) |
| `type`, `size`, `severity` | Labels `type:<type>`, `size:<S|M|L>`, `severity:<P1|P2|P3>` |
| `status` | Label `status:<status>`. `done`/`verified` close the issue (`verified` keeps a `status:verified` label); `reopened` reopens it (`gh issue reopen`); `cancelled` closes it as not planned |
| `bug_of` | A `Bug of: #<n> (T-<original>)` line at the top of the body; GitHub then shows the link on the original's timeline. Also comment on the original. Add the bug as a sub-issue of the original where sub-issues are enabled |
| `history` | One comment per status change: `status: <from> → <to> (<note>)` |
| `depends_on` | A `Depends on: #<n>` line in the body (plus native sub-issues/dependencies where enabled) |
| other fields | Body sections in the format of `local.md` |

## Commands
```bash
gh issue create --title "[T-001] <title>" --label "role:backend,status:ready" --milestone "ms-1" --body-file <tmpfile>
gh issue list --milestone "ms-1" --label "status:ready" --json number,title,labels --limit 200
gh issue edit <n> --remove-label "status:ready" --add-label "status:in_progress"
gh issue comment <n> --body-file <tmpfile>
gh issue close <n> --reason completed
gh issue reopen <n>
gh issue create --title "[T-045] bug: <symptom>" --label "type:bug,severity:P1,role:backend,status:ready" --milestone "ms-2" --body-file <tmpfile>   # body starts with "Bug of: #12 (T-010)"
gh issue comment 12 --body "Bug T-045 (#<new>) reported against this ticket: <symptom>"
```
Write bodies to a temporary file and pass `--body-file`, rather than putting them inline.
