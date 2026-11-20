#!/usr/bin/env bash
# PreToolUse (Agent|Task|SendMessage): no new or continued agent work once the token budget is reached.
# The budget is the one the human approved (`delivery-state.sh usage budget`), else DELIVERY_TOKEN_BUDGET (0 = none).
# It first brings the usage ledger up to date from this session's transcript, so the check counts the orchestrator
# and every finished agent with the provider-reported numbers. Applies only while a delivery run exists.
DL_INPUT="$(cat)"
. "$(dirname "$0")/lib.sh"
dl_has_jq || exit 0
[ -f "$DL_STATE" ] || exit 0
budget_set() {
  local u="$DL_ROOT/.claude/delivery/usage.json" v=""
  [ -f "$u" ] && v=$(jq -r '.budget.tokens // empty' "$u" 2>/dev/null)
  [ -n "$v" ] || v="${DELIVERY_TOKEN_BUDGET:-0}"
  case "$v" in ''|*[!0-9]*|0) return 1 ;; esac
  return 0
}
budget_set || exit 0
t=$(dl_json '.transcript_path // empty')
if [ -n "$t" ] && [ -f "$t" ]; then out=$(bash "$DL_STATE_SH" usage sync "$t" 2>/dev/null); rc=$?
else out=$(bash "$DL_STATE_SH" usage check 2>/dev/null); rc=$?; fi
[ "$rc" -eq 4 ] || exit 0
dl_block "Blocked: the token budget is reached ($(printf '%s' "$out" | grep '^total tokens' | head -n 1))." \
  "This is a major decision (decision-policy): stop and ask the human with AskUserQuestion. Options: raise the budget (once they approve, run: delivery-state.sh usage budget <tokens> --approved-by \"<name>\"), switch to DELIVERY_PROFILE=lean, or pause the run. Show 'delivery-state.sh usage summary' so they see where the tokens went."
