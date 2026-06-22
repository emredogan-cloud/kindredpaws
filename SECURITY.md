# Security Policy

## This is a PUBLIC repository

Treat everything here as world-readable, forever. **Never commit secrets** —
keystores, `*.p8`/`*.p12`, `google-services.json`, `GoogleService-Info.plist`,
service-account JSON, API keys, or `.env` files. These are blocked by
`.gitignore` and scanned by `gitleaks` on every PR, but the first line of
defense is you/the agent.

All secrets live in **GitHub Actions Secrets** (and, for runtime, the backend's
secret manager). The Android signing flow consumes:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
`ANDROID_KEY_PASSWORD`. iOS signing uses fastlane match (separate private repo).

## Automated controls (see .github/workflows/security.yml)

- **Secret scanning** — gitleaks (full history on PRs)
- **Dependency vulnerabilities** — OSV-Scanner over `pubspec.lock` (SARIF → code scanning)
- **SBOM** — SPDX generated via Syft on every run
- **Workflow hardening** — actionlint over all workflow files
- **Dependency updates** — Dependabot (pub, github-actions, gradle)

## Reporting a vulnerability

Use **GitHub → Security → Report a vulnerability** (private advisory) or email
the founder. Please do not open a public issue for sensitive reports. We aim to
acknowledge within 72 hours.

## Supported versions

Pre-release (`0.x`). Only the latest `main` is supported until the first GA tag.
