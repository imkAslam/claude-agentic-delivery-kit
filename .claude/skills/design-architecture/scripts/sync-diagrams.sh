#!/usr/bin/env bash
# sync-diagrams.sh [--check] <PRD.md> <ARCHITECTURE.md>
# The PRD is the source of every architecture diagram (D0-D8). ARCHITECTURE.md carries an identical copy in
# "## 14. Architecture diagrams", between the markers
#   <!-- diagrams:begin ... -->  and  <!-- diagrams:end -->
# so engineers read the diagrams next to the architecture text and the two documents can never drift.
#   (default)  copy every diagram section from the PRD into ARCHITECTURE.md (creates §14 if it is missing)
#   --check    change nothing; fail when the copy is missing, incomplete or different from the PRD
# A diagram section starts at a heading "### D<n>[-<suffix>] · <title>" (any level) and ends at the next heading.
# Blank-line and trailing-space differences are ignored.
# Exit 0 = in sync · 1 = out of sync (--check) or no diagrams in the PRD · 2 = usage error.
set -uo pipefail

check=0
[ "${1:-}" = "--check" ] && { check=1; shift; }
case "${1:-}" in -h|--help) sed -n 2,11p "$0"; exit 0 ;; esac
[ $# -eq 2 ] || { echo "usage: sync-diagrams.sh [--check] <PRD.md> <ARCHITECTURE.md>" >&2; exit 2; }
prd="$1" arch="$2"
[ -f "$prd" ] || { echo "sync-diagrams: missing $prd" >&2; exit 2; }
[ -f "$arch" ] || { echo "sync-diagrams: missing $arch" >&2; exit 2; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/syncdiag.XXXXXX") || exit 2
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/prd" "$tmp/arch"

extract() { # extract <markdown> <dir>: one normalized file per diagram id, plus <dir>/order
  : > "$2/order"
  awk -v dir="$2" '
    function finish() { if (cur != "") { for (i = 1; i <= last; i++) print buf[i] > out; close(out) } cur = ""; n = 0; last = 0 }
    /^```/ { fence = !fence }
    !fence && /^<!-- (architect|diagrams):(begin|end)/ { finish(); next }
    !fence && /^#{1,6} / {
      finish()
      if ($2 ~ /^D[0-9]+(-[A-Za-z0-9_-]+)?$/) { cur = $2; out = dir "/" cur ".md"; print cur >> (dir "/order") }
    }
    cur != "" {
      line = $0; sub(/[ \t]+$/, "", line)
      if (line == "" && (n == 0 || buf[n] == "")) next      # squeeze blank lines
      buf[++n] = line; if (line != "") last = n
    }
    END { finish() }
  ' "$1"
}

extract "$prd" "$tmp/prd"
[ -s "$tmp/prd/order" ] || { echo "sync-diagrams: no diagram sections (### D<n> · <title>) found in $prd"; exit 1; }
dups=$(sort "$tmp/prd/order" | uniq -d | tr '\n' ' ')
[ -z "$dups" ] || { echo "sync-diagrams: duplicate diagram ids in $prd: $dups"; exit 1; }

BEGIN_MARK='<!-- diagrams:begin (generated from PRD.md by sync-diagrams.sh; edit diagrams in the PRD, never here) -->'
END_MARK='<!-- diagrams:end -->'

if [ "$check" = 1 ]; then
  awk '/^<!-- diagrams:begin/ { on = 1; next } /^<!-- diagrams:end/ { on = 0 } on' "$arch" > "$tmp/region"
  extract "$tmp/region" "$tmp/arch"
  status=0
  while IFS= read -r id; do
    if [ ! -f "$tmp/arch/$id.md" ]; then echo "MISSING   $id is in $prd but not in $arch"; status=1
    elif ! cmp -s "$tmp/prd/$id.md" "$tmp/arch/$id.md"; then echo "DIFFERS   $id is not the same in $prd and $arch"; status=1
    fi
  done < "$tmp/prd/order"
  while IFS= read -r id; do
    [ -f "$tmp/prd/$id.md" ] || { echo "EXTRA     $id is in $arch but not in $prd"; status=1; }
  done < "$tmp/arch/order"
  n=$(grep -c . "$tmp/prd/order")
  if [ "$status" = 0 ]; then echo "diagrams in sync: $n (PRD = ARCHITECTURE)"
  else echo "diagrams out of sync: run sync-diagrams.sh $prd $arch (the PRD is the source)"; fi
  exit "$status"
fi

{
  printf '%s\n\n' "$BEGIN_MARK"
  while IFS= read -r id; do cat "$tmp/prd/$id.md"; printf '\n'; done < "$tmp/prd/order"
  printf '%s\n' "$END_MARK"
} > "$tmp/block"

if grep -q '^<!-- diagrams:begin' "$arch" && grep -q '^<!-- diagrams:end' "$arch"; then
  awk -v block="$tmp/block" '
    /^<!-- diagrams:begin/ { while ((getline l < block) > 0) print l; close(block); skip = 1; next }
    /^<!-- diagrams:end/ { skip = 0; next }
    !skip' "$arch" > "$tmp/new"
else
  { cat "$arch"
    printf '\n## 14. Architecture diagrams\nThe full diagram set (D0–D8), mirrored from the PRD. The PRD is the source: change a diagram there, then run `sync-diagrams.sh`.\n\n'
    cat "$tmp/block"; } > "$tmp/new"
fi
cat "$tmp/new" > "$arch"
echo "synced $(grep -c . "$tmp/prd/order") diagrams from $prd into $arch"
