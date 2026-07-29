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

if grep -En 'https://github\.com/JhiNResH(/|\))' README.md; then
  fail "README contains an unavailable legacy GitHub link"
fi

grep -Eq 'cron: "17 3 \* \* \*"' .github/workflows/metrics.yml || fail "3D contribution workflow must run once daily away from the top-of-hour load spike"
grep -Eq 'USERNAME: \$\{\{ github\.repository_owner \}\}' .github/workflows/metrics.yml || fail "3D contribution workflow must use the current repository owner"
grep -Eq 'git add -- profile-3d-contrib' .github/workflows/metrics.yml || fail "3D contribution workflow must stage only its generated directory"
grep -Eq '^[[:space:]]+ref: main$' .github/workflows/metrics.yml || fail "3D contribution workflow must check out main"
grep -Eq 'git pull --rebase origin main' .github/workflows/metrics.yml || fail "3D contribution workflow must rebase onto main"
grep -Eq 'gh pr create.*' .github/workflows/metrics.yml || fail "3D contribution workflow must publish generated assets through a pull request"
grep -Eq 'gh workflow run ci\.yml' .github/workflows/metrics.yml || fail "3D contribution workflow must dispatch validation for generated assets"
grep -Eq 'statuses/\$\{head_sha\}' .github/workflows/metrics.yml || fail "3D contribution workflow must publish the successful validation status"
grep -Eq 'gh pr merge.*--auto.*--squash' .github/workflows/metrics.yml || fail "3D contribution workflow must auto-merge validated generated assets into main"
if grep -Eq 'git push origin HEAD:main' .github/workflows/metrics.yml; then
  fail "3D contribution workflow must not bypass the main pull request rule"
fi
grep -Fq 'jh1nresh/jh1nresh/main/profile-3d-contrib/profile-night-rainbow.svg' README.md || fail "README must load the 3D contribution visualization from main"
if grep -R -n --exclude-dir=.git --exclude=check-profile.sh 'profile-assets' README.md SETUP.md .github scripts; then
  fail "profile repository must not depend on the retired profile-assets branch"
fi
if grep -Eq '^[[:space:]]+push:' .github/workflows/metrics.yml; then
  fail "3D contribution workflow must not trigger itself on push"
fi

ruby --disable-gems -e '
  Dir[".github/workflows/*.{yml,yaml}"].each do |path|
    File.foreach(path).with_index(1) do |line, number|
      target = line[/\buses:\s*([^\s#]+)/, 1]
      next unless target
      next if target.start_with?("./", "docker://")
      ref = target.split("@", 2)[1]
      abort "#{path}:#{number}: unpinned action #{target}" unless ref&.match?(/\A[0-9a-f]{40}\z/)
    end
  end
'

ruby --disable-gems -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path) }' .github/workflows/*.yml

if [[ "${1:-}" == "--links" ]]; then
  while IFS= read -r url; do
    code="$(curl -L -sS -o /dev/null --max-time 20 -A 'Mozilla/5.0' -w '%{http_code}' "$url")"
    [[ "$code" =~ ^[23][0-9][0-9]$ ]] || fail "$url returned HTTP $code"
    printf 'ok %s %s\n' "$code" "$url"
  done < <(ruby --disable-gems -ne 'STDOUT.write($_.scan(/\]\((https?:\/\/[^)]+)\)/).flatten.join("\n") + ($_.match?(/\]\(https?:\/\//) ? "\n" : ""))' README.md | sed '/^$/d' | sort -u)
fi

printf 'profile checks passed\n'
