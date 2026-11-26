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
check "allows normal push"                 0 guard-prod.sh "$(bash_json "git push origin feature/t-001-api")"
check "blocks remote migration"            2 guard-prod.sh "$(bash_json "DATABASE_URL=postgres://u:p@db.prod.internal/app npm run db:migrate")"
check "allows local migration"             0 guard-prod.sh "$(bash_json "DATABASE_URL=postgres://u:p@localhost/app npm run db:migrate")"
check "blocks state file overwrite"        2 guard-prod.sh "$(bash_json "jq '.gates.g3.status=\"approved\"' .claude/delivery/state.json > /tmp/s && mv /tmp/s .claude/delivery/state.json")"
check "blocks deleting the usage ledger"   2 guard-prod.sh "$(bash_json "rm .claude/delivery/usage.json")"
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
check "blocks Write to the usage ledger"   2 guard-gates.sh "$(write_json "$REPO/.claude/delivery/usage.json" "{}")"
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
check "orchestrator (main session) cannot write product code" 2 guard-boundary.sh "$(write_json "$REPO/api/new.ts" "x")"
check "orchestrator agent cannot write product code"          2 guard-boundary.sh "$(write_json "$REPO/web/c.ts" "x" orchestrator)"
check "orchestrator can write delivery documents"             0 guard-boundary.sh "$(write_json "$REPO/docs/delivery/PLAN.md" "x")"
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

echo "usage ledger (provider-reported, from the transcripts)"
uok() { if [ "$1" -eq 0 ]; then pass=$((pass+1)); echo "  ok   $2"; else fail=$((fail+1)); echo "  FAIL $2"; bash "$S" usage summary | sed 's/^/       /'; fi; }
TD="$TMP/transcripts"; mkdir -p "$TD/sess-1/subagents"; MAIN="$TD/sess-1.jsonl"; AG="$TD/sess-1/subagents/agent-a1.jsonl"
now_ts=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
tline() { # tline <msg-id> <model> <input> <cache-write> <cache-read> <output> [timestamp]
  jq -nc --arg id "$1" --arg m "$2" --argjson i "$3" --argjson w "$4" --argjson r "$5" --argjson o "$6" --arg t "${7:-$now_ts}" \
    '{type:"assistant", timestamp:$t, message:{id:$id, model:$m, usage:{input_tokens:$i, cache_creation_input_tokens:$w, cache_read_input_tokens:$r, output_tokens:$o}}}'; }
{ tline m1 claude-opus 10 100 1000 5; tline m1 claude-opus 10 100 1000 5      # one response, written as two lines
  tline m2 claude-opus 1 0 200 7
  tline m0 claude-opus 999 999 999 999 2000-01-01T00:00:00.000Z              # before the run started
  echo '{"type":"user","message":{"content":"hi"}}'; echo '{not json'; } > "$MAIN"
tline s1 claude-sonnet 2 50 400 30 > "$AG"; echo '{"agentType":"backend-engineer"}' > "${AG%.jsonl}.meta.json"
stop_json() { jq -nc --arg t "$MAIN" '{hook_event_name:"Stop", transcript_path:$t}'; }
check "record-usage never blocks"          0 record-usage.sh "$(stop_json)"
bash "$S" usage summary | grep -q "^Tokens: 1805 "; uok $? "counts the orchestrator and every agent, each API response once, only since the run started"
bash "$S" usage summary | grep -q "orchestrator=1323/1 runs.*backend-engineer=482/1 runs"; uok $? "attributes usage to the main session and to the agent type"
bash "$S" usage summary | grep -q "cache reads 1600 · output 42"; uok $? "keeps input, cache writes, cache reads and output apart"
printf '%s' "$(stop_json)" | bash "$H/record-usage.sh"; bash "$S" usage summary | grep -q "^Tokens: 1805 "; uok $? "a repeated sync adds nothing"
bash "$S" set-step build dispatch >/dev/null; tline s2 claude-sonnet 0 0 100 20 >> "$AG"
check "record-usage on SubagentStop"       0 record-usage.sh "$(jq -nc --arg t "$MAIN" --arg a "$AG" '{hook_event_name:"SubagentStop", transcript_path:$t, agent_transcript_path:$a, agent_type:"backend-engineer", agent_id:"a1"}')"
bash "$S" usage summary | grep -q "^Tokens: 1925 .*" && bash "$S" usage summary | grep -q "By lane: build=120  understand=1805"; uok $? "a continued agent adds only its new usage, to the current lane"
bash "$S" summary | grep -q "Usage: 1925 tokens, provider-reported"; uok $? "summary shows the provider-reported total"
bash "$S" usage add qa-agent sonnet 900 >/dev/null 2>&1; [ $? -eq 1 ]; uok $? "the manual usage add is gone"
DELIVERY_TOKEN_BUDGET=1000 check "budget reached blocks new agents"     2 guard-budget.sh "$(agent_json qa-agent)"
DELIVERY_TOKEN_BUDGET=1000 bash "$S" usage check >/dev/null; [ $? -eq 4 ]; uok $? "usage check exits 4 at the budget"
bash "$S" usage budget 5000 >/dev/null 2>&1; [ $? -eq 1 ]; uok $? "a new budget needs the human's approval"
bash "$S" usage budget 5000 --approved-by "Client" >/dev/null
DELIVERY_TOKEN_BUDGET=1000 check "the approved budget overrides the env" 0 guard-budget.sh "$(agent_json qa-agent)"
bash "$S" usage budget 2000 --approved-by "Client" | grep -q "BUDGET_WARNING: 96%"; uok $? "warns at 80% of the budget"
bash "$S" usage budget 0 --approved-by "Client" >/dev/null
check "no budget, no block"                0 guard-budget.sh "$(agent_json qa-agent)"
bash "$S" usage context a1 | grep -q "context 100 tokens now, peak 452, 2 API calls; limit 100000 -> continue"; uok $? "a small agent is continued"
DELIVERY_FRESH_CONTEXT=50 bash "$S" usage context a1 | grep -q -- "-> fresh"; uok $? "a big agent is handed over to a fresh agent"
bash "$S" agent set ticket:T-900 a1 >/dev/null; bash "$S" usage context ticket:T-900 | grep -q "agent a1 (backend-engineer)"; uok $? "usage context accepts the saved agent key"
bash "$S" usage context nope >/dev/null 2>&1; [ $? -eq 1 ]; uok $? "usage context refuses an agent with no recorded usage"
bash "$S" usage summary | grep -q "Largest agent contexts: backend-engineer a1 peak 452 now 100 (2 calls)"; uok $? "summary shows the largest agent contexts"
bash "$S" set-step understand intake >/dev/null

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
[ ! -f docs/delivery/MESSAGES.md ] && { pass=$((pass+1)); echo "  ok   no message log file (messages stay in the run state)"; } || { fail=$((fail+1)); echo "  FAIL no message log file (messages stay in the run state)"; }
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

echo "check-tokens"
CT="$REPO/.claude/skills/build-design-system/scripts/check-tokens.sh"; TD="$TMP/tok"; mkdir -p "$TD"
DT="$REPO/.claude/skills/build-design-system/references/DESIGN_TOKENS.md"
tpl() { awk -v n="$1" 'index($0, "## " n ".") == 1 {f=1} f && /^```json/ {g=1; next} g && /^```/ {exit} g' "$DT"; }
tpl 9 > "$TD/tokens.json"; tpl 10 > "$TD/tokens.dark.json"
jq '.color.brand["600"]["$value"] = "#e11d48"' "$TD/tokens.json" > "$TD/rose.json"                 # brand reads as danger
jq '.color.neutral["600"]["$value"] = "#cbd5e1"' "$TD/tokens.json" > "$TD/lowcontrast.json"       # muted text too light
jq 'del(.color.secondary)' "$TD/tokens.json" > "$TD/nosecondary.json"
tok() { out=$(bash "$CT" "$@" 2>&1); c=$?; }
expect() { [ "$c" -eq "$1" ] && { pass=$((pass+1)); echo "  ok   $2"; } || { fail=$((fail+1)); echo "  FAIL $2 (exit $c)"; printf '%s\n' "$out" | grep -v '^OK' | sed 's/^/       /'; }; }
tok --theme "$TD/tokens.dark.json" "$TD/tokens.json"; expect 0 "templates pass contrast and distinctness (light + dark)"
printf '%s\n' "$out" | grep -q '^WARN.*deuteranopia' && { pass=$((pass+1)); echo "  ok   red/green status pair warns under deuteranopia"; } || { fail=$((fail+1)); echo "  FAIL red/green status pair warns under deuteranopia"; }
tok "$TD/rose.json"; expect 1 "brand color too close to danger fails"
printf '%s\n' "$out" | grep -q '^FAIL.*distinct color.primary.default.*color.danger.default' && { pass=$((pass+1)); echo "  ok   distinctness failure names the pair"; } || { fail=$((fail+1)); echo "  FAIL distinctness failure names the pair"; }
tok "$TD/lowcontrast.json"; expect 1 "low-contrast muted text fails"
tok "$TD/nosecondary.json"; expect 1 "missing secondary (the 30% color) fails"
jq '.color.brand["600"]["$value"] = "#b62268"' "$TD/tokens.json" > "$TD/pink.json"                 # pink brand: under the 0.10 gap from the template red
tok "$TD/pink.json"; expect 1 "pink brand too close to the error red fails"
jq '.color.brand["600"]["$value"] = "#b62268" | .color.red["700"]["$value"] = "#920d03"' "$TD/tokens.json" > "$TD/pinkdeep.json"   # pink brand, deep red error
tok "$TD/pinkdeep.json"; expect 0 "pink brand with a deep red error passes"
printf '%s\n' "$out" | grep -q '^WARN.*error look-alike' && { pass=$((pass+1)); echo "  ok   pink brand next to red warns (separate by lightness and presentation)"; } || { fail=$((fail+1)); echo "  FAIL pink brand next to red warns"; }
jq '.color.red["700"]["$value"] = "#ae4800"' "$TD/tokens.json" > "$TD/orangedanger.json"           # danger moved to orange
tok "$TD/orangedanger.json"; expect 1 "an error color that is not red fails (danger stays red)"
jq '.color.violet["50"]["$value"] = "#36274e"' "$TD/tokens.json" > "$TD/darkband.json"            # secondary.subtle made dark
tok "$TD/darkband.json"; expect 1 "a dark secondary tint in the light theme fails (light theme reads light)"
tok --css --theme "$TD/tokens.dark.json" "$TD/tokens.json"; printf '%s\n' "$out" | grep -q -- '--color-secondary-default' && printf '%s\n' "$out" | grep -q '^\[data-theme="dark"\]' && { pass=$((pass+1)); echo "  ok   css export has secondary and the dark theme"; } || { fail=$((fail+1)); echo "  FAIL css export has secondary and the dark theme"; }
jq '. + {material: {glass: {blur: {"$type": "dimension", "$value": "16px"}, opacity: {"$type": "number", "$value": 0.72}}}}' "$TD/tokens.json" > "$TD/glass.json"
tok --theme "$TD/tokens.dark.json" "$TD/glass.json"; expect 0 "visual-style tokens (glass blur and opacity) pass the checks"
tok --css "$TD/glass.json"; printf '%s\n' "$out" | grep -q -- '--material-glass-opacity: 0.72' && { pass=$((pass+1)); echo "  ok   css carries the visual-style tokens"; } || { fail=$((fail+1)); echo "  FAIL css carries the visual-style tokens"; }
RP="$REPO/.claude/skills/build-design-system/scripts/render-png.sh"; printf '<p>x</p>' > "$TD/m.html"
out=$(bash "$RP" "$TD/m.html" "$TD/m.png" 100x100 'dark;x' 2>&1); c=$?; expect 2 "render-png refuses a theme that is not a plain name"

echo "adopt mode"
AR="$TMP/adopt"; mkdir -p "$AR/.claude" "$AR/src" "$AR/legacy" "$AR/docs/delivery"
for part in agents hooks rules skills settings.json; do [ -e "$KIT/$part" ] && cp -R "$KIT/$part" "$AR/.claude/"; done
( cd "$AR" && git init -q && git config user.email t@t && git config user.name t
  printf 'export const a = 1;\n' > src/a.ts; printf 'export const old = 1; // TODO clean up\n' > legacy/old.ts
  git add -A && git commit -qm "existing product" )
AS="$AR/.claude/skills/deliver/scripts/delivery-state.sh"
ast() { out=$(cd "$AR" && CLAUDE_PROJECT_DIR="$AR" bash "$AS" "$@" 2>&1); c=$?; }
ahook() { # ahook <name> <expected-exit> <hook> <json>
  local o code; o=$(cd "$AR" && printf '%s' "$4" | CLAUDE_PROJECT_DIR="$AR" bash "$AR/.claude/hooks/$3" 2>&1); code=$?
  if [ "$code" -eq "$2" ]; then pass=$((pass+1)); printf '  ok   %s\n' "$1"; else fail=$((fail+1)); printf '  FAIL %s (expected %s, got %s)\n%s\n' "$1" "$2" "$code" "$(printf '%s' "$o" | sed 's/^/       /')"; fi
}
awrite() { jq -nc --arg f "$AR/$1" --arg a "${2:-}" --arg d "$AR" '{tool_name:"Write",tool_input:{file_path:$f,content:"x"},cwd:$d} + (if $a=="" then {} else {agent_type:$a} end)'; }
out=$(bash "$S" init --mode adopt 2>&1); c=$?; expect 1 "an existing run cannot be converted to adopt mode"
out=$(bash "$S" approve-baseline "Client" "x" docs/delivery/PRD.md 2>&1); c=$?; expect 1 "approve-baseline is refused outside an adopt run"
ast init --mode adopt; expect 0 "adopt init creates the run"
ast summary; printf '%s\n' "$out" | grep -q 'Mode: adopt' && printf '%s\n' "$out" | grep -q 'Lane: adopt   Step: detect' && { pass=$((pass+1)); echo "  ok   summary shows the adopt mode and lane"; } || { fail=$((fail+1)); echo "  FAIL summary shows the adopt mode and lane"; }
ahook "code is blocked before the baseline"        2 guard-coding.sh "$(awrite src/b.ts)"
ahook "as-built documents can be written"          0 guard-coding.sh "$(awrite docs/delivery/PRD.md)"
ast approve-baseline "Client" "ok" docs/delivery/PRD.md; expect 1 "baseline refused without project.json"
printf '{"version":1,"roles":{"frontend":{"enabled":true,"agent":"frontend-engineer","paths":["src/**"],"commands":{}}},"contracts":{"paths":["contracts/**"]},"commands":{}}\n' > "$AR/.claude/project.json"
for f in PRD ARCHITECTURE BASELINE; do printf '# %s (as built)\n' "$f" > "$AR/docs/delivery/$f.md"; done
ast approve-baseline "Client" "ok" docs/delivery/PRD.md docs/delivery/ARCHITECTURE.md; expect 1 "baseline refused when BASELINE.md is not in the package"
ast approve-baseline "Client" "ok" docs/delivery/PRD.md docs/delivery/ARCHITECTURE.md docs/delivery/BASELINE.md; expect 1 "baseline refused while the package is uncommitted"
( cd "$AR" && git add -A && git commit -qm "docs: as-built baseline" )
ast approve-baseline "Client" "as built accepted" docs/delivery/PRD.md docs/delivery/ARCHITECTURE.md docs/delivery/BASELINE.md; expect 0 "baseline approved in one step"
ast verify g1; expect 0 "g1 is recorded by the baseline"
ast verify g2; expect 0 "g2 is recorded by the baseline"
( cd "$AR" && git rev-parse -q --verify refs/tags/delivery-baseline >/dev/null ) && { pass=$((pass+1)); echo "  ok   the baseline commit is tagged"; } || { fail=$((fail+1)); echo "  FAIL the baseline commit is tagged"; }
ast summary; printf '%s\n' "$out" | grep -q 'Lane: build   Step: increment-wait' && { pass=$((pass+1)); echo "  ok   the run waits for the first increment"; } || { fail=$((fail+1)); echo "  FAIL the run waits for the first increment"; }
ast approve-baseline "Client" "again" docs/delivery/PRD.md docs/delivery/ARCHITECTURE.md docs/delivery/BASELINE.md; expect 1 "a baseline is approved only once"
ahook "code is allowed after the baseline"         0 guard-coding.sh "$(awrite src/b.ts)"
ahook "approved as-built documents are protected"  2 guard-gates.sh "$(awrite docs/delivery/PRD.md)"
ahook "a role edits inside its adopted paths"      0 guard-boundary.sh "$(awrite src/b.ts frontend-engineer)"
ahook "unmapped folders are blocked for roles"     2 guard-boundary.sh "$(awrite legacy/old.ts frontend-engineer)"
printf 'export const b = 2; // TODO later\n' > "$AR/src/b.ts"; ( cd "$AR" && git add -A && git commit -qm "feat: b" )
out=$(bash "$AR/.claude/skills/integrate-milestone/scripts/check-hygiene.sh" --root "$AR" --base delivery-baseline --no-unused 2>&1); c=$?
expect 1 "hygiene since the baseline flags new leftovers"
printf '%s\n' "$out" | grep -q 'src/b.ts' && ! printf '%s\n' "$out" | grep -q 'legacy/old.ts' && { pass=$((pass+1)); echo "  ok   existing debt is not reported against new work"; } || { fail=$((fail+1)); echo "  FAIL existing debt is not reported against new work"; printf '%s\n' "$out" | sed 's/^/       /'; }

echo "check-hygiene"
CH="$REPO/.claude/skills/integrate-milestone/scripts/check-hygiene.sh"; HR="$TMP/hyg"; mkdir -p "$HR/web/src" "$HR/docs" "$HR/scripts" "$HR/.claude"
( cd "$HR" && git init -q && git config user.email t@t && git config user.name t
  printf 'export const a = 1;\n' > web/src/a.ts
  printf '# App\n[code map](docs/CODEMAP.md)\n' > README.md
  printf '# Code map\n`web/src/a.ts` entry point\n`application/json` is a media type, not a path\n' > docs/CODEMAP.md
  printf 'console.log("allowed in scripts");\n' > scripts/seed.js
  git add -A && git commit -qm init )
hy() { out=$(bash "$CH" --root "$HR" "$@" 2>&1); c=$?; }
plant() { ( cd "$HR" && git add -A -f && git commit -qm "$1" ); }
has() { printf '%s\n' "$out" | grep -q "$1" && { pass=$((pass+1)); echo "  ok   $2"; } || { fail=$((fail+1)); echo "  FAIL $2"; printf '%s\n' "$out" | sed 's/^/       /'; }; }
hy; expect 0 "clean repository passes"
mkdir -p "$HR/web/.next/cache" "$HR/web/src/empty"; printf '.next/\n' > "$HR/.gitignore"; plant ignore
hy; printf '%s\n' "$out" | grep -q 'emptydir.web/src/empty' && ! printf '%s\n' "$out" | grep -q '\.next' && { pass=$((pass+1)); echo "  ok   empty folders warn, except inside git-ignored paths"; } || { fail=$((fail+1)); echo "  FAIL empty folders warn, except inside git-ignored paths"; printf '%s\n' "$out" | sed 's/^/       /'; }
rmdir "$HR/web/src/empty"
printf 'x' > "$HR/.DS_Store"; printf 'A=1\n' > "$HR/.env"; printf 'A=\n' > "$HR/.env.example"; plant stray
hy; expect 1 "stray and env files fail"; has '^FAIL.stray..DS_Store' "stray file is named"
printf '%s\n' "$out" | grep -q 'env.example' && { fail=$((fail+1)); echo "  FAIL .env.example is allowed"; } || { pass=$((pass+1)); echo "  ok   .env.example is allowed"; }
( cd "$HR" && git rm -q --cached .DS_Store .env && rm -f .DS_Store .env && git commit -qm unstray )
mkdir -p "$HR/web/public"; printf '<svg/>' > "$HR/web/public/next.svg"; printf 'export const P = "Get started by editing";\n' > "$HR/web/src/page.ts"; plant scaffold
hy; expect 1 "scaffold leftovers fail"; has '^FAIL.scaffold.web/public/next.svg' "starter asset is named"; has '^FAIL.scaffold.web/src/page.ts:1' "starter text is located"
printf '{"hygiene":{"allow":[{"path":"web/public/next.svg","reason":"shown on the docs page"},{"path":"web/src/page.ts","reason":"copy under review"}]}}\n' > "$HR/.claude/project.json"
hy; expect 0 "allow-list with reasons accepts the exceptions"
printf '{"hygiene":{"allow":[{"path":"web/public/next.svg"},{"path":"web/src/page.ts","reason":"copy under review"}]}}\n' > "$HR/.claude/project.json"
hy; expect 1 "an allow entry without a reason fails"
printf '{"hygiene":{"allow":[{"path":"web/public/next.svg","reason":"shown on the docs page"},{"path":"web/src/page.ts","reason":"copy under review"}]},"commands":{"unused":"echo unused-export; exit 1"}}\n' > "$HR/.claude/project.json"
hy; expect 1 "the pinned unused-code command failing fails the check"
hy --no-unused; expect 0 "--no-unused skips the unused-code command"
printf 'export const b = 2; // TODO remove later\nexport const c = 3; // TODO T-12 keep until the migration\nconsole.log(b);\nconsole.log(c); // hygiene:allow CLI output\n' > "$HR/web/src/b.ts"; plant debug
hy --no-unused; expect 1 "debug output and a ticketless TODO fail"; has '^FAIL.todo.web/src/b.ts:1' "the TODO without a ticket is located"; has '^FAIL.debug.web/src/b.ts:3' "console.log is located"
[ "$(printf '%s\n' "$out" | grep -c 'web/src/b.ts')" = 2 ] && { pass=$((pass+1)); echo "  ok   a ticketed TODO and a hygiene:allow line are accepted"; } || { fail=$((fail+1)); echo "  FAIL a ticketed TODO and a hygiene:allow line are accepted"; }
hy --no-unused --base HEAD~1; expect 1 "--base checks only the ticket diff"
printf 'export const b = 2;\n' > "$HR/web/src/b.ts"; printf '\n`web/src/gone.ts` was removed\n' >> "$HR/docs/CODEMAP.md"; plant deadlink
hy --no-unused; expect 1 "a code map path to a missing file fails"; has '^FAIL.deadlink.docs/CODEMAP.md' "the dead path is located"
printf '%s\n' "$out" | grep -q 'application/json' && { fail=$((fail+1)); echo "  FAIL non-path code spans are ignored"; } || { pass=$((pass+1)); echo "  ok   non-path code spans are ignored"; }

echo "lean kit"
printf 'services:\n  db:\n    image: postgres:16-alpine\n  web:\n    build: .\n' > "$HR/compose.yml"; plant compose
hy --no-unused; printf '%s\n' "$out" | grep -q 'services' && { fail=$((fail+1)); echo "  FAIL one database container is accepted"; } || { pass=$((pass+1)); echo "  ok   one database container is accepted"; }
printf 'services:\n  db:\n    image: postgres:16-alpine\n  test-db:\n    image: "postgres:16-alpine"\n' > "$HR/compose.yml"; plant twodb
hy --no-unused; has '^FAIL.services.compose.yml.2 postgres containers' "two database containers in one compose file fail"
printf 'services:\n  db:\n    image: postgres:16-alpine\n' > "$HR/compose.yml"; printf 'services:\n  pg:\n    image: postgres:16-alpine\n' > "$HR/compose.test.yml"; plant testcompose
hy --no-unused; has '^FAIL.services.compose.test.yml.a separate postgres container for tests' "a database container just for tests fails"
( cd "$HR" && git rm -q compose.test.yml && git commit -qm "one db" )
printf '{"devDependencies":{"testcontainers":"^10"}}\n' > "$HR/package.json"; plant tc
hy --no-unused; has '^FAIL.services.package.json.Testcontainers' "a Testcontainers dependency fails"
printf '{"devDependencies":{}}\n' > "$HR/package.json"; plant notc
mkdir -p "$HR/docs/delivery/milestones/ms-1/screens"; printf '# PRD\n' > "$HR/docs/delivery/PRD.md"; printf '# Review\n' > "$HR/docs/delivery/milestones/ms-1/REVIEW.md"; printf 'x' > "$HR/docs/delivery/milestones/ms-1/screens/S-01.png"; plant leandocs
hy --no-unused; printf '%s\n' "$out" | grep -q '^FAIL.docs.' && { fail=$((fail+1)); echo "  FAIL the lean document set passes"; printf '%s\n' "$out" | sed 's/^/       /'; } || { pass=$((pass+1)); echo "  ok   the lean document set passes"; }
printf '# BA\n' > "$HR/docs/delivery/BA-ANALYSIS.md"; mkdir -p "$HR/docs/delivery/evidence/T-001"; printf 'log\n' > "$HR/docs/delivery/evidence/T-001/test.txt"; plant extradocs
hy --no-unused; has '^FAIL.docs.docs/delivery/BA-ANALYSIS.md' "a document outside the lean set fails"; has '^FAIL.docs.docs/delivery/evidence/T-001/test.txt' "stored evidence files fail"
printf '{"docs":{"layout":"classic"}}\n' > "$HR/.claude/project.json"
hy --no-unused; printf '%s\n' "$out" | grep -q '^FAIL.docs.' && { fail=$((fail+1)); echo "  FAIL the classic layout skips the documents check"; } || { pass=$((pass+1)); echo "  ok   the classic layout skips the documents check"; }
rm -f "$HR/.claude/project.json"; ( cd "$HR" && git rm -rq docs/delivery/BA-ANALYSIS.md docs/delivery/evidence && git commit -qm "lean again" )
awk 'BEGIN { for (i = 0; i < 901; i++) print "line " i }' > "$HR/docs/delivery/PRD.md"; plant longprd
hy --no-unused; has '^FAIL.docs.docs/delivery/PRD.md.901 lines, over the limit of 900' "a document over its length limit fails"
printf '{"docs":{"limits":{"PRD.md":1000}}}\n' > "$HR/.claude/project.json"; hy --no-unused; printf '%s\n' "$out" | grep -q '^FAIL.docs.docs/delivery/PRD.md' && { fail=$((fail+1)); echo "  FAIL a project's own limit (docs.limits) is honoured"; } || { pass=$((pass+1)); echo "  ok   a project's own limit (docs.limits) is honoured"; }
echo "infra hygiene (commands, scripts, test containers)"
mkdir -p "$HR/api/tests" "$HR/ci/tests" "$HR/.github/workflows"
printf "import { execFile } from 'node:child_process';\nexecFile('docker', ['run', '--rm', 'postgres:16']);\n" > "$HR/api/tests/db.test.ts"
printf "import { execFile } from 'node:child_process';\nexecFile('docker', ['image', 'inspect', 'postgres:16']);\n" > "$HR/api/tests/image.test.ts"
printf '{"commands":{"dev":"pnpm dev","test":"pnpm -r test && (cd ai && uv run pytest)"}}\n' > "$HR/.claude/project.json"
printf '{"scripts":{"dev":"pnpm -r dev","seed":"bash scripts/used.sh"}}\n' > "$HR/package.json"
printf '#!/bin/sh\necho used\n' > "$HR/scripts/used.sh"; printf '#!/bin/sh\necho orphan\n' > "$HR/scripts/orphan.sh"
printf '#!/bin/sh\necho proof\n' > "$HR/scripts/rate-proof.sh"; printf 'run scripts/rate-proof.sh\n' >> "$HR/README.md"
printf '#!/bin/sh\nfor t in ci/tests/*.test.sh; do sh "$t"; done\n' > "$HR/ci/tests/run-all.sh"; printf '#!/bin/sh\necho ok\n' > "$HR/ci/tests/a.test.sh"
printf 'jobs:\n  t:\n    steps:\n      - run: sh ci/tests/run-all.sh\n      - run: for t in b; do bash "loop/tests/${t}.test.sh"; done\n' > "$HR/.github/workflows/ci.yml"; mkdir -p "$HR/loop/tests"; printf '#!/bin/sh\necho b\n' > "$HR/loop/tests/b.test.sh"
plant infra
hy --no-unused
has '^FAIL.services.api/tests/db.test.ts:2' "test code that runs a database container fails"
has '^WARN.services.api/tests/image.test.ts:2' "other docker calls from tests only warn"
has '^FAIL.commands..claude/project.json.commands.test chains several steps' "a chained project.json command fails"
has '^FAIL.commands.package.json.no "test" script for commands.test' "a command without its package script fails"
printf '%s\n' "$out" | grep -q 'no "dev" script' && { fail=$((fail+1)); echo "  FAIL a command with its package script passes"; } || { pass=$((pass+1)); echo "  ok   a command with its package script passes"; }
has '^FAIL.scripts.scripts/orphan.sh.nothing uses this script' "a shell script nothing uses fails"
has '^FAIL.scripts.scripts/rate-proof.sh.a proof or evidence script' "a proof script fails even when it is mentioned"
printf '%s\n' "$out" | grep -qE 'scripts/used\.sh|ci/tests/(a\.test|run-all)\.sh|loop/tests/b\.test\.sh' && { fail=$((fail+1)); echo "  FAIL used scripts and folder runners pass"; printf '%s\n' "$out" | grep scripts | sed 's/^/       /'; } || { pass=$((pass+1)); echo "  ok   used scripts and folder runners pass"; }
( cd "$HR" && git rm -rq api/tests ci loop .github scripts/used.sh scripts/orphan.sh scripts/rate-proof.sh .claude/project.json && git commit -qm "infra hygiene done" ) 2>/dev/null; rm -f "$HR/.claude/project.json"
PS="$TMP/plan"; mkdir -p "$PS/.claude"; cp -R "$KIT/skills" "$KIT/hooks" "$PS/.claude/"; ( cd "$PS" && git init -q )
pst() { out=$(cd "$PS" && CLAUDE_PROJECT_DIR="$PS" bash "$PS/.claude/skills/deliver/scripts/delivery-state.sh" "$@" 2>&1); c=$?; }
pst init
pst ticket add T-001 backend ms-1 "Scaffold API" --type chore --paths "api/package.json,api/src/main.ts"
pst ticket add T-002 backend ms-1 "Auth API" T-001 --paths "api/src/modules/auth/**"
pst ticket add T-003 frontend ms-1 "Auth screens" --paths "web/src/app/(auth)/**"
pst plan-check ms-1; expect 0 "independent tickets pass the plan check"
printf '%s\n' "$out" | grep -q '2 feature tickets, 2 can start together' && { pass=$((pass+1)); echo "  ok   the plan check reports how many tickets can start together"; } || { fail=$((fail+1)); echo "  FAIL the plan check reports how many tickets can start together"; printf '%s\n' "$out" | sed 's/^/       /'; }
pst ticket add T-004 frontend ms-1 "Profile screens" T-002 --paths "web/src/app/(app)/profile/**"
pst plan-check ms-1; expect 1 "a feature ticket depending on another in the same milestone fails"
pst ticket status T-004 cancelled --force "replanned"
pst ticket add T-005 backend ms-1 "Auth tweaks" T-001 --paths "api/src/modules/auth/session.ts"
pst plan-check ms-1; expect 1 "parallel tickets touching the same files fail"
pst ticket status T-002 in_progress; pst agent set ticket:T-002 agent-abc
pst board; printf '%s\n' "$out" | grep -q 'T-002.backend.in_progress.*agent-abc' && { pass=$((pass+1)); echo "  ok   the board shows who has which ticket"; } || { fail=$((fail+1)); echo "  FAIL the board shows who has which ticket"; printf '%s\n' "$out" | sed 's/^/       /'; }
pst stats ms-1; printf '%s\n' "$out" | grep -q '^backend: ' && { pass=$((pass+1)); echo "  ok   stats report rework per role"; } || { fail=$((fail+1)); echo "  FAIL stats report rework per role"; }

echo "app commands"
AP="$REPO/.claude/skills/deliver/scripts/app.sh"; AD="$TMP/app"; mkdir -p "$AD/.claude" "$AD/fakebin"; ( cd "$AD" && git init -q )
ap() { out=$(PATH="$AD/fakebin:$PATH" bash "$AP" "$@" --root "$AD" 2>&1); c=$?; }
ap start; expect 0 "no app yet is a plain message, not an error"; has 'There is no app yet' "it says there is no app yet"
printf '{"commands":{"test":"echo 12 passed; echo DB=$DATABASE_URL","build":"echo built"},"stack":{"database":"postgresql"}}\n' > "$AD/.claude/project.json"
ap start; expect 0 "a missing start command is explained"; has 'no start command yet' "it names the missing command"
ap build; expect 0 "build runs the project's build command"
ap test; expect 0 "test runs the project's tests"; has 'All tests passed' "passing tests are reported in plain words"
printf 'services:\n  db:\n    image: postgres:16-alpine\n' > "$AD/compose.yml"; printf '#!/bin/sh\nexit 1\n' > "$AD/fakebin/docker"; chmod +x "$AD/fakebin/docker"
ap test; expect 0 "without Docker the tests run on SQLite"; has 'DB=file:./.data/test.sqlite' "the SQLite test database is selected by DATABASE_URL"
printf '{"commands":{"test":"echo 1 failed: orders total; exit 1"},"stack":{"database":"postgresql"}}\n' > "$AD/.claude/project.json"
ap test; expect 1 "failing tests fail the command"; has 'Some tests failed' "failing tests are reported in plain words"

echo "sync-diagrams"
SD="$REPO/.claude/skills/design-architecture/scripts/sync-diagrams.sh"; CD="$REPO/.claude/skills/design-architecture/scripts/check-diagrams.sh"
DD="$TMP/diag"; mkdir -p "$DD"
printf '# PRD\n## 10. Solution\n<!-- architect:begin -->\n### D1 · Main system\nPurpose: whole app.\n```mermaid\nflowchart TB\n  web --> api\n```\n**What to notice:** one.\n\n## 12. Architecture diagrams\n### D0 · Context\n```mermaid\nflowchart LR\n  user --> sys\n```\n#### D2-L3 · Application layer\n```mermaid\nflowchart LR\n  a --> b\n```\n<!-- architect:end -->\n## 13. Other\nnot a diagram\n' > "$DD/PRD.md"
printf '# Architecture\n## 12. Layers\nkeep this text\n' > "$DD/ARCH.md"
dg() { out=$("$@" 2>&1); c=$?; }
dg bash "$SD" --check "$DD/PRD.md" "$DD/ARCH.md"; expect 1 "architecture without the diagrams fails the check"
dg bash "$SD" "$DD/PRD.md" "$DD/ARCH.md"; expect 0 "sync copies the PRD diagrams into ARCHITECTURE"
dg bash "$CD" --no-render --require "D0 D1 D2" --mirror "$DD/ARCH.md" "$DD/PRD.md"; expect 0 "mirror check passes after sync"
grep -q 'keep this text' "$DD/ARCH.md" && grep -q '^## 14. Architecture diagrams' "$DD/ARCH.md" && ! grep -q 'not a diagram' "$DD/ARCH.md" && { pass=$((pass+1)); echo "  ok   sync keeps the architecture text and copies only diagram sections"; } || { fail=$((fail+1)); echo "  FAIL sync keeps the architecture text and copies only diagram sections"; }
cp "$DD/ARCH.md" "$DD/ARCH.first"; bash "$SD" "$DD/PRD.md" "$DD/ARCH.md" >/dev/null
cmp -s "$DD/ARCH.md" "$DD/ARCH.first" && { pass=$((pass+1)); echo "  ok   sync is idempotent"; } || { fail=$((fail+1)); echo "  FAIL sync is idempotent"; }
sed 's/web --> api/web --> gateway/' "$DD/ARCH.md" > "$DD/ARCH.tmp" && mv "$DD/ARCH.tmp" "$DD/ARCH.md"
dg bash "$CD" --no-render --require "D0 D1" --mirror "$DD/ARCH.md" "$DD/PRD.md"; expect 1 "a diagram edited in ARCHITECTURE fails the mirror check"
printf '%s\n' "$out" | grep -q '^DIFFERS   D1 ' && { pass=$((pass+1)); echo "  ok   the mirror check names the diagram that differs"; } || { fail=$((fail+1)); echo "  FAIL the mirror check names the diagram that differs"; }
bash "$SD" "$DD/PRD.md" "$DD/ARCH.md" >/dev/null
dg bash "$SD" --check "$DD/PRD.md" "$DD/ARCH.md"; expect 0 "re-sync restores the copy"

echo "kit consistency"
CFD="$REPO/.claude/skills/coding-foundations"; miss=""
for g in $(grep -o 'references/[A-Z_]*\.md' "$CFD/SKILL.md" | sort -u); do [ -f "$CFD/$g" ] || miss="$miss $g"; done
[ -z "$miss" ] && { pass=$((pass+1)); echo "  ok   every guide listed in coding-foundations exists"; } || { fail=$((fail+1)); echo "  FAIL missing guides:$miss"; }
miss=""
for g in $(grep -o '"guides": \[[^]]*\]' "$REPO/.claude/skills/deliver/references/manifest.md" | grep -o '"[a-z_]*"' | tr -d '"' | grep -v '^guides$' | sort -u); do
  [ -f "$CFD/references/$(printf '%s' "$g" | tr '[:lower:]' '[:upper:]').md" ] || miss="$miss $g"
done
[ -z "$miss" ] && { pass=$((pass+1)); echo "  ok   every guide named in the manifest example exists"; } || { fail=$((fail+1)); echo "  FAIL manifest guides without a file:$miss"; }
miss=""
for a in "$REPO"/.claude/agents/*.md; do
  for k in name description model; do sed -n '2,12p' "$a" | grep -q "^$k:" || miss="$miss $(basename "$a"):$k"; done
  [ "$(sed -n 's/^name: *//p' "$a" | head -1)" = "$(basename "$a" .md)" ] || miss="$miss $(basename "$a"):name-mismatch"
done
[ -z "$miss" ] && { pass=$((pass+1)); echo "  ok   every agent has name, description and model, and its name matches the file"; } || { fail=$((fail+1)); echo "  FAIL agent frontmatter:$miss"; }
miss=""
for sk in "$REPO"/.claude/skills/*/; do
  for r in $(grep -oE '\]\(references/[A-Za-z_]+\.md' "$sk/SKILL.md" 2>/dev/null | sed 's/](//' | sort -u); do [ -f "$sk/$r" ] || miss="$miss $(basename "$sk")/$r"; done
done
[ -z "$miss" ] && { pass=$((pass+1)); echo "  ok   every reference linked from a SKILL.md exists"; } || { fail=$((fail+1)); echo "  FAIL broken skill references:$miss"; }

echo "check-ownership"
git checkout -qb feature/t-9-sneaky; echo z > api/sneaky.ts; echo z > web/ok.ts; git add -A; git commit -qm t --no-verify
git checkout -q -
bash "$REPO/.claude/skills/deliver/scripts/check-ownership.sh" feature/t-9-sneaky frontend >/dev/null; c=$?
[ $c -eq 1 ] && { pass=$((pass+1)); echo "  ok   flags out-of-role file"; } || { fail=$((fail+1)); echo "  FAIL flags out-of-role file (got $c)"; }

echo "git flow (branch helper and protected branches)"
DEFB=$(git rev-parse --abbrev-ref HEAD)
br() { out=$(bash "$S" branch "$@" 2>&1); c=$?; }
has_ref() { git rev-parse -q --verify "refs/heads/$1" >/dev/null 2>&1; }
yes() { if [ "$1" -eq 0 ]; then pass=$((pass+1)); echo "  ok   $2"; else fail=$((fail+1)); echo "  FAIL $2"; printf '%s\n' "$out" | sed 's/^/       /'; fi; }
br milestone ms-1; has_ref develop && has_ref ms-1/integration; yes $? "milestone start creates develop and ms-1/integration"
bash "$S" ticket add T-101 backend ms-1 "Auth API: signup & login!" --paths "api/**" >/dev/null
br ticket T-101; [ "$(printf '%s' "$out" | cut -f1)" = "feature/t-101-auth-api-signup-login" ] && [ "$(git rev-parse feature/t-101-auth-api-signup-login)" = "$(git rev-parse ms-1/integration)" ]
yes $? "ticket branch is named feature/<id>-<slug> and starts from the milestone branch"
bash "$S" ticket show T-101 | grep -q "branch: feature/t-101-auth-api-signup-login  base: ms-1/integration"; yes $? "ticket branch and base are recorded"
br ticket T-101; [ "$(printf '%s' "$out" | cut -f1)" = "feature/t-101-auth-api-signup-login" ]; yes $? "a correction round reuses the same branch"
br ticket T-004 --base "$DEFB"; printf '%s' "$out" | grep -q "^hotfix/t-004-login-fails-on-uppercase-email"; yes $? "a bug based on the default branch is a hotfix/ branch"
git checkout -q ms-1/integration; echo i > web/i.ts; git add web/i.ts; git commit -qm "feat(web): integrate" --no-verify; git checkout -q "$DEFB"
br milestone ms-2; [ $c -eq 1 ]; yes $? "the next milestone waits until the previous one is merged into develop"
git checkout -q develop; git merge -q --no-ff --no-edit ms-1/integration; git checkout -q "$DEFB"
br milestone ms-2; [ $c -eq 0 ] && has_ref ms-2/integration; yes $? "the next milestone starts once the previous one is merged"
br release 1.0; [ $c -eq 1 ]; yes $? "a release version must be semver with a leading v"
br release v1.0.0; [ $c -eq 0 ] && has_ref release/v1.0.0; yes $? "release branch is cut from develop"
for st in in_progress in_review approved done; do bash "$S" ticket status T-101 $st >/dev/null; done
br cleanup ms-1; ! has_ref feature/t-101-auth-api-signup-login && has_ref hotfix/t-004-login-fails-on-uppercase-email
yes $? "cleanup removes done ticket branches and keeps open ones"
check "allows first publish of develop"    0 guard-prod.sh "$(bash_json "git push -u origin develop")"
git update-ref refs/remotes/origin/develop develop; git update-ref "refs/remotes/origin/$DEFB" "$DEFB"
check "blocks direct push to develop"      2 guard-prod.sh "$(bash_json "git push origin develop")"
check "blocks push HEAD:<default branch>"  2 guard-prod.sh "$(bash_json "git push origin HEAD:$DEFB")"
git checkout -q develop
check "blocks bare push while on develop"  2 guard-prod.sh "$(bash_json "git push")"
git checkout -q "$DEFB"
check "allows pushing a ticket branch"     0 guard-prod.sh "$(bash_json "git push -u origin feature/t-101-auth-api")"
check "allows pushing a release branch"    0 guard-prod.sh "$(bash_json "git push -u origin release/v1.0.0")"
HB=hotfix/t-004-login-fails-on-uppercase-email; git worktree add -q "$TMP/wt-old" "$HB" 2>/dev/null
echo dirty > "$TMP/wt-old/wip.txt"
br handover T-004; [ $c -eq 1 ] && git -C "$TMP/wt-old" symbolic-ref -q HEAD >/dev/null; yes $? "handover refuses while the old agent's worktree has uncommitted work"
rm -f "$TMP/wt-old/wip.txt"
br handover T-004; [ $c -eq 0 ] && ! git -C "$TMP/wt-old" symbolic-ref -q HEAD >/dev/null; yes $? "handover frees the ticket branch from a clean old worktree"
git worktree add -q "$TMP/wt-new" "$HB" 2>/dev/null; [ "$(git -C "$TMP/wt-new" branch --show-current 2>/dev/null)" = "$HB" ]; yes $? "a fresh agent can then switch to the ticket branch"
git worktree remove --force "$TMP/wt-new" 2>/dev/null; git worktree remove --force "$TMP/wt-old" 2>/dev/null

echo "guard-services (agents never manage containers) and app.sh in a worktree"
check "blocks docker run from an agent"        2 guard-services.sh "$(bash_json "docker run -d postgres:16" backend-engineer)"
check "blocks compose up from an agent"        2 guard-services.sh "$(bash_json "cd api && docker compose -f infra/compose.yaml up -d" backend-engineer)"
check "blocks infra:up from an agent"          2 guard-services.sh "$(bash_json "pnpm infra:up" devops-engineer)"
check "blocks app.sh services from an agent"   2 guard-services.sh "$(bash_json "bash .claude/skills/deliver/scripts/app.sh services" integrator)"
check "blocks a plain app.sh stop from an agent" 2 guard-services.sh "$(bash_json "bash .claude/skills/deliver/scripts/app.sh stop" integrator)"
check "allows app.sh stop --app"               0 guard-services.sh "$(bash_json "bash .claude/skills/deliver/scripts/app.sh stop --app" integrator)"
check "allows app.sh start and test"           0 guard-services.sh "$(bash_json "bash .claude/skills/deliver/scripts/app.sh start && bash .claude/skills/deliver/scripts/app.sh test" integrator)"
check "allows compose config and docker build" 0 guard-services.sh "$(bash_json "docker compose config --quiet && docker build -t app ." devops-engineer)"
check "allows compose exec into the database"  0 guard-services.sh "$(bash_json "docker compose exec db psql -c 'select 1'" backend-engineer)"
check "allows the main session"                0 guard-services.sh "$(bash_json "docker compose up -d --wait" orchestrator)"
check "allows a session without an agent"      0 guard-services.sh "$(bash_json "docker compose up -d --wait")"
APP="$REPO/.claude/skills/deliver/scripts/app.sh"; git worktree add -q --detach "$TMP/wt-app" HEAD 2>/dev/null
out=$(cd "$TMP/wt-app" && bash "$APP" services 2>&1); c=$?; [ $c -eq 1 ] && printf '%s' "$out" | grep -q "main checkout"; yes $? "app.sh services refuses in a worktree"
out=$(cd "$TMP/wt-app" && bash "$APP" clean 2>&1); c=$?; [ $c -eq 1 ]; yes $? "app.sh clean refuses in a worktree"
out=$(cd "$TMP/wt-app" && bash "$APP" stop 2>&1); c=$?; [ $c -eq 0 ] && printf '%s' "$out" | grep -q "keep running for everyone"; yes $? "app.sh stop in a worktree stops only the app"
out=$(bash "$APP" stop --bogus 2>&1); c=$?; [ $c -eq 2 ]; yes $? "app.sh rejects an unknown option"
git worktree remove --force "$TMP/wt-app" 2>/dev/null

echo "check-assets (logo, icons, animated illustrations)"
CA="$REPO/.claude/skills/build-design-system/scripts/check-assets.sh"
mkfix() { mkdir -p "$TMP/$1/docs/delivery/brand/assets/icons" "$TMP/$1/docs/delivery/brand/assets/illustrations"; ( cd "$TMP/$1" && git init -q ); printf '%s' "$TMP/$1/docs/delivery/brand/assets"; }
ca() { out=$(bash "$CA" --root "$TMP/$1" 2>&1); c=$?; }
OK=$(mkfix assets-ok)
printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path d="M4 4h40v40H4z"/></svg>\n' > "$OK/logo-mark.svg"
printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M2 2h20" stroke="currentColor"/></svg>\n' > "$OK/icons/visit.svg"
printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300"><style>.s{animation:fill 6s ease-in-out infinite}@keyframes fill{to{opacity:1}}@media (prefers-reduced-motion: reduce){.s{animation:none}}</style><rect class="s" width="10" height="10"/></svg>\n' > "$OK/illustrations/hero.svg"
ca assets-ok; expect 0 "a clean logo, icon and animated illustration pass"
BAD=$(mkfix assets-bad)
printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300"><style>.s{animation:pulse 4s infinite}@keyframes pulse{to{opacity:0}}</style><rect class="s"/></svg>\n' > "$BAD/illustrations/auth.svg"
printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><circle r="4"><animate attributeName="r" values="4;5" dur="2s" repeatCount="indefinite"/></circle></svg>\n' > "$BAD/illustrations/smil.svg"
printf '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script><image href="data:image/png;base64,AAAA"/></svg>\n' > "$BAD/logo.svg"
printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><use href="https://cdn.example.com/i.svg#a"/></svg>\n' > "$BAD/icons/remote.svg"
{ printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'; awk 'BEGIN { for (i = 0; i < 120; i++) printf "<path d=\"M%d 0h1v1h-1z\"/>", i }'; printf '</svg>\n'; } > "$BAD/icons/heavy.svg"
printf 'GIF89a' > "$BAD/illustrations/loop.gif"
head -c 1700000 /dev/zero > "$BAD/illustrations/demo.webm"
ca assets-bad; expect 1 "asset problems fail the check"
has '^FAIL.svg.*illustrations/auth.svg.animated without a prefers-reduced-motion block' "an animation without reduced motion fails"
has '^FAIL.svg.*illustrations/smil.svg.SMIL animation' "SMIL animation fails (it can't honour reduced motion)"
has '^FAIL.svg.*/logo.svg.no viewBox' "an SVG without a viewBox fails"
has '^FAIL.svg.*/logo.svg.script or event handler' "a script inside an SVG fails"
has '^FAIL.svg.*/logo.svg.an embedded raster' "an embedded raster fails"
has '^FAIL.svg.*icons/remote.svg.an external reference' "an external reference fails"
has '^FAIL.size.*icons/heavy.svg' "an icon over 2 KB fails"
has '^FAIL.format.*illustrations/loop.gif' "a GIF fails"
has '^FAIL.size.*illustrations/demo.webm' "a video over 1.5 MB fails"

echo "check-architecture (PRD §11, §12 layer blocks, §13 tree vs project.json, routing)"
CK="$REPO/.claude/skills/design-architecture/scripts/check-architecture.sh"
archfix() { # archfix <dir> <good|bad>
  local d="$TMP/$1"; mkdir -p "$d/docs/delivery" "$d/.claude"
  if [ "$2" = good ]; then
    printf '## 11. Application folder structure\n```text\n.\n├── apps/\n│   ├── web/\n│   └── api/\n├── packages/\n│   └── contracts/\n└── e2e/\n```\n| Folder | Owner role |\n|---|---|\n| apps/web | frontend |\n| apps/api | backend |\n## 12. Architecture diagrams\n' > "$d/docs/delivery/PRD.md"
  else
    printf '## 11. Application folder structure\n```text\napps/web/{src,tests} → frontend · apps/api → backend\n```\n## 12. Architecture diagrams\n' > "$d/docs/delivery/PRD.md"
  fi
  { printf '## 4. Stack\nReact with Vite and React Router; FastAPI.\n## 12. Layer-by-layer architecture\n'
    for id in L0 L1 L2 L3 L4 L5 L6 L7 X1 X2 X3; do
      printf '### %s Block\n- **Responsibility:** r\n- **Components:** c\n- **Technology:** t\n- **Owner role:** o\n- **Folder(s):** f\n- **Talks to:** x\n' "$id"
      [ "$2" = bad ] && [ "$id" = L4 ] || printf -- '- **Scaling:** s\n'
      printf -- '- **Failure handling:** h\n- **Key NFRs:** n\n'
    done
    printf '## 13. Application folder structure\n```text\n.\n├── apps/\n│   ├── web/                # L0\n│   │   └── src/app/%s\n│   └── api/\n├── packages/\n│   └── contracts/\n├── e2e/\n├── infra/{docker,scripts}/\n%s\n└── package.json pnpm-lock.yaml\n```\n## 14. Architecture diagrams\n' \
      "$( [ "$2" = bad ] && echo '(auth)/' || echo 'routes/' )" "$( [ "$2" = bad ] && echo '├── tools/' || echo '├── .husky/pre-push' )"
  } > "$d/docs/delivery/ARCHITECTURE.md"
  printf '{"roles":{"frontend":{"paths":["apps/web/**"]},"backend":{"paths":["apps/api/**"]},"qa":{"paths":["e2e/**"]},"devops":{"paths":["infra/**"]},"mobile":{"enabled":false,"paths":["apps/mobile/**"]}},"contracts":{"paths":["packages/contracts/**"]},"shared_files":{"package.json":"integrator","pnpm-lock.yaml":"integrator",".husky/pre-push":"devops"}}\n' > "$d/.claude/project.json"
}
archfix arch-ok good; out=$(bash "$CK" --root "$TMP/arch-ok" 2>&1); c=$?; expect 0 "a complete architecture passes (tree, owner table, every layer field, tree = project.json)"
archfix arch-bad bad; out=$(bash "$CK" --root "$TMP/arch-bad" 2>&1); c=$?; expect 1 "architecture gaps fail the check"
has '^FAIL.prd11.*no drawn folder tree' "a compressed PRD §11 tree fails"
has '^FAIL.prd11.*no folder → owner role table' "a PRD §11 without an ownership table fails"
has '^FAIL.layers.*§12 L4 is missing: Scaling' "a layer block missing a field fails"
has '^FAIL.tree.*does not show .husky/pre-push' "a shared file missing from the §13 tree fails"
has '^FAIL.tree.*tools is in the §13 tree but has no owner' "a top-level folder without an owner fails"
has '^FAIL.routing.*Next.js syntax' "Next.js route groups in a React Router app fail"
printf '%s\n' "$out" | grep -q 'apps/mobile' && { fail=$((fail+1)); echo "  FAIL a disabled role's paths are ignored"; } || { pass=$((pass+1)); echo "  ok   a disabled role's paths are ignored"; }

echo "UI design kit (mockup base)"
check "a doc table naming Vercel is not a deploy" 0 guard-prod.sh "$(bash_json "printf '%s\n' '| Geist (Vercel), Linear | patterns only |' >> notes.md")"
check "the lowercase deploy command is still blocked" 2 guard-prod.sh "$(bash_json "vercel deploy --prod")"
MKDIR="$TMP/mockup-kit"; mkdir -p "$MKDIR"; BDS="$REPO/.claude/skills/build-design-system"
awk '/^```json/{f=1;buf="";next} /^```/{if(f){print buf > "'"$MKDIR"'/t.json"; f=0}; next} f{buf=buf $0 "\n"}' "$BDS/references/DESIGN_TOKENS.md"
bash "$BDS/scripts/check-tokens.sh" --css "$MKDIR/t.json" 2>/dev/null | grep -o -- '--[a-z0-9-]*:' | tr -d ':' | sort -u > "$MKDIR/defined"
grep -o 'var(--[a-z0-9-]*' "$BDS/assets/mockup-kit.css" | sed 's/var(//' | sort -u > "$MKDIR/used"
out=$(comm -23 "$MKDIR/used" "$MKDIR/defined"); [ -s "$MKDIR/used" ] && [ -z "$out" ]; yes $? "every token variable mockup-kit.css uses exists in the token output"
out=$(bash "$BDS/scripts/render-png.sh" "$TMP/no-such.html" "$TMP/x.png" 2>&1); [ $? -eq 2 ]; yes $? "render-png still refuses a missing local file"

DB="$REPO/.claude/skills/define-brand/scripts"; LB="$TMP/logo-board"; mkdir -p "$LB"
printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><path d="M12 16 C12 46 52 46 52 16" fill="none" stroke="currentColor" stroke-width="6"/></svg>\n' > "$LB/a.svg"
out=$(bash "$DB/logo-board.sh" "$LB/board.html" "$LB/a.svg" --brand "#4338ca" --name Demo 2>&1); c=$?; [ $c -eq 0 ] && grep -q 'class="tile"' "$LB/board.html" && grep -q 'height:16px' "$LB/board.html"; yes $? "the logo board shows each mark at 16-120 px, on dark, as an app icon and in a header"
out=$(bash "$DB/logo-board.sh" "$LB/board.html" "$LB/missing.svg" 2>&1); c=$?; [ $c -eq 2 ]; yes $? "the logo board refuses a missing mark"
out=$(bash "$DB/wordmark.sh" "$LB/no-font.ttf" "Demo" "$LB/w.svg" 2>&1); c=$?; [ $c -eq 2 ]; yes $? "the wordmark tool refuses a missing font file"

echo "Self-driven: routine work is never a stop"
grep -q '^## Routine work: act, don.t ask' "$REPO/.claude/rules/decision-policy.md"; yes $? "the decision policy lists the routine work done without asking"
grep -q 'git init -b main' "$REPO/.claude/skills/deliver/SKILL.md"; yes $? "preflight creates a missing git repository itself"
! grep -q 'show the user the exact commands to run and stop' "$REPO/.claude/skills/deliver/SKILL.md"; yes $? "preflight no longer stops for a gap the kit can fix"
! grep -q 'ask the human to commit or stash' "$REPO/.claude/skills/deliver/references/workflow.md"; yes $? "adopt no longer stops on uncommitted changes"
grep -q 'Shall I continue' "$REPO/.claude/agents/orchestrator.md"; yes $? "the orchestrator never asks to go on to the next step"
SET="$REPO/.claude/settings.json"
jq -e '.permissions.allow as $a | ["Bash(git init:*)","Bash(git commit:*)","Bash(bash .claude/*)","Bash(pnpm:*)","Edit(./**)"] | all(. as $x | $a | index($x))' "$SET" >/dev/null; yes $? "routine commands (git init, commits, kit scripts, project scripts, edits) run without a prompt"
jq -e '.permissions.deny as $d | ["Bash(git push --force:*)","Bash(git reset --hard:*)","Bash(git clean -f:*)","Bash(sudo:*)","Read(./.env)"] | all(. as $x | $d | index($x))' "$SET" >/dev/null; yes $? "force-push, reset --hard, clean -f, sudo and reading .env are always refused"
out=$(jq -r '.permissions.allow[] | select(test("^Bash\\((rm|sudo|gh api|vercel|git reset|git clean|git rebase|docker run|docker compose (up|down))"))' "$SET"); [ -z "$out" ]; yes $? "nothing destructive, deploying or container-starting is pre-approved"
jq -e '.permissions | has("defaultMode") | not' "$SET" >/dev/null; yes $? "the kit leaves the user's permission mode alone"
check "a pre-approved push is still checked by the hooks" 2 guard-prod.sh "$(bash_json "git push --force origin main")"

echo; echo "passed: $pass  failed: $fail"
[ $fail -eq 0 ]
