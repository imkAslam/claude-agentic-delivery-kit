#!/usr/bin/env bash
# check-assets.sh [--root <dir>] [path...]
# Checks brand and UI assets (define-brand → LOGO_AND_ICONS.md, build-design-system → ILLUSTRATIONS_AND_ANIMATION.md).
# Default paths: docs/delivery/brand/assets and the tracked public/, static/ and assets/ folders of the apps.
#   svg     a viewBox; no <script>, <foreignObject>, embedded raster (data:image, <image>) or external reference;
#           an animated SVG uses CSS keyframes with a prefers-reduced-motion block (SMIL animation can't honour it)
#   size    logo* and favicon* SVG ≤ 10 KB · icons/ ≤ 2 KB · other SVG ≤ 60 KB · Lottie ≤ 150 KB · video ≤ 1.5 MB
#           · AVIF/WebP ≤ 200 KB · PNG/JPEG ≤ 500 KB
#   format  no GIF (use SVG or a video loop); (warning) a PNG/JPEG illustration (prefer AVIF/WebP)
# Never changes a file. Exit 0 = clean (warnings allowed) · 1 = findings · 2 = usage error.
set -uo pipefail

root=""; paths=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root="${2:-}"; [ -n "$root" ] || { echo "--root needs a directory" >&2; exit 2; }; shift 2 ;;
    -h|--help) sed -n 2,10p "$0"; exit 0 ;;
    -*) echo "usage: check-assets.sh [--root <dir>] [path...]" >&2; exit 2 ;;
    *) paths="${paths}$1
"; shift ;;
  esac
done
[ -n "$root" ] || root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$root" 2>/dev/null || { echo "check-assets: cannot open $root" >&2; exit 2; }

EXT='\.(svg|lottie|json|webm|mp4|mov|gif|avif|webp|png|jpe?g)$'
list=$(mktemp "${TMPDIR:-/tmp}/assets.XXXXXX") || exit 2
trap 'rm -f "$list"' EXIT
if [ -n "$paths" ]; then
  printf '%s' "$paths" | while IFS= read -r p; do
    [ -n "$p" ] || continue
    if [ -d "$p" ]; then find "$p" -type f -not -path '*/node_modules/*' | grep -iE "$EXT"
    elif [ -f "$p" ]; then printf '%s\n' "$p"
    else echo "check-assets: not found: $p" >&2; fi
  done > "$list"
else
  { [ -d docs/delivery/brand/assets ] && find docs/delivery/brand/assets -type f
    git ls-files 2>/dev/null | grep -E '(^|/)(public|static|assets)/' | grep -vE '(^|/)node_modules/|^docs/'; } \
    | grep -iE "$EXT" | grep -vE '\.json$|(^|/)(manifest|site)\.webmanifest$' > "$list" || true
  # JSON only counts when it is a Lottie animation in an illustrations or animations folder
  { [ -d docs/delivery/brand/assets ] && find docs/delivery/brand/assets -type f -name '*.json'
    git ls-files 2>/dev/null | grep -E '(^|/)(illustrations|animations|lottie)/[^/]*\.json$'; } >> "$list" 2>/dev/null || true
fi

out=""
add() { out="${out}$1	$2	$3	$4
"; }
kb() { echo $(( ($1 + 1023) / 1024 )); }
size_check() { # size_check <file> <bytes> <limit-bytes> <what>
  [ "$2" -le "$3" ] || add FAIL size "$1" "$(kb "$2") KB, over the $(kb "$3") KB budget for $4"
}

while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  bytes=$(wc -c < "$f" | tr -d ' ')
  name=$(basename "$f" | tr 'A-Z' 'a-z')
  case "$name" in
    *.svg)
      grep -q 'viewBox' "$f" || add FAIL svg "$f" "no viewBox: it won't scale"
      grep -qiE '<script|[[:space:]]on(load|click|error)=' "$f" && add FAIL svg "$f" "script or event handler inside the SVG"
      grep -qi '<foreignObject' "$f" && add FAIL svg "$f" "<foreignObject>: draw it as SVG paths"
      grep -qiE 'data:image/|<image[[:space:]]' "$f" && add FAIL svg "$f" "an embedded raster image: draw it as paths, or ship the raster separately"
      grep -qiE '(xlink:)?href[[:space:]]*=[[:space:]]*["'"'"']https?:|url\([[:space:]]*["'"'"']?https?:|@import' "$f" && add FAIL svg "$f" "an external reference: assets load nothing from the network"
      if grep -qiE '<(animate|animateTransform|animateMotion|set)[[:space:]>]' "$f"; then
        add FAIL svg "$f" "SMIL animation can't honour prefers-reduced-motion: animate with CSS keyframes in the SVG's <style>"
      elif grep -qiE '@keyframes|animation(-name)?[[:space:]]*:' "$f" && ! grep -qi 'prefers-reduced-motion' "$f"; then
        add FAIL svg "$f" "animated without a prefers-reduced-motion block: show the static final frame under reduced motion"
      fi
      case "$f" in
        */icons/*) size_check "$f" "$bytes" 2048 "an icon" ;;
        *) case "$name" in logo*|favicon*|app-icon*) size_check "$f" "$bytes" 10240 "a logo or icon file" ;;
             *) size_check "$f" "$bytes" 61440 "an SVG illustration" ;; esac ;;
      esac ;;
    *.lottie|*.json) size_check "$f" "$bytes" 153600 "a Lottie animation" ;;
    *.webm|*.mp4|*.mov) size_check "$f" "$bytes" 1572864 "a video loop" ;;
    *.gif) add FAIL format "$f" "a GIF: use an animated SVG or a muted video loop (smaller, themeable)" ;;
    *.avif|*.webp) size_check "$f" "$bytes" 204800 "an AVIF/WebP image" ;;
    *.png|*.jpg|*.jpeg)
      size_check "$f" "$bytes" 512000 "a PNG/JPEG image"
      case "$f" in */illustrations/*) add WARN format "$f" "a PNG/JPEG illustration: prefer SVG, or AVIF/WebP for photographic art" ;; esac ;;
  esac
done < "$list"

printf '%s' "$out" | grep . | sort -u
fails=$(printf '%s' "$out" | grep -c '^FAIL' || true); warns=$(printf '%s' "$out" | grep -c '^WARN' || true)
echo "assets: $(grep -c . "$list" | tr -d ' ') files, ${fails} findings, ${warns} warnings"
[ "$fails" -eq 0 ]
