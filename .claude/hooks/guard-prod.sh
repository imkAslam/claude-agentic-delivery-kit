#!/usr/bin/env bash
# PreToolUse (Bash): enforces "deploys only through CI" and the G3 production gate.
#  - always blocks: local deploy/apply/submit CLIs, destructive git (force push, reset --hard, clean -f, --no-verify),
#    migrations against non-local databases, and direct writes to the run state file
#  - blocks production pipeline triggers and release-tag pushes unless gate g3 is approved with matching hashes
DL_INPUT="$(cat)"
. "$(dirname "$0")/lib.sh"
dl_has_jq || exit 0

cmd=$(dl_json '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0

deny() {
  dl_block "Blocked by guard-prod: $1" \
    "Deployments, infrastructure changes and production operations run only through the CI pipeline (see the ci and ship skills)." \
    "${2:-If you believe this is wrong, stop and ask the user. Do not work around the hook.}"
}

markers=$(dl_manifest '(.deploy.prod_markers // ["prod","production"]) | join("|")')
[ -n "$markers" ] || markers="prod|production"
prod_re="(^|[^a-z0-9])(${markers})([^a-z0-9]|$)"

# Direct writes to the run state (it changes only through delivery-state.sh)
if printf '%s' "$cmd" | grep -q '\.claude/delivery/state\.json'; then
  if printf '%s' "$cmd" | grep -Eq '(>|tee[[:space:]]|mv[[:space:]]|cp[[:space:]]|sed[[:space:]]+-i|rm[[:space:]]|truncate|perl[[:space:]]+-[a-z]*i)'; then
    printf '%s' "$cmd" | grep -q 'delivery-state\.sh' || deny "direct modification of .claude/delivery/state.json" "Use: bash .claude/skills/deliver/scripts/delivery-state.sh <command>"
  fi
fi

needs_g3=""
while IFS= read -r seg; do
  s=$(dl_norm "$seg")
  [ -n "$s" ] || continue
  low=$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')
  git_re='^git([[:space:]]+-c[[:space:]]+[^[:space:]]+)*[[:space:]]+'

  # destructive git
  if printf '%s' "$low" | grep -Eq "${git_re}push([[:space:]]|$)"; then
    printf '%s' "$low" | grep -Eq '[[:space:]](-f|--force|--force-with-lease|--force-if-includes)([[:space:]=]|$)|[[:space:]]\+[^[:space:]]+' && deny "force push"
    printf '%s' "$low" | grep -Eq '[[:space:]](--tags|--follow-tags)([[:space:]]|$)|refs/tags/|[[:space:]]v[0-9]+\.[0-9]+' && needs_g3="release tag push"
  fi
  printf '%s' "$low" | grep -Eq "${git_re}reset[[:space:]].*--hard" && deny "git reset --hard"
  printf '%s' "$low" | grep -Eq "${git_re}clean[[:space:]]+(-[a-z]*f|--force)" && deny "git clean -f"
  printf '%s' "$low" | grep -Eq "^git[[:space:]].*--no-verify" && deny "--no-verify bypasses the commit gate"

  # local deploy / apply / submit CLIs (CI-only)
  if printf '%s' "$low" | grep -Eq '^vercel([[:space:]]|$)'; then
    printf '%s' "$low" | grep -Eq '^vercel[[:space:]]+(whoami|ls|list|inspect|logs|pull|build|link|login|help|--version|--help|-v|env[[:space:]]+(ls|list|pull))([[:space:]]|$)' \
      || deny "local Vercel deploy or change ('$s')"
  fi
  printf '%s' "$low" | grep -Eq '^(fly|flyctl)[[:space:]]+(deploy|launch|destroy|scale|secrets[[:space:]]+(set|unset|import)|releases[[:space:]]+rollback|machines?[[:space:]]+(run|update|destroy|stop|start|restart)|apps[[:space:]]+destroy|postgres[[:space:]]+(create|destroy|attach))' && deny "local Fly.io change ('$s')"
  printf '%s' "$low" | grep -Eq '^railway[[:space:]]+(up|redeploy|down|deploy|variables[[:space:]].*--set)' && deny "local Railway deploy ('$s')"
  printf '%s' "$low" | grep -Eq '^render[[:space:]]+(deploy|deploys[[:space:]]+create|services[[:space:]]+(delete|update))' && deny "local Render deploy ('$s')"
  printf '%s' "$low" | grep -Eq '^(terraform|tofu)([[:space:]]+-chdir=[^[:space:]]+)?[[:space:]]+(apply|destroy|import|taint|untaint|force-unlock|state[[:space:]]+(rm|mv|push))' && deny "local infrastructure apply ('$s')" "Local 'plan'/'validate' are fine; apply runs in CI after review."
  printf '%s' "$low" | grep -Eq '^pulumi[[:space:]]+(up|update|destroy|refresh|import)' && deny "local Pulumi apply ('$s')"
  printf '%s' "$low" | grep -Eq '^(cdk|aws-cdk)[[:space:]]+(deploy|destroy|bootstrap)' && deny "local CDK deploy ('$s')" "Local 'cdk synth'/'cdk diff' are fine."
  printf '%s' "$low" | grep -Eq '^(sam[[:space:]]+(deploy|delete|sync)|(serverless|sls)[[:space:]]+(deploy|remove))' && deny "local serverless deploy ('$s')"
  printf '%s' "$low" | grep -Eq '^aws[[:space:]].*[[:space:]](deploy|create-stack|update-stack|delete-stack|update-service|update-function-code|run-task|rb|rm|sync|mv|(create|update|delete|put|terminate|start|stop|modify|restore|reboot)-[a-z0-9-]+)([[:space:]]|$)' && deny "mutating AWS CLI call ('$s')" "Read-only describe/list/get calls are fine."
  printf '%s' "$low" | grep -Eq '^kubectl[[:space:]](.*[[:space:]])?(apply|create|delete|replace|patch|rollout|scale|set|edit|drain|cordon|annotate|label)([[:space:]]|$)' && deny "kubectl change ('$s')"
  printf '%s' "$low" | grep -Eq '^helm[[:space:]]+(install|upgrade|uninstall|delete|rollback)' && deny "helm release change ('$s')"
  printf '%s' "$low" | grep -Eq '^(eas|eas-cli)[[:space:]]+(build|submit|update|channel:edit|branch:delete)' && deny "local EAS build/submit/update ('$s')"
  printf '%s' "$low" | grep -Eq '^docker[[:space:]]+(push|(-h|--host|--context)[[:space:]])' && deny "docker push or remote docker host"
  printf '%s' "$seg" | grep -Eq 'DOCKER_HOST=(ssh|tcp)://' && deny "remote docker host"
  printf '%s' "$low" | grep -Eq '^ssh[[:space:]].*(docker|compose|systemctl|kubectl|helm|deploy|migrate|psql|mysql)' && deny "remote deploy/ops over ssh"
  printf '%s' "$low" | grep -Eq '^(scp|rsync)[[:space:]].*[^[:space:]]+@[^[:space:]]+:' && deny "copying files to a remote host"

  # migrations against non-local databases
  if printf '%s' "$low" | grep -Eq '(migrate|db:push|db[[:space:]]+push|alembic[[:space:]]+upgrade|flyway|liquibase|migration:run|goose[[:space:]]+up|dbmate[[:space:]]+up|db:migrate)'; then
    printf '%s' "$low" | grep -Eq "$prod_re" && deny "migration that references production ('$s')" "Production migrations run only in the CI deploy job after G3."
    url=$(printf '%s' "$seg" | grep -Eo '(^|[[:space:]])[A-Z_]*(DATABASE_URL|DB_URL|DB_HOST)=[^[:space:]]+' | head -n 1)
    if [ -n "$url" ] && ! printf '%s' "$url" | grep -Eqi '(localhost|127\.0\.0\.1|::1|host\.docker\.internal|@db[:/]|@postgres[:/]|@mysql[:/]|=db$|=postgres$|sqlite|file:)'; then
      deny "migration against a non-local database ('$s')" "Run migrations locally against a disposable database; remote migrations run in CI."
    fi
  fi

  # production pipeline triggers and releases (allowed only with a valid G3)
  if printf '%s' "$low" | grep -Eq '^gh[[:space:]]+(workflow[[:space:]]+run|api[[:space:]].*(dispatches|deployments))'; then
    printf '%s' "$low" | grep -Eq "$prod_re" && needs_g3="production workflow trigger"
  fi
  printf '%s' "$low" | grep -Eq '^(gh|glab)[[:space:]]+release[[:space:]]+create' && needs_g3="release creation"
  if printf '%s' "$low" | grep -Eq '^glab[[:space:]]+(ci[[:space:]]+(run|trigger|retry)|pipeline[[:space:]]+run)'; then
    printf '%s' "$low" | grep -Eq "$prod_re" && needs_g3="production pipeline trigger"
  fi
  printf '%s' "$low" | grep -Eq '^glab[[:space:]]+api[[:space:]].*jobs/[^[:space:]]*/play' && needs_g3="manual (production) job"
  if printf '%s' "$low" | grep -Eq '^(curl|wget|http|https|xh)[[:space:]]'; then
    printf '%s' "$low" | grep -Eq "$prod_re" && printf '%s' "$low" | grep -Eq '(deploy|hook|release|promote)' && needs_g3="production deploy hook"
  fi
done < <(dl_segments "$cmd")

if [ -n "$needs_g3" ] && ! dl_g3_valid; then
  dl_block "Blocked by guard-prod: ${needs_g3} needs an approved G3 (named release) whose package is unchanged." \
    "Check with: bash .claude/skills/deliver/scripts/delivery-state.sh verify g3" \
    "Present the gate to the human with the gate-review skill first."
fi
exit 0
