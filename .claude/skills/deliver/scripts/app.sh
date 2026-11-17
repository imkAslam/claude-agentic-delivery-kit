#!/usr/bin/env bash
# app.sh start | stop | test | build | status   [--root <dir>]
# One simple way to run the product locally, with or without Claude. Everything comes from
# .claude/project.json (commands.install, dev, test, build, migrate, seed, services_up, services_down; dev_url).
#   start   start the local services (one database container; SQLite when Docker is not running),
#           install dependencies the first time, run migrations and seeds, start the app, wait until it answers
#   stop    stop the app and the local services (data is kept)
#   test    run the project's tests (the test database lives in the same container, or in SQLite)
#   build   run the production build
#   status  what is running, and in which mode
# Before the app exists it says so in one line. It never edits code and never prints secrets.
# Exit 0 = done · 1 = the command failed (the last lines are shown) · 2 = usage error.
set -uo pipefail

action="${1:-}"; [ $# -gt 0 ] && shift
root=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root="${2:-}"; [ -n "$root" ] || { echo "--root needs a directory" >&2; exit 2; }; shift 2 ;;
    *) echo "usage: app.sh start|stop|test|build|status [--root <dir>]" >&2; exit 2 ;;
  esac
done
case "$action" in start|stop|test|build|status) : ;; -h|--help|help) sed -n 2,12p "$0"; exit 0 ;;
  *) echo "usage: app.sh start|stop|test|build|status [--root <dir>]" >&2; exit 2 ;; esac

[ -n "$root" ] || root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$root" 2>/dev/null || { echo "app: cannot open $root" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "app: jq is required" >&2; exit 2; }

MAN=".claude/project.json"; RUN=".claude/delivery"; PID="$RUN/app.pid"; LOG="$RUN/app.log"; MODE="$RUN/app.mode"
if [ ! -f "$MAN" ]; then
  echo "There is no app yet: the project is not set up (.claude/project.json is written after the architecture is approved)."
  exit 0
fi
cmd() { jq -r --arg k "$1" '.commands[$k] // empty' "$MAN" 2>/dev/null; }
say() { printf '%s\n' "$*"; }
step() { # step "<what, in plain words>" "<command>": run it, show the last lines only when it fails
  local out
  say "• $1"
  if out=$(bash -c "$2" 2>&1); then return 0; fi
  say "  This step failed: $1"
  say "  Command: $2"
  printf '%s\n' "$out" | tail -n 15 | sed 's/^/    /'
  return 1
}
compose_file() { for f in compose.yml compose.yaml docker-compose.yml docker-compose.yaml; do [ -f "$f" ] && { echo "$f"; return 0; }; done; return 1; }
docker_ok() { command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; }
has_services() { [ -n "$(cmd services_up)" ] || compose_file >/dev/null; }
relational() { jq -e '[.services[]?.kind // empty] | map(ascii_downcase) | any(test("postgres|mysql|mariadb|sqlserver|mssql|sqlite"))' "$MAN" >/dev/null 2>&1 \
               || jq -e '(.stack.database // "") | ascii_downcase | test("postgres|mysql|mariadb|sql")' "$MAN" >/dev/null 2>&1; }
running() { [ -f "$PID" ] && kill -0 "$(cat "$PID" 2>/dev/null)" 2>/dev/null; }

services_up() { # decides the mode: docker | sqlite | none. Prints what it did.
  mkdir -p "$RUN"
  if ! has_services; then echo none > "$MODE"; return 0; fi
  if docker_ok; then
    local up; up=$(cmd services_up); [ -n "$up" ] || up="docker compose -f $(compose_file) up -d --wait"
    step "Starting the local services in Docker (one container per service)" "$up" || return 1
    echo docker > "$MODE"; return 0
  fi
  if relational; then
    mkdir -p .data
    export DELIVERY_DB_MODE=sqlite
    [ "$1" = "test" ] && export DATABASE_URL="file:./.data/test.sqlite" || export DATABASE_URL="file:./.data/dev.sqlite"
    say "• Docker is not running, so the app uses a local SQLite file (.data/). Start Docker and run this again to use the real database."
    echo sqlite > "$MODE"; return 0
  fi
  say "Docker is not running, and this project's services have no SQLite fallback."
  say "Start Docker, or put the service addresses in the .env file (see README, Run it locally)."
  return 1
}

case "$action" in
  status)
    mode=$(cat "$MODE" 2>/dev/null || echo "not started")
    if running; then say "The app is running (process $(cat "$PID")) at $(jq -r '.dev_url // "the address in the README"' "$MAN"). Services: $mode."
    else say "The app is not running. Services: $mode."; fi
    exit 0 ;;
  stop)
    if running; then kill "$(cat "$PID")" 2>/dev/null; say "• Stopped the app."; else say "• The app was not running."; fi
    : > /dev/null; [ -f "$PID" ] && : > "$PID"
    if [ "$(cat "$MODE" 2>/dev/null)" = "docker" ] && docker_ok; then
      down=$(cmd services_down); [ -n "$down" ] || { cf=$(compose_file) && down="docker compose -f $cf stop"; }
      [ -z "${down:-}" ] || step "Stopping the local services (your data is kept)" "$down" || exit 1
    fi
    say "Done."; exit 0 ;;
  build)
    b=$(cmd build)
    [ -n "$b" ] || { say "There is no build command yet (project.json → commands.build). The app has not been set up."; exit 0; }
    step "Building the app" "$b" || exit 1
    say "The build succeeded."; exit 0 ;;
  test)
    t=$(cmd test)
    [ -n "$t" ] || { say "There is no test command yet (project.json → commands.test). The app has not been set up."; exit 0; }
    services_up test || exit 1
    say "• Running the tests"
    if out=$(bash -c "$t" 2>&1); then
      printf '%s\n' "$out" | tail -n 6 | sed 's/^/    /'; say "All tests passed."; exit 0
    fi
    printf '%s\n' "$out" | tail -n 25 | sed 's/^/    /'
    say "Some tests failed. The lines above show which ones."; exit 1 ;;
  start)
    d=$(cmd dev)
    [ -n "$d" ] || { say "There is no start command yet (project.json → commands.dev). The app has not been set up."; exit 0; }
    if running; then say "The app is already running at $(jq -r '.dev_url // "the address in the README"' "$MAN")."; exit 0; fi
    services_up start || exit 1
    i=$(cmd install)
    if [ -n "$i" ] && [ ! -f "$RUN/app.installed" ]; then
      step "Installing dependencies (first run only)" "$i" || exit 1
      : > "$RUN/app.installed"
    fi
    m=$(cmd migrate); [ -z "$m" ] || step "Preparing the database (migrations)" "$m" || exit 1
    s=$(cmd seed);    [ -z "$s" ] || step "Adding the sample data" "$s" || exit 1
    say "• Starting the app"
    nohup bash -c "$d" > "$LOG" 2>&1 &
    echo $! > "$PID"
    url=$(jq -r '.dev_url // empty' "$MAN")
    if [ -n "$url" ] && command -v curl >/dev/null 2>&1; then
      n=0
      while [ $n -lt 60 ]; do
        running || { say "  The app stopped while starting. Last lines of its output:"; tail -n 15 "$LOG" | sed 's/^/    /'; exit 1; }
        curl -fsS -o /dev/null --max-time 2 "$url" 2>/dev/null && break
        n=$((n + 1)); sleep 1
      done
      [ $n -lt 60 ] || { say "  The app did not answer at $url within a minute. Last lines of its output:"; tail -n 15 "$LOG" | sed 's/^/    /'; exit 1; }
      say "The app is running: $url"
    else
      say "The app was started. Its output is in $LOG."
    fi
    say "Sample accounts and what to try: README, section \"Run it locally\". Stop it with: app.sh stop"
    exit 0 ;;
esac
