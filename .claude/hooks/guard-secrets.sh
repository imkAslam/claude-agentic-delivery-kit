#!/usr/bin/env bash
# PreToolUse (Write|Edit|MultiEdit|NotebookEdit|Bash): blocks likely secrets in written content and in staged changes at git commit.
# A line containing "delivery:allow-secret" is skipped (use it only for obviously fake test values).
DL_INPUT="$(cat)"
. "$(dirname "$0")/lib.sh"
dl_has_jq || exit 0
dl_enter_cwd

tool=$(dl_json '.tool_name // empty')
content=""
case "$tool" in
  Write)        content=$(dl_json '.tool_input.content // empty') ;;
  Edit)         content=$(dl_json '.tool_input.new_string // empty') ;;
  MultiEdit)    content=$(dl_json '[.tool_input.edits[]?.new_string] | join("\n")') ;;
  NotebookEdit) content=$(dl_json '.tool_input.new_source // empty') ;;
  Bash)
    cmd=$(dl_json '.tool_input.command // empty')
    is_commit=0
    while IFS= read -r seg; do
      s=$(dl_norm "$seg")
      printf '%s' "$s" | grep -Eq '^git([[:space:]]+-[cC][[:space:]]+[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)' && is_commit=1
    done < <(dl_segments "$cmd")
    [ $is_commit -eq 1 ] || exit 0
    git rev-parse --git-dir >/dev/null 2>&1 || exit 0
    if command -v gitleaks >/dev/null 2>&1; then
      gitleaks protect --staged --no-banner --redact >/dev/null 2>&1
      [ $? -eq 1 ] && dl_block "Commit blocked: gitleaks found a likely secret in the staged changes. Run 'gitleaks protect --staged -v' to see it, move the value to an environment variable, and reference it by name."
    fi
    content=$(git diff --cached -U0 --no-color 2>/dev/null | grep '^+' | grep -v '^+++')
    ;;
  *) exit 0 ;;
esac
[ -n "$content" ] || exit 0

scan=$(printf '%s\n' "$content" | grep -v 'delivery:allow-secret')
placeholder='(example|changeme|change-me|placeholder|your[_-]|xxx|<[^>]+>|\$\{|\$[A-Z_]+|dummy|fake|sample|redacted|\*\*\*|localhost|127\.0\.0\.1|@db:|@postgres:|@mysql:|@redis:)'

hit() { # hit <name> <ere> [skip-placeholders]
  local lines
  lines=$(printf '%s\n' "$scan" | grep -nE -- "$2")
  [ -n "$3" ] && lines=$(printf '%s\n' "$lines" | grep -viE -- "$placeholder")
  lines=$(printf '%s\n' "$lines" | grep -v '^$' | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')
  [ -n "$lines" ] && found="${found}
  - ${1} (line ${lines})"
}

found=""
hit "AWS access key id"         'A(KIA|SIA)[0-9A-Z]{16}'
hit "private key block"         '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
hit "GitHub token"              'gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{50,}'
hit "GitLab token"              'glpat-[A-Za-z0-9_-]{20,}'
hit "Slack token"               'xox[abposr]-[A-Za-z0-9-]{10,}'
hit "Stripe live key"           '(sk|rk)_live_[0-9A-Za-z]{20,}'
hit "Anthropic/OpenAI API key"  'sk-ant-[A-Za-z0-9_-]{20,}|sk-(proj-)?[A-Za-z0-9]{32,}'
hit "Google API key"            'AIza[0-9A-Za-z_-]{35}'
hit "SendGrid key"              'SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}'
hit "credentials in a URL"      '(postgres(ql)?|mysql|mariadb|mongodb(\+srv)?|redis|rediss|amqps?)://[^:@/[:space:]]+:[^@/[:space:]]{3,}@' skip
hit "hardcoded secret value"    '(api[_-]?key|secret|token|passwd|password)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][A-Za-z0-9/+_=.-]{20,}["'"'"']' skip

if [ -n "$found" ]; then
  dl_block "Blocked: the content looks like it contains a secret:${found}" \
    "Store the value in the CI secret store or a git-ignored env file, reference it by environment-variable name, and list the name in .env.example and project.json deploy.required_secrets." \
    "If this is an obviously fake test value, add the marker 'delivery:allow-secret' on that line."
fi
exit 0
