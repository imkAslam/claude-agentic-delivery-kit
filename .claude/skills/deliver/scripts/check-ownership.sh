#!/usr/bin/env bash
# check-ownership.sh <branch> <role> [base]
# Run by the integrator before merging a role branch: every file changed on <branch> since <base> (default: HEAD)
# must be inside the role's owned paths, shared files it owns, or docs/delivery/** and docs/adr/**. After G2,
# contract paths are off-limits to every role (only "solution-architect" may change them under a change request).
# Exit 0 = clean, 1 = violations (listed), 2 = usage/setup error.
set -uo pipefail
[ $# -ge 2 ] || { echo "usage: check-ownership.sh <branch> <role> [base]" >&2; exit 2; }
branch="$1" role="$2" base="${3:-HEAD}"

ROOT=$(cd "$(dirname "$0")/../../../.." && pwd -P)
[ -n "${CLAUDE_PROJECT_DIR:-}" ] || export CLAUDE_PROJECT_DIR="$ROOT"
DL_INPUT=""
. "$CLAUDE_PROJECT_DIR/.claude/hooks/lib.sh"
command -v jq >/dev/null 2>&1 || { echo "check-ownership: jq is required" >&2; exit 2; }
[ -f "$DL_MANIFEST" ] || { echo "check-ownership: missing .claude/project.json" >&2; exit 2; }

files=$(git diff --name-only "${base}...${branch}" 2>/dev/null) || { echo "check-ownership: cannot diff ${base}...${branch}" >&2; exit 2; }
[ -n "$files" ] || { echo "no changes on ${branch}"; exit 0; }

if [ "$role" = "solution-architect" ] || [ "$role" = "api-designer" ]; then
  allowed=$(dl_manifest '.contracts.paths[]?'; printf '%s\n' 'docs/delivery/**' 'docs/adr/**' '.claude/project.json' '.claude/PROJECT.md')
else
  [ "$(dl_manifest --arg r "$role" '.roles[$r] // empty')" != "" ] || { echo "check-ownership: unknown role '$role'" >&2; exit 2; }
  allowed=$(dl_manifest --arg r "$role" '.roles[$r].paths[]?'
            dl_manifest --arg r "$role" '.shared_files // {} | to_entries[] | select(.value == $r) | .key'
            printf '%s\n' 'docs/delivery/**' 'docs/adr/**')
fi
contracts=$(dl_manifest '.contracts.paths[]?')
g2=$(dl_gate_status g2)

violations=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ "$role" != "solution-architect" ] && [ "$role" != "api-designer" ] && { [ "$g2" = "approved" ] || [ "$g2" = "invalidated" ]; } && printf '%s\n' "$contracts" | dl_match_any "$f"; then
    violations="${violations}  contract (frozen since G2): ${f}
"; continue
  fi
  case "$f" in .claude/*|CLAUDE.md)
    if [ "$role" != "solution-architect" ]; then violations="${violations}  delivery kit: ${f}
"; continue; fi ;;
  esac
  printf '%s\n' "$allowed" | dl_match_any "$f" || violations="${violations}  outside ${role} paths: ${f}
"
done <<EOF
$files
EOF

if [ -n "$violations" ]; then
  printf 'Ownership violations on %s (role %s):\n%s' "$branch" "$role" "$violations"
  exit 1
fi
echo "ownership OK: ${branch} (${role}), $(printf '%s\n' "$files" | grep -c .) files"
exit 0
