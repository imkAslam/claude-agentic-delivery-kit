#!/usr/bin/env bash
# delivery-state.sh: the only supported way to change the delivery run state (.claude/delivery/state.json).
# Used by the deliver, gate-review and delivery-status skills and by the hooks. Requires jq. Compatible with bash 3.2+.
set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "delivery-state: jq is required (install jq)" >&2; exit 2; }

resolve_root() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ]; then (cd "$CLAUDE_PROJECT_DIR" && pwd -P); return; fi
  local common; common=$(git rev-parse --git-common-dir 2>/dev/null || true)
  if [ -n "$common" ]; then (cd "$common/.." && pwd -P); return; fi
  (cd "$(dirname "$0")/../../../.." && pwd -P)
}

ROOT=$(resolve_root)
cd "$ROOT"
STATE=".claude/delivery/state.json"
EXAMPLE=".claude/skills/deliver/references/state.example.json"
LOG="docs/delivery/GATE-LOG.md"
MAX="${DELIVERY_MAX_ROUNDS:-3}"
LANES="adopt understand plan build verify release done"
TICKET_STATUSES="backlog ready in_progress in_review changes_requested approved done verified reopened blocked cancelled"
TICKET_TYPES="feature chore spike bug"
SEVERITIES="P1 P2 P3"
# allowed_next <status>: the statuses a ticket may move to (tracker skill -> "Status lifecycle")
allowed_next() {
  case "$1" in
    backlog) echo "ready cancelled" ;;
    ready) echo "in_progress backlog blocked cancelled" ;;
    in_progress) echo "in_review ready blocked" ;;
    in_review) echo "approved changes_requested blocked" ;;
    changes_requested) echo "in_progress blocked" ;;
    approved) echo "done reopened changes_requested blocked" ;;
    done) echo "verified reopened" ;;
    verified) echo "reopened" ;;
    reopened) echo "ready in_progress blocked cancelled" ;;
    blocked) echo "ready in_progress backlog cancelled" ;;
    cancelled) echo "backlog" ;;
    *) echo "" ;;
  esac
}

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
die() { echo "delivery-state: $*" >&2; exit 1; }
need_state() { [ -f "$STATE" ] || die "no run state; run: delivery-state.sh init"; }
in_list() { local x="$1"; shift; for i in $*; do [ "$i" = "$x" ] && return 0; done; return 1; }

file_sha() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi
}

rel() { local p="$1"; p="${p#"$ROOT"/}"; p="${p#./}"; printf '%s' "${p%/}"; }

# upd <jq-filter> [jq options...]: atomically apply a filter to the state
upd() {
  local filter="$1"; shift
  local tmp; tmp=$(mktemp "${STATE}.XXXXXX")
  if jq "$@" --arg now "$(now)" "${filter} | .updated_at = \$now" "$STATE" > "$tmp"; then mv "$tmp" "$STATE"; else rm -f "$tmp"; die "state update failed"; fi
}

# hash_paths <path>...: prints a JSON object {relpath: sha256} for files, expanding directories
hash_paths() {
  local p f lines=""
  for p in "$@"; do
    p=$(rel "$p")
    if [ -d "$p" ]; then
      while IFS= read -r f; do lines="${lines}${f}	$(file_sha "$f")
"; done < <(find "$p" -type f ! -name '.DS_Store' | sort)
    elif [ -f "$p" ]; then
      lines="${lines}${p}	$(file_sha "$p")
"
    else
      die "package path not found: $p"
    fi
  done
  printf '%s' "$lines" | jq -Rn '[inputs | select(length > 0) | split("\t") | {(.[0]): .[1]}] | add // {}'
}

# ---- Usage ledger: .claude/delivery/usage.json -------------------------------------------------------------------
# Provider-reported token usage, read from Claude Code's transcripts (every assistant line carries the API's `usage`),
# for the main session (the orchestrator) and every subagent. Written only by `usage sync` (the record-usage.sh hook)
# under a lock, apart from state.json, so hooks finishing at the same time never clobber the run state.
USAGE=".claude/delivery/usage.json"
U_ZERO='{"sources": {}, "entries": [], "budget": null}'
SINCE=""
usage_json() { if [ -f "$USAGE" ]; then cat "$USAGE"; else printf '%s' "$U_ZERO"; fi; }
usage_lock() {
  local n=0
  mkdir -p "$(dirname "$USAGE")"
  while ! mkdir "$USAGE.lock" 2>/dev/null; do
    n=$((n + 1))
    if [ -n "$(find "$USAGE.lock" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then rm -rf "$USAGE.lock"; continue; fi   # stale
    [ "$n" -lt 150 ] || die "the usage ledger is locked ($USAGE.lock)"
    sleep 0.1
  done
  trap 'rm -rf "$USAGE.lock"' EXIT
}
usage_unlock() { rm -rf "$USAGE.lock"; trap - EXIT; }
# usage_file_totals <transcript>: {model: {input, cache_write, cache_read, output, calls}} since $SINCE.
# One API response is written as several lines with the same message id and the same usage: count it once.
usage_file_totals() {
  jq -nR --arg since "$SINCE" '
    [inputs | (fromjson? // empty)
      | select(.type == "assistant" and (.message.usage | type) == "object" and (.message.model // "") != "<synthetic>")
      | select($since == "" or ((.timestamp // "")[0:19]) >= ($since[0:19]))
      | {id: (.message.id // .requestId // .uuid), m: (.message.model // "unknown"), u: .message.usage}]
    | unique_by(.id) | group_by(.m)
    | map({key: .[0].m, value: {input: (map(.u.input_tokens // 0) | add), cache_write: (map(.u.cache_creation_input_tokens // 0) | add),
           cache_read: (map(.u.cache_read_input_tokens // 0) | add), output: (map(.u.output_tokens // 0) | add), calls: length}})
    | from_entries' "$1"
}
# usage_sync_one <transcript> <key> <agent> <session|subagent>: add what this transcript used since its last sync,
# attributed to the current lane/step. Idempotent: an unchanged file is skipped, a grown one adds only the difference.
usage_sync_one() {
  local f="$1" key="$2" agent="$3" kind="$4" size old totals step tmp
  size=$(wc -c < "$f" | tr -d ' ')
  old=$(jq -r --arg k "$key" '.sources[$k].size // -1' "$USAGE")
  [ "$size" = "$old" ] && return 0
  totals=$(usage_file_totals "$f") || return 0
  step=$(jq -r '(.lane // "") + "/" + (.step // "")' "$STATE")
  tmp=$(mktemp "${USAGE}.XXXXXX")
  if jq --arg k "$key" --arg a "$agent" --arg kind "$kind" --arg step "$step" --arg f "$f" --argjson size "$size" \
       --argjson t "$totals" --arg now "$(now)" '
    def d(a; b): if a > b then a - b else 0 end;
    (.sources[$k].models // {}) as $old
    | [ $t | to_entries[] | .key as $m | .value as $n | ($old[$m] // {}) as $o
        | {model: $m, input: d($n.input; $o.input // 0), cache_write: d($n.cache_write; $o.cache_write // 0),
           cache_read: d($n.cache_read; $o.cache_read // 0), output: d($n.output; $o.output // 0), calls: d($n.calls; $o.calls // 0)}
        | select(.input + .cache_write + .cache_read + .output > 0) ] as $new
    | reduce $new[] as $e (.;
        (first(range(.entries | length) as $i
          | select(.entries[$i].source == $k and .entries[$i].model == $e.model and .entries[$i].step == $step) | $i) // null) as $i
        | if $i == null then .entries += [$e + {source: $k, agent: $a, kind: $kind, step: $step, first: $now, last: $now}]
          else .entries[$i] |= (.input += $e.input | .cache_write += $e.cache_write | .cache_read += $e.cache_read
                                | .output += $e.output | .calls += $e.calls | .last = $now) end)
    | .sources[$k] = {agent: $a, kind: $kind, file: $f, size: $size, models: $t, updated: $now}' "$USAGE" > "$tmp"
  then mv "$tmp" "$USAGE"; else rm -f "$tmp"; fi
}
usage_budget() { # the human-approved budget in the ledger, else DELIVERY_TOKEN_BUDGET; 0 = none
  local b; b=$(usage_json | jq -r '.budget.tokens // empty')
  [ -n "$b" ] || b="${DELIVERY_TOKEN_BUDGET:-0}"
  case "$b" in ''|*[!0-9]*) b=0 ;; esac
  printf '%s' "$b"
}
usage_total() { usage_json | jq '[(.entries // [])[] | .input + .cache_write + .cache_read + .output] | add // 0'; }
usage_status() { # prints the total; BUDGET_WARNING at 80%; BUDGET_REACHED and return 4 at 100%
  local total budget; total=$(usage_total); budget=$(usage_budget)
  if [ "$budget" -gt 0 ]; then echo "total tokens: ${total} / budget ${budget}"; else echo "total tokens: ${total}"; fi
  [ "$budget" -gt 0 ] || return 0
  if [ "$total" -ge "$budget" ]; then echo "BUDGET_REACHED: ${total} of ${budget} tokens used. Ask the human before starting or continuing any agent (decision-policy: major decisions)"; return 4; fi
  if [ "$total" -ge $(( budget * 8 / 10 )) ]; then echo "BUDGET_WARNING: $(( total * 100 / budget ))% of the token budget used"; fi
  return 0
}

log_gate() {
  mkdir -p "$(dirname "$LOG")"
  [ -f "$LOG" ] || printf '# Gate log\n\n| When (UTC) | Gate | Status | Decision | Approver | Notes |\n|---|---|---|---|---|---|\n' > "$LOG"
  printf '| %s | %s | %s | %s | %s | %s |\n' "$(now)" "$1" "$2" "$3" "$4" "$(printf '%s' "$5" | tr '\n|' '  ')" >> "$LOG"
}

usage() {
  cat <<'EOF'
delivery-state.sh <command> [args]
  init [--mode adopt]                          create .claude/delivery/state.json (no-op if present);
                                               --mode adopt starts an adopt run for an existing codebase (lane adopt)
  summary                                      print lane, step, gates, tickets, CRs, failures
  set-step <lane> <step>                       lanes: adopt understand plan build verify release done
  milestone <ms-n>                             set the current milestone
  validated                                    record that every project.json command ran green
  round <loop-id> | round-reset <loop-id>      review-round counter (exit 3 + CAP_REACHED at the cap)
  note "<text>"                                record a note (e.g. a skipped step and why)
  approve <gate> <decision> "<approver>" "<notes>" <path>...   human approval tied to file hashes
  approve-baseline "<approver>" "<notes>" <path>...   adopt runs only: one human approval of the as-built package;
                                               records baseline, g1 and g2 together and tags the commit delivery-baseline
  reject  <gate> <decision> "<approver>" "<notes>"             human rejection / revise decision
  verify  <gate>                               exit 0 only if approved and every package hash matches
  release "<name>" "<artifact>" "<environment>" record the release identity (required before approving g3)
  cr-open <gate> "<reason>" --approved-by "<human>" <path>...
                                               open a change request (invalidates the gate); prints the id.
                                               Needs the human's explicit yes first (a major decision)
  cr-close <CR-id>
  ticket add <id> <role> <milestone> "<title>" [dep1,dep2] [--type feature|chore|spike|bug] [--size S|M|L] [--paths <glob,glob>]
             [--status ready|backlog] [--of <original-id>|none] [--severity P1|P2|P3] [--found-in "<where>"]
                                               a bug needs --of and --severity; it is linked both ways
  ticket status <id> <status> [--note "<text>"] [--force "<reason>"]
                                               validated transition, recorded in the ticket's history
                                               statuses: backlog ready in_progress in_review changes_requested
                                               approved done verified reopened blocked cancelled
  ticket show <id>                             fields, links (bug of / bugs) and the status history
  ticket attempt <id>                          increment attempts (exit 3 + CAP_REACHED at the cap)
  ticket set <id> <branch|tracker_ref|title|size> <value>
  branch milestone <ms-n>                      create develop from the default branch if missing; refuse while the previous
                                               milestone is not merged into develop; create ms-<n>/integration from develop
  branch ticket <id> [--base <branch>]         name, create and record the ticket branch: feature|chore|spike|bugfix/<id>-<slug>
                                               (hotfix/ when the base is the default branch); base defaults to ms-<n>/integration
                                               (a bug found in verify or release: --base release/<version>)
  branch release <vX.Y.Z>                      cut release/<vX.Y.Z> from develop once every milestone is merged into it
  branch cleanup <ms-n>                        after the milestone is merged into develop: remove its clean ticket worktrees and branches
  ready <ms-n>                                list ready tickets whose dependencies are done (or verified)
  plan-check <ms-n>                            are the milestone's tickets independent? fails when a feature ticket depends on
                                               another feature ticket in the same milestone, or when two tickets that can run
                                               together touch the same files (ticket add --paths); prints how many can start together
  board                                        who is working on what right now (ticket, role, status, attempts, agent)
  stats [ms-n]                                 rework and cost per role: attempts, returns from review, reopened, bugs, tokens
  bugs [open|all] [ms-n]                       list bug tickets with severity, status and the original ticket
  fail <ticket> <role> <attempts> <report-path>
  msg add <from> <to> <question|request|handoff|finding|info|decision-needed> "<re>" "<body>" [blocking]
  msg answer <M-id> <from> "<body>" | msg close <M-id> | msg open [to]
  agent set <key> <agent-id> | agent get <key>    remember subagent ids so they can be continued (SendMessage)
  usage sync [--agent-type t] [transcript...]  record provider-reported usage from Claude Code transcripts (the record-usage.sh
                                               hook calls it; with no file or --all [--since ISO]: every session of this project);
                                               exit 4 + BUDGET_REACHED when the budget is hit
  usage check                                  the total against the budget (exit 4 + BUDGET_REACHED at 100%)
  usage budget <tokens> --approved-by "<human>"   set the budget the human approved (overrides DELIVERY_TOKEN_BUDGET)
  usage summary                                input, cache writes, cache reads, output; by model, agent and lane
EOF
}

MSG_LOG="docs/delivery/MESSAGES.md"
MSG_TYPES="question request handoff finding info decision-needed"
log_msg() { # messages live in the run state; the file is only kept up for older runs that already have it
  [ -f "$MSG_LOG" ] || return 0
  printf '| %s | %s | %s | %s | %s | %s | %s |\n' "$(now)" "$1" "$2" "$3" "$4" "$5" "$(printf '%s' "$6" | tr '\n|' '  ')" >> "$MSG_LOG"
}

cmd="${1:-help}"; shift || true
case "$cmd" in
  init)
    mode="new"
    if [ "${1:-}" = "--mode" ]; then mode="${2:-}"; in_list "$mode" new adopt || die "unknown mode: ${mode} (new | adopt)"; fi
    mkdir -p "$(dirname "$STATE")"
    if [ ! -f "$STATE" ]; then
      [ -f "$EXAMPLE" ] || die "missing $EXAMPLE"
      cp "$EXAMPLE" "$STATE"; upd '.started_at = $now'
      if [ "$mode" = "adopt" ]; then
        upd '.mode = "adopt" | .lane = "adopt" | .step = "detect" | .gates.baseline = {status: "pending", decision: null, approver: null, ts: null, notes: null, package: {}}'
      fi
      echo "created $STATE (${mode} run)"
    else
      cur=$(jq -r '.mode // "new"' "$STATE")
      [ "$mode" = "new" ] || [ "$cur" = "$mode" ] || die "a ${cur} run already exists here; an adopt run can only start in a repository without a delivery run"
      echo "state exists: $STATE"
    fi
    if [ -d .git ] || git rev-parse --git-dir >/dev/null 2>&1; then
      grep -qxF '.claude/delivery/' .gitignore 2>/dev/null || printf '\n# delivery run state (local cursor; audit trail is docs/delivery/GATE-LOG.md)\n.claude/delivery/\n' >> .gitignore
    fi
    ;;
  summary)
    need_state
    jq -r --arg max "$MAX" --argjson U "$(usage_json)" '
      (if (.mode // "new") == "adopt" then "Mode: adopt (existing codebase)   Baseline: " + (if .baseline then "\(.baseline.tag) @ \(.baseline.commit[0:7])" else "not approved yet" end) else empty end),
      "Lane: \(.lane)   Step: \(.step)   Milestone: \(.milestone // "-")",
      "Gates: " + ([.gates | to_entries[] | "\(.key)=\(.value.status)" + (if .value.decision then "(\(.value.decision))" else "" end)] | join("  ")),
      "Tickets: " + (if (.tickets | length) == 0 then "none" else ([.tickets | to_entries | group_by(.value.status)[] | "\(.[0].value.status)=\(length)"] | join("  ")) end),
      (([.tickets[] | select((.type // "") == "bug" and ((.status | IN("done", "verified", "cancelled")) | not))]) as $b | if ($b | length) > 0 then "Open bugs: \($b | length) (" + ([$b | group_by(.severity)[] | "\(.[0].severity)=\(length)"] | join(" ")) + ")" else empty end),
      (([.tickets | to_entries[] | select(.value.status | IN("in_progress", "in_review", "changes_requested", "reopened", "blocked")) | "\(.key)[\(.value.role)]:\(.value.status)"]) as $a | if ($a | length) > 0 then "Active/blocked: " + ($a | join(", ")) else empty end),
      (([.change_requests[] | select(.status == "open") | "\(.id)(\(.gate))"]) as $c | if ($c | length) > 0 then "Open CRs: " + ($c | join(", ")) else empty end),
      (if (.failures | length) > 0 then "Last failure: \(.failures[-1].ticket) [\(.failures[-1].role)] -> \(.failures[-1].report)" else empty end),
      (([(.messages // [])[] | select(.status == "open")]) as $m | if ($m | length) > 0 then "Open messages: \($m | length)" + (if ([$m[] | select(.blocking)] | length) > 0 then " (\([$m[] | select(.blocking)] | length) blocking)" else "" end) else empty end),
      (if (.rounds | length) > 0 then "Rounds: " + ([.rounds | to_entries[] | "\(.key)=\(.value)/\($max)"] | join("  ")) else empty end),
      (if ((.notes // []) | length) > 0 then "Last note: \(.notes[-1].text)" else empty end),
      (($U.entries // []) as $e | if ($e | length) > 0 then "Usage: \([$e[] | .input + .cache_write + .cache_read + .output] | add) tokens, provider-reported (\([$U.sources[]? | select(.kind == "session")] | length) main sessions, \([$U.sources[]? | select(.kind == "subagent")] | length) agent runs)" else empty end),
      "Validated: \(.validated_at // "no")   Updated: \(.updated_at // "-")"' "$STATE"
    usage_status | grep '^BUDGET_' || true
    ;;
  set-step)
    need_state; [ $# -eq 2 ] || die "usage: set-step <lane> <step>"
    in_list "$1" $LANES || die "unknown lane: $1"
    upd '.lane = $l | .step = $s' --arg l "$1" --arg s "$2"
    ;;
  milestone)
    need_state; [ $# -eq 1 ] || die "usage: milestone <ms-n>"
    upd '.milestone = $m' --arg m "$1"
    ;;
  validated)
    need_state; upd '.validated_at = $now'
    ;;
  round)
    need_state; [ $# -eq 1 ] || die "usage: round <loop-id>"
    upd '.rounds[$k] = ((.rounds[$k] // 0) + 1)' --arg k "$1"
    n=$(jq -r --arg k "$1" '.rounds[$k]' "$STATE"); echo "$n"
    if [ "$n" -ge "$MAX" ]; then echo "CAP_REACHED"; exit 3; fi
    ;;
  round-reset)
    need_state; upd 'del(.rounds[$k])' --arg k "$1"
    ;;
  note)
    need_state; upd '.notes += [{ts: $now, text: $t}]' --arg t "${1:-}"
    ;;
  approve)
    need_state; [ $# -ge 5 ] || die "usage: approve <gate> <decision> <approver> <notes> <path>..."
    gate="$1" decision="$2" approver="$3" notes="$4"; shift 4
    [ -n "$approver" ] || die "approver is required"
    if [ "$gate" = "g3" ]; then
      [ "$(jq -r '.release.name // empty' "$STATE")" != "" ] || die "record the release first: delivery-state.sh release <name> <artifact> <environment>"
    fi
    pkg=$(hash_paths "$@")
    upd '.gates[$g] = {status: "approved", decision: $d, approver: $a, ts: $now, notes: $n, package: $pkg}' \
      --arg g "$gate" --arg d "$decision" --arg a "$approver" --arg n "$notes" --argjson pkg "$pkg"
    log_gate "$gate" approved "$decision" "$approver" "$notes"
    echo "approved $gate ($(printf '%s' "$pkg" | jq 'length') files hashed)"
    ;;
  approve-baseline)
    need_state; [ $# -ge 3 ] || die "usage: approve-baseline <approver> <notes> <path>..."
    [ "$(jq -r '.mode // "new"' "$STATE")" = "adopt" ] || die "approve-baseline is only for adopt runs (delivery-state.sh init --mode adopt)"
    [ "$(jq -r '.gates.baseline.status // "pending"' "$STATE")" != "approved" ] || die "the baseline is already approved; later changes go through change requests (cr-open)"
    approver="$1" notes="$2"; shift 2
    [ -n "$approver" ] || die "approver is required"
    [ -f .claude/project.json ] || die "the baseline is incomplete: missing .claude/project.json (role boundaries and commands)"
    for p in "$@"; do [ -e "$p" ] || die "not found: $p"; done
    pkg=$(hash_paths "$@")
    for req in docs/delivery/PRD.md docs/delivery/ARCHITECTURE.md docs/delivery/BASELINE.md; do
      printf '%s' "$pkg" | jq -e --arg p "$req" 'has($p)' >/dev/null || die "the baseline package must include $req"
    done
    commit=""
    if git rev-parse --git-dir >/dev/null 2>&1; then
      dirty=$(git status --porcelain -- "$@" 2>/dev/null)
      [ -z "$dirty" ] || die "commit the baseline package before approving it (uncommitted: $(printf '%s' "$dirty" | head -3 | tr '\n' ' '))"
      commit=$(git rev-parse HEAD 2>/dev/null) || die "the repository has no commit yet"
      if git rev-parse -q --verify refs/tags/delivery-baseline >/dev/null 2>&1; then
        [ "$(git rev-parse 'delivery-baseline^{commit}')" = "$commit" ] || die "the tag delivery-baseline already exists on another commit; remove it only if the human asked to redo the baseline"
      else
        git tag delivery-baseline || die "could not create the tag delivery-baseline"
      fi
    fi
    upd '(.gates.baseline, .gates.g1, .gates.g2) = {status: "approved", decision: "baseline", approver: $a, ts: $now, notes: $n, package: $pkg}
         | .gates.intake = {status: "approved", decision: "baseline", approver: $a, ts: $now, notes: "replaced by the adopt baseline", package: {}}
         | .baseline = {tag: "delivery-baseline", commit: $c, ts: $now}
         | .lane = "build" | .step = "increment-wait"' \
      --arg a "$approver" --arg n "$notes" --arg c "$commit" --argjson pkg "$pkg"
    for g in baseline g1 g2; do log_gate "$g" approved baseline "$approver" "$notes"; done
    echo "approved the baseline ($(printf '%s' "$pkg" | jq 'length') files hashed); g1 and g2 recorded; tag delivery-baseline @ $(printf '%s' "$commit" | cut -c1-7); coding is unlocked"
    ;;
  reject)
    need_state; [ $# -ge 3 ] || die "usage: reject <gate> <decision> <approver> [notes]"
    upd '.gates[$g] = {status: "rejected", decision: $d, approver: $a, ts: $now, notes: $n, package: {}}' \
      --arg g "$1" --arg d "$2" --arg a "$3" --arg n "${4:-}"
    log_gate "$1" rejected "$2" "$3" "${4:-}"
    echo "rejected $1 ($2)"
    ;;
  verify)
    need_state; [ $# -eq 1 ] || die "usage: verify <gate>"
    status=$(jq -r --arg g "$1" '.gates[$g].status // "pending"' "$STATE")
    if [ "$status" != "approved" ]; then echo "gate $1 is $status"; exit 1; fi
    bad=0
    while IFS="	" read -r path expected; do
      [ -z "$path" ] && continue
      if [ ! -f "$path" ]; then echo "missing: $path"; bad=1
      elif [ "$(file_sha "$path")" != "$expected" ]; then echo "changed: $path"; bad=1; fi
    done < <(jq -r --arg g "$1" '.gates[$g].package | to_entries[] | "\(.key)\t\(.value)"' "$STATE")
    if [ $bad -ne 0 ]; then echo "gate $1 approval no longer matches its package"; exit 1; fi
    echo "gate $1 OK"
    ;;
  release)
    need_state; [ $# -eq 3 ] || die "usage: release <name> <artifact> <environment>"
    upd '.release = ((.release // {}) + {name: $n, artifact: $a, environment: $e})' --arg n "$1" --arg a "$2" --arg e "$3"
    ;;
  cr-open)
    need_state; [ $# -ge 3 ] || die "usage: cr-open <gate> <reason> --approved-by <human> <path>..."
    gate="$1" reason="$2"; shift 2
    approver="" rest=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --approved-by) approver="${2:-}"; shift 2 ;;
        *) rest="${rest}${1}
"; shift ;;
      esac
    done
    [ -n "$approver" ] || die "a change request reopens an approved decision, so it needs the human's explicit approval first (decision-policy: major decisions). Ask with AskUserQuestion, then: cr-open <gate> \"<reason>\" --approved-by \"<human>\" <path>..."
    [ -n "$rest" ] || die "usage: cr-open <gate> <reason> --approved-by <human> <path>..."
    paths=$(printf '%s' "$rest" | while IFS= read -r p; do [ -n "$p" ] && { rel "$p"; echo; }; done | jq -R . | jq -s 'map(select(length > 0))')
    id="CR-$(( $(jq '.change_requests | length' "$STATE") + 1 ))"
    upd '.change_requests += [{id: $id, gate: $g, paths: $p, reason: $r, approved_by: $a, status: "open", ts: $now}]
         | if .gates[$g].status == "approved" then .gates[$g].status = "invalidated" else . end' \
      --arg id "$id" --arg g "$gate" --arg r "$reason" --arg a "$approver" --argjson p "$paths"
    log_gate "$gate" "change-request $id" "-" "$approver" "$reason"
    echo "$id"
    ;;
  cr-close)
    need_state; [ $# -eq 1 ] || die "usage: cr-close <CR-id>"
    upd '(.change_requests[] | select(.id == $id) | .status) = "closed"' --arg id "$1"
    ;;
  usage)
    need_state; sub="${1:-}"; shift || true
    case "$sub" in
      sync)
        SINCE=$(jq -r '.started_at // ""' "$STATE"); atype=""; files=""; all=0
        while [ $# -gt 0 ]; do
          case "$1" in
            --agent-type) atype="${2:-}"; shift 2 ;;
            --since) SINCE="${2:-}"; shift 2 ;;
            --all) all=1; shift ;;
            *) files="${files}$1
"; shift ;;
          esac
        done
        if [ -z "$files" ] || [ "$all" -eq 1 ]; then
          # Catch-up: every main-session transcript Claude Code keeps for this project.
          tdir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/$(printf '%s' "$ROOT" | sed 's/[^A-Za-z0-9]/-/g')"
          [ -d "$tdir" ] || die "no transcripts found for this project in $tdir"
          [ -n "$SINCE" ] || die "this run has no start time recorded; pass --since <ISO time> so earlier sessions are not counted"
          for f in "$tdir"/*.jsonl; do [ -f "$f" ] && files="${files}${f}
"; done
        fi
        main=$(jq -r '.agent // "main-session"' .claude/settings.json 2>/dev/null || echo main-session)
        usage_lock
        [ -f "$USAGE" ] || printf '%s\n' "$U_ZERO" > "$USAGE"
        while IFS= read -r f; do
          { [ -n "$f" ] && [ -f "$f" ]; } || continue
          b=$(basename "$f" .jsonl)
          case "$b" in
            agent-*)
              a=$(jq -r '.agentType // empty' "${f%.jsonl}.meta.json" 2>/dev/null || true)
              usage_sync_one "$f" "$(basename "$(dirname "$(dirname "$f")")")/$b" "${a:-${atype:-subagent}}" subagent ;;
            *)
              usage_sync_one "$f" "$b" "$main" session
              for s in "${f%.jsonl}"/subagents/agent-*.jsonl; do
                [ -f "$s" ] || continue
                a=$(jq -r '.agentType // empty' "${s%.jsonl}.meta.json" 2>/dev/null || true)
                usage_sync_one "$s" "$b/$(basename "$s" .jsonl)" "${a:-subagent}" subagent
              done ;;
          esac
        done <<EOF
$files
EOF
        usage_unlock
        rc=0; usage_status || rc=$?; exit "$rc"
        ;;
      check) rc=0; usage_status || rc=$?; exit "$rc" ;;
      budget)
        [ $# -eq 3 ] && [ "$2" = "--approved-by" ] && [ -n "$3" ] || die "usage: usage budget <tokens> --approved-by \"<human>\" (0 = no budget)"
        case "$1" in ''|*[!0-9]*) die "tokens must be a whole number" ;; esac
        usage_lock
        [ -f "$USAGE" ] || printf '%s\n' "$U_ZERO" > "$USAGE"
        tmp=$(mktemp "${USAGE}.XXXXXX")
        jq --argjson t "$1" --arg by "$3" --arg now "$(now)" '.budget = {tokens: $t, approved_by: $by, ts: $now}' "$USAGE" > "$tmp" && mv "$tmp" "$USAGE"
        usage_unlock
        upd '.notes = ((.notes // []) + [{ts: $now, text: ("token budget set to " + $t + " by " + $by)}])' --arg t "$1" --arg by "$3"
        rc=0; usage_status || rc=$?; exit "$rc"
        ;;
      summary)
        usage_json | jq -r --argjson b "$(usage_budget)" '
          def tot: .input + .cache_write + .cache_read + .output;
          def sum(f): map(f) | add // 0;
          (.entries // []) as $e | ($e | sum(tot)) as $t
          | "Tokens: \($t)   (input \($e | sum(.input)) · cache writes \($e | sum(.cache_write)) · cache reads \($e | sum(.cache_read)) · output \($e | sum(.output)); \($e | sum(.calls)) API calls)"
              + (if $b > 0 then "   Budget: \($b) (\($t * 100 / $b | floor)% used)" else "" end),
            "Recorded from: \([.sources[]? | select(.kind == "session")] | length) main-session transcripts, \([.sources[]? | select(.kind == "subagent")] | length) agent runs",
            "By model: " + ([$e | group_by(.model)[] | "\(.[0].model)=\(sum(tot))"] | join("  ")),
            "By agent (top 8): " + ([$e | group_by(.agent)[] | {a: .[0].agent, t: sum(tot), n: ([.[].source] | unique | length)}] | sort_by(-.t) | .[0:8] | map("\(.a)=\(.t)/\(.n) runs") | join("  ")),
            "By lane: " + ([$e | group_by(.step | split("/")[0])[] | "\(.[0].step | split("/")[0])=\(sum(tot))"] | join("  "))'
        usage_status | grep '^BUDGET_' || true
        ;;
      add) die "usage add was removed: usage is now recorded automatically from Claude Code's transcripts (the record-usage.sh hook runs 'usage sync'). See cost.md §4." ;;
      *) die "usage: usage sync|check|budget|summary" ;;
    esac
    ;;
  ticket)
    need_state; sub="${1:-}"; shift || true
    case "$sub" in
      add)
        [ $# -ge 4 ] || die "usage: ticket add <id> <role> <milestone> <title> [deps] [--type t] [--size S|M|L] [--status ready|backlog] [--of <id>|none] [--severity P1|P2|P3] [--found-in <where>] [--paths <glob,glob>]"
        id="$1" role="$2" ms="$3" title="$4"; shift 4
        deps="" type="feature" size="" of="" sev="" found="" st="ready" paths=""
        if [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; then deps="$1"; shift; fi
        while [ $# -gt 0 ]; do
          [ $# -ge 2 ] || die "option $1 needs a value"
          case "$1" in
            --type) type="$2" ;;
            --size) size="$2" ;;
            --of) of="$2" ;;
            --severity) sev="$2" ;;
            --found-in) found="$2" ;;
            --status) st="$2" ;;
            --paths) paths="$2" ;;
            *) die "unknown option: $1" ;;
          esac
          shift 2
        done
        [ "$(jq -r --arg i "$id" '.tickets[$i] // empty' "$STATE")" = "" ] || die "ticket $id exists"
        in_list "$type" $TICKET_TYPES || die "type must be one of: $TICKET_TYPES"
        in_list "$st" "ready backlog" || die "a new ticket starts as ready or backlog"
        [ -z "$size" ] || in_list "$size" "S M L" || die "size must be S, M or L (split anything larger)"
        if [ "$type" = "bug" ]; then
          [ -n "$of" ] || die "a bug needs --of <original ticket id> (or --of none, with the reason in --found-in)"
          in_list "$sev" $SEVERITIES || die "a bug needs --severity P1|P2|P3"
          if [ "$of" != "none" ]; then
            [ "$(jq -r --arg o "$of" '.tickets[$o] // empty' "$STATE")" != "" ] || die "original ticket $of not found"
          fi
        else
          [ -z "$of" ] || die "--of is only for bugs (--type bug)"
        fi
        upd '.tickets[$i] = {title: $t, type: $ty, role: $r, milestone: $m, status: $st,
              size: (if $sz == "" then null else $sz end), attempts: 0,
              depends_on: ($d | split(",") | map(select(length > 0))), paths: ($p | split(",") | map(select(length > 0))), branch: null, tracker_ref: null,
              bug_of: (if $of == "" or $of == "none" then null else $of end),
              severity: (if $sev == "" then null else $sev end),
              found_in: (if $f == "" then null else $f end), bugs: [],
              history: [{from: null, to: $st, ts: $now, note: "created"}]}
            | if $of != "" and $of != "none" then .tickets[$of].bugs = ((.tickets[$of].bugs // []) + [$i]) else . end' \
          --arg i "$id" --arg r "$role" --arg m "$ms" --arg t "$title" --arg d "$deps" --arg ty "$type" \
          --arg sz "$size" --arg of "$of" --arg sev "$sev" --arg f "$found" --arg st "$st" --arg p "$paths"
        ;;
      status)
        [ $# -ge 2 ] || die "usage: ticket status <id> <status> [--note \"<text>\"] [--force \"<reason>\"]"
        id="$1" to="$2"; shift 2; note="" force=""
        while [ $# -gt 0 ]; do
          [ $# -ge 2 ] || die "option $1 needs a value"
          case "$1" in
            --note) note="$2" ;;
            --force) force="$2" ;;
            *) die "unknown option: $1" ;;
          esac
          shift 2
        done
        in_list "$to" $TICKET_STATUSES || die "unknown status: $to (one of: $TICKET_STATUSES)"
        from=$(jq -r --arg i "$id" '.tickets[$i].status // empty' "$STATE")
        [ -n "$from" ] || die "no ticket $id"
        [ "$from" != "$to" ] || die "$id is already $to"
        if [ -z "$force" ] && ! in_list "$to" $(allowed_next "$from"); then
          die "$id: $from -> $to is not allowed. From $from: $(allowed_next "$from"). Use --force \"<reason>\" only to correct a wrong status."
        fi
        upd '.tickets[$i].status = $to
             | .tickets[$i].history = ((.tickets[$i].history // []) + [{from: $fr, to: $to, ts: $now}
                 + (if $n != "" then {note: $n} else {} end) + (if $fo != "" then {forced: $fo} else {} end)])' \
          --arg i "$id" --arg fr "$from" --arg to "$to" --arg n "$note" --arg fo "$force"
        ;;
      show)
        [ $# -eq 1 ] || die "usage: ticket show <id>"
        [ "$(jq -r --arg i "$1" '.tickets[$i] // empty' "$STATE")" != "" ] || die "no ticket $1"
        jq -r --arg i "$1" '.tickets[$i] as $t
          | "\($i) · \($t.title)",
            "type: \($t.type // "feature")  role: \($t.role)  milestone: \($t.milestone)  size: \($t.size // "-")  status: \($t.status)  attempts: \($t.attempts // 0)",
            "depends_on: \((($t.depends_on // []) | join(", ")) as $d | if $d == "" then "-" else $d end)",
            (if $t.branch then "branch: \($t.branch)  base: \($t.base // "-")" else empty end),
            (if ($t.type // "") == "bug" then "bug of: \($t.bug_of // "none")  severity: \($t.severity)  found in: \($t.found_in // "-")" else empty end),
            (if (($t.bugs // []) | length) > 0 then "bugs: " + ($t.bugs | join(", ")) else empty end),
            "history:",
            (($t.history // [])[] | "  \(.ts)  \(.from // "new") -> \(.to)" + (if .note then "  (\(.note))" else "" end) + (if .forced then "  [forced: \(.forced)]" else "" end))' "$STATE"
        ;;
      attempt)
        [ $# -eq 1 ] || die "usage: ticket attempt <id>"
        upd '.tickets[$i].attempts = ((.tickets[$i].attempts // 0) + 1)' --arg i "$1"
        n=$(jq -r --arg i "$1" '.tickets[$i].attempts' "$STATE"); echo "$n"
        if [ "$n" -ge "$MAX" ]; then echo "CAP_REACHED"; exit 3; fi
        ;;
      set)
        [ $# -eq 3 ] || die "usage: ticket set <id> <field> <value>"
        in_list "$2" "branch tracker_ref title size" || die "field must be branch, tracker_ref, title or size"
        [ "$2" != "size" ] || in_list "$3" "S M L" || die "size must be S, M or L"
        upd '.tickets[$i][$f] = $v' --arg i "$1" --arg f "$2" --arg v "$3"
        ;;
      *) die "usage: ticket add|status|show|attempt|set ..." ;;
    esac
    ;;
  branch)
    # Git Flow (.claude/rules/git.md): main = released code, develop = integrated milestones,
    # ms-<n>/integration = the milestone join, <type>/<id>-<slug> = one ticket, release/<vX.Y.Z> = the candidate.
    need_state; sub="${1:-}"; shift || true
    git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repository"
    ref_ok() { git rev-parse -q --verify "refs/heads/$1" >/dev/null 2>&1 || git rev-parse -q --verify "refs/remotes/origin/$1" >/dev/null 2>&1; }
    ref_of() { # the newest known copy: origin/<b> after a fetch when the remote has it, else the local branch
      if git rev-parse -q --verify "refs/remotes/origin/$1" >/dev/null 2>&1; then echo "origin/$1"; else echo "$1"; fi; }
    new_branch() { # new_branch <name> <base>: create the local branch unless it exists
      git rev-parse -q --verify "refs/heads/$1" >/dev/null 2>&1 && return 0
      git branch -q "$1" "$(ref_of "$2")" || die "could not create $1 from $2"; }
    merged() { git merge-base --is-ancestor "$(ref_of "$1")" "$(ref_of develop)"; }
    if git remote | grep -qx origin; then git fetch -q origin 2>/dev/null || echo "warning: git fetch origin failed; using local branches" >&2; fi
    DEF=$(jq -r '.ci.default_branch // empty' .claude/project.json 2>/dev/null || true)
    if [ -z "$DEF" ]; then
      for b in main master; do ref_ok "$b" && { DEF="$b"; break; }; done
      [ -n "$DEF" ] || DEF=$(git rev-parse --abbrev-ref HEAD)
    fi
    case "$sub" in
      milestone)
        [ $# -eq 1 ] || die "usage: branch milestone <ms-n>"
        n="${1#ms-}"; case "$n" in ''|*[!0-9]*) die "a milestone looks like ms-<n>" ;; esac
        if ! ref_ok develop; then
          ref_ok "$DEF" || die "default branch $DEF not found (project.json ci.default_branch)"
          new_branch develop "$DEF"; echo "created develop from $DEF (publish it once: git push -u origin develop)"
        fi
        if [ "$n" -gt 1 ]; then
          prev="ms-$((n - 1))"
          if ref_ok "$prev/integration"; then
            merged "$prev/integration" || die "$prev/integration is not merged into develop yet. Merge its PR/MR (after gate mbr:$prev) and retry"
          else
            [ "$(jq -r --arg g "mbr:$prev" '.gates[$g].status // "pending"' "$STATE")" = "approved" ] \
              || die "gate mbr:$prev is not approved and $prev/integration does not exist: finish $prev first"
          fi
        fi
        new_branch "ms-$n/integration" develop
        echo "ms-$n/integration (from develop @ $(git rev-parse --short "$(ref_of develop)"))"
        ;;
      ticket)
        [ $# -ge 1 ] || die "usage: branch ticket <id> [--base <branch>]"
        id="$1"; shift; base=""
        if [ "${1:-}" = "--base" ]; then base="${2:-}"; [ -n "$base" ] || die "--base needs a branch"; fi
        t=$(jq -c --arg i "$id" '.tickets[$i] // empty' "$STATE"); [ -n "$t" ] || die "no ticket $id"
        cur=$(printf '%s' "$t" | jq -r '.branch // empty')
        if [ -n "$cur" ]; then # idempotent: correction rounds reuse the branch
          printf '%s\t%s\n' "$cur" "$(printf '%s' "$t" | jq -r '.base // "-"')"; exit 0
        fi
        ms=$(printf '%s' "$t" | jq -r '.milestone'); [ -n "$base" ] || base="$ms/integration"
        ref_ok "$base" || die "base branch $base not found (start the milestone first: branch milestone $ms)"
        case "$(printf '%s' "$t" | jq -r '.type // "feature"')" in
          chore) prefix="chore" ;; spike) prefix="spike" ;; bug) prefix="bugfix" ;; *) prefix="feature" ;;
        esac
        [ "$base" != "$DEF" ] || prefix="hotfix"
        slug=$(printf '%s' "$t" | jq -r '.title' | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//' | cut -c1-40 | sed -E 's/-+$//')
        name="$prefix/$(printf '%s' "$id" | tr '[:upper:]' '[:lower:]')${slug:+-$slug}"
        new_branch "$name" "$base"
        upd '.tickets[$i].branch = $b | .tickets[$i].base = $s' --arg i "$id" --arg b "$name" --arg s "$base"
        printf '%s\t%s\n' "$name" "$base"
        ;;
      release)
        [ $# -eq 1 ] || die "usage: branch release <vX.Y.Z>"
        printf '%s' "$1" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$' || die "a release version looks like v1.2.0 (semver with a leading v)"
        ref_ok develop || die "develop not found: start the first milestone with branch milestone ms-1"
        for ms in $(jq -r '[.tickets[].milestone] | unique[]' "$STATE"); do
          if ref_ok "$ms/integration"; then merged "$ms/integration" || die "$ms/integration is not merged into develop yet"; fi
        done
        new_branch "release/$1" develop
        upd '.release = ((.release // {}) + {branch: $b})' --arg b "release/$1"
        echo "release/$1 (from develop @ $(git rev-parse --short "$(ref_of develop)"))"
        ;;
      cleanup)
        [ $# -eq 1 ] || die "usage: branch cleanup <ms-n>"
        ref_ok "$1/integration" && { merged "$1/integration" || die "$1/integration is not merged into develop yet: nothing removed"; }
        for b in $(jq -r --arg m "$1" '.tickets[] | select(.milestone == $m and (.status | IN("done", "verified", "cancelled")) and .branch) | .branch' "$STATE"); do
          wt=$(git worktree list --porcelain | awk -v b="refs/heads/$b" '/^worktree /{p=substr($0, 10)} $0 == "branch " b {print p}')
          if [ -n "$wt" ]; then git worktree remove "$wt" 2>/dev/null || { echo "kept $b: its worktree $wt has uncommitted changes"; continue; }; fi
          git rev-parse -q --verify "refs/heads/$b" >/dev/null 2>&1 && git branch -q -D "$b" && echo "removed $b"
        done
        git worktree prune
        ;;
      *) die "usage: branch milestone|ticket|release|cleanup ..." ;;
    esac
    ;;
  ready)
    need_state; [ $# -eq 1 ] || die "usage: ready <ms-n>"
    jq -r --arg m "$1" '.tickets as $t | $t | to_entries[]
      | select(.value.milestone == $m and .value.status == "ready")
      | select(all(.value.depends_on[]?; (($t[.].status // "") | IN("done", "verified"))))
      | "\(.key)\t\(.value.role)\t\(.value.title)"' "$STATE"
    ;;
  plan-check)
    need_state; [ $# -eq 1 ] || die "usage: plan-check <ms-n>"
    res=$(jq -r --arg m "$1" '
      def root: split("*")[0] | sub("/$"; "");
      def overlap($a; $b): ($a | root) as $x | ($b | root) as $y
        | ($x == $y) or ($x == "") or ($y == "") or ($x | startswith($y + "/")) or ($y | startswith($x + "/"));
      .tickets as $t
      | [$t | to_entries[] | select(.value.milestone == $m and .value.status != "cancelled")] as $ms
      | ($ms | map(select((.value.type // "feature") != "chore"))) as $feat
      | ( $feat[] | . as $a | ($a.value.depends_on // [])[] as $d
          | select(($t[$d].milestone // "") == $m and (($t[$d].type // "feature") != "chore"))
          | "FAIL\t\($a.key) depends on \($d) in the same milestone: feature tickets must be independent (depend only on foundation tickets or an earlier milestone)" ),
        ( range(0; $ms | length) as $i | range($i + 1; $ms | length) as $j | $ms[$i] as $a | $ms[$j] as $b
          | select((($a.value.depends_on // []) | index($b.key)) == null and (($b.value.depends_on // []) | index($a.key)) == null)
          | [ ($a.value.paths // [])[] as $pa | ($b.value.paths // [])[] as $pb | select(overlap($pa; $pb)) | "\($pa) and \($pb)" ] as $o
          | select(($o | length) > 0)
          | "FAIL\t\($a.key) and \($b.key) can run at the same time but touch the same files (\($o[0])): split the files, or put the shared file in a foundation ticket" ),
        ( $ms[] | select(((.value.paths // []) | length) == 0) | "WARN\t\(.key) has no paths, so overlaps cannot be checked (ticket add --paths)" ),
        ( ($feat | map(select(all((.value.depends_on // [])[]; ($t[.].milestone != $m) or (($t[.].type // "feature") == "chore")))) | length) as $par
          | "plan: \($ms | length) tickets in \($m), \($feat | length) feature tickets, \($par) can start together once the foundation is done" )' "$STATE")
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q '^FAIL' && exit 1
    exit 0
    ;;
  board)
    need_state
    jq -r '(.agents // {}) as $ag
      | [.tickets | to_entries[] | select(.value.status | IN("in_progress", "in_review", "changes_requested", "reopened", "blocked", "approved"))] as $a
      | if ($a | length) == 0 then "board: nothing in progress"
        else ("TICKET\tROLE\tSTATUS\tATTEMPTS\tSINCE (UTC)\tAGENT\tTITLE",
              ($a[] | "\(.key)\t\(.value.role)\t\(.value.status)\t\(.value.attempts // 0)\t\((.value.history // [])[-1].ts // "-")\t\($ag["ticket:" + .key] // "-")\t\(.value.title)")) end' "$STATE"
    ;;
  stats)
    need_state
    jq -r --arg m "${1:-}" --argjson U "$(usage_json)" '
      def returns: [(.value.history // [])[] | select(.to == "changes_requested" or .to == "reopened")] | length;
      [.tickets | to_entries[] | select($m == "" or .value.milestone == $m)] as $ts
      | "Tickets: \($ts | length)   done: \([$ts[] | select(.value.status | IN("done", "verified"))] | length)   bugs: \([$ts[] | select((.value.type // "") == "bug")] | length)",
        ( $ts | group_by(.value.role)[] | . as $g
          | "\($g[0].value.role): \($g | length) tickets, \([$g[].value.attempts // 0] | add) attempts, \([$g[] | returns] | add) sent back by review or reopened, \([$g[] | select(((.value.bugs // []) | length) > 0)] | length) with bugs found later" ),
        ( [$ts[] | {k: .key, n: returns, a: (.value.attempts // 0)} | select((.n + .a) > 1)] | sort_by(-(.n + .a)) | .[0:5]
          | if length > 0 then "Most rework: " + (map("\(.k) (\(.a) attempts, \(.n) returns)") | join(", ")) else "Most rework: none" end ),
        ( (($U.entries // []) | map(. + {t: (.input + .cache_write + .cache_read + .output)})) as $u | if ($u | length) > 0
          then "Tokens by agent (whole run): " + ([$u | group_by(.agent)[] | {a: .[0].agent, t: ([.[].t] | add), n: ([.[].source] | unique | length)}] | sort_by(-.t) | .[0:8] | map("\(.a) \(.t) in \(.n) runs") | join(" · "))
          else empty end )' "$STATE"
    ;;
  bugs)
    need_state; scope="${1:-open}"; ms="${2:-}"
    in_list "$scope" "open all" || die "usage: bugs [open|all] [ms-n]"
    jq -r --arg sc "$scope" --arg m "$ms" '.tickets | to_entries[] | select(.value.type == "bug")
      | select($m == "" or .value.milestone == $m)
      | select($sc == "all" or ((.value.status | IN("done", "verified", "cancelled")) | not))
      | "\(.key)\t\(.value.severity)\t\(.value.status)\tof:\(.value.bug_of // "none")\t\(.value.title)"' "$STATE"
    ;;
  fail)
    need_state; [ $# -eq 4 ] || die "usage: fail <ticket> <role> <attempts> <report>"
    upd '.failures += [{ticket: $t, role: $r, attempts: ($a | tonumber), report: $p, ts: $now}]
         | if .tickets[$t] then
             .tickets[$t].history = ((.tickets[$t].history // []) + [{from: .tickets[$t].status, to: "blocked", ts: $now, note: "failure report \($p)"}])
             | .tickets[$t].status = "blocked"
           else . end' \
      --arg t "$1" --arg r "$2" --arg a "$3" --arg p "$4"
    ;;
  msg)
    need_state; sub="${1:-}"; shift || true
    case "$sub" in
      add)
        [ $# -ge 5 ] || die "usage: msg add <from> <to> <type> <re> <body> [blocking]"
        in_list "$3" $MSG_TYPES || die "type must be one of: $MSG_TYPES"
        id="M-$(( $(jq '(.messages // []) | length' "$STATE") + 1 ))"
        bl=false; case "${6:-}" in blocking|yes|true) bl=true ;; esac
        upd '.messages = ((.messages // []) + [{id: $id, from: $f, to: $t, type: $ty, re: $re, body: $b,
              blocking: ($bl == "true"), status: "open", answer: null, ts: $now}])' \
          --arg id "$id" --arg f "$1" --arg t "$2" --arg ty "$3" --arg re "$4" --arg b "$5" --arg bl "$bl"
        log_msg "$id" "$1" "$2" "$3" "$4" "$5"
        echo "$id"
        ;;
      answer)
        [ $# -eq 3 ] || die "usage: msg answer <M-id> <from> <body>"
        [ "$(jq -r --arg i "$1" '(.messages // [])[] | select(.id == $i) | .id' "$STATE")" = "$1" ] || die "no message $1"
        upd '(.messages[] | select(.id == $i)) |= (.status = "answered" | .answer = {from: $f, body: $b, ts: $now})' \
          --arg i "$1" --arg f "$2" --arg b "$3"
        log_msg "$1" "$2" "(reply)" "answer" "$1" "$3"
        ;;
      close)
        [ $# -eq 1 ] || die "usage: msg close <M-id>"
        upd '(.messages[] | select(.id == $i) | .status) = "closed"' --arg i "$1"
        ;;
      open)
        jq -r --arg t "${1:-}" '(.messages // [])[] | select(.status == "open") | select($t == "" or .to == $t)
          | "\(.id)\t\(.from) -> \(.to)\t\(.type)\(if .blocking then " BLOCKING" else "" end)\t\(.re)\t\(.body)"' "$STATE"
        ;;
      *) die "usage: msg add|answer|close|open ..." ;;
    esac
    ;;
  agent)
    need_state; sub="${1:-}"; shift || true
    case "$sub" in
      set) [ $# -eq 2 ] || die "usage: agent set <key> <agent-id>"; upd '.agents = ((.agents // {}) + {($k): $v})' --arg k "$1" --arg v "$2" ;;
      get) [ $# -eq 1 ] || die "usage: agent get <key>"; jq -r --arg k "$1" '(.agents // {})[$k] // empty' "$STATE" ;;
      *) die "usage: agent set|get ..." ;;
    esac
    ;;
  help|-h|--help) usage ;;
  *) usage; exit 1 ;;
esac
