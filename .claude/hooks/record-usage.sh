#!/usr/bin/env bash
# Stop, SubagentStop, SessionEnd: records the tokens the provider reported for this session into the usage ledger
# (.claude/delivery/usage.json). Claude Code writes the API's `usage` (input, cache writes, cache reads, output) on
# every assistant line of its transcripts; `delivery-state.sh usage sync` counts each API response once, for the
# main session (the orchestrator) and every subagent, and adds only what changed since the last sync.
# Never blocks and never prints: a failure here must not stop the run. Applies only while a delivery run exists.
DL_INPUT="$(cat)"
. "$(dirname "$0")/lib.sh"
dl_has_jq || exit 0
[ -f "$DL_STATE" ] || exit 0
main=$(dl_json '.transcript_path // empty')
agent=$(dl_json '.agent_transcript_path // empty')
atype=$(dl_json '.agent_type // empty')
[ -n "$main" ] && [ -f "$main" ] && bash "$DL_STATE_SH" usage sync "$main" >/dev/null 2>&1
[ -n "$agent" ] && [ -f "$agent" ] && bash "$DL_STATE_SH" usage sync --agent-type "$atype" "$agent" >/dev/null 2>&1
exit 0
