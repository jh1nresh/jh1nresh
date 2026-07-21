#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'profile check failed: %s\n' "$1" >&2
  exit 1
}

for file in README.md SETUP.md AGENTS.md .github/workflows/metrics.yml; do
  [[ -f "$file" ]] || fail "missing $file"
done

if rg -n 'https://github\.com/JhiNResH(?:/|\))' README.md; then
  fail "README contains an unavailable legacy GitHub link"
fi

rg -q 'cron: "17 3 \* \* \*"' .github/workflows/metrics.yml || fail "3D contribution workflow must run once daily away from the top-of-hour load spike"
rg -q 'USERNAME: \$\{\{ github\.repository_owner \}\}' .github/workflows/metrics.yml || fail "3D contribution workflow must use the current repository owner"
rg -q 'git add -- profile-3d-contrib' .github/workflows/metrics.yml || fail "3D contribution workflow must stage only its generated directory"
if rg -q '^[[:space:]]+push:' .github/workflows/metrics.yml; then
  fail "3D contribution workflow must not trigger itself on push"
fi

if unpinned="$(rg -n --pcre2 'uses:\s+\S+@(?![0-9a-f]{40}(?:\s|#|$))' .github/workflows || true)" && [[ -n "$unpinned" ]]; then
  printf '%s\n' "$unpinned" >&2
  fail "third-party actions must use full commit SHAs"
fi

ruby --disable-gems -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path) }' .github/workflows/*.yml

if [[ "${1:-}" == "--links" ]]; then
  while IFS= read -r url; do
    code="$(curl -L -sS -o /dev/null --max-time 20 -A 'Mozilla/5.0' -w '%{http_code}' "$url")"
    [[ "$code" =~ ^[23][0-9][0-9]$ ]] || fail "$url returned HTTP $code"
    printf 'ok %s %s\n' "$code" "$url"
  done < <(ruby --disable-gems -ne 'STDOUT.write($_.scan(/\]\((https?:\/\/[^)]+)\)/).flatten.join("\n") + ($_.match?(/\]\(https?:\/\//) ? "\n" : ""))' README.md | sed '/^$/d' | sort -u)
fi

printf 'profile checks passed\n'
