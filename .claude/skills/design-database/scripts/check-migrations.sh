#!/usr/bin/env bash
# check-migrations.sh [--base <git-ref>] [file...]
# Scans migration files for statements that are unsafe for zero-downtime deploys or that lose data.
# Called by the database-reviewer and the integrator (and by backend engineers before committing).
#  - No files given: scans migration files changed between <base> (default HEAD~1) and HEAD,
#    i.e. *.sql, plus files under migration directories.
#  - BLOCK findings → exit 1. WARN findings are printed but don't fail.
#  - A statement containing "migration:allow <reason>" is reported as ALLOWED (contract-phase drops with a runbook step).
# Exit: 0 clean (warnings possible), 1 blocking findings, 2 usage error. Compatible with bash 3.2+.
set -uo pipefail

base="HEAD~1"; files=()
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) files+=("$1"); shift ;;
  esac
done

if [ ${#files[@]} -eq 0 ]; then
  while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$f" ] && files+=("$f")
  done < <(git diff --name-only --diff-filter=AM "${base}...HEAD" 2>/dev/null | grep -Ei '(\.sql$|/migrations?/|/alembic/versions/|/db/migrate/)')
fi
[ ${#files[@]} -gt 0 ] || { echo "check-migrations: no migration files to check"; exit 0; }

blocks=0
for f in "${files[@]}"; do
  [ -f "$f" ] || { echo "check-migrations: not found: $f" >&2; exit 2; }
  out=$(awk -v FILE="$f" '
    BEGIN { RS = ";"; line = 1 }
    {
      stmt = $0; start = line
      n = gsub(/\n/, "\n", stmt); line += n
      s = tolower(stmt)
      allow = (s ~ /migration:allow/)
      # strip SQL line comments per line (before collapsing whitespace), then normalize
      gsub(/--[^\n]*/, "", s)
      gsub(/[ \t\r\n]+/, " ", s)
      sub(/^ +/, "", s)
      if (s ~ /^ *$/) next
      lvl = ""; msg = ""
      if (s ~ /drop table/)                                         { lvl = "BLOCK"; msg = "DROP TABLE loses data: drop only in a contract-phase migration after a backup" }
      else if (s ~ /drop column/)                                   { lvl = "BLOCK"; msg = "DROP COLUMN loses data and breaks the running version: use expand -> migrate -> contract" }
      else if (s ~ /(^| )truncate /)                                { lvl = "BLOCK"; msg = "TRUNCATE deletes all rows" }
      else if (s ~ /alter column [a-z0-9_"]+ (set data )?type /)    { lvl = "BLOCK"; msg = "Column type change rewrites/locks the table: add a new column, dual-write, backfill, switch" }
      else if (s ~ /rename column/ || s ~ /alter table [a-z0-9_."]+ rename to /) { lvl = "BLOCK"; msg = "RENAME breaks the running app version: expand/contract instead" }
      else if (s ~ /add column/ && s ~ /not null/ && s !~ /default/) { lvl = "BLOCK"; msg = "ADD COLUMN NOT NULL without DEFAULT fails on existing rows: add nullable, backfill, then enforce" }
      else if (s ~ /^delete from / && s !~ / where /)               { lvl = "BLOCK"; msg = "DELETE without WHERE" }
      else if (s ~ /^update [a-z0-9_."]+ set / && s !~ / where /)   { lvl = "BLOCK"; msg = "UPDATE without WHERE: backfills must be batched and bounded" }
      else if (s ~ /(drop_column|dropcolumn|drop_table|droptable|removecolumn|renamecolumn|rename_column)/) { lvl = "BLOCK"; msg = "Destructive ORM migration call (drop/rename): use expand -> migrate -> contract" }
      else if (s ~ /create (unique )?index/ && s !~ /concurrently/) { lvl = "WARN";  msg = "CREATE INDEX without CONCURRENTLY locks writes on large tables (PostgreSQL)" }
      else if (s ~ /foreign key/ && s ~ /add constraint/ && s !~ /not valid/) { lvl = "WARN"; msg = "ADD FOREIGN KEY without NOT VALID scans and locks the table: add NOT VALID, then VALIDATE" }
      else if (s ~ /set not null/)                                  { lvl = "WARN";  msg = "SET NOT NULL scans the table: validate a CHECK (col IS NOT NULL) NOT VALID constraint first" }
      else if (s ~ /lock table/)                                    { lvl = "WARN";  msg = "Explicit LOCK TABLE in a migration" }
      else if (s ~ /(price|amount|total|balance|cost)[a-z_]* (real|float|double)/) { lvl = "WARN"; msg = "Money stored as floating point: use integer minor units or numeric" }
      if (lvl != "") {
        if (allow && lvl == "BLOCK") lvl = "ALLOWED"
        snippet = substr(s, 1, 100)
        printf "%s\t%s:%d\t%s\t%s\n", lvl, FILE, start, msg, snippet
      }
    }' "$f")
  if [ -n "$out" ]; then
    printf '%s\n' "$out"
    c=$(printf '%s\n' "$out" | grep -c '^BLOCK' || true)
    blocks=$((blocks + c))
  fi
done

if [ $blocks -gt 0 ]; then
  echo "check-migrations: ${blocks} blocking finding(s). See .claude/skills/design-database/references/MIGRATIONS.md"
  exit 1
fi
echo "check-migrations: OK (${#files[@]} file(s))"
exit 0
