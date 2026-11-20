#!/usr/bin/env bash
# PreToolUse (Bash): agents never start, stop or remove containers.
# The local services run once for everyone, one container per service (setup-docker → LOCAL_SERVICES.md): the
# orchestrator (the main session) starts them with `app.sh services` before parallel work. A subagent that runs
# compose from its worktree recreates the shared containers from its own paths, and a test that starts its own
# database multiplies containers by agents, workers and test files; containers from killed runs keep running.
# Applies to subagents only; the main session (the orchestrator) manages the services. A subagent's hook input
# carries an agent_id; the main session's carries none, or only the project's main agent type (settings.json).
DL_INPUT="$(cat)"
. "$(dirname "$0")/lib.sh"
dl_has_jq || exit 0
agent=$(dl_json '.agent_type // empty')
[ -n "$agent" ] || exit 0
main=$(jq -r '.agent // empty' "$DL_ROOT/.claude/settings.json" 2>/dev/null)
[ -z "$(dl_json '.agent_id // empty')" ] && [ "$agent" = "$main" ] && exit 0
cmd=$(dl_json '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0

starts_containers() { # starts_containers <normalized segment>
  printf '%s' "$1" | grep -Eq '^docker([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+(run|create|start|stop|restart|rm|kill|(container)[[:space:]]+(run|create|start|stop|restart|rm|kill|prune)|system[[:space:]]+prune|volume[[:space:]]+(rm|prune)|network[[:space:]]+(rm|prune))([[:space:]]|$)' && return 0
  printf '%s' "$1" | grep -Eq '^(docker[[:space:]]+compose|docker-compose)([[:space:]]+[^[:space:]]+)*[[:space:]]+(up|down|start|stop|restart|rm|kill|run|create)([[:space:]]|$)' && return 0
  printf '%s' "$1" | grep -Eq '^((pnpm|npm|yarn|bun)([[:space:]]+run)?[[:space:]]+infra:(up|down|restart|clean)|make[[:space:]]+infra-(up|down|restart|clean))([[:space:]]|$)' && return 0
  printf '%s' "$1" | grep -Eq '(^|[[:space:]/])app\.sh[[:space:]]+(services|clean)([[:space:]]|$)' && return 0
  # app.sh start and stop --app run the app against the running services; a plain stop would stop them for everyone
  printf '%s' "$1" | grep -Eq '(^|[[:space:]/])app\.sh[[:space:]]+stop([[:space:]]|$)' && ! printf '%s' "$1" | grep -Eq '[[:space:]]--app([[:space:]]|$)' && return 0
  return 1
}

while IFS= read -r seg; do
  s=$(dl_norm "$seg")
  [ -n "$s" ] || continue
  if starts_containers "$s"; then
    dl_block "Blocked: agents never start, stop or remove containers (${agent}: $(printf '%s' "$s" | cut -c1-80))." \
      "The local services already run for everyone, one container per service, started by the orchestrator (app.sh services). Tests use the test database inside that container (setup-docker → TEST_DATABASE.md). If a service is not reachable, return BLOCKED with the error. To check a compose file or an image, use 'docker compose config' and 'docker build'."
  fi
done <<EOF
$(dl_segments "$cmd")
EOF
exit 0
