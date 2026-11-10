#!/usr/bin/env bash
# check-diagrams.sh [--require "D0 D1 D2 ..."] [--mirror <ARCHITECTURE.md>] [--no-render] <markdown-file>...
# Checks the architecture diagrams that live inside the PRD (and any other markdown passed in):
#   1. every required diagram id has a heading ("### D3 · Deployment", "#### D2-L3 · Application layer", ...)
#   2. every ```mermaid block renders. Rendering happens in a temporary directory outside the repository;
#      nothing is written into the project. Diagrams are never stored as separate files.
#   3. with --mirror: the copy of the diagrams in ARCHITECTURE.md (§14) is identical to the first file (the PRD);
#      sync-diagrams.sh creates and refreshes that copy.
# Renderer: `mmdc` on PATH, otherwise `npx -y @mermaid-js/mermaid-cli@11`. Use --no-render to skip.
# Exit 0 = all ids present and all blocks render · 1 = a missing id or a render failure ·
#      2 = usage error · 3 = ids present but no renderer available (syntax NOT checked; say so).
set -uo pipefail

require="" render=1 files="" mirror=""
while [ $# -gt 0 ]; do
  case "$1" in
    --require) require="${2:-}"; shift 2 ;;
    --mirror) mirror="${2:-}"; [ -n "$mirror" ] || { echo "--mirror needs a file" >&2; exit 2; }; shift 2 ;;
    --no-render) render=0; shift ;;
    -h|--help) sed -n 2,12p "$0"; exit 0 ;;
    *) files="${files}${1}
"; shift ;;
  esac
done
[ -n "$files" ] || { echo "usage: check-diagrams.sh [--require \"D0 D1 ...\"] [--mirror <ARCHITECTURE.md>] [--no-render] <markdown-file>..." >&2; exit 2; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/diagrams.XXXXXX") || exit 2
trap 'rm -rf "$tmp"' EXIT
status=0

# 1. Required ids
for id in $require; do
  found=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$f" ] || { echo "missing file: $f" >&2; exit 2; }
    grep -Eq "^#{2,6} ${id}([^0-9]|$)" "$f" && { found=1; break; }
  done <<EOF
$files
EOF
  if [ "$found" = 1 ]; then echo "present   ${id}"; else echo "MISSING   ${id} (no heading '### ${id} · <title>')"; status=1; fi
done

# 1b. The mirrored copy in ARCHITECTURE.md matches the source (the first file)
if [ -n "$mirror" ]; then
  src=$(printf '%s\n' "$files" | sed -n 1p)
  bash "$(dirname "$0")/sync-diagrams.sh" --check "$src" "$mirror" || status=1
fi

# 2. Extract every mermaid block: <n>.mmd plus an index line "<n>\t<file>:<line>\t<last heading>"
: > "$tmp/index"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -f "$f" ] || { echo "missing file: $f" >&2; exit 2; }
  awk -v dir="$tmp" -v file="$f" -v start="$(($(wc -l < "$tmp/index") + 1))" '
    BEGIN { n = start - 1; inb = 0 }
    /^#{1,6} / && !inb { h = $0; sub(/^#+ /, "", h) }
    /^```mermaid[[:space:]]*$/ && !inb { inb = 1; n++; out = dir "/" n ".mmd"; printf "" > out
                                         printf "%d\t%s:%d\t%s\n", n, file, NR, h >> (dir "/index"); next }
    /^```[[:space:]]*$/ && inb { inb = 0; close(out); next }
    inb { print >> out }
    END { if (inb) printf "%d\t%s:%d\tUNCLOSED mermaid block\n", n, file, NR >> (dir "/index") }
  ' "$f"
done <<EOF
$files
EOF
total=$(grep -c . "$tmp/index" || true)
echo "mermaid blocks: ${total}"
[ "$total" -gt 0 ] || { echo "no mermaid blocks found"; exit 1; }
if grep -q "UNCLOSED" "$tmp/index"; then grep "UNCLOSED" "$tmp/index" | cut -f2-; status=1; fi

[ "$render" = 1 ] || exit "$status"

# 3. Render each block (outside the repo)
if command -v mmdc >/dev/null 2>&1; then mm="mmdc"
elif command -v npx >/dev/null 2>&1; then mm="npx -y @mermaid-js/mermaid-cli@11"
else echo "NOT RENDERED: neither mmdc nor npx is available; diagram syntax was not checked"; [ "$status" = 0 ] && exit 3; exit "$status"
fi
# Use an installed Chrome/Chromium when the renderer has no browser of its own.
browser="${PUPPETEER_EXECUTABLE_PATH:-}"
if [ -z "$browser" ]; then
  for b in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "/Applications/Chromium.app/Contents/MacOS/Chromium" \
           "$(command -v google-chrome 2>/dev/null)" "$(command -v chromium 2>/dev/null)" "$(command -v chromium-browser 2>/dev/null)"; do
    [ -n "$b" ] && [ -x "$b" ] && { browser="$b"; break; }
  done
fi
if [ -n "$browser" ]; then printf '{"executablePath":"%s","args":["--no-sandbox"]}\n' "$browser" > "$tmp/puppeteer.json"
else printf '{"args":["--no-sandbox"]}\n' > "$tmp/puppeteer.json"; fi
while IFS="	" read -r n loc head; do
  [ -f "$tmp/$n.mmd" ] || continue
  if $mm -q -p "$tmp/puppeteer.json" -i "$tmp/$n.mmd" -o "$tmp/$n.svg" > "$tmp/$n.log" 2>&1 && [ -s "$tmp/$n.svg" ]; then
    echo "renders   ${loc}  ${head}"
  elif grep -qi "could not find chrome\|failed to launch the browser\|browser was not found" "$tmp/$n.log"; then
    echo "NOT RENDERED: the renderer has no headless browser (install Chrome or run 'npx puppeteer browsers install chrome-headless-shell'); diagram syntax was not checked"
    [ "$status" = 0 ] && exit 3; exit "$status"
  else
    echo "FAILS     ${loc}  ${head}"
    grep -v "^$" "$tmp/$n.log" | grep -iv "puppeteer\|deprecat" | head -5 | sed 's/^/          /'
    status=1
  fi
done < "$tmp/index"
exit "$status"
