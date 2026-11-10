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
  ticket add <id> <role> <milestone> "<title>" [dep1,dep2] [--type feature|chore|spike|bug] [--size S|M|L]
             [--status ready|backlog] [--of <original-id>|none] [--severity P1|P2|P3] [--found-in "<where>"]
                                               a bug needs --of and --severity; it is linked both ways
  ticket status <id> <status> [--note "<text>"] [--force "<reason>"]
                                               validated transition, recorded in the ticket's history
                                               statuses: backlog ready in_progress in_review changes_requested
                                               approved done verified reopened blocked cancelled
  ticket show <id>                             fields, links (bug of / bugs) and the status history
  ticket attempt <id>                          increment attempts (exit 3 + CAP_REACHED at the cap)
  ticket set <id> <branch|tracker_ref|title|size> <value>
  ready <ms-n>                                 list ready tickets whose dependencies are done (or verified)
  bugs [open|all] [ms-n]                       list bug tickets with severity, status and the original ticket
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
    mode="new"
    if [ "${1:-}" = "--mode" ]; then mode="${2:-}"; in_list "$mode" new adopt || die "unknown mode: ${mode} (new | adopt)"; fi
    mkdir -p "$(dirname "$STATE")"
    if [ ! -f "$STATE" ]; then
      [ -f "$EXAMPLE" ] || die "missing $EXAMPLE"
      cp "$EXAMPLE" "$STATE"; upd '.'
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
    jq -r --arg max "$MAX" '
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
        [ $# -ge 4 ] || die "usage: ticket add <id> <role> <milestone> <title> [deps] [--type t] [--size S|M|L] [--status ready|backlog] [--of <id>|none] [--severity P1|P2|P3] [--found-in <where>]"
        id="$1" role="$2" ms="$3" title="$4"; shift 4
        deps="" type="feature" size="" of="" sev="" found="" st="ready"
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
              depends_on: ($d | split(",") | map(select(length > 0))), branch: null, tracker_ref: null,
              bug_of: (if $of == "" or $of == "none" then null else $of end),
              severity: (if $sev == "" then null else $sev end),
              found_in: (if $f == "" then null else $f end), bugs: [],
              history: [{from: null, to: $st, ts: $now, note: "created"}]}
            | if $of != "" and $of != "none" then .tickets[$of].bugs = ((.tickets[$of].bugs // []) + [$i]) else . end' \
          --arg i "$id" --arg r "$role" --arg m "$ms" --arg t "$title" --arg d "$deps" --arg ty "$type" \
          --arg sz "$size" --arg of "$of" --arg sev "$sev" --arg f "$found" --arg st "$st"
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
  ready)
    need_state; [ $# -eq 1 ] || die "usage: ready <ms-n>"
    jq -r --arg m "$1" '.tickets as $t | $t | to_entries[]
      | select(.value.milestone == $m and .value.status == "ready")
      | select(all(.value.depends_on[]?; (($t[.].status // "") | IN("done", "verified"))))
      | "\(.key)\t\(.value.role)\t\(.value.title)"' "$STATE"
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
