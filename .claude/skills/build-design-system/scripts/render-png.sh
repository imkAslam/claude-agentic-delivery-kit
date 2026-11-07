#!/usr/bin/env bash
# render-png.sh <page.html> <out.png> [WIDTHxHEIGHT]   (default 1440x900)
# Renders a self-contained HTML mockup, direction board or asset to PNG for review and evidence.
# Tries, in order: Playwright (if its browser is installed), then an installed Chrome/Chromium in headless mode.
# Exit 0 = PNG written · 2 = usage error · 3 = no renderer available (keep the HTML and say "not rendered").
# Never fabricate a PNG: if this exits non-zero, report it.
set -uo pipefail
[ $# -ge 2 ] || { echo "usage: render-png.sh <page.html> <out.png> [WIDTHxHEIGHT]" >&2; exit 2; }
src="$1" out="$2" size="${3:-1440x900}"
[ -f "$src" ] || { echo "render-png: missing $src" >&2; exit 2; }
case "$size" in *x*) w="${size%x*}" h="${size#*x}" ;; *) echo "render-png: size must be WIDTHxHEIGHT" >&2; exit 2 ;; esac
abs="$(cd "$(dirname "$src")" && pwd -P)/$(basename "$src")"
mkdir -p "$(dirname "$out")"
outabs="$(cd "$(dirname "$out")" && pwd -P)/$(basename "$out")"
rm -f "$outabs"

if command -v npx >/dev/null 2>&1; then
  npx --no-install playwright screenshot --viewport-size="${w},${h}" "file://${abs}" "$outabs" >/dev/null 2>&1 \
    || npx -y playwright@1 screenshot --viewport-size="${w},${h}" "file://${abs}" "$outabs" >/dev/null 2>&1 || true
  [ -s "$outabs" ] && { echo "rendered (playwright) ${out} ${w}x${h}"; exit 0; }
fi

for b in "${CHROME_PATH:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "/Applications/Chromium.app/Contents/MacOS/Chromium" \
         "$(command -v google-chrome 2>/dev/null)" "$(command -v chromium 2>/dev/null)" "$(command -v chromium-browser 2>/dev/null)"; do
  [ -n "$b" ] && [ -x "$b" ] || continue
  "$b" --headless=new --disable-gpu --hide-scrollbars --no-first-run --no-default-browser-check \
       --window-size="${w},${h}" --screenshot="$outabs" "file://${abs}" >/dev/null 2>&1
  [ -s "$outabs" ] && { echo "rendered (chrome headless) ${out} ${w}x${h}"; exit 0; }
done

echo "NOT RENDERED: no Playwright browser and no Chrome/Chromium found (install one, or run 'npx playwright install chromium'). Keep the HTML and report it."
exit 3
