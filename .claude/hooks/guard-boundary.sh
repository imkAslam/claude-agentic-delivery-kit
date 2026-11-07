#!/usr/bin/env bash
# PreToolUse (Write|Edit|MultiEdit|NotebookEdit): role ownership and contract freeze.
#  - after G2 is approved, contract paths are read-only (solution-architect may edit them only under an open change request)
#  - a role subagent (mapped through project.json roles.<role>.agent) writes only inside its owned paths,
#    the shared files it owns, and docs/delivery/** or docs/adr/**; never the kit (.claude/, CLAUDE.md)
# The main session and agents without a role aren't path-restricted here (gates and contracts still apply).
DL_INPUT="$(cat)"
. "$(dirname "$0")/lib.sh"
dl_has_jq || exit 0
[ -f "$DL_MANIFEST" ] || exit 0
dl_enter_cwd

file=$(dl_json '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -n "$file" ] || exit 0
rel=$(dl_rel "$file")
agent=$(dl_json '.agent_type // empty')

# Contract freeze
g2=$(dl_gate_status g2)
if [ "$g2" = "approved" ] || [ "$g2" = "invalidated" ]; then
  if dl_manifest '.contracts.paths[]?' | dl_match_any "$rel"; then
    if { [ "$agent" = "solution-architect" ] || [ "$agent" = "api-designer" ]; } && dl_open_cr_covers "$rel"; then :; else
      dl_block "Blocked: ${rel} is a contract, frozen since G2." \
        "Report 'RESULT: CONTRACT_CHANGE_NEEDED' with the exact change. The orchestrator opens a change request and routes it to the api-designer."
    fi
  fi
fi

role=$(dl_role_for_agent "$agent")
[ -n "$role" ] || exit 0

case "$rel" in
  .claude/*|CLAUDE.md) dl_block "Blocked: the ${role} role may not modify the delivery kit (${rel})." ;;
esac

allowed=$(
  dl_manifest --arg r "$role" '.roles[$r].paths[]?'
  dl_manifest --arg r "$role" '.shared_files // {} | to_entries[] | select(.value == $r) | .key'
  printf '%s\n' 'docs/delivery/**' 'docs/adr/**'
)
printf '%s\n' "$allowed" | dl_match_any "$rel" && exit 0

owner=$(dl_manifest '.roles | to_entries[] | "\(.key)\t\(.value.paths[]?)"' | while IFS="	" read -r r g; do dl_match "$rel" "$g" && { echo "$r"; break; }; done)
dl_block "Blocked: ${rel} is outside the ${role} role's owned paths." \
  "Owned: $(printf '%s' "$allowed" | tr '\n' ' ')" \
  "${owner:+That path belongs to the ${owner} role. }Report it in your return block instead, e.g. 'NEEDS: ${owner:-<owner>} — ${rel} — <change> — <reason>' (see the role-boundaries skill)."
