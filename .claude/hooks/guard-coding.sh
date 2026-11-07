#!/usr/bin/env bash
# PreToolUse (Write|Edit|MultiEdit|NotebookEdit, Bash, Agent|Task): no coding before the human approves it.
# Until gate g2 ("Implementation scope — approval to start coding") has been approved, the run may only produce
# documents and contracts. Blocked before g2:
#   - writing any file outside: docs/**, .claude/**, CLAUDE.md, README.md, CHANGELOG.md, .gitignore, .gitattributes,
#     .editorconfig, .env.example, project.json contracts.paths and pre_build_paths
#   - project scaffolding commands (npm/pnpm/yarn/bun create|init, npx create-*, rails new, cargo new, …)
#   - git commits that include files outside those paths
#   - starting the build-only agents (frontend-, backend-, mobile-engineer, integrator)
# Applies only while a delivery run exists (the run state file). After g2 is approved (or invalidated by a change
# request the human approved), this hook allows everything; the other guards still apply.
DL_INPUT="$(cat)"
. "$(dirname "$0")/lib.sh"
dl_has_jq || exit 0
dl_enter_cwd
[ -f "$DL_STATE" ] || exit 0
g2=$(dl_gate_status g2)
case "$g2" in approved|invalidated) exit 0 ;; esac

why="Coding starts only after the human approves gate g2 (\"Implementation scope — approval to start coding\"). g2 is ${g2}."
how="Finish the plan (PRD, architecture, design, contracts, tickets), then present g2 with the gate-review skill. Only the human can approve it."

pre_build_ok() { # pre_build_ok <relpath>
  case "$1" in
    docs/*|.claude/*|CLAUDE.md|README.md|CHANGELOG.md|.gitignore|.gitattributes|.editorconfig|.env.example) return 0 ;;
  esac
  dl_manifest '.contracts.paths[]?, .pre_build_paths[]?' | dl_match_any "$1"
}

tool=$(dl_json '.tool_name // empty')
case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit)
    file=$(dl_json '.tool_input.file_path // .tool_input.notebook_path // empty')
    [ -n "$file" ] || exit 0
    rel=$(dl_rel "$file")
    pre_build_ok "$rel" || dl_block "Blocked: ${rel} is product code or configuration. ${why}" "$how"
    ;;
  Agent|Task)
    st=$(dl_json '.tool_input.subagent_type // empty')
    case "$st" in
      frontend-engineer|backend-engineer|mobile-engineer|integrator)
        dl_block "Blocked: ${st} builds product code. ${why}" "$how" ;;
    esac
    ;;
  Bash)
    cmd=$(dl_json '.tool_input.command // empty')
    [ -n "$cmd" ] || exit 0
    if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])((npm|pnpm|yarn|bun)[[:space:]]+(create|init)([[:space:]]|$)|npx[[:space:]]+(-y[[:space:]]+)?create-|(rails|nest|ng|mix|poetry)[[:space:]]+new([[:space:]]|$)|cargo[[:space:]]+(new|init)|django-admin[[:space:]]+startproject|flutter[[:space:]]+create|dotnet[[:space:]]+new|expo[[:space:]]+init|go[[:space:]]+mod[[:space:]]+init|composer[[:space:]]+create-project|uv[[:space:]]+init)'; then
      dl_block "Blocked: project scaffolding. ${why}" "$how"
    fi
    if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+([^;&|]*[[:space:]])?commit([[:space:]]|$)'; then
      files=$(git diff --cached --name-only 2>/dev/null)
      if printf '%s' "$cmd" | grep -Eq 'commit[^;&|]*[[:space:]]-[a-zA-Z]*a'; then files="${files}
$(git diff --name-only 2>/dev/null)"; fi
      bad=""
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        pre_build_ok "$f" || bad="${bad} ${f}"
      done <<EOF2
$files
EOF2
      [ -z "$bad" ] || dl_block "Blocked: the commit includes product files:${bad}. ${why}" "$how"
    fi
    ;;
esac
exit 0
