#!/usr/bin/env bash
# SessionStart (startup|resume|compact): puts the delivery run state into context so the orchestrator can resume.
DL_INPUT="$(cat)"
. "$(dirname "$0")/lib.sh"

if ! dl_has_jq; then
  echo "Delivery kit: jq is not installed, so the delivery hooks are inactive. Ask the user to install jq."
  exit 0
fi
[ -f "$DL_STATE" ] || exit 0

echo "## Delivery run state (.claude/delivery/state.json)"
bash "$DL_STATE_SH" summary 2>/dev/null || echo "(state unreadable; run: bash .claude/skills/deliver/scripts/delivery-state.sh summary)"
case "$(dl_gate_status g2)" in
  approved|invalidated) echo "Coding: approved at g2." ;;
  *) echo "Coding: NOT approved. Only documents and contracts may be written until the human approves g2 (guard-coding.sh)." ;;
esac
echo "Profile: ${DELIVERY_PROFILE:-standard} · max parallel agents: ${DELIVERY_MAX_PARALLEL:-3} · token budget: ${DELIVERY_TOKEN_BUDGET:-0} (0 = none). Record every agent run: delivery-state.sh usage add."
L="$CLAUDE_PROJECT_DIR/docs/delivery/LESSONS.md"
[ -f "$L" ] && echo "Lessons: $(grep -c '^- \[' "$L" 2>/dev/null || echo 0) lines in docs/delivery/LESSONS.md (pass the role's lines in briefs; never read the file whole)."
echo "Memory: files, not this conversation (.claude/skills/deliver/references/memory.md). Saved agent ids may be unreachable after a restart: respawn with the brief + last return block."
echo "Resume with /deliver resume. Before acting, re-read the current step in .claude/skills/deliver/references/workflow.md. Never redo approved gates."
exit 0
