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
LANES="understand plan build verify release done"
TICKET_STATUSES="ready in_progress in_review approved done blocked"

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

log_gate() {
  mkdir -p "$(dirname "$LOG")"
  [ -f "$LOG" ] || printf '# Gate log\n\n| When (UTC) | Gate | Status | Decision | Approver | Notes |\n|---|---|---|---|---|---|\n' > "$LOG"
  printf '| %s | %s | %s | %s | %s | %s |\n' "$(now)" "$1" "$2" "$3" "$4" "$(printf '%s' "$5" | tr '\n|' '  ')" >> "$LOG"
}

usage() {
  cat <<'EOF'
delivery-state.sh <command> [args]
  init                                         create .claude/delivery/state.json (no-op if present)
  summary                                      print lane, step, gates, tickets, CRs, failures
  set-step <lane> <step>                       lanes: understand plan build verify release done
  milestone <ms-n>                             set the current milestone
  validated                                    record that every project.json command ran green
  round <loop-id> | round-reset <loop-id>      review-round counter (exit 3 + CAP_REACHED at the cap)
  note "<text>"                                record a note (e.g. a skipped step and why)
  approve <gate> <decision> "<approver>" "<notes>" <path>...   human approval tied to file hashes
  reject  <gate> <decision> "<approver>" "<notes>"             human rejection / revise decision
  verify  <gate>                               exit 0 only if approved and every package hash matches
  release "<name>" "<artifact>" "<environment>" record the release identity (required before approving g3)
  cr-open <gate> "<reason>" --approved-by "<human>" <path>...
                                               open a change request (invalidates the gate); prints the id.
                                               Needs the human's explicit yes first (a major decision)
  cr-close <CR-id>
  ticket add <id> <role> <milestone> "<title>" [dep1,dep2]
  ticket status <id> <ready|in_progress|in_review|approved|done|blocked>
  ticket attempt <id>                          increment attempts (exit 3 + CAP_REACHED at the cap)
  ticket set <id> <branch|tracker_ref|title> <value>
  ready <ms-n>                                 list ready tickets whose dependencies are done
  fail <ticket> <role> <attempts> <report-path>
  msg add <from> <to> <question|request|handoff|finding|info|decision-needed> "<re>" "<body>" [blocking]
  msg answer <M-id> <from> "<body>" | msg close <M-id> | msg open [to]
  agent set <key> <agent-id> | agent get <key>    remember subagent ids so they can be continued (SendMessage)
  usage add <agent> <model> <tokens> [step]    record one subagent run (tokens from the Agent result); prints the
                                               total; exit 4 + BUDGET_REACHED when DELIVERY_TOKEN_BUDGET (>0) is hit
  usage summary                                tokens and runs by model and by agent
EOF
}

MSG_LOG="docs/delivery/MESSAGES.md"
MSG_TYPES="question request handoff finding info decision-needed"
log_msg() {
  mkdir -p "$(dirname "$MSG_LOG")"
  [ -f "$MSG_LOG" ] || printf '# Agent messages\n\n| When (UTC) | Id | From | To | Type | Re | Message |\n|---|---|---|---|---|---|---|\n' > "$MSG_LOG"
  printf '| %s | %s | %s | %s | %s | %s | %s |\n' "$(now)" "$1" "$2" "$3" "$4" "$5" "$(printf '%s' "$6" | tr '\n|' '  ')" >> "$MSG_LOG"
}

cmd="${1:-help}"; shift || true
case "$cmd" in
  init)
    mkdir -p "$(dirname "$STATE")"
    if [ ! -f "$STATE" ]; then
      [ -f "$EXAMPLE" ] || die "missing $EXAMPLE"
      cp "$EXAMPLE" "$STATE"; upd '.'
      echo "created $STATE"
    else
      echo "state exists: $STATE"
    fi
    if [ -d .git ] || git rev-parse --git-dir >/dev/null 2>&1; then
      grep -qxF '.claude/delivery/' .gitignore 2>/dev/null || printf '\n# delivery run state (local cursor; audit trail is docs/delivery/GATE-LOG.md)\n.claude/delivery/\n' >> .gitignore
    fi
    ;;
  summary)
    need_state
    jq -r --arg max "$MAX" '
      "Lane: \(.lane)   Step: \(.step)   Milestone: \(.milestone // "-")",
      "Gates: " + ([.gates | to_entries[] | "\(.key)=\(.value.status)" + (if .value.decision then "(\(.value.decision))" else "" end)] | join("  ")),
      "Tickets: " + (if (.tickets | length) == 0 then "none" else ([.tickets | to_entries | group_by(.value.status)[] | "\(.[0].value.status)=\(length)"] | join("  ")) end),
      (([.tickets | to_entries[] | select(.value.status == "in_progress" or .value.status == "in_review" or .value.status == "blocked") | "\(.key)[\(.value.role)]:\(.value.status)"]) as $a | if ($a | length) > 0 then "Active/blocked: " + ($a | join(", ")) else empty end),
      (([.change_requests[] | select(.status == "open") | "\(.id)(\(.gate))"]) as $c | if ($c | length) > 0 then "Open CRs: " + ($c | join(", ")) else empty end),
      (if (.failures | length) > 0 then "Last failure: \(.failures[-1].ticket) [\(.failures[-1].role)] -> \(.failures[-1].report)" else empty end),
      (([(.messages // [])[] | select(.status == "open")]) as $m | if ($m | length) > 0 then "Open messages: \($m | length)" + (if ([$m[] | select(.blocking)] | length) > 0 then " (\([$m[] | select(.blocking)] | length) blocking)" else "" end) else empty end),
      (if (.rounds | length) > 0 then "Rounds: " + ([.rounds | to_entries[] | "\(.key)=\(.value)/\($max)"] | join("  ")) else empty end),
      (if ((.usage // []) | length) > 0 then "Usage: \(.usage | length) agent runs, \([.usage[].tokens] | add) tokens" else empty end),
      "Validated: \(.validated_at // "no")   Updated: \(.updated_at // "-")"' "$STATE"
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
    upd '.release = {name: $n, artifact: $a, environment: $e}' --arg n "$1" --arg a "$2" --arg e "$3"
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
      add)
        [ $# -ge 3 ] || die "usage: usage add <agent> <model> <tokens> [step]"
        case "$3" in ''|*[!0-9]*) die "tokens must be a whole number" ;; esac
        upd '.usage = ((.usage // []) + [{agent: $a, model: $m, tokens: ($t | tonumber), step: ((.lane // "") + "/" + (if $s == "" then (.step // "") else $s end)), ts: $now}])' \
          --arg a "$1" --arg m "$2" --arg t "$3" --arg s "${4:-}"
        total=$(jq '[.usage[].tokens] | add // 0' "$STATE")
        budget="${DELIVERY_TOKEN_BUDGET:-0}"
        case "$budget" in ''|*[!0-9]*) budget=0 ;; esac
        if [ "$budget" -gt 0 ]; then echo "total tokens: ${total} / budget ${budget}"; else echo "total tokens: ${total}"; fi
        if [ "$budget" -gt 0 ]; then
          if [ "$total" -ge "$budget" ]; then echo "BUDGET_REACHED: ask the human before starting more agent runs (decision-policy: major decisions)"; exit 4; fi
          if [ "$total" -ge $(( budget * 8 / 10 )) ]; then echo "BUDGET_WARNING: 80% of the token budget used"; fi
        fi
        ;;
      summary)
        jq -r '(.usage // []) as $u
          | "Runs: \($u | length)   Tokens: \([$u[].tokens] | add // 0)",
            "By model: " + ([$u | group_by(.model)[] | "\(.[0].model)=\([.[].tokens] | add) (\(length) runs)"] | join("  ")),
            "By agent (top 8): " + ([$u | group_by(.agent)[] | {a: .[0].agent, t: ([.[].tokens] | add), n: length}] | sort_by(-.t) | .[0:8] | map("\(.a)=\(.t)/\(.n)") | join("  ")),
            "By lane: " + ([$u | group_by(.step | split("/")[0])[] | "\(.[0].step | split("/")[0])=\([.[].tokens] | add)"] | join("  "))' "$STATE"
        ;;
      *) die "usage: usage add|summary" ;;
    esac
    ;;
  ticket)
    need_state; sub="${1:-}"; shift || true
    case "$sub" in
      add)
        [ $# -ge 4 ] || die "usage: ticket add <id> <role> <milestone> <title> [deps]"
        [ "$(jq -r --arg i "$1" '.tickets[$i] // empty' "$STATE")" = "" ] || die "ticket $1 exists"
        upd '.tickets[$i] = {title: $t, role: $r, milestone: $m, status: "ready", attempts: 0,
              depends_on: ($d | split(",") | map(select(length > 0))), branch: null, tracker_ref: null}' \
          --arg i "$1" --arg r "$2" --arg m "$3" --arg t "$4" --arg d "${5:-}"
        ;;
      status)
        [ $# -eq 2 ] || die "usage: ticket status <id> <status>"
        in_list "$2" $TICKET_STATUSES || die "unknown status: $2"
        [ "$(jq -r --arg i "$1" '.tickets[$i] // empty' "$STATE")" != "" ] || die "no ticket $1"
        upd '.tickets[$i].status = $s' --arg i "$1" --arg s "$2"
        ;;
      attempt)
        [ $# -eq 1 ] || die "usage: ticket attempt <id>"
        upd '.tickets[$i].attempts = ((.tickets[$i].attempts // 0) + 1)' --arg i "$1"
        n=$(jq -r --arg i "$1" '.tickets[$i].attempts' "$STATE"); echo "$n"
        if [ "$n" -ge "$MAX" ]; then echo "CAP_REACHED"; exit 3; fi
        ;;
      set)
        [ $# -eq 3 ] || die "usage: ticket set <id> <field> <value>"
        in_list "$2" "branch tracker_ref title" || die "field must be branch, tracker_ref or title"
        upd '.tickets[$i][$f] = $v' --arg i "$1" --arg f "$2" --arg v "$3"
        ;;
      *) die "usage: ticket add|status|attempt|set ..." ;;
    esac
    ;;
  ready)
    need_state; [ $# -eq 1 ] || die "usage: ready <ms-n>"
    jq -r --arg m "$1" '.tickets as $t | $t | to_entries[]
      | select(.value.milestone == $m and .value.status == "ready")
      | select(all(.value.depends_on[]?; ($t[.].status // "") == "done"))
      | "\(.key)\t\(.value.role)\t\(.value.title)"' "$STATE"
    ;;
  fail)
    need_state; [ $# -eq 4 ] || die "usage: fail <ticket> <role> <attempts> <report>"
    upd '.failures += [{ticket: $t, role: $r, attempts: ($a | tonumber), report: $p, ts: $now}]
         | if .tickets[$t] then .tickets[$t].status = "blocked" else . end' \
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
