# Profile repository setup

This repository preserves the Git history and public profile material previously maintained under `JhiNResH`. The active profile repository must be named exactly `jh1nresh` under the `jh1nresh` account for GitHub to render `README.md` on the profile page.

## Initial publication

1. Create an empty public repository named `jh1nresh`. Do not initialize it with a README, license, or `.gitignore`.
2. Authenticate GitHub CLI as the `jh1nresh` account and verify the active login before pushing.
3. Push the reviewed profile branch to `main` only after `./scripts/check-profile.sh --links` passes.

The local repository already points `origin` at:

```text
https://github.com/jh1nresh/jh1nresh.git
```

## 3D contribution visualization

The active `.github/workflows/metrics.yml` refreshes the 3D contribution SVGs once per hour and also supports manual runs. It uses GitHub's built-in short-lived token, so no additional secret is required.

The workflow is limited to scheduled and manual triggers, stages only `profile-3d-contrib`, and pins every third-party action to a full commit SHA. Review those pins before changing action versions.

## Local verification

```bash
./scripts/check-profile.sh
./scripts/check-profile.sh --links
git diff --check
```
