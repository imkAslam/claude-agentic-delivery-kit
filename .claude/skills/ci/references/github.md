# GitHub Actions

Requires `gh auth status`. Validate workflow files with `actionlint` when it's installed.

## Files
- `.github/workflows/ci.yml`: on `pull_request` and `push`. Jobs: `checks` (install/lint/typecheck/test/build), `e2e`.
- `.github/workflows/deploy.yml`: `on: push` to the default branch (staging) **and** `workflow_dispatch` with an input `environment` (`staging|production`) and an input `artifact`.

## Skeleton (fill the steps from `project.json` and the `ship` target)
```yaml
name: deploy
on:
  push: { branches: [main] }
  workflow_dispatch:
    inputs:
      environment: { type: choice, options: [staging, production], default: staging }
      artifact:    { type: string, required: false, description: "image digest / build id to promote" }
permissions: { contents: read, id-token: write }   # id-token for OIDC to the cloud
concurrency: { group: deploy-${{ inputs.environment || 'staging' }}, cancel-in-progress: false }
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment || 'staging' }}   # "production" must have required reviewers
    steps:
      - uses: actions/checkout@v4
      # build or fetch the artifact, then the deploy steps from ship/targets/<target>.md
      # smoke: curl -fsS "$URL$HEALTH_PATH"
```
Pin third-party actions to a full commit SHA in production workflows.

## Commands
```bash
gh secret list                                   # names only
gh api repos/{owner}/{repo}/environments --jq '.environments[].name'
gh workflow run deploy.yml -f environment=staging
gh workflow run deploy.yml -f environment=production -f artifact=<digest>   # after G3 only
gh run list --workflow deploy.yml --limit 5
gh run watch <run-id> --exit-status
gh run view <run-id> --log-failed
gh pr create --base main --head ms-1/integration --title "<title>" --body-file <tmpfile>
```

## Bootstrap (the human does this once; list it in BOOTSTRAP.md)
Create the `staging` and `production` environments, add the required reviewers to `production`, add the secrets named in `deploy.required_secrets`, and protect the default branch (require the `checks` job).
