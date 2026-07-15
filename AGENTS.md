# AGENTS.md - GitHub Profile

Repo rails for agents editing Jerry Chen's public GitHub profile.

## Before Editing

- Confirm the branch and dirty state with `git status --short --branch`.
- Read `README.md`, `SETUP.md`, and the workflows before changing public claims.
- Treat the legacy profile checkout as read-only evidence. Never edit it from this repo.
- Preserve the profile's proof-first tone. Do not add typing animations, profile-view counters, uncurated badge walls, or unsupported metrics. A compact Languages & Tools badge table is allowed when every item matches the verified current stack.
- Do not restore a source link until the destination is public and returns a successful response.

## Public Content Boundaries

- Every claim must be supported by a live product, public artifact, or verified local history.
- Never publish local paths, tokens, secret values, private repository names, or customer data.
- Keep `JhiNResH` as historical identity text only; do not add links to the unavailable account or repositories.

## Verification

Run:

```bash
./scripts/check-profile.sh
./scripts/check-profile.sh --links
git diff --check
```

The profile script checks README/workflow invariants. The `--links` command also verifies every public HTTP link in the README.

Never claim verification passed if a command was not run. Report skipped checks with the exact reason.

## Boundaries

- Do not publish, merge, change repository visibility, trigger a workflow, or change account permissions without explicit action-time approval.
- Keep third-party GitHub Actions pinned to full commit SHAs.

## Done Criteria

A handoff is complete only when it includes changed files, verification evidence, skipped checks, residual risk, and commit/publish status.
