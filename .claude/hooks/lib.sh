#!/usr/bin/env bash
# Shared helpers for the delivery hooks and scripts. Source it; don't execute it. Compatible with bash 3.2+ and requires jq.
# Hooks set DL_INPUT (the hook's JSON from stdin) before sourcing.

dl_resolve_root() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ]; then (cd "$CLAUDE_PROJECT_DIR" && pwd -P); return; fi
  local common; common=$(git rev-parse --git-common-dir 2>/dev/null || true)
  if [ -n "$common" ]; then (cd "$common/.." && pwd -P); else pwd -P; fi
}

DL_ROOT="$(dl_resolve_root)"
DL_STATE="$DL_ROOT/.claude/delivery/state.json"
DL_MANIFEST="$DL_ROOT/.claude/project.json"
DL_STATE_SH="$DL_ROOT/.claude/skills/deliver/scripts/delivery-state.sh"

dl_has_jq() { command -v jq >/dev/null 2>&1; }

# dl_block <message...>: print to stderr and exit 2 (Claude Code shows stderr to the model and blocks the tool call)
dl_block() { printf '%s\n' "$@" >&2; exit 2; }

dl_json()     { printf '%s' "${DL_INPUT:-}" | jq -r "$1" 2>/dev/null; }
dl_manifest() { [ -f "$DL_MANIFEST" ] && jq -r "$@" "$DL_MANIFEST" 2>/dev/null; }
dl_state()    { [ -f "$DL_STATE" ] && jq -r "$@" "$DL_STATE" 2>/dev/null; }

dl_gate_status() { local s; s=$(dl_state --arg g "$1" '.gates[$g].status // "pending"'); printf '%s' "${s:-pending}"; }
dl_g3_valid()    { [ -f "$DL_STATE" ] && bash "$DL_STATE_SH" verify g3 >/dev/null 2>&1; }

# Glob → anchored ERE. Supports *, ** and ?. A trailing "/" or a bare directory name matches everything under it.
dl_glob_re() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/[.+()|^$]/\\&/g' -e 's/[][{}]/\\&/g' \
    -e 's#\*\*/#@DS@#g' -e 's#\*\*#@DD@#g' -e 's#\*#[^/]*#g' -e 's#?#[^/]#g' \
    -e 's#@DS@#(.*/)?#g' -e 's#@DD@#.*#g'
}

dl_match() { # dl_match <path> <glob>
  local p="$1" g="$2" re
  [ -z "$g" ] && return 1
  case "$g" in */) g="${g}**" ;; esac
  re="^$(dl_glob_re "$g")\$"
  [[ "$p" =~ $re ]] && return 0
  case "$p" in "$g"/*) return 0 ;; esac
  return 1
}

dl_match_any() { # dl_match_any <path>  (globs on stdin, one per line)
  local p="$1" g
  while IFS= read -r g; do dl_match "$p" "$g" && return 0; done
  return 1
}

# dl_rel <path>: the path relative to the git toplevel that contains it (worktree-aware), or to DL_ROOT
dl_rel() {
  local f="$1" a phys top
  case "$f" in /*) ;; *) f="$PWD/$f" ;; esac
  a=$(dirname "$f"); while [ ! -d "$a" ]; do a=$(dirname "$a"); done
  phys="$(cd "$a" && pwd -P)${f#"$a"}"
  top=$(git -C "$a" rev-parse --show-toplevel 2>/dev/null || true)
  [ -n "$top" ] || top="$DL_ROOT"
  top=$(cd "$top" && pwd -P)
  case "$phys" in "$top"/*) printf '%s' "${phys#"$top"/}" ;; *) printf '%s' "$phys" ;; esac
}

dl_role_for_agent() { # map a subagent type to its role key in project.json
  [ -n "${1:-}" ] || return 0
  dl_manifest --arg a "$1" '.roles // {} | to_entries[] | select(.value.agent == $a) | .key' | head -n 1
}

dl_open_cr_covers() { # dl_open_cr_covers <relpath> [gate]
  [ -f "$DL_STATE" ] || return 1
  dl_state --arg g "${2:-}" '.change_requests[]? | select(.status == "open") | select($g == "" or .gate == $g) | .paths[]?' | dl_match_any "$1"
}

# Split a shell command into simple-command segments (on ; && || | and newlines)
dl_segments() { printf '%s\n' "$1" | awk '{ gsub(/&&|\|\||;|\|/, "\n"); print }'; }

# Strip leading env assignments and wrappers (sudo, env, npx -y, pnpm dlx, …) from one segment
dl_norm() {
  local s="$1" prev=""
  s=$(printf '%s' "$s" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  while [ "$s" != "$prev" ]; do
    prev="$s"
    s=$(printf '%s' "$s" | sed -E \
      -e "s/^[A-Za-z_][A-Za-z0-9_]*=(\"[^\"]*\"|'[^']*'|[^[:space:]]*)[[:space:]]+//" \
      -e 's/^\(+[[:space:]]*//' \
      -e 's/^(sudo|command|exec|time|nohup|env)[[:space:]]+//' \
      -e 's/^(npx|bunx)([[:space:]]+(-y|--yes))?[[:space:]]+//' \
      -e 's/^(pnpm|yarn)[[:space:]]+(dlx|exec)[[:space:]]+//')
  done
  printf '%s' "$s"
}

# cd into the tool call's cwd when the hook input provides one
dl_enter_cwd() { local d; d=$(dl_json '.cwd // empty'); [ -n "$d" ] && [ -d "$d" ] && cd "$d"; return 0; }
