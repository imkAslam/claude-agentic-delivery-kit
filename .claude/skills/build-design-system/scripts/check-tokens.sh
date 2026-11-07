#!/usr/bin/env bash
# check-tokens.sh [--theme <override.json>]... [--css] [--quiet] <tokens.json>
# Validates design tokens in the W3C DTCG format ($value / $type) and checks WCAG contrast:
#   - the file is valid JSON; every alias "{group.token}" resolves (no loops)
#   - every color.* token resolves to a hex color (#rgb, #rrggbb, #rrggbbaa)
#   - the required semantic tokens exist ($extensions."delivery.required", or the default list below)
#   - every contrast pair passes ($extensions."delivery.contrastPairs": [{fg, bg, min}], or the defaults),
#     for the base tokens and again for each --theme override (e.g. tokens.dark.json)
# --css prints CSS custom properties instead (:root, plus [data-theme="<name>"] and a prefers-color-scheme
#       block for each theme) for mockups and the web theme. Names: color.text.default -> --color-text-default;
#       aliases become var(--…) so component tokens follow the active theme. Run the checks first.
# Exit 0 = pass · 1 = a failed check · 2 = usage error or invalid JSON. Requires jq.
set -uo pipefail
command -v jq >/dev/null 2>&1 || { echo "check-tokens: jq is required" >&2; exit 2; }

base="" themes="" css=0 quiet=0
while [ $# -gt 0 ]; do
  case "$1" in
    --theme) [ -n "${2:-}" ] || { echo "--theme needs a file" >&2; exit 2; }; themes="${themes}${2}
"; shift 2 ;;
    --css) css=1; shift ;;
    --quiet) quiet=1; shift ;;
    -h|--help) sed -n 2,13p "$0"; exit 0 ;;
    *) base="$1"; shift ;;
  esac
done
[ -n "$base" ] || { echo "usage: check-tokens.sh [--theme <override.json>]... [--css] [--quiet] <tokens.json>" >&2; exit 2; }
for f in "$base" $themes; do
  [ -f "$f" ] || { echo "check-tokens: missing file $f" >&2; exit 2; }
  jq empty "$f" 2>/dev/null || { echo "check-tokens: invalid JSON in $f" >&2; exit 2; }
done

LIB='
def flat: [paths(type == "object" and has("$value")) as $p
           | select(all($p[]; (tostring | startswith("$")) | not))
           | {key: ($p | map(tostring) | join(".")), value: getpath($p)}] | from_entries;
def resolve($m):
  def r($d): if type == "string" and test("^\\{[^{}]+\\}$") then (.[1:-1]) as $k
               | if $d > 12 then error("alias loop at {\($k)}")
                 elif ($m | has($k)) then ($m[$k]["$value"] | r($d + 1))
                 else error("unresolved alias {\($k)}") end
             else . end;
  r(0);
def hexd: if . >= 97 then . - 87 elif . >= 65 then . - 55 else . - 48 end;
def hex2: explode | map(hexd) | .[0] * 16 + .[1];
def ishex: type == "string" and test("^#([0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$");
def rgb: ltrimstr("#") | (if length <= 4 then (split("") | .[0:3] | map(. + .) | join("")) else .[0:6] end)
         | [.[0:2], .[2:4], .[4:6]] | map(hex2);
def lin: (. / 255) as $c | if $c <= 0.04045 then $c / 12.92 else pow(($c + 0.055) / 1.055; 2.4) end;
def lum: rgb | map(lin) | (.[0] * 0.2126 + .[1] * 0.7152 + .[2] * 0.0722);
def ratio($a; $b): ([($a | lum), ($b | lum)] | sort) as $l | (($l[1] + 0.05) / ($l[0] + 0.05));
def r2: (. * 100 | round) / 100;
def cssval: if type == "array" and length == 4 and all(.[]; type == "number") then "cubic-bezier(\(map(tostring) | join(", ")))"
            elif type == "array" then map(tostring | if test(" ") then "\"" + . + "\"" else . end) | join(", ")
            elif type == "object" and has("offsetX") then "\(.offsetX) \(.offsetY) \(.blur // "0") \(.spread // "0") \(.color)"
            elif type == "object" then null
            else tostring end;
def cssname: "--" + gsub("\\."; "-");
def cssref: if type == "string" and test("^\\{[^{}]+\\}$") then "var(\(.[1:-1] | cssname))" else cssval end;
'

DEFAULT_REQUIRED='["color.bg.default","color.surface.default","color.border.default","color.border.strong","color.text.default","color.text.muted","color.primary.default","color.primary.hover","color.primary.on","color.danger.default","color.danger.on","color.success.default","color.warning.default","color.info.default","color.focus.ring","font.family.sans","font.size.base","space.4","radius.md"]'
DEFAULT_PAIRS='[{"fg":"color.text.default","bg":"color.bg.default","min":4.5},{"fg":"color.text.default","bg":"color.surface.default","min":4.5},{"fg":"color.text.muted","bg":"color.bg.default","min":4.5},{"fg":"color.text.muted","bg":"color.surface.default","min":4.5},{"fg":"color.primary.on","bg":"color.primary.default","min":4.5},{"fg":"color.primary.on","bg":"color.primary.hover","min":4.5},{"fg":"color.primary.default","bg":"color.bg.default","min":3},{"fg":"color.danger.default","bg":"color.bg.default","min":4.5},{"fg":"color.danger.on","bg":"color.danger.default","min":4.5},{"fg":"color.border.strong","bg":"color.bg.default","min":3},{"fg":"color.focus.ring","bg":"color.bg.default","min":3}]'

theme_name() { b=$(basename "$1" .json); b=${b#tokens.}; b=${b#tokens-}; printf '%s' "$b"; }

if [ "$css" = 1 ]; then
  jq -r "$LIB"' flat as $m | ":root {", ($m | to_entries[] | (.value["$value"] | cssref) as $v
        | select($v != null) | "  \(.key | cssname): \($v);"), "}"' "$base"
  while IFS= read -r t; do
    [ -n "$t" ] || continue; n=$(theme_name "$t")
    jq -r --arg n "$n" --slurpfile o "$t" "$LIB"' (flat) as $b | ($o[0] | flat) as $ov | ($b + $ov) as $m
        | [$ov | to_entries[] | (.value["$value"] | cssref) as $v | select($v != null)
           | "\(.key | cssname): \($v);"] as $lines
        | "[data-theme=\"\($n)\"] {", ($lines[] | "  " + .), "}",
          (if $n == "dark" then ("@media (prefers-color-scheme: dark) {", "  :root:not([data-theme]) {", ($lines[] | "    " + .), "  }", "}") else empty end)' "$base"
  done <<EOF2
$themes
EOF2
  exit 0
fi

out=""
run_set() { # $1 = label, $2 = override file or ""
  if [ -n "$2" ]; then ov="$2"; else ov=$(mktemp "${TMPDIR:-/tmp}/tok.XXXXXX"); echo '{}' > "$ov"; fi
  jq -r --arg t "$1" --slurpfile o "$ov" --argjson dreq "$DEFAULT_REQUIRED" --argjson dpairs "$DEFAULT_PAIRS" "$LIB"'
    . as $root | (flat + ($o[0] | flat)) as $m
    | ($root["$extensions"]["delivery.required"] // $dreq) as $req
    | ($root["$extensions"]["delivery.contrastPairs"] // $dpairs) as $pairs
    | ( $m | to_entries[] | .key as $k | (.value["$value"] | try resolve($m) catch ("ERR:" + .)) as $v
        | if ($v | type) == "string" and ($v | startswith("ERR:")) then "FAIL\t\($t)\t\($k): \($v[4:])"
          elif ($k | startswith("color.")) and (($v | ishex) | not) then "FAIL\t\($t)\t\($k) = \($v | tojson) is not a hex color"
          elif ($k | startswith("color.")) and ($v | length) == 9 then "WARN\t\($t)\t\($k) has alpha; contrast is computed without it"
          else empty end ),
      ( $req[] as $r | select(($m | has($r)) | not) | "FAIL\t\($t)\tmissing required token \($r)" ),
      ( $pairs[] | . as $p
        | if (($m | has($p.fg)) and ($m | has($p.bg))) | not then "FAIL\t\($t)\tcontrast pair \($p.fg) on \($p.bg): token missing"
          else (try ([($m[$p.fg]["$value"] | resolve($m)), ($m[$p.bg]["$value"] | resolve($m))]) catch null) as $c
          | if $c == null or (($c[0] | ishex) and ($c[1] | ishex) | not) then "FAIL\t\($t)\tcontrast pair \($p.fg) on \($p.bg): not resolvable to hex colors"
            else ratio($c[0]; $c[1]) as $r
            | if $r + 0.0001 < $p.min then "FAIL\t\($t)\tcontrast \($p.fg) \($c[0]) on \($p.bg) \($c[1]) = \($r | r2):1 (needs \($p.min):1)"
              else "OK\t\($t)\tcontrast \($p.fg) on \($p.bg) = \($r | r2):1 (min \($p.min))" end
            end
          end )
  ' "$base"
  [ -n "$2" ] || rm -f "$ov"
}

out=$(run_set base "")
while IFS= read -r t; do
  [ -n "$t" ] || continue
  out="${out}
$(run_set "$(theme_name "$t")" "$t")"
done <<EOF2
$themes
EOF2

if [ "$quiet" = 1 ]; then printf '%s\n' "$out" | grep -v '^OK' | grep . ; else printf '%s\n' "$out" | grep .; fi
fails=$(printf '%s\n' "$out" | grep -c '^FAIL' || true)
oks=$(printf '%s\n' "$out" | grep -c '^OK' || true)
echo "tokens: ${oks} contrast pairs pass, ${fails} failures"
[ "$fails" -eq 0 ]
