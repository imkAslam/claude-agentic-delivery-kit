#!/usr/bin/env bash
# PreToolUse (Write|Edit|MultiEdit|NotebookEdit): protects approved gate packages and the run state file.
#  - .claude/delivery/state.json is never edited with file tools (use delivery-state.sh)
#  - a file in an approved gate package is editable only while an open change request lists it
DL_INPUT="$(cat)"
. "$(dirname "$0")/lib.sh"
dl_has_jq || exit 0
dl_enter_cwd

file=$(dl_json '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -n "$file" ] || exit 0
rel=$(dl_rel "$file")

case "$rel" in
  .claude/delivery/state.json|*/.claude/delivery/state.json)
    dl_block "Blocked: the run state changes only through: bash .claude/skills/deliver/scripts/delivery-state.sh <command>" ;;
esac

[ -f "$DL_STATE" ] || exit 0
gates=$(dl_state --arg p "$rel" '[.gates | to_entries[] | select(.value.status == "approved") | select(.value.package | has($p)) | .key] | join(", ")')
[ -n "$gates" ] || exit 0
dl_open_cr_covers "$rel" && exit 0

dl_block "Blocked: ${rel} is part of the approved gate package(s): ${gates}." \
  "The latest agreed decision stands until a change request is opened:" \
  "  bash .claude/skills/deliver/scripts/delivery-state.sh cr-open <gate> \"<reason>\" --approved-by \"<human>\" ${rel}" \
  "(a change request is a major decision: the human approves it first)." \
  "Opening a change request invalidates the gate, which must then be presented to the human again (gate-review skill)."
