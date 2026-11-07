# GitHub Issues tracker (gh CLI)

Requires `gh auth status` to succeed in a repo that has a GitHub remote. Otherwise fall back to **local** and report `BLOCKED: gh not authenticated`.

## Mapping
| Ticket field | GitHub |
|---|---|
| `id` | Title prefix `[T-nnn]` |
| `role` | Label `role:<role>` (`gh label create role:<role> --force`) |
| `milestone` | Milestone `ms-<n>` (`gh api repos/{owner}/{repo}/milestones -f title=ms-<n>` if it's missing) |
| `status` | Label `status:<status>`. `done` closes the issue |
| `depends_on` | A `Depends on: #<n>` line in the body (plus native sub-issues/dependencies where enabled) |
| other fields | Body sections in the format of `local.md` |

## Commands
```bash
gh issue create --title "[T-001] <title>" --label "role:backend,status:ready" --milestone "ms-1" --body-file <tmpfile>
gh issue list --milestone "ms-1" --label "status:ready" --json number,title,labels --limit 200
gh issue edit <n> --remove-label "status:ready" --add-label "status:in_progress"
gh issue comment <n> --body-file <tmpfile>
gh issue close <n> --reason completed
```
Write bodies to a temporary file and pass `--body-file`, rather than putting them inline.
