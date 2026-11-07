# BOOTSTRAP.md template (one-time human steps)

```markdown
> Status: in-review · Owner: devops-engineer · Sources: DEVOPS-PLAN.md, ship/<target>, ci/<kind> · Updated: <ISO>

# Bootstrap checklist

The human performs these steps once. Agents never handle credential values. When you're done, tell the orchestrator so the system-detector can re-check them (by name only).

## 1. Accounts and projects
- [ ] Create or confirm the hosting account and project for **staging** and **production** (<target>)
- [ ] Create the managed database for each environment (<provider>), with backups enabled
- [ ] (Mobile) Expo project, Apple Developer and Google Play accounts, app records

## 2. Repository and CI
- [ ] Create the remote repository and push the default branch
- [ ] Protect the default branch: required checks `checks`, `e2e`; review required
- [ ] Create the environments `staging` and `production`; add the required approvers to `production`

## 3. Secrets / variables (names only; values go into the CI or platform secret store)
| Name | Environment(s) | Where to get it |
|---|---|---|
| <NAME> | staging, production | <provider console → section> |

## 4. DNS and TLS
- [ ] Point <staging host> and <prod host> to the platform (records listed by the target)
- [ ] Confirm the certificates are issued

## 5. Verification
- [ ] `gh secret list` / `glab variable list` shows every name above
- [ ] The first staging pipeline is green and `<staging_url><health_path>` returns 200
```
