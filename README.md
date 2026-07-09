# KindredPaws 🐾

> Emotionally intelligent AI virtual-pet mobile game (iOS + Android).
> Adopt a rescued puppy/kitten, raise it with an LLM companion that remembers you, and turn daily care into real-world shelter impact.

[![PR CI](https://github.com/emredogan-cloud/kindredpaws/actions/workflows/pr-ci.yml/badge.svg)](https://github.com/emredogan-cloud/kindredpaws/actions/workflows/pr-ci.yml)
[![Nightly](https://github.com/emredogan-cloud/kindredpaws/actions/workflows/nightly.yml/badge.svg)](https://github.com/emredogan-cloud/kindredpaws/actions/workflows/nightly.yml)
[![Security](https://github.com/emredogan-cloud/kindredpaws/actions/workflows/security.yml/badge.svg)](https://github.com/emredogan-cloud/kindredpaws/actions/workflows/security.yml)

> **Status: Phase 3 (MVP / closed beta) — pre-release remediation in progress.** Phases 0–2 engineering plus two evolution programs (E1–E6, GE-1–GE-7) are complete: an 8-room home, the vector pet on the locked Rive contract, Heartmind memory/dialogue, décor/sets/seasons/minigames, save schema v10 (migrations v1→v10), 644 tests at 91% coverage. The 2026-07-08 pre-App-Store audit ([`PRE_APP_STORE_FINAL_AUDIT_REPORT.md`](PRE_APP_STORE_FINAL_AUDIT_REPORT.md)) verdict is **DO NOT SUBMIT yet** — commerce/backend run on inert seams pending founder provisioning. The active execution backlog is [`PRE_RELEASE_REMEDIATION_ROADMAP.md`](PRE_RELEASE_REMEDIATION_ROADMAP.md) (KP-001…KP-052). See [`game-os/current_state.json`](game-os/current_state.json) for the live phase/gate status.

---

## Repository map

| Path | What it is |
|---|---|
| [`PRE_PHASE0_ENGINEERING_FOUNDATION_MASTER_REPORT.md`](PRE_PHASE0_ENGINEERING_FOUNDATION_MASTER_REPORT.md) | The complete engineering-environment architecture, setup, and readiness checklist. **Start here.** |
| [`CLAUDE.md`](CLAUDE.md) | Operating manual for AI agents working this repo (build/test/ship loop, guardrails). |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Branching, conventional commits, PR rules, the self-merge model. |
| [`game-os/`](game-os/) | Product/design "operating system" (roadmap, gameplay bible, decision log, canonical brief). Design source of truth. |
| `lib/`, `test/`, `integration_test/` | The Flutter app + its unit / widget / golden / integration / performance tests. |
| `tool/` | Agent automation scripts (doctor, emulator boot, E2E drive, screenshots, coverage). |
| `.github/` | CI/CD workflows, issue/PR templates, CODEOWNERS, labels, dependabot, release automation. |
| `Justfile` / `Makefile` | The canonical command surface used by humans, agents, and CI alike. |

## Tech stack (decided)

- **Engine:** Flutter (stable) + Dart — chosen for agent-autonomy & testability (see report §3).
- **Backend:** Firebase (locked at G0, D-049) — auth, Firestore cloud save, Remote Config, Analytics, Crashlytics; no owned servers. Runs on inert mock seams until founder provisioning (see `PRE_RELEASE_REMEDIATION_ROADMAP.md` KP-001).
- **CI/CD:** GitHub Actions (PR / nightly / release / security).
- **Device testing:** local Android emulator (KVM) + **Firebase Test Lab** (cloud Android/iOS) + **Codemagic** (macOS iOS builds). See report §5.

## Quick start

```bash
# 0. one-time: verify the toolchain
just doctor            # or: make doctor

# 1. install deps
just setup

# 2. the inner loop agents/humans use
just format            # dart format
just analyze           # static analysis
just test              # unit + widget + golden + perf, with coverage
just run-android       # boot emulator, run the app

# 3. full E2E with screenshots/video/logcat on a device
just e2e-android
```

The PR-gate recipes (`format-check`, `analyze`, `test`, `build-apk`, `e2e-android`) run the **exact same commands** in CI, so for those, "green locally" means "green in CI". Device/housekeeping recipes (`emulator`, `screenshots`, `clean`, `hooks`, `doctor`, …) are local-only by design.

## Branching & contribution

`main` (protected, releasable) ← PRs ← `feature/*` branches off `develop`.
Direct pushes to `main` are blocked; merges require **CI green** but **no human approval** (AI agents may self-merge after checks pass). Details in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

Proprietary — all rights reserved. See [`LICENSE`](LICENSE).
