#!/usr/bin/env bash
# PreToolUse (Bash): before any `git commit`, run the committing role's lint, typecheck and test commands from
# project.json (repo-wide commands for the main session and agents without a role). Blocks the commit if any fails.
# Commits that touch only docs/, .claude/ or *.md skip the checks.
DL_INPUT="$(cat)"
. "$(dirname "$0")/lib.sh"
dl_has_jq || exit 0
dl_enter_cwd

cmd=$(dl_json '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0

is_commit=0; all=0
while IFS= read -r seg; do
  s=$(dl_norm "$seg")
  case "$s" in cd\ *) d=$(printf '%s' "$s" | sed -E "s/^cd[[:space:]]+//; s/^[\"']//; s/[\"']$//"); [ -d "$d" ] && cd "$d" ;; esac
  if printf '%s' "$s" | grep -Eq '^git([[:space:]]+-[cC][[:space:]]+[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)'; then
    printf '%s' "$s" | grep -Eq -- '--dry-run' && continue
    is_commit=1
    printf '%s' "$s" | grep -Eq -- '[[:space:]](-a|--all|-[a-zA-Z]*a[a-zA-Z]*)([[:space:]]|$)' && all=1
  fi
done < <(dl_segments "$cmd")
[ $is_commit -eq 1 ] || exit 0

top=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
staged=$(git -C "$top" diff --cached --name-only 2>/dev/null)
[ $all -eq 1 ] && staged=$(printf '%s\n%s\n' "$staged" "$(git -C "$top" diff --name-only 2>/dev/null)")
staged=$(printf '%s\n' "$staged" | grep -v '^$')
[ -n "$staged" ] || exit 0

# docs/kit-only commits skip the checks
printf '%s\n' "$staged" | grep -Ev '^(\.claude/|docs/)|\.md$' | grep -q . || exit 0
[ -f "$DL_MANIFEST" ] || exit 0

agent=$(dl_json '.agent_type // empty')
role=$(dl_role_for_agent "$agent")
for k in lint typecheck test; do
  if [ -n "$role" ]; then c=$(dl_manifest --arg r "$role" --arg k "$k" '.roles[$r].commands[$k] // empty')
  else c=$(dl_manifest --arg k "$k" '.commands[$k] // empty'); fi
  [ -n "$c" ] || continue
  out=$(cd "$top" && bash -c "$c" 2>&1); rc=$?
  if [ $rc -ne 0 ]; then
    dl_block "Commit blocked by commit-gate: '${k}' failed (exit ${rc}) for ${role:-repo}: ${c}" \
      "--- last 40 lines ---" "$(printf '%s\n' "$out" | tail -n 40)" \
      "Fix it and commit again. Never use --no-verify or change the commands in project.json to get past the gate."
  fi
done
exit 0
