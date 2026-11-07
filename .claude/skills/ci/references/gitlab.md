# GitLab CI

Requires `glab auth status`. Validate with `glab ci lint` when it's available.

## File: `.gitlab-ci.yml`
```yaml
stages: [checks, build, e2e, deploy-staging, deploy-production]
default:
  interruptible: true
checks:
  stage: checks
  script: ["<install>", "<lint>", "<typecheck>", "<test>"]
build:
  stage: build
  script: ["<build and push the artifact; export the digest in a dotenv report>"]
  artifacts: { reports: { dotenv: build.env } }
e2e:
  stage: e2e
  script: ["<e2e>"]
deploy-staging:
  stage: deploy-staging
  environment: { name: staging, url: "$STAGING_URL" }
  rules: [{ if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH' }]
  script: ["<ship target deploy steps>", "curl -fsS \"$STAGING_URL$HEALTH_PATH\""]
deploy-production:
  stage: deploy-production
  environment: { name: production, url: "$PROD_URL" }
  rules: [{ if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH', when: manual }]
  allow_failure: false
  resource_group: production
  script: ["<ship target deploy steps using the same digest>", "curl -fsS \"$PROD_URL$HEALTH_PATH\""]
```
Fill in the commands from `project.json` and the `ship` target. Mark the `production` environment as **protected**, with approval rules.

## Commands
```bash
glab variable list                         # names only
glab ci status                             # current pipeline
glab ci list --per-page 5
glab ci view                               # interactive; prefer: glab ci get --pipeline-id <id>
glab ci trace <job-id>                     # logs of a failed job
glab ci run --branch main                  # new pipeline (staging deploy runs automatically)
# production: play the manual job of the approved pipeline (after G3 only)
glab api --method POST "projects/:id/jobs/<deploy-production-job-id>/play"
glab mr create --source-branch ms-1/integration --target-branch main --title "<title>" --description "<text>"
```
Check `glab <cmd> --help` for the flags of the installed version before running.

## Bootstrap (the human does this once; list it in BOOTSTRAP.md)
Create the `staging` and `production` environments, protect `production` with approvers, add the masked/protected CI variables named in `deploy.required_secrets`, and protect the default branch.
