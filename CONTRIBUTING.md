# Contributing to KindredPaws

This repo is built by a **solo founder + AI agents**. The rules below exist so that
both humans and autonomous agents can ship safely without a human reviewer in the
loop, while keeping `main` always releasable.

## 1. Branching model

```
main      ← protected, always releasable, tagged for releases
  ▲
  │ PR (squash, CI-gated)
develop   ← integration branch; default base for day-to-day work
  ▲
  │ PR
feature/* ← one branch per issue/task (also: fix/*, chore/*, ci/*, docs/*)
```

- Branch off `develop` for features: `feature/<issue#>-short-slug`.
- Hotfixes may branch off `main` as `fix/<issue#>-...` and PR back into `main` (then forward-merge to `develop`).
- **Direct pushes to `main` and `develop` are blocked.** All change lands via PR.

## 2. Conventional Commits (required)

PR **titles** (squash-merge uses them) and commits must follow
[Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<optional scope>): <description>

[optional body]
[optional footer(s)]   # e.g. "Closes #123", "BREAKING CHANGE: ..."
```

Allowed types: `feat`, `fix`, `perf`, `refactor`, `docs`, `test`, `build`, `ci`, `deps`, `chore`, `revert`.
This is enforced locally by `commitlint` (via the `commit-msg` pre-commit hook).

## 3. Semantic Versioning + releases

Versioning is automated by **Release Please**:

1. Merging Conventional-Commit PRs into `main` updates an open **release PR**.
2. Merging that release PR bumps `pubspec.yaml`, updates `CHANGELOG.md`, creates the
   GitHub Release, and tags `vX.Y.Z`.
3. The tag triggers `release.yml`, which builds and attaches APK/AAB/iOS artifacts.

`feat` → minor, `fix`/`perf` → patch, `feat!`/`BREAKING CHANGE:` → major (pre-1.0: minor).

## 4. The PR gate (what "ready to merge" means)

A PR is mergeable when **every required check is green**. The required contexts are
exactly these five job names:

- `analyze` — `dart format` clean, `flutter analyze --fatal-infos --fatal-warnings`, lockfile in sync
- `test` — unit + widget + golden + performance, coverage ≥ threshold
- `build-android` — debug APK builds
- `integration-android` — emulator smoke/integration test passes
- `secret-scan` — gitleaks finds no committed secrets (**required** — this is a PUBLIC repo)

Also run on every PR but **advisory / non-blocking**: `dependency-scan` (OSV CVE scan),
`sbom`, `workflow-hardening` (actionlint + yamllint). Promote any to required by adding its
job name to the branch ruleset's `contexts`.

Human approval is **NOT required** (`required_approving_review_count = 0`).

> **Flaky required check?** `integration-android` boots an emulator and can occasionally
> flake. Re-run it with `gh run rerun --failed <run-id>` (find it via `gh pr checks`). Never
> bypass with `--admin`; if it keeps failing, treat it as a real failure and apply
> `agent: needs-human`.

## 5. Agent self-merge policy

An AI agent **may merge its own PR** when **all** of the following hold:

1. All required CI checks are green.
2. The PR is **not** labeled `do-not-merge` or `agent: needs-human`.
3. The PR does not modify a founder-gated path (see `.github/CODEOWNERS`) without an explicit go-ahead.
4. The change is within the current roadmap phase (no scope creep).

Self-merge command (squash):

```bash
gh pr merge <number> --squash --delete-branch
```

If a check is red or anything is uncertain, the agent applies `agent: needs-human`,
comments why, and stops. **Never** disable a check, use admin bypass, or force-merge.

## 6. Local quality gate (run before every PR)

```bash
just verify   # format + analyze + test (the exact PR gate, locally)
```

`just` recipes are the single command surface — CI runs the same commands. See `CLAUDE.md`
for the full agent loop and `tool/` for device automation.

## 7. Definition of Done

- Acceptance criteria met; tests added/updated at the right layer.
- `just verify` green; device-affecting changes validated via `just e2e-android` or screenshots.
- No secrets committed; scope limited to the linked issue.
- PR title is a valid Conventional Commit.
