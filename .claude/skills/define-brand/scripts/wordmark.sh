#!/usr/bin/env bash
# wordmark.sh <font.ttf|otf> "<text>" <out.svg> [--size 96] [--tracking 0] [--fill currentColor]
# Sets a word in an open-licence font (Google Fonts, Fontshare: record the licence) and writes it as SVG outlines,
# one <path id="wm-N"> per letter, so the designer can refine it by hand: kerning, a cut, a ligature, a custom letter
# (LOGO_AND_ICONS.md §3). No live <text>, no font file needed afterwards. --tracking is in thousandths of an em.
# Use a **static** font file of the weight you want (e.g. Manrope-SemiBold.ttf): a variable font gives only its default
# (often its lightest) instance. Needs node; fetches opentype.js once into a cache folder (network). The font file itself stays out of git.
# Exit 0 = written · 2 = usage error · 3 = node or opentype.js unavailable (say "wordmark not generated").
set -uo pipefail
[ $# -ge 3 ] || { echo "usage: wordmark.sh <font.ttf|otf> \"<text>\" <out.svg> [--size 96] [--tracking 0] [--fill currentColor]" >&2; exit 2; }
font="$1" text="$2" out="$3"; shift 3
size=96 tracking=0 fill=currentColor
while [ $# -gt 0 ]; do
  case "$1" in
    --size) size="${2:-}"; shift 2 ;;
    --tracking) tracking="${2:-}"; shift 2 ;;
    --fill) fill="${2:-}"; shift 2 ;;
    *) echo "wordmark: unknown option $1" >&2; exit 2 ;;
  esac
done
[ -f "$font" ] || { echo "wordmark: missing font file $font" >&2; exit 2; }
case "$size$tracking" in *[!0-9.-]*) echo "wordmark: --size and --tracking must be numbers" >&2; exit 2 ;; esac
command -v node >/dev/null 2>&1 || { echo "wordmark: node is not installed" >&2; exit 3; }
cache="${XDG_CACHE_HOME:-$HOME/.cache}/delivery-kit/opentype"
if [ ! -f "$cache/node_modules/opentype.js/package.json" ]; then
  mkdir -p "$cache" && npm install --silent --no-audit --no-fund --prefix "$cache" opentype.js@1.3.4 >/dev/null 2>&1 \
    || { echo "wordmark: could not install opentype.js (offline?)" >&2; exit 3; }
fi
mkdir -p "$(dirname "$out")"
FONT="$font" TEXT="$text" OUT="$out" SIZE="$size" TRACK="$tracking" FILL="$fill" OT="$cache/node_modules/opentype.js" node -e '
const opentype = require(process.env.OT);
const font = opentype.loadSync(process.env.FONT);
const size = Number(process.env.SIZE), track = Number(process.env.TRACK), scale = size / font.unitsPerEm;
const glyphs = font.stringToGlyphs(process.env.TEXT);
let x = 0; const parts = []; const all = new opentype.Path();
glyphs.forEach((g, i) => {
  const p = g.getPath(x, size, size); all.extend(p);
  const d = p.toPathData(2); if (d) parts.push(`  <path id="wm-${i}" d="${d}"/>`);
  x += g.advanceWidth * scale + (track / 1000) * size;
  if (i < glyphs.length - 1) x += font.getKerningValue(g, glyphs[i + 1]) * scale;
});
const b = all.getBoundingBox(), pad = Math.round(size * 0.04);
const vb = [Math.floor(b.x1) - pad, Math.floor(b.y1) - pad, Math.ceil(b.x2 - b.x1) + 2 * pad, Math.ceil(b.y2 - b.y1) + 2 * pad];
const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb.join(" ")}" fill="${process.env.FILL}">\n${parts.join("\n")}\n</svg>\n`;
require("fs").writeFileSync(process.env.OUT, svg);
console.log(`wordmark: ${process.env.OUT} (${glyphs.length} letters, ${svg.length} bytes)`);
' || { echo "wordmark: conversion failed (is it a TrueType or OpenType font?)" >&2; exit 3; }
