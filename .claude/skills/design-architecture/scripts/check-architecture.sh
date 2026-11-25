#!/usr/bin/env bash
# check-architecture.sh [--root <dir>] [--prd <path>] [--arch <path>] [--manifest <path>]
# Deterministic checks of the architect's documents (design-architecture Steps 4–8, LAYERED_BLUEPRINT, FOLDER_STRUCTURES):
#   prd11    PRD §11 holds the full folder tree (a drawn ```text tree) and a folder → owner role table
#   layers   ARCHITECTURE §12 has every block L0–L7 and X1–X3, each with all nine block fields
#   tree     once .claude/project.json exists: every role path and shared file appears in the ARCHITECTURE §13 tree,
#            and every top-level folder of the tree has an owner
#   routing  route-group folders such as (auth)/ appear only when the web stack is Next.js (ARCHITECTURE §4)
# Never changes a file. Exit 0 = clean (warnings allowed) · 1 = findings · 2 = usage error.
set -uo pipefail

root=""; prd=""; arch=""; man=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root="${2:-}"; shift 2 ;;
    --prd) prd="${2:-}"; shift 2 ;;
    --arch) arch="${2:-}"; shift 2 ;;
    --manifest) man="${2:-}"; shift 2 ;;
    -h|--help) sed -n 2,9p "$0"; exit 0 ;;
    *) echo "usage: check-architecture.sh [--root <dir>] [--prd <path>] [--arch <path>] [--manifest <path>]" >&2; exit 2 ;;
  esac
done
[ -n "$root" ] || root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$root" 2>/dev/null || { echo "check-architecture: cannot open $root" >&2; exit 2; }
prd="${prd:-docs/delivery/PRD.md}"; arch="${arch:-docs/delivery/ARCHITECTURE.md}"; man="${man:-.claude/project.json}"
[ -f "$prd" ] || { echo "check-architecture: no $prd" >&2; exit 2; }
[ -f "$arch" ] || { echo "check-architecture: no $arch" >&2; exit 2; }
command -v perl >/dev/null 2>&1 || { echo "check-architecture: perl is required" >&2; exit 2; }

out=""
add() { out="${out}$1	$2	$3	$4
"; }
section() { # section <file> <heading prefix, e.g. "## 11.">: the lines under that heading, up to the next "## "
  awk -v h="$2" 'index($0, h) == 1 { f = 1; next } f && /^## / { exit } f' "$1"
}
textblock() { awk '/^```text/ { f = 1; next } /^```/ { if (f) exit } f'; }

# 1. PRD §11: a drawn tree and an ownership table
s11=$(section "$prd" "## 11.")
if [ -z "$s11" ]; then
  add FAIL prd11 "$prd" "no §11 Application folder structure"
else
  tree11=$(printf '%s\n' "$s11" | textblock)
  if [ "$(printf '%s\n' "$tree11" | grep -c '├──\|└──')" -lt 3 ]; then
    add FAIL prd11 "$prd" "§11 has no drawn folder tree: put the full tree from FOLDER_STRUCTURES, adapted (not compressed one-line paths)"
  fi
  printf '%s\n' "$s11" | grep -qiE '^\|.*(owner|role).*\|' && [ "$(printf '%s\n' "$s11" | grep -c '^|')" -ge 4 ] \
    || add FAIL prd11 "$prd" "§11 has no folder → owner role table (LAYERED_BLUEPRINT › PRD section format)"
fi

# 2. ARCHITECTURE §12: every block with every field
s12=$(section "$arch" "## 12.")
if [ -z "$s12" ]; then
  add FAIL layers "$arch" "no §12 Layer-by-layer architecture"
else
  for id in L0 L1 L2 L3 L4 L5 L6 L7 X1 X2 X3; do
    blk=$(printf '%s\n' "$s12" | awk -v id="$id" '$0 ~ "^### " id "([ .:]|$)" { f = 1; next } f && /^#{2,3} / { exit } f')
    if [ -z "$blk" ]; then add FAIL layers "$arch" "§12 has no ### $id block"; continue; fi
    miss=""
    for fld in Responsibility Components Technology Owner Folder "Talks to" Scaling "Failure handling" NFR; do
      printf '%s' "$blk" | grep -qi -- "$fld" || miss="${miss}, ${fld}"
    done
    [ -z "$miss" ] || add FAIL layers "$arch" "§12 $id is missing: ${miss#, } (LAYERED_BLUEPRINT › Block format)"
  done
fi

# 3. ARCHITECTURE §13 tree against project.json
s13=$(section "$arch" "## 13.")
tree13=$(printf '%s\n' "$s13" | textblock)
if [ -z "$tree13" ]; then
  add FAIL tree "$arch" "§13 has no folder tree (a \`\`\`text block)"
elif [ ! -f "$man" ]; then
  add WARN tree "$man" "no project.json yet: the tree is compared with it after the boundaries step"
else
  # Every path the tree draws, with all its parent folders; {a,b} expands, comments after # are ignored
  paths=$(printf '%s\n' "$tree13" | perl -CSD -ne '
    sub expand { my $s = shift; if ($s =~ /^(.*?)\{([^{}]*)\}(.*)$/) { my ($a, $l, $b) = ($1, $2, $3); return map { expand("$a$_$b") } split /,/, $l, -1 } return ($s) }
    chomp; s/\s+#.*$//; s/^\s*#.*$//;
    my ($pre, $rest) = /^([\x{2502}\x{251C}\x{2514}\x{2500}\s]*)(.*)$/; $rest =~ s/\s+$//;
    next if $rest eq "" || $rest eq ".";
    my $d = int(length($pre) / 4); $d = 1 if $d < 1;
    my $parent = $d > 1 ? ($stack[$d - 1] // "") : "";
    for my $item (split /\s+/, $rest) {
      next if $item =~ /^[\x{2190}-\x{21FF}]/ || $item eq "";
      for my $e (expand($item)) {
        my $dir = $e =~ m{/$}; (my $p = ($parent eq "" ? $e : "$parent/$e")) =~ s{/+}{/}g; $p =~ s{/$}{};
        my @seg = split m{/}, $p; print join("/", @seg[0..$_]), "\n" for 0..$#seg;
        $stack[$d] = $p if $dir;
      }
    }' | sort -u)
  bases=$(jq -r '[(.roles // {} | to_entries[] | select(.value.enabled != false) | .value.paths[]?), ((.shared_files // {}) | keys[]), (.contracts.paths // [] | .[])] | .[]' "$man" 2>/dev/null \
    | sed -e 's#/\*\*$##' -e 's#/\*$##' -e 's#\*\*$##' | grep -v '^$' | sort -u)
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    case "$b" in *'*'*|*'?'*) add WARN tree "$man" "$b: a wildcard inside the path, not compared with the tree"; continue ;; esac
    printf '%s\n' "$paths" | grep -qxF -- "$b" || add FAIL tree "$arch" "§13 tree does not show $b, which project.json gives an owner: add it to the tree (and PRD §11)"
  done <<EOF
$bases
EOF
  # every top-level folder (and every app or package) has an owner
  printf '%s\n' "$paths" | grep -E '^[^/]+$|^(apps|packages|services)/[^/]+$' | grep -vE '^(apps|packages|services|docs|\.claude)$' | while IFS= read -r t; do
    [ -n "$t" ] || continue
    owned=0
    while IFS= read -r b; do
      [ -n "$b" ] || continue
      case "$t" in "$b"|"$b"/*) owned=1; break ;; esac
      case "$b" in "$t"/*) owned=1; break ;; esac
    done <<EOF2
$bases
EOF2
    [ "$owned" -eq 1 ] || echo "$t"
  done > "${TMPDIR:-/tmp}/arch-unowned.$$"
  while IFS= read -r t; do [ -n "$t" ] && add FAIL tree "$arch" "$t is in the §13 tree but has no owner in project.json"; done < "${TMPDIR:-/tmp}/arch-unowned.$$"
  rm -f "${TMPDIR:-/tmp}/arch-unowned.$$"
fi

# 4. Route groups are Next.js syntax
s4=$(section "$arch" "## 4.")
stack_text="$s4 $( [ -f .claude/PROJECT.md ] && cat .claude/PROJECT.md ) $( [ -f "$man" ] && jq -r '.stack // empty | tostring' "$man" 2>/dev/null )"
if [ -z "$(printf '%s' "$stack_text" | tr -d '[:space:]')" ]; then
  add WARN routing "$arch" "no stack found (§4, PROJECT.md, project.json stack): routing check skipped"
elif ! printf '%s' "$stack_text" | grep -qiE 'next\.?js'; then
  { printf '%s\n' "$tree13" | grep -nE '\([a-z][a-z0-9-]*\)/' | sed "s|^|$arch §13 line |"
    printf '%s\n' "$s11" | grep -nE '\([a-z][a-z0-9-]*\)/' | sed "s|^|$prd §11 line |"; } | while IFS= read -r hit; do
    echo "$hit"
  done > "${TMPDIR:-/tmp}/arch-routes.$$"
  while IFS= read -r hit; do
    [ -n "$hit" ] && add FAIL routing "${hit%%:*}" "route-group folders like (auth)/ are Next.js syntax and the stack is not Next.js: use the framework's own routing convention (FOLDER_STRUCTURES §A2 for React Router)"
  done < "${TMPDIR:-/tmp}/arch-routes.$$"
  rm -f "${TMPDIR:-/tmp}/arch-routes.$$"
fi

printf '%s' "$out" | grep . | sort -u
fails=$(printf '%s' "$out" | grep -c '^FAIL' || true); warns=$(printf '%s' "$out" | grep -c '^WARN' || true)
echo "architecture: ${fails} findings, ${warns} warnings"
[ "$fails" -eq 0 ]
