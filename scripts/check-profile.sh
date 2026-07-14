#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'profile check failed: %s\n' "$1" >&2
  exit 1
}

for file in README.md SETUP.md AGENTS.md .github/workflows/waka.yml archive/workflows/metrics.yml scripts/update_wakatime.py; do
  [[ -f "$file" ]] || fail "missing $file"
done

[[ "$(grep -c '<!--START_SECTION:waka-->' README.md)" -eq 1 ]] || fail "README must contain one WakaTime start marker"
[[ "$(grep -c '<!--END_SECTION:waka-->' README.md)" -eq 1 ]] || fail "README must contain one WakaTime end marker"

if rg -n 'https://github\.com/JhiNResH(?:/|\))' README.md; then
  fail "README contains an unavailable legacy GitHub link"
fi

rg -q 'python3 scripts/update_wakatime.py' .github/workflows/waka.yml || fail "WakaTime workflow must use the repo-local updater"
rg -q 'WAKATIME_API_KEY: \$\{\{ secrets\.WAKATIME_API_KEY \}\}' .github/workflows/waka.yml || fail "WakaTime secret must stay in the workflow environment"
if rg -q 'GH_TOKEN|waka-readme-stats|SHOW_PROJECTS' .github/workflows/waka.yml; then
  fail "WakaTime workflow reintroduced a PAT or third-party stats action"
fi
rg -q 'user: \$\{\{ github\.repository_owner \}\}' archive/workflows/metrics.yml || fail "archived metrics workflow must not hardcode the legacy owner"

if unpinned="$(rg -n --pcre2 'uses:\s+\S+@(?![0-9a-f]{40}(?:\s|#|$))' .github/workflows || true)" && [[ -n "$unpinned" ]]; then
  printf '%s\n' "$unpinned" >&2
  fail "third-party actions must use full commit SHAs"
fi

ruby --disable-gems -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path) }' .github/workflows/*.yml archive/workflows/*.yml

if [[ "${1:-}" == "--links" ]]; then
  while IFS= read -r url; do
    code="$(curl -L -sS -o /dev/null --max-time 20 -A 'Mozilla/5.0' -w '%{http_code}' "$url")"
    [[ "$code" =~ ^[23][0-9][0-9]$ ]] || fail "$url returned HTTP $code"
    printf 'ok %s %s\n' "$code" "$url"
  done < <(ruby --disable-gems -ne 'STDOUT.write($_.scan(/\]\((https?:\/\/[^)]+)\)/).flatten.join("\n") + ($_.match?(/\]\(https?:\/\//) ? "\n" : ""))' README.md | sed '/^$/d' | sort -u)
fi

printf 'profile checks passed\n'
