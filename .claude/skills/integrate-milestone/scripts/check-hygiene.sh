#!/usr/bin/env bash
# check-hygiene.sh [--base <ref>] [--no-unused] [--root <dir>]
# Keeps the codebase neat: reports leftovers that should not survive a ticket or a milestone.
#   stray      tracked junk: .DS_Store, logs, temp/backup files, build output, dependency folders, .env files
#   scaffold   framework starter leftovers: default logos, starter page text, boilerplate README
#   debug      console.log / console.debug / debugger / pdb / breakpoint() in source (not in scripts/)
#   todo       TODO / FIXME / HACK / XXX without a ticket id (T-12, ABC-123 or #123) on the same line
#   unused     the project's own unused-code check, only if project.json -> commands.unused is set
#   deadlink   links in README.md and docs/*.md, and paths in docs/CODEMAP.md, that point to nothing
#   commented  (warning) 3+ consecutive lines of commented-out code
#   emptydir   (warning) empty folders in the working tree
# --base <ref>  check only files changed since <ref> (a ticket diff); default: every tracked file.
# Exceptions: project.json -> hygiene.allow: [{ "path": "<glob>", "reason": "<why>" }] (a reason is required),
#             or the marker "hygiene:allow <reason>" on the line itself.
# Never deletes anything. Exit 0 = clean (warnings allowed) · 1 = findings · 2 = usage or setup error.
set -uo pipefail

base="" unused=1 root=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="${2:-}"; [ -n "$base" ] || { echo "--base needs a ref" >&2; exit 2; }; shift 2 ;;
    --no-unused) unused=0; shift ;;
    --root) root="${2:-}"; [ -n "$root" ] || { echo "--root needs a directory" >&2; exit 2; }; shift 2 ;;
    -h|--help) sed -n 2,15p "$0"; exit 0 ;;
    *) echo "usage: check-hygiene.sh [--base <ref>] [--no-unused] [--root <dir>]" >&2; exit 2 ;;
  esac
done
[ -n "$root" ] || root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "$root" ] && cd "$root" 2>/dev/null || { echo "check-hygiene: not inside a project" >&2; exit 2; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "check-hygiene: not a git repository" >&2; exit 2; }

MAN=".claude/project.json"; allow_globs=""; out=""
add() { out="${out}${1}
"; }
if [ -f "$MAN" ] && command -v jq >/dev/null 2>&1; then
  noreason=$(jq -r '.hygiene.allow // [] | .[] | select(((.reason // "") | length) == 0) | .path' "$MAN" 2>/dev/null)
  for p in $noreason; do add "FAIL	allow	$MAN	hygiene.allow entry \"$p\" has no reason"; done
  allow_globs=$(jq -r '.hygiene.allow // [] | .[] | select(((.reason // "") | length) > 0) | .path' "$MAN" 2>/dev/null)
fi
allowed() { # allowed <path>: true when the path matches an allow glob
  local g
  set -f
  for g in $allow_globs; do
    # shellcheck disable=SC2254
    case "$1" in $g) set +f; return 0 ;; esac
  done
  set +f; return 1
}

tmp=$(mktemp -d "${TMPDIR:-/tmp}/hygiene.XXXXXX") || exit 2
trap 'rm -rf "$tmp"' EXIT

if [ -n "$base" ]; then
  git diff --name-only --diff-filter=ACMR "${base}...HEAD" > "$tmp/all" 2>/dev/null || { echo "check-hygiene: cannot diff ${base}...HEAD" >&2; exit 2; }
else
  git ls-files > "$tmp/all"
fi
# The kit itself and delivery artifacts are not product code.
grep -vE '^(\.claude/|docs/delivery/|docs/intake/)' "$tmp/all" | while IFS= read -r f; do
  [ -e "$f" ] && ! allowed "$f" && printf '%s\n' "$f"
done > "$tmp/files"

SRC='\.(ts|tsx|js|jsx|mjs|cjs|vue|svelte|astro|py|go|java|kt|cs|rb|php|rs|swift|dart|css|scss|html|sql|sh|ya?ml)$'
grep -E "$SRC" "$tmp/files" | grep -vE '(^|/)(package-lock\.json|pnpm-lock\.yaml|yarn\.lock)$|\.min\.(js|css)$|(^|/)(vendor|generated|__generated__)/' > "$tmp/src" || true
scan() { # scan <file-list> <grep -E pattern>: prints file:line:text, skipping lines marked hygiene:allow
  [ -s "$1" ] || return 0
  tr '\n' '\0' < "$1" | xargs -0 grep -nHE -- "$2" 2>/dev/null | grep -v 'hygiene:allow' || true
}
report() { # report <FAIL|WARN> <check> <detail>: reads file:line:text lines on stdin
  local loc text
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    loc=$(printf '%s' "$line" | cut -d: -f1,2); text=$(printf '%s' "$line" | cut -d: -f3- | sed 's/^[[:space:]]*//' | cut -c1-100)
    add "$1	$2	$loc	$3: $text"
  done
}

# 1. stray files
grep -E '(^|/)(\.DS_Store|Thumbs\.db|npm-debug\.log.*|yarn-error\.log)$|\.(log|tmp|bak|orig|rej|swp|pyc)$|~$|(^|/)(node_modules|dist|build|\.next|\.nuxt|\.svelte-kit|coverage|__pycache__|\.turbo|\.cache)/|(^|/)\.env(\.[A-Za-z0-9_-]+)?$' "$tmp/files" \
  | grep -vE '(^|/)\.env\.(example|sample|template)$' > "$tmp/stray" || true
while IFS= read -r f; do [ -n "$f" ] && add "FAIL	stray	$f	junk, build output or an env file is tracked: remove it and ignore it"; done < "$tmp/stray"

# 2. scaffold leftovers
grep -E '(^|/)(next\.svg|vercel\.svg|vite\.svg|react\.svg|logo192\.png|logo512\.png)$' "$tmp/files" > "$tmp/scaffiles" || true
while IFS= read -r f; do [ -n "$f" ] && add "FAIL	scaffold	$f	framework starter asset: remove it (the brand asset kit replaces it)"; done < "$tmp/scaffiles"
grep -E "$SRC|\.md$" "$tmp/files" | grep -vE '^docs/' > "$tmp/scafsrc" || true
scan "$tmp/scafsrc" 'Get started by editing|bootstrapped with \[?`?(create-next-app|Create React App)|Getting Started with Create React App|Learn React|Vite \+ (React|Vue|Svelte)|Welcome to (Next\.js|Nuxt|SvelteKit|your Expo app)|Edit <code>src/App' > "$tmp/r"
report FAIL scaffold "framework starter text" < "$tmp/r"

# 3. debug output
grep -E '\.(ts|tsx|js|jsx|mjs|cjs|vue|svelte|astro)$' "$tmp/src" | grep -vE '(^|/)scripts/' > "$tmp/js" || true
scan "$tmp/js" '(^|[^A-Za-z0-9_.])console\.(log|debug)\(|^[[:space:]]*debugger;?[[:space:]]*$' > "$tmp/r"
report FAIL debug "debug output" < "$tmp/r"
grep -E '\.py$' "$tmp/src" | grep -vE '(^|/)scripts/' > "$tmp/py" || true
scan "$tmp/py" '^[[:space:]]*(breakpoint\(\)|import pdb|pdb\.set_trace\(\))' > "$tmp/r"
report FAIL debug "debugger call" < "$tmp/r"

# 4. TODO without a ticket
scan "$tmp/src" '(^|[^A-Za-z0-9_])(TODO|FIXME|HACK|XXX)([^A-Za-z0-9_]|$)' | grep -vE '([A-Z][A-Z0-9]*-[0-9]+|#[0-9]+)' > "$tmp/r" || true
report FAIL todo "no ticket id" < "$tmp/r"

# 5. commented-out code (warning)
grep -E '\.(ts|tsx|js|jsx|mjs|cjs|go|java|kt|cs|rs|swift|dart|py|rb)$' "$tmp/src" > "$tmp/cc" || true
: > "$tmp/r"
if [ -s "$tmp/cc" ]; then
  tr '\n' '\0' < "$tmp/cc" | xargs -0 awk '
    function flush() { if (run >= 3) printf "%s:%d:%d lines\n", file, start, run; run = 0 }
    FNR == 1 { flush(); file = FILENAME }
    {
      c = (file ~ /\.(py|rb)$/) ? "^[ \t]*#[ \t]*" : "^[ \t]*//[ \t]*"
      if ($0 ~ c && $0 !~ /hygiene:allow/) {
        body = $0; sub(c, "", body)
        if (body ~ /[;{}][ \t]*$/ || body ~ /^(const|let|var|import|export|return|if|for|while|def|function|class|await)[ (]/) { if (run == 0) start = FNR; run++; next }
      }
      flush()
    }
    END { flush() }' > "$tmp/r" 2>/dev/null
fi
report WARN commented "commented-out code" < "$tmp/r"

# 6. empty folders (warning, whole-tree runs only)
if [ -z "$base" ]; then
  find . -type d -empty -not -path './.git/*' -not -path '*/node_modules/*' -not -path './.claude' -not -path './.claude/*' 2>/dev/null | sed 's|^\./||' | while IFS= read -r d; do
    allowed "$d" || git check-ignore -q "$d" 2>/dev/null || printf '%s\n' "$d"
  done > "$tmp/empty"
  while IFS= read -r d; do [ -n "$d" ] && add "WARN	emptydir	$d	empty folder"; done < "$tmp/empty"
fi

# 7. the project's unused-code check
if [ "$unused" = 1 ] && [ -f "$MAN" ] && command -v jq >/dev/null 2>&1; then
  cmd=$(jq -r '.commands.unused // empty' "$MAN" 2>/dev/null)
  if [ -n "$cmd" ]; then
    if ! bash -c "$cmd" > "$tmp/unused" 2>&1; then
      add "FAIL	unused	(commands.unused)	the unused-code check failed: $(tail -n 15 "$tmp/unused" | tr '\n' ' ' | cut -c1-600)"
    fi
  fi
fi

# 8. dead links in the living documents
: > "$tmp/dead"
for doc in README.md docs/README.md docs/CODEMAP.md docs/FEATURES.md docs/SYSTEM-FLOWS.md docs/database/DATABASE.md; do
  [ -f "$doc" ] || continue
  dir=$(dirname "$doc")
  grep -noE '\]\([^)# ]+' "$doc" | sed 's/](/:/' | while IFS=: read -r ln _ target; do
    case "$target" in http://*|https://*|mailto:*|\<*|'') continue ;; esac
    case "$target" in /*) path=".${target}" ;; *) path="$dir/$target" ;; esac
    [ -e "$path" ] || printf '%s:%s:%s\n' "$doc" "$ln" "$target"
  done >> "$tmp/dead"
done
if [ -f docs/CODEMAP.md ]; then
  grep -noE '`[A-Za-z0-9_.@()/-]+/[A-Za-z0-9_.@()/-]*`' docs/CODEMAP.md | tr -d '`' | while IFS=: read -r ln p; do
    case "$p" in */) : ;; *) case "${p##*/}" in *.*) : ;; *) continue ;; esac ;; esac
    [ -e "$p" ] || allowed "$p" || printf 'docs/CODEMAP.md:%s:%s\n' "$ln" "$p"
  done >> "$tmp/dead"
fi
report FAIL deadlink "points to a file that does not exist" < "$tmp/dead"

printf '%s' "$out" | grep . | sort -u > "$tmp/out" || true
cat "$tmp/out"
fails=$(grep -c '^FAIL' "$tmp/out" || true); warns=$(grep -c '^WARN' "$tmp/out" || true)
echo "hygiene: ${fails} findings, ${warns} warnings"
[ "$fails" -eq 0 ]
