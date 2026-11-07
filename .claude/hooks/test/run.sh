#!/usr/bin/env bash
# Tests for the delivery hooks and scripts. Builds a throwaway git repo with a sample manifest and state,
# feeds hook JSON on stdin, and asserts exit codes. Usage: bash .claude/hooks/test/run.sh
set -u
KIT=$(cd "$(dirname "$0")/../.." && pwd -P)          # the .claude directory under test
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO"
# Copy only the kit itself: never a project's run state, worktrees (with node_modules) or local settings.
mkdir -p "$REPO/.claude"
for part in agents hooks rules skills settings.json; do
  [ -e "$KIT/$part" ] && cp -R "$KIT/$part" "$REPO/.claude/"
done
export CLAUDE_PROJECT_DIR="$REPO"
cd "$REPO" && git init -q && git config user.email t@t && git config user.name t
H="$REPO/.claude/hooks"; S="$REPO/.claude/skills/deliver/scripts/delivery-state.sh"

cat > .claude/project.json <<'JSON'
{ "version": 1,
  "roles": {
    "frontend": { "enabled": true, "agent": "frontend-engineer", "paths": ["web/**"], "commands": { "test": "true" } },
    "backend":  { "enabled": true, "agent": "backend-engineer",  "paths": ["api/**"], "commands": { "test": "echo backend-tests-failing; exit 1" } }
  },
  "shared_files": { "package.json": "integrator", "api/migrations/**": "backend" },
  "contracts": { "paths": ["contracts/**"] },
  "commands": { "test": "true" },
  "deploy": { "prod_markers": ["prod", "production"] } }
JSON
mkdir -p web api contracts docs/delivery
echo "x" > web/a.ts; echo "x" > api/b.ts; echo "openapi: 3.1.0" > contracts/api.yaml; echo "# PRD" > docs/delivery/PRD.md
git add -A && git commit -qm init --no-gpg-sign 2>/dev/null || git commit -qm init
bash "$S" init >/dev/null

pass=0; fail=0
check() { # check <name> <expected-exit> <hook> <json>
  local out code
  out=$(printf '%s' "$4" | bash "$H/$3" 2>&1); code=$?
  if [ "$code" -eq "$2" ]; then pass=$((pass+1)); printf '  ok   %s\n' "$1"
  else fail=$((fail+1)); printf '  FAIL %s (expected %s, got %s)\n%s\n' "$1" "$2" "$code" "$(printf '%s' "$out" | sed 's/^/       /')"; fi
}
bash_json()  { jq -nc --arg c "$1" --arg a "${2:-}" --arg d "$REPO" '{tool_name:"Bash",tool_input:{command:$c},cwd:$d} + (if $a=="" then {} else {agent_type:$a} end)'; }
write_json() { jq -nc --arg f "$1" --arg c "$2" --arg a "${3:-}" --arg d "$REPO" '{tool_name:"Write",tool_input:{file_path:$f,content:$c},cwd:$d} + (if $a=="" then {} else {agent_type:$a} end)'; }
agent_json() { jq -nc --arg t "$1" --arg d "$REPO" '{tool_name:"Agent",tool_input:{subagent_type:$t,prompt:"x"},cwd:$d}'; }
edit_json()  { jq -nc --arg f "$1" --arg a "${2:-}" --arg d "$REPO" '{tool_name:"Edit",tool_input:{file_path:$f,old_string:"x",new_string:"y"},cwd:$d} + (if $a=="" then {} else {agent_type:$a} end)'; }

# fake credentials are assembled at runtime so this file never contains one
AWS="AKIA""IOSFODNN7""EXAMPLE"; GHT="ghp_""$(printf 'a%.0s' $(seq 1 36))"

echo "guard-secrets"
check "blocks AWS key in Write"            2 guard-secrets.sh "$(write_json "$REPO/web/c.ts" "const k = '$AWS';")"
check "blocks GitHub token in Write"       2 guard-secrets.sh "$(write_json "$REPO/web/c.ts" "token=$GHT")"
check "allows clean content"               0 guard-secrets.sh "$(write_json "$REPO/web/c.ts" "export const x = process.env.API_KEY;")"
check "allows marked fake value"           0 guard-secrets.sh "$(write_json "$REPO/web/c.ts" "const k = '$AWS'; // delivery:allow-secret")"
check "allows local dev db url"            0 guard-secrets.sh "$(write_json "$REPO/.env.example" "DATABASE_URL=postgres://postgres:postgres@localhost:5432/app")"
check "blocks remote db url with password" 2 guard-secrets.sh "$(write_json "$REPO/web/c.ts" "postgres://admin:S3cr3tPassw0rd@prod-db.internal:5432/app")"
echo "$AWS" > web/leak.ts; git add web/leak.ts
check "blocks commit with staged secret"   2 guard-secrets.sh "$(bash_json "git commit -m leak")"
git reset -q web/leak.ts; rm -f web/leak.ts

echo "guard-prod"
check "blocks vercel --prod"               2 guard-prod.sh "$(bash_json "npx vercel deploy --prod")"
check "blocks bare vercel"                 2 guard-prod.sh "$(bash_json "vercel")"
check "allows vercel whoami"               0 guard-prod.sh "$(bash_json "vercel whoami")"
check "blocks flyctl deploy"               2 guard-prod.sh "$(bash_json "flyctl deploy --remote-only")"
check "blocks terraform apply"             2 guard-prod.sh "$(bash_json "terraform -chdir=infra apply -auto-approve")"
check "allows terraform plan"              0 guard-prod.sh "$(bash_json "terraform plan")"
check "blocks force push"                  2 guard-prod.sh "$(bash_json "git push --force origin main")"
check "blocks reset --hard"                2 guard-prod.sh "$(bash_json "git status && git reset --hard HEAD~1")"
check "blocks --no-verify"                 2 guard-prod.sh "$(bash_json "git commit --no-verify -m x")"
check "allows normal push"                 0 guard-prod.sh "$(bash_json "git push origin ms-1/frontend/T-001")"
check "blocks remote migration"            2 guard-prod.sh "$(bash_json "DATABASE_URL=postgres://u:p@db.prod.internal/app npm run db:migrate")"
check "allows local migration"             0 guard-prod.sh "$(bash_json "DATABASE_URL=postgres://u:p@localhost/app npm run db:migrate")"
check "blocks state file overwrite"        2 guard-prod.sh "$(bash_json "jq '.gates.g3.status=\"approved\"' .claude/delivery/state.json > /tmp/s && mv /tmp/s .claude/delivery/state.json")"
check "allows state helper"                0 guard-prod.sh "$(bash_json "bash .claude/skills/deliver/scripts/delivery-state.sh summary")"
check "allows staging workflow"            0 guard-prod.sh "$(bash_json "gh workflow run deploy.yml -f environment=staging")"
check "blocks prod workflow before G3"     2 guard-prod.sh "$(bash_json "gh workflow run deploy.yml -f environment=production")"
check "blocks tag push before G3"          2 guard-prod.sh "$(bash_json "git push origin v1.2.0")"
echo "release notes" > docs/delivery/RELEASE-REVIEW.md
bash "$S" release "r1" "sha256:abc" "production" >/dev/null
bash "$S" approve g3 approve "Release Owner" "ok" docs/delivery/RELEASE-REVIEW.md >/dev/null
check "allows prod workflow after G3"      0 guard-prod.sh "$(bash_json "gh workflow run deploy.yml -f environment=production")"
echo "tampered" >> docs/delivery/RELEASE-REVIEW.md
check "blocks prod after package changed"  2 guard-prod.sh "$(bash_json "gh workflow run deploy.yml -f environment=production")"

echo "guard-coding (before g2)"
check "blocks product file before g2"      2 guard-coding.sh "$(write_json "$REPO/web/new.ts" "x")"
check "blocks package.json before g2"      2 guard-coding.sh "$(write_json "$REPO/package.json" "{}")"
check "allows docs before g2"              0 guard-coding.sh "$(write_json "$REPO/docs/delivery/PRD.md" "x")"
check "allows contracts before g2"         0 guard-coding.sh "$(write_json "$REPO/contracts/api.yaml" "x")"
check "allows README before g2"            0 guard-coding.sh "$(write_json "$REPO/README.md" "x")"
check "blocks scaffolding before g2"       2 guard-coding.sh "$(bash_json "cd web && npx -y create-next-app@latest .")"
check "blocks npm init before g2"          2 guard-coding.sh "$(bash_json "npm init -y")"
check "allows npm install of tools"        0 guard-coding.sh "$(bash_json "npm view react version")"
check "blocks frontend agent before g2"    2 guard-coding.sh "$(agent_json frontend-engineer)"
check "allows uiux agent before g2"        0 guard-coding.sh "$(agent_json uiux-agent)"
echo "y" >> web/a.ts; git add web/a.ts
check "blocks code commit before g2"       2 guard-coding.sh "$(bash_json "git commit -m 'feat(web): x'")"
git reset -q web/a.ts; git checkout -q web/a.ts
echo "notes" >> docs/delivery/PRD.md; git add docs/delivery/PRD.md
check "allows docs commit before g2"       0 guard-coding.sh "$(bash_json "git commit -m 'docs: prd'")"
git reset -q docs/delivery/PRD.md; git checkout -q docs/delivery/PRD.md

echo "guard-gates"
bash "$S" approve g1 approve "Client" "ok" docs/delivery/PRD.md >/dev/null
check "blocks edit of approved PRD"        2 guard-gates.sh "$(edit_json "$REPO/docs/delivery/PRD.md")"
check "blocks Write to state file"         2 guard-gates.sh "$(write_json "$REPO/.claude/delivery/state.json" "{}")"
check "allows unrelated file"              0 guard-gates.sh "$(edit_json "$REPO/web/a.ts")"
bash "$S" cr-open g1 "scope change" docs/delivery/PRD.md >/dev/null 2>&1; c=$?
[ $c -ne 0 ] && { pass=$((pass+1)); echo "  ok   cr-open refuses without the human's approval"; } || { fail=$((fail+1)); echo "  FAIL cr-open refuses without the human's approval"; }
bash "$S" cr-open g1 "scope change" --approved-by "Client" docs/delivery/PRD.md >/dev/null
check "allows edit under open CR"          0 guard-gates.sh "$(edit_json "$REPO/docs/delivery/PRD.md")"

echo "guard-boundary"
check "frontend writes own path"           0 guard-boundary.sh "$(write_json "$REPO/web/new.ts" "x" frontend-engineer)"
check "frontend blocked in backend path"   2 guard-boundary.sh "$(write_json "$REPO/api/new.ts" "x" frontend-engineer)"
check "frontend may write evidence docs"   0 guard-boundary.sh "$(write_json "$REPO/docs/delivery/evidence/T-1/a.md" "x" frontend-engineer)"
check "frontend blocked from kit"          2 guard-boundary.sh "$(write_json "$REPO/.claude/rules/x.md" "x" frontend-engineer)"
check "backend owns migrations"            0 guard-boundary.sh "$(write_json "$REPO/api/migrations/001.sql" "x" backend-engineer)"
check "main session unrestricted"          0 guard-boundary.sh "$(write_json "$REPO/api/new.ts" "x")"
check "architect edits contract before G2" 0 guard-boundary.sh "$(write_json "$REPO/contracts/api.yaml" "x" solution-architect)"
check "backend never owns contracts"       2 guard-boundary.sh "$(write_json "$REPO/contracts/api.yaml" "x" backend-engineer)"
bash "$S" approve g2 approve "Architect" "ok" contracts docs/delivery/PRD.md >/dev/null
check "contract frozen after G2"           2 guard-boundary.sh "$(write_json "$REPO/contracts/api.yaml" "x" backend-engineer)"
check "architect blocked without CR"       2 guard-boundary.sh "$(write_json "$REPO/contracts/api.yaml" "x" solution-architect)"
bash "$S" cr-open g2 "add field" --approved-by "Architect" contracts/api.yaml >/dev/null
check "architect allowed under CR"         0 guard-boundary.sh "$(write_json "$REPO/contracts/api.yaml" "x" solution-architect)"
check "api-designer allowed under CR"       0 guard-boundary.sh "$(write_json "$REPO/contracts/api.yaml" "x" api-designer)"

echo "guard-coding (after g2)"
check "allows product file after g2"       0 guard-coding.sh "$(write_json "$REPO/web/new.ts" "x")"
check "allows frontend agent after g2"     0 guard-coding.sh "$(agent_json frontend-engineer)"

echo "usage ledger"
bash "$S" usage add backend-engineer sonnet 1200 >/dev/null && bash "$S" usage add solution-architect opus 3000 >/dev/null
bash "$S" usage summary | grep -q "Tokens: 4200" && { pass=$((pass+1)); echo "  ok   usage totals"; } || { fail=$((fail+1)); echo "  FAIL usage totals"; }
DELIVERY_TOKEN_BUDGET=5000 bash "$S" usage add qa-agent sonnet 900 >/dev/null; c=$?
[ $c -eq 4 ] && { pass=$((pass+1)); echo "  ok   budget reached stops"; } || { fail=$((fail+1)); echo "  FAIL budget reached stops (got $c)"; }

bash "$S" note "checkpoint: build-fork done T-001; next T-002" >/dev/null
bash "$S" summary | grep -q "Last note: checkpoint: build-fork" && { pass=$((pass+1)); echo "  ok   summary shows last checkpoint"; } || { fail=$((fail+1)); echo "  FAIL summary shows last checkpoint"; }

echo "commit-gate"
echo "y" >> api/b.ts; git add api/b.ts
check "blocks red backend commit"          2 commit-gate.sh "$(bash_json "git commit -m 'feat(api): x'" backend-engineer)"
git reset -q api/b.ts; git checkout -q api/b.ts
echo "y" >> web/a.ts; git add web/a.ts
check "allows green frontend commit"       0 commit-gate.sh "$(bash_json "git commit -m 'feat(web): x'" frontend-engineer)"
git reset -q web/a.ts; git checkout -q web/a.ts
echo "more" >> docs/delivery/notes.md; git add docs/delivery/notes.md
check "docs-only commit skips checks"      0 commit-gate.sh "$(bash_json "git commit -m 'docs: notes'" backend-engineer)"
git reset -q docs/delivery/notes.md
check "non-commit command ignored"         0 commit-gate.sh "$(bash_json "git status")"

echo "session-context"
out=$(printf '{}' | bash "$H/session-context.sh")
case "$out" in *"Lane:"*) pass=$((pass+1)); echo "  ok   prints run summary" ;; *) fail=$((fail+1)); echo "  FAIL prints run summary"; echo "$out" ;; esac

echo "delivery-state"
bash "$S" ticket add T-001 backend ms-1 "API" >/dev/null; bash "$S" ticket add T-002 frontend ms-1 "UI" T-001 >/dev/null
r=$(bash "$S" ready ms-1 | cut -f1 | tr '\n' ' ')
[ "$r" = "T-001 " ] && { pass=$((pass+1)); echo "  ok   ready respects depends_on"; } || { fail=$((fail+1)); echo "  FAIL ready respects depends_on (got '$r')"; }
for st in in_progress in_review approved done; do bash "$S" ticket status T-001 $st >/dev/null; done
r=$(bash "$S" ready ms-1 | cut -f1 | tr '\n' ' ')
[ "$r" = "T-002 " ] && { pass=$((pass+1)); echo "  ok   dependency done unlocks ticket"; } || { fail=$((fail+1)); echo "  FAIL dependency done unlocks ticket (got '$r')"; }
bash "$S" ticket attempt T-002 >/dev/null; bash "$S" ticket attempt T-002 >/dev/null
bash "$S" ticket attempt T-002 >/dev/null; c=$?
[ $c -eq 3 ] && { pass=$((pass+1)); echo "  ok   attempt cap exits 3"; } || { fail=$((fail+1)); echo "  FAIL attempt cap exits 3 (got $c)"; }
echo "ticket lifecycle and bugs"
bash "$S" ticket add T-003 backend ms-1 "Auth API" --size L >/dev/null
bash "$S" ticket status T-003 done >/dev/null 2>&1; c=$?
[ $c -ne 0 ] && { pass=$((pass+1)); echo "  ok   rejects ready -> done"; } || { fail=$((fail+1)); echo "  FAIL rejects ready -> done"; }
bash "$S" ticket show T-001 | grep -q "approved -> done" && { pass=$((pass+1)); echo "  ok   status history recorded"; } || { fail=$((fail+1)); echo "  FAIL status history recorded"; }
bash "$S" ticket add T-004 backend ms-1 "Login fails" --type bug --severity P1 >/dev/null 2>&1; c=$?
[ $c -ne 0 ] && { pass=$((pass+1)); echo "  ok   bug without original rejected"; } || { fail=$((fail+1)); echo "  FAIL bug without original rejected"; }
bash "$S" ticket add T-004 backend ms-1 "Login fails on uppercase email" --type bug --of T-001 --severity P1 --found-in "acceptance TC-004" >/dev/null
bash "$S" ticket show T-001 | grep -q "bugs: T-004" && { pass=$((pass+1)); echo "  ok   bug linked to original"; } || { fail=$((fail+1)); echo "  FAIL bug linked to original"; }
bash "$S" bugs open | grep -q "T-004.*P1.*of:T-001" && { pass=$((pass+1)); echo "  ok   open bugs list"; } || { fail=$((fail+1)); echo "  FAIL open bugs list"; }
bash "$S" ticket status T-001 reopened --note "regression T-004" >/dev/null && bash "$S" ticket status T-003 done --force "test correction" >/dev/null
bash "$S" ticket show T-003 | grep -q "forced: test correction" && { pass=$((pass+1)); echo "  ok   forced transition needs and records a reason"; } || { fail=$((fail+1)); echo "  FAIL forced transition needs and records a reason"; }

bash "$S" verify g1 >/dev/null; c=$?
[ $c -eq 1 ] && { pass=$((pass+1)); echo "  ok   CR invalidates gate"; } || { fail=$((fail+1)); echo "  FAIL CR invalidates gate (got $c)"; }
[ -f docs/delivery/GATE-LOG.md ] && { pass=$((pass+1)); echo "  ok   gate log written"; } || { fail=$((fail+1)); echo "  FAIL gate log written"; }

echo "messages"
m=$(bash "$S" msg add solution-architect product-manager question "AC-ORD-4" "First-come or reserve?" blocking)
[ "$m" = "M-1" ] && { pass=$((pass+1)); echo "  ok   msg add returns id"; } || { fail=$((fail+1)); echo "  FAIL msg add returns id (got '$m')"; }
bash "$S" msg open product-manager | grep -q 'BLOCKING' && { pass=$((pass+1)); echo "  ok   open blocking message listed"; } || { fail=$((fail+1)); echo "  FAIL open blocking message listed"; }
bash "$S" msg answer M-1 product-manager "First-come only" >/dev/null
[ -z "$(bash "$S" msg open)" ] && { pass=$((pass+1)); echo "  ok   answered message closes"; } || { fail=$((fail+1)); echo "  FAIL answered message closes"; }
grep -q 'First-come only' docs/delivery/MESSAGES.md && { pass=$((pass+1)); echo "  ok   message log written"; } || { fail=$((fail+1)); echo "  FAIL message log written"; }
bash "$S" msg add a b gossip "x" "y" >/dev/null 2>&1; c=$?
[ $c -ne 0 ] && { pass=$((pass+1)); echo "  ok   rejects unknown message type"; } || { fail=$((fail+1)); echo "  FAIL rejects unknown message type"; }
bash "$S" agent set ticket:T-002 agent-abc >/dev/null
[ "$(bash "$S" agent get ticket:T-002)" = "agent-abc" ] && { pass=$((pass+1)); echo "  ok   agent id stored"; } || { fail=$((fail+1)); echo "  FAIL agent id stored"; }

echo "check-migrations"
CM="$REPO/.claude/skills/design-database/scripts/check-migrations.sh"; MD="$TMP/mig"; mkdir -p "$MD"
printf 'ALTER TABLE orders ADD COLUMN note text;\nCREATE INDEX CONCURRENTLY ix_orders__note ON orders (note);\n' > "$MD/ok.sql"
printf 'ALTER TABLE orders\n  DROP COLUMN legacy;\n' > "$MD/drop.sql"
printf -- '-- migration:allow contract phase, runbook step 4\nALTER TABLE orders DROP COLUMN legacy;\n' > "$MD/allowed.sql"
printf -- '-- harmless comment\nALTER TABLE orders DROP COLUMN legacy;\n' > "$MD/comment_then_drop.sql"
printf 'ALTER TABLE orders ADD COLUMN code text NOT NULL;\n' > "$MD/notnull.sql"
printf "ALTER TABLE orders ADD COLUMN code text NOT NULL DEFAULT '';\n" > "$MD/notnull_default.sql"
printf 'CREATE INDEX ix_orders__status ON orders (status);\n' > "$MD/warn.sql"
mig() { bash "$CM" "$MD/$1.sql" >/dev/null 2>&1; c=$?; [ $c -eq "$2" ] && { pass=$((pass+1)); echo "  ok   $3"; } || { fail=$((fail+1)); echo "  FAIL $3 (exit $c)"; }; }
mig ok 0 "safe migration passes"
mig drop 1 "DROP COLUMN blocks"
mig allowed 0 "allow marker accepts a contract-phase drop"
mig comment_then_drop 1 "comment does not hide a DROP"
mig notnull 1 "NOT NULL without default blocks"
mig notnull_default 0 "NOT NULL with default passes"
mig warn 0 "non-concurrent index only warns"
bash "$CM" "$MD/allowed.sql" | grep -q '^ALLOWED' && { pass=$((pass+1)); echo "  ok   allowed finding is reported"; } || { fail=$((fail+1)); echo "  FAIL allowed finding is reported"; }

echo "check-ownership"
git checkout -qb ms-1/frontend/T-9; echo z > api/sneaky.ts; echo z > web/ok.ts; git add -A; git commit -qm t --no-verify
git checkout -q -
bash "$REPO/.claude/skills/deliver/scripts/check-ownership.sh" ms-1/frontend/T-9 frontend >/dev/null; c=$?
[ $c -eq 1 ] && { pass=$((pass+1)); echo "  ok   flags out-of-role file"; } || { fail=$((fail+1)); echo "  FAIL flags out-of-role file (got $c)"; }

echo; echo "passed: $pass  failed: $fail"
[ $fail -eq 0 ]
