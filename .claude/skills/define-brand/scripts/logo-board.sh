#!/usr/bin/env bash
# logo-board.sh <out.png|out.html> <mark.svg>... [--brand "#hex"] [--name "<product>"]
# A logo contact sheet for judging concepts by eye (LOGO_AND_ICONS.md §2): each SVG on one row at 120, 32 and 16 px,
# on light and on dark, inside an app-icon tile in the brand colour, and in a product header. A .png target renders
# the sheet with build-design-system/scripts/render-png.sh (the HTML is kept beside it); a .html target only writes it.
# Exit 0 = written · 2 = usage error · 3 = no renderer (keep the HTML, say "not rendered").
set -uo pipefail
out=""; brand="#1d4ed8"; name="Product"; marks=""
while [ $# -gt 0 ]; do
  case "$1" in
    --brand) brand="${2:-}"; shift 2 ;;
    --name) name="${2:-}"; shift 2 ;;
    -*) echo "logo-board: unknown option $1" >&2; exit 2 ;;
    *) if [ -z "$out" ]; then out="$1"; else marks="${marks}$1
"; fi; shift ;;
  esac
done
[ -n "$out" ] && [ -n "$marks" ] || { echo "usage: logo-board.sh <out.png|out.html> <mark.svg>... [--brand \"#hex\"] [--name \"<product>\"]" >&2; exit 2; }
case "$brand" in \#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]*) : ;; *) echo "logo-board: --brand must be a hex colour" >&2; exit 2 ;; esac
case "$out" in *.html) html="$out" ;; *.png) html="${out%.png}.html" ;; *) echo "logo-board: the output must be .png or .html" >&2; exit 2 ;; esac
mkdir -p "$(dirname "$html")"
rows=0; body=""
while IFS= read -r m; do
  [ -n "$m" ] || continue
  [ -f "$m" ] || { echo "logo-board: missing $m" >&2; exit 2; }
  src="file://$(cd "$(dirname "$m")" && pwd -P)/$(basename "$m")"
  body="${body}<small>$(basename "$m")</small><div class=\"row\"><div class=\"cell light\"><img src=\"$src\" style=\"height:120px;max-width:170px\"><img src=\"$src\" style=\"height:32px;max-width:70px\"><img src=\"$src\" style=\"height:16px;max-width:36px\"></div><div class=\"cell dark\"><img src=\"$src\" style=\"height:120px;max-width:170px\"><img src=\"$src\" style=\"height:32px;max-width:70px\"><img src=\"$src\" style=\"height:16px;max-width:36px\"></div><div class=\"tile\"><img src=\"$src\"></div><div class=\"hdr\"><img src=\"$src\" style=\"height:28px;max-width:160px\"><b>${name}</b><span>Dashboard</span><span>Patients</span><span>Reports</span></div></div>
"
  rows=$((rows + 1))
done <<EOF
$marks
EOF
cat > "$html" <<EOF
<!doctype html><meta charset="utf-8"><title>Logo board</title>
<style>body{margin:0;font:13px/1.4 system-ui,sans-serif;background:#f4f5f7;color:#111}.row{display:grid;grid-template-columns:300px 300px 110px 1fr;gap:16px;padding:12px 20px 18px;border-bottom:1px solid #dcdfe5;align-items:center}.cell{display:flex;align-items:center;gap:18px;padding:14px;border-radius:10px;min-height:140px;overflow:hidden}img{max-width:100%;object-fit:contain}.light{background:#fff}.dark{background:#111418}.dark img,.tile img{filter:brightness(0) invert(1)}.tile{width:96px;height:96px;border-radius:22px;display:grid;place-items:center;overflow:hidden;background:${brand}}.tile img{width:60px;height:60px;object-fit:contain}.hdr{background:#fff;border-radius:10px;height:56px;display:flex;align-items:center;gap:10px;padding:0 16px;box-shadow:0 1px 2px #0002;overflow:hidden}.hdr b{font-weight:600}.hdr span{color:#667;margin-left:14px}small{display:block;color:#667;padding:10px 20px 0}</style>
<body>
${body}</body>
EOF
case "$out" in *.html) echo "logo-board: $html ($rows marks)"; exit 0 ;; esac
here="$(cd "$(dirname "$0")" && pwd -P)"
bash "$here/../../build-design-system/scripts/render-png.sh" "$html" "$out" "1200x$((rows * 200 + 20))"
