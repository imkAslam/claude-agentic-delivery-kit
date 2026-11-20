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
  rules: [{ if: '$CI_COMMIT_BRANCH == "develop" || $CI_COMMIT_BRANCH =~ /^(release|hotfix)\//' }]
  script: ["<ship target deploy steps>", "curl -fsS \"$STAGING_URL$HEALTH_PATH\""]
deploy-production:   # the release/hotfix pipeline's own artifact, played after G3
  stage: deploy-production
  environment: { name: production, url: "$PROD_URL" }
  rules: [{ if: '$CI_COMMIT_BRANCH =~ /^(release|hotfix)\//', when: manual }]
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
glab ci run --branch develop               # new pipeline (staging deploy runs automatically)
# production: play the manual job of the approved release/hotfix pipeline (after G3 only)
glab api --method POST "projects/:id/jobs/<deploy-production-job-id>/play"
glab mr create --source-branch ms-1/integration --target-branch develop --title "<title>" --description "<text>"   # after mbr:ms-1
glab mr create --source-branch release/v1.0.0 --target-branch main --title "chore(release): v1.0.0" --description "<text>"   # after g3
glab mr view <iid> --output json           # wait-merged: poll until "state" is "merged"
git fetch origin && git tag -a v1.0.0 -m "v1.0.0" origin/main && git push origin v1.0.0   # after g3 (guard-prod checks it)
```
Check `glab <cmd> --help` for the flags of the installed version before running.

## Bootstrap (the human does this once; list it in BOOTSTRAP.md)
Create the `staging` and `production` environments, protect `production` with approvers, add the masked/protected CI variables named in `deploy.required_secrets`, publish `develop` (`git push -u origin develop`), and protect **`main` and `develop`** (allowed to push: no one; allowed to merge: maintainers; force-push off), require one MR approval and a passing pipeline, and set the merge method to **merge commit** (milestones and releases merge with one).
