# KindredPaws — Pre-Phase-0 Engineering Foundation · Master Report

**Status:** ✅ Foundation built & validated · **Date:** 2026-06-22
**Engine decision:** Flutter (stable) + Dart · **Repo:** `emredogan-cloud/kindredpaws` (public)
**Scope:** engineering environment only — **no gameplay implemented** (see Hard Stop, §14).

This is the single source of truth for *how KindredPaws gets built, tested, and shipped*.
It is intentionally honest about what is **verified working on this machine** vs. what is
**documented for CI / macOS / the founder to action**. Markers used throughout:

- ✅ **VERIFIED** — installed and exercised successfully on this host during setup.
- 🟡 **READY** — configured/scripted; runs in CI or on first use (not exercised here).
- 📋 **DOCUMENTED** — cannot be done in this Linux sandbox (needs `sudo`/macOS/credentials); exact steps given.

---

## 0. TL;DR — what an agent can do *right now*

After cloning and running `just doctor`, a future Claude agent can autonomously:

| Capability | How | Status |
|---|---|---|
| Write code | `lib/`, structured per `CLAUDE.md` | ✅ |
| Run all tests | `just test` (unit/widget/golden/perf, coverage gate) | ✅ 31 tests, 76.4% (as of Phase 0; 6 tests @ 93.3% at the close of Pre-Phase-0) |
| Static analysis | `just analyze` (`--fatal-infos --fatal-warnings`) | ✅ clean |
| Boot an emulator | `just emulator` (KVM AVD `kp_pixel_api34`) | ✅ |
| Build an APK | `just build-apk` / release variants | ✅ built in ~47s |
| Build an IPA | `release.yml` / Codemagic (macOS) | 📋 CI/macOS |
| Drive UI + screenshot + video + logcat | `just e2e-android` | ✅ artifacts captured |
| Detect crashes | `android_e2e.sh` greps logcat for FATAL/ANR | ✅ |
| Open a PR | `gh pr create` (Conventional-Commit title) | ✅ gh authed |
| Merge a PR after CI | `gh pr merge --squash` (no human review required) | ✅ ruleset live & verified |
| Ship a release | Release Please → tag → `release.yml` artifacts | 🟡 configured |

---

## 1. Host environment (ground truth)

Probed and recorded on 2026-06-22:

| Item | Value |
|---|---|
| OS | Ubuntu 24.04.4 LTS, kernel 6.17 |
| CPU / RAM / Disk | 12 cores / 15 GiB / 629 GiB free |
| Virtualization | `/dev/kvm` present **and writable** → HW-accelerated Android emulator works |
| `sudo` | **Not available non-interactively** → no `apt` installs; everything is user-space |
| Network egress | github.com, pub.dev, dl.google.com reachable |
| `gh` auth | ✅ `emredogan-cloud`, scopes `repo`, `workflow`, `read:org`, `gist` |
| git identity | `emredogan-cloud` / `ed897854@gmail.com` |

### 1.1 Toolchain inventory

**Pre-existing & ✅ VERIFIED:** Flutter 3.41.9 (stable, `~/dev/flutter`), Dart 3.11.5,
git 2.43, gh 2.45, OpenJDK 17, adb 1.0.41, jq 1.7, ripgrep 14.1, tree, GNU make 4.3,
uv 0.11, Node 24.13 + npm/pnpm/yarn, Docker 29.5, curl/wget/unzip, python3.12.

**Installed during setup (user-space) & ✅ VERIFIED:**

| Tool | Version | Location | Method |
|---|---|---|---|
| fd | 10.4.2 | `~/.local/bin` | GitHub release |
| just | 1.53.0 | `~/.local/bin` | GitHub release |
| shellcheck | latest | `~/.local/bin` | GitHub release |
| actionlint | 1.7.12 | `~/.local/bin` | GitHub release |
| act | 0.2.89 | `~/.local/bin` | GitHub release |
| pre-commit | 4.6.0 | uv tool | `uv tool install` |
| yamllint | 1.38.0 | uv tool | `uv tool install` |
| gcloud | 573.0.0 | `~/google-cloud-sdk` | tarball (no sudo) |
| firebase-tools | 15.22.0 | `~/.npm-global` | `npm i -g` (user prefix) |
| Android SDK | cmdline-tools + platform-tools 37 + platforms 33–36 + build-tools + **emulator 36.6.11** + system-image `android-34;google_apis;x86_64` | `~/Android/Sdk` | sdkmanager (no sudo) |
| AVD | `kp_pixel_api34` (Pixel 6, API 34) | `~/.android/avd` | avdmanager |

**📋 NOT installable on this host (documented for CI/macOS):**

- **Ruby + fastlane** — Ruby needs `apt` (no sudo). Used only in CI/CD for store delivery; runs on the macOS/Codemagic side. Install on a Mac with `brew install fastlane` or `gem install fastlane`.
- **Xcode / xcodebuild / CocoaPods** — macOS-only. iOS builds happen on `macos-latest` runners and Codemagic (§5).

### 1.2 Shell PATH (add to `~/.profile` / `~/.bashrc`)

```bash
export PATH="$HOME/dev/flutter/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/google-cloud-sdk/bin:$HOME/Android/Sdk/platform-tools:$HOME/Android/Sdk/cmdline-tools/latest/bin:$HOME/Android/Sdk/emulator:$PATH"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export ANDROID_HOME="$HOME/Android/Sdk"
```

> The `Justfile`, `Makefile`, and every `tool/*.sh` already prepend these paths, so the
> command surface works even if the profile isn't sourced. The export above is for
> interactive shells.

---

## 2. Engine decision — Flutter (not Unity)

**Decision: Flutter (stable channel) + Dart.** This resolves Open Decision #1 from
`game-os/` for the *engineering* dimension; the design docs already biased toward the
mainstream, AI-codegen-friendly stack.

| Criterion | Flutter | Unity |
|---|---|---|
| Agent autonomy on **Linux** | Full CLI: analyze/test/build/drive headless | License activation in CI, heavy installs, weaker Linux story |
| Test toolchain | Built-in unit/widget/golden/integration + coverage | Test Framework exists but slower, less agent-friendly |
| Headless CI | First-class (`subosito/flutter-action`) | GameCI works but heavier, licensing friction |
| Iteration speed | Hot reload, fast `flutter test` | Slower domain reloads |
| 2D cozy pet UI | Excellent; widgets + animation | Excellent, but heavier than needed |
| **Already installed here** | ✅ Yes | ❌ No |

**Animation caveat (carry into Phase 0 / G0):** the design docs assume **Live2D Cubism**.
Live2D's Flutter runtime is less mature than Unity's. The de-risked Flutter-native path is
**Rive** (vector skeletal animation, first-class Flutter runtime) for the pet rig, with
Live2D-via-platform-view as a fallback. This is a *content/animation* decision flagged in
`game-os/GAME_CONTENT_FACTORY.md`; it does **not** block the engineering foundation.

---

## 3. Repository architecture

Public monorepo at `emredogan-cloud/kindredpaws`. `git init` on `main`; `develop` is the
integration branch.

```
kindredpaws/
├── PRE_PHASE0_ENGINEERING_FOUNDATION_MASTER_REPORT.md   ← this file
├── README.md                 ← overview + quick start + badges
├── CLAUDE.md                 ← agent operating manual (build/test/ship loop, guardrails)
├── CONTRIBUTING.md           ← branching, conventional commits, self-merge policy
├── SECURITY.md               ← secret hygiene, scanning, disclosure
├── LICENSE                   ← proprietary (source-viewable, not OSS)
├── Justfile / Makefile       ← THE command surface (CI runs these exact recipes)
├── pubspec.yaml / .lock      ← Flutter app manifest (version mgmt via release-please)
├── analysis_options.yaml     ← strict static-analysis config
├── dart_test.yaml            ← test tag declarations (golden, performance)
├── commitlint.config.js      ← Conventional Commits rules
├── .pre-commit-config.yaml   ← local guardrails mirrored by CI
├── .yamllint.yaml .editorconfig .gitattributes .gitignore .env.example
├── release-please-config.json / .release-please-manifest.json
├── lib/
│   ├── main.dart             ← walking-skeleton app (env-check screen, NO gameplay)
│   └── src/build_info.dart   ← trivial pure-Dart target for the unit layer
├── test/
│   ├── unit/        widget/        golden/ (+ goldens/home.png)        performance/
├── integration_test/app_smoke_test.dart   ← on-device E2E
├── tool/                     ← agent automation (doctor, emulator, e2e, screenshots, coverage)
├── .github/
│   ├── workflows/   pr-ci · nightly · release · security · release-please · labels-sync
│   ├── ISSUE_TEMPLATE/   bug · feature · agent_task · config
│   ├── pull_request_template.md · CODEOWNERS · dependabot.yml · labels.yml
└── game-os/                  ← product/design "operating system" (pre-existing)
```

### 3.1 Branching & governance

```
main      protected · always releasable · tagged for releases
  ▲ PR (squash, CI-gated, 0 approvals required)
develop   integration branch · default base for feature work
  ▲ PR
feature/* one branch per issue (also fix/* chore/* ci/* docs/*)
```

- **Direct pushes to `main`/`develop` blocked.** All change via PR.
- **No mandatory human review** (`required_approving_review_count = 0`) → **AI agents self-merge** once CI is green (`gh pr merge --squash`).
- **CI must be green to merge** (required status checks). Agents must never use `--admin` to bypass; CODEOWNERS pings the founder on sensitive paths (workflows, signing, `game-os/`).
- **Conventional Commits** enforced by commitlint (commit-msg hook). **SemVer** automated by Release Please.

Full rules: `CONTRIBUTING.md`; agent rules: `CLAUDE.md`.

### 3.2 GitHub settings applied (and how to re-apply)

**Branch protection** (classic, applied to `main`; lighter on `develop`):

```bash
gh api -X PUT repos/emredogan-cloud/kindredpaws/branches/main/protection \
  --input - <<'JSON'
{
  "required_status_checks": { "strict": true,
    "contexts": ["analyze","test","build-android","integration-android","secret-scan"] },
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 0,
    "dismiss_stale_reviews": false, "require_code_owner_reviews": false },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
```

`develop` gets the same gate (block direct pushes; require the same five checks):

```bash
gh api -X PUT repos/emredogan-cloud/kindredpaws/branches/develop/protection --input - <<'JSON'
{ "required_status_checks": { "strict": true,
    "contexts": ["analyze","test","build-android","integration-android","secret-scan"] },
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null, "allow_force_pushes": false, "allow_deletions": false }
JSON
```

- `enforce_admins:false` keeps an emergency founder bypass; policy forbids agents from using it.
- **Five required contexts:** the four `pr-ci.yml` jobs + `secret-scan` (gitleaks, from `security.yml`). `dependency-scan`/`sbom`/`workflow-hardening` run on PRs but are **advisory** (non-blocking).
- **Labels** are declarative (`.github/labels.yml`) and auto-synced by `labels-sync.yml`.
- **Milestones** seeded for Pre-Phase-0 → Phase 3 (created via `gh api`).
- Recommended repo toggles: squash-merge only; auto-delete head branches; Dependabot + secret scanning + push protection ON (Settings → Code security).

---

## 4. CI/CD design (Step 2)

All pipelines pin **Flutter 3.41.9 / stable**, cache pub+SDK, set least-privilege
`permissions:`, use `concurrency` to cancel superseded runs, fail-fast, and emit
`::error::` annotations for actionable logs. All workflows pass `actionlint` + `yamllint`.

### 4.1 `pr-ci.yml` — every PR (the merge gate)

| Job (required check) | Does |
|---|---|
| `analyze` | `flutter pub get`, lockfile-in-sync check, `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos --fatal-warnings` (lints + dead/unused code fatal) |
| `test` | unit + widget + golden + performance with coverage; **fails below `MIN_COVERAGE=60%`** (Python lcov parser); uploads `lcov.info` |
| `build-android` | `flutter build apk --debug` (build verification); uploads APK |
| `integration-android` | KVM emulator (API 34) via `reactivecircus/android-emulator-runner`; runs `integration_test` smoke |

Covers the Step-2 PR checklist: formatting, linting, static analysis, dead-code (fatal
unused lints), dependency validation (lockfile sync), unit/widget/integration/smoke, coverage,
build verification. The merge gate also requires **`secret-scan`** (gitleaks, from §4.4);
`dependency-scan`/`sbom`/`workflow-hardening` run on every PR but are advisory.

### 4.2 `nightly.yml` — 03:00 UTC

Full regression (incl. golden/perf tags), **golden screenshot-diff** (uploads diffs on
failure), dependency/outdated audit, and a build matrix (**Android on Linux + iOS on
`macos-latest`, no-codesign**) producing artifacts.

### 4.3 `release.yml` — on `v*.*.*` tag

Android release **APK + AAB** (conditional signing if `ANDROID_KEYSTORE_BASE64` secret set,
else unsigned), iOS `--no-codesign` archive, both attached to the GitHub Release.

### 4.4 `security.yml` — PR + push + 04:00 UTC

**gitleaks** (`secret-scan`, full history, **merge-blocking**), **OSV-Scanner** over `pubspec.lock`
(`dependency-scan`, SARIF → code scanning, advisory), **SBOM** (SPDX via Syft, uploaded),
**actionlint + yamllint** (`workflow-hardening`).
> *CodeQL is intentionally omitted — it has no Dart analyzer (Dart isn't a CodeQL-supported
> language). Coverage split: `dependency-scan` (OSV) flags known CVEs in **third-party** Pub
> deps; `flutter analyze` covers **first-party** lint/type safety; there is no SAST equivalent
> to CodeQL for first-party Dart — an accepted, documented gap. Only `secret-scan` (gitleaks)
> is merge-blocking; `dependency-scan`/`sbom` are advisory.*

### 4.5 `release-please.yml` + `labels-sync.yml`

Release Please maintains a release PR on `main`; merging it bumps `pubspec.yaml`, writes
`CHANGELOG.md`, creates the Release + tag (→ triggers `release.yml`). Labels sync on change.

---

## 5. Device testing strategy (Steps 4 & 5)

**Constraint:** Linux cannot run Apple's iOS Simulator, and iOS builds require macOS + Xcode.
So Android is local; iOS is cloud.

### 5.1 Cloud options evaluated

| Option | iOS build | Real-device tests | Agent/CLI-friendly | Cost model | Verdict |
|---|---|---|---|---|---|
| **Firebase Test Lab** | iOS needs an **XCTest .zip** (xctestrun + app bundle, built on macOS); IPA only for game-loop tests | ✅ Android **and iOS** real + virtual | ✅ `gcloud firebase test` (scriptable, artifacts to GCS) | pay-per-minute, free daily quota | **Primary device-test cloud** |
| **Codemagic** | ✅ builds IPA on macOS M-series, fastlane match signing | ✅ via integrations | ✅ `codemagic.yaml`, API | 500 free macOS min/mo | **Primary iOS build/CD** |
| BrowserStack App Automate | ✅ (upload IPA) | ✅ huge device farm | ✅ REST/CLI | subscription | Alt — manual/interactive QA |
| LambdaTest | ✅ (upload IPA) | ✅ | ✅ | subscription | Alt — cheaper BrowserStack-like |
| MacStadium / Mac mini | ✅ full control | ✅ local sim | ⚙️ you operate it | fixed monthly / capex | Long-term if iOS volume is high |

### 5.2 Recommendation (long-term)

1. **iOS builds & CD → Codemagic** (managed macOS, fastlane match, App Store/TestFlight upload). Cheapest path to "agents ship iOS" without owning a Mac. `release.yml`'s `macos-latest` job is the GitHub-native fallback.
2. **Device test runs (both platforms) → Firebase Test Lab**, driven by `gcloud` (already installed) — agents trigger runs and pull screenshots/video/logcat from GCS:
   ```bash
   gcloud firebase test android run \
     --type instrumentation --app app-debug.apk --test app-debug-androidTest.apk \
     --device model=oriole,version=34 --results-bucket gs://kindredpaws-ci
   gcloud firebase test ios run \
     --test KindredPaws.zip --device model=iphone14,version=17.0
   ```
   > Device model IDs and OS versions rotate — resolve current ones first with
   > `gcloud firebase test ios models list` / `... ios versions list` (and the `android`
   > equivalents). The `--test KindredPaws.zip` above is an XCTest bundle, not an IPA.
3. **Interactive/manual QA → BrowserStack or LambdaTest** when a human wants to poke a real device.
4. **Own a Mac mini / MacStadium** only once iOS build minutes or test volume make managed pricing the bottleneck.

This gives full autonomous iOS coverage (build on Codemagic → test on Firebase Test Lab → artifacts to the agent) with **zero local macOS**.

### 5.3 Android local (Step 6) — ✅ VERIFIED working here

Exact commands (all wrapped by `just`/`tool/`):

```bash
# one-time SDK (already done on this host):
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" \
           "emulator" "system-images;android-34;google_apis;x86_64"
avdmanager create avd -n kp_pixel_api34 -k "system-images;android-34;google_apis;x86_64" -d pixel_6

just emulator      # boot AVD headless (KVM), wait for sys.boot_completed
just run-android   # flutter run -d emulator-5554
just e2e-android   # build+install+drive integration_test; capture screenshots/video/logcat; fail on FATAL/ANR
just screenshots   # launch app, adb screencap → screenshots/home.png
```

Raw adb the scripts rely on: `adb wait-for-device`, `adb shell getprop sys.boot_completed`,
`adb install -r app-debug.apk`, `adb exec-out screencap -p > x.png`,
`adb shell screenrecord --time-limit 170 /sdcard/x.mp4`, `adb logcat`.

---

## 6. Automated testing environment (Step 4) — ✅ VERIFIED

Five layers; add tests at the lowest layer that proves the behavior:

| Layer | Path | Runs on | Verified |
|---|---|---|---|
| unit | `test/unit/` | host | ✅ 2 tests |
| widget | `test/widget/` | host | ✅ 2 tests |
| golden/snapshot | `test/golden/` (+ `goldens/home.png`, Linux-rendered to match CI) | host | ✅ 1 test |
| performance smoke | `test/performance/` | host | ✅ 1 test (2s budget) |
| integration/E2E | `integration_test/` | device/emulator | ✅ on `kp_pixel_api34` |

**Local validation results (this host):** `flutter analyze` → *No issues found*; `flutter test`
→ **6/6 passed, 93.3% line coverage** (gate 60%); `flutter build apk --debug` → built in ~47s;
`just e2e-android` → emulator booted, app driven, **e2e.mp4 + logcat.txt + final.png** captured,
exit 0. `actionlint`, `yamllint`, `shellcheck` → all clean.

Agents detect crashes by grepping logcat for `FATAL EXCEPTION|ANR in|signal 11|libc: Fatal`
(in `tool/android_e2e.sh`) and validate flows via `integration_test` assertions.

---

## 7. Agent tooling (Step 7)

Installed & verified (§1.1): git, gh, jq, ripgrep, fd, tree, just, make, uv, pre-commit,
act, yamllint, actionlint, shellcheck, firebase, gcloud, docker, node/npm/pnpm.

Install commands (reproducible, no sudo):

```bash
# prebuilt binaries → ~/.local/bin
for repo_pat in "sharkdp/fd:*x86_64-unknown-linux-gnu.tar.gz" \
                "casey/just:*x86_64-unknown-linux-musl.tar.gz" \
                "koalaman/shellcheck:*linux.x86_64.tar.xz" \
                "rhysd/actionlint:*linux_amd64.tar.gz" \
                "nektos/act:*Linux_x86_64.tar.gz"; do
  gh release download --repo "${repo_pat%%:*}" --pattern "${repo_pat##*:}" --dir /tmp/dl --clobber
  # extract → cp binary → ~/.local/bin  (see commit history for the exact unpack)
done
uv tool install pre-commit && uv tool install yamllint
npm config set prefix ~/.npm-global && npm i -g firebase-tools
curl -fsSL https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz \
  | tar -xz -C ~ && ~/google-cloud-sdk/install.sh -q --path-update false
```

**Recommended additions for more autonomy** (not yet installed): `lcov`+`genhtml`
(HTML coverage; needs apt), `dcm`/`dart_code_metrics` (deeper metrics), `patrol` (richer
Flutter native E2E), `melos` (only if this becomes a multi-package monorepo), `gh`
extensions `gh-dash` (PR triage). `fastlane` belongs on the macOS/Codemagic side.

Install git hooks: `just hooks` (`pre-commit install` for pre-commit/commit-msg/pre-push).
Run CI locally: `just ci-local` (`act`, needs Docker — present).

---

## 8. Observability (Step 8)

**Local / dev (agent-inspectable):**

- `flutter run` + **DevTools** (CPU/memory/widget-rebuild/timeline), `adb logcat`, `flutter logs`.
- Performance: `integration_test` + `flutter drive --profile` → timeline JSON; the
  `test/performance` budget as a coarse host gate.
- Startup time: `adb shell am start -W <activity>` reports `TotalTime`/`WaitTime`.
- Memory: `adb shell dumpsys meminfo <app>`; crashes: logcat `FATAL`/tombstones.

**Cloud (recommended for Phase 0+):**

1. **Firebase Crashlytics** — crash/ANR aggregation (pairs with the chosen Firebase backend). Primary.
2. **Firebase Performance Monitoring** — startup time, network, custom traces.
3. **Sentry (`sentry_flutter`)** — richer error grouping + release health; use instead of/alongside Crashlytics if you want one tool across client+backend.
4. **GA4 / Firebase Analytics** — funnels (ties to the KPIs in `game-os/`).
5. CI observability: artifacts (coverage, SBOM, screenshots, golden diffs) + GitHub Actions run history; add a status dashboard later (`gh-dash`).

> Wire-up is **Phase 0** work (it touches app code), so it is documented here, not implemented
> (Hard Stop, §14). The DSN/keys go in Actions Secrets + the backend secret manager — never the client repo.

---

## 9. Exact setup — reproduce on a fresh machine

```bash
# 1. clone
gh repo clone emredogan-cloud/kindredpaws && cd kindredpaws
# 2. PATH (see §1.2) → add to ~/.profile, then: source ~/.profile
# 3. verify toolchain
just doctor
# 4. deps + hooks
just setup && just hooks
# 5. quality gate
just verify           # format-check + analyze + test (coverage ≥ 60%)
# 6. device loop
just emulator && just e2e-android
# 7. open & merge work (after CI green)
git switch -c feature/123-thing && ... && gh pr create --base develop --fill
gh pr checks --watch && gh pr merge --squash --delete-branch
```

macOS-only (iOS), 📋: install Xcode + CocoaPods + `brew install fastlane`; `cd ios && pod install`;
`flutter build ipa`. Prefer Codemagic so no local Mac is required.

---

## 10. Risks & mitigations

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | **Public repo leaks a secret** | High | `.gitignore` blocks key types; gitleaks on every PR + push-protection; secrets only in Actions Secrets; `SECURITY.md`. |
| R2 | Self-merging agent ships a regression | High | Required CI gate (analyze/test/build/integration) blocks red merges; agents forbidden from `--admin`; CODEOWNERS pings founder on sensitive paths; nightly regression. |
| R3 | iOS toolchain absent locally | Med | Codemagic + FTL + `macos-latest` runners; documented; no local Mac needed. |
| R4 | Emulator CI flakiness/time | Med | `android-emulator-runner` w/ KVM + caching; integration is one fast smoke; re-run on flake; heavy device runs go to nightly/FTL. |
| R5 | Golden tests differ across OS | Med | Goldens generated on Linux to match Ubuntu CI; regenerate via `just goldens-update`; diffs uploaded by nightly. |
| R6 | **Bus factor = 1 GitHub account** | Med | Document recovery; add a second admin/owner; store recovery codes; consider a `kindredpaws` org. |
| R7 | LLM/runtime cost later | Med | Out of scope now; `game-os/` already gates LLM cost; keys server-side only. |
| R8 | No `sudo` on dev host | Low | Everything user-space & reproducible; documented. |
| R9 | Pinned action/tool versions drift | Low | Dependabot (actions+pub+gradle) weekly; `pre-commit autoupdate`. |
| R10 | First Release Please run nuances | Low | Manifest seeded at 0.1.0; verify the first release PR before merging. |

---

## 11. Recommendations (priority order)

1. **Turn on GitHub Advanced Security toggles** (Settings → Code security): secret-scanning **push protection**, Dependabot alerts, code scanning. (Free for public repos.)
2. **Add a second repo admin / create a `kindredpaws` org** to fix the bus-factor (R6).
3. **Provision Firebase project early** (backend + Crashlytics + Test Lab) so device-cloud and observability are ready when Phase 0 starts.
4. **Set up Codemagic** + `fastlane match` (private certs repo) before the first iOS TestFlight.
5. **Confirm the engine/animation choice at G0** (Flutter ✓; Rive vs Live2D for the rig).
6. **Keep the command surface canonical** — any new command goes in the `Justfile` so humans, agents, and CI stay in lock-step.

---

## 12. Validation evidence (what was actually run)

- `flutter analyze --fatal-infos --fatal-warnings` → **No issues found**.
- `flutter test --coverage` → **6/6 passed**; `tool/coverage_report.sh` → **93.3%** (≥60%).
- Golden generated (`test/golden/goldens/home.png`, 27 KB) and verified.
- `flutter build apk --debug` → **app-debug.apk built (~47s)**.
- `just e2e-android` → AVD booted (KVM, headless), app installed & driven, **e2e.mp4 + logcat.txt + final.png** captured, **exit 0**, no crash.
- `actionlint` ✓, `yamllint` ✓, `shellcheck -S style` ✓ (all clean).
- 116 files staged; secret/large-file sanity scan → clean; `build/` & `.dart_tool/` excluded.
- **Adversarial verification pass** (5 independent reviewers) run against this foundation; all
  high/critical findings fixed and re-validated (notably the Android release-signing wiring below).
- **Release-signing fix verified:** with a throwaway `key.properties`, `flutter build apk --release`
  produced an APK signed by the **release** key (`apksigner`: `V2 Signer: certificate DN:
  CN=KindredPaws Release Test`), not the debug key; throwaway keystore removed (untracked).
- **GitHub state (post-push, verified live):** `main` + `develop` pushed; branch protection on
  **both** with required contexts `[analyze, test, build-android, integration-android, secret-scan]`,
  PR required, 0 approvals, linear history, no force-push; squash-only + auto-delete branches;
  secret-scanning push-protection on; **28 labels synced** (22 custom); 5 milestones; Release
  Please + Security green on bootstrap; validation PR **#5** opened for founder approval.

---

## 13. Final readiness checklist

Foundation is complete when future Claude agents can autonomously do all of the below:

- [x] **Write code** — structured app + `CLAUDE.md` operating manual.
- [x] **Run tests** — `just test`, 5 layers, coverage-gated. ✅ verified.
- [x] **Launch emulators/devices** — `just emulator` (KVM AVD). ✅ verified.
- [x] **Build APK** — `just build-apk`. ✅ verified. **Build IPA** — `release.yml`/Codemagic. 🟡/📋.
- [x] **Analyze failures** — analyzer fatal, logcat crash-grep, golden diffs, CI annotations. ✅
- [x] **Take screenshots/videos** — `tool/android_e2e.sh` ✅ verified (artifacts captured); `capture_screenshots.sh` 🟡 ready (wired, not independently run).
- [x] **Open PRs** — `gh` authed, templates + Conventional-Commit gate. ✅
- [x] **Merge PRs** — ruleset CI-gated, 0 approvals, self-merge allowed. ✅ applied & verified (main + develop; 5 required contexts).
- [x] **Safely ship releases** — Release Please + `release.yml`. ✅ Release Please ran green on bootstrap; 🟡 first tagged release pending.
- [x] **CI/CD** — pr-ci/nightly/release/security all lint-clean. ✅ live (Release Please + Security green on bootstrap; PR CI running on validation PR #5).
- [x] **Quality guardrails** — pre-commit, commitlint, dependabot, gitleaks/OSV/SBOM. 🟡/✅.
- [x] **Device cloud strategy** — FTL + Codemagic decided & documented. 📋 provision when needed.
- [x] **Observability** — local verified; cloud (Crashlytics/Perf/Sentry) documented for Phase 0. 📋

**Outstanding founder actions** (credential/account-gated, cannot be done autonomously):
provision Firebase project; set up Codemagic + signing secrets; enable GHAS toggles;
add a second admin/org (R6).

---

## 14. HARD STOP

Per the engagement: the environment is complete; **Phase 0 has NOT begun.** No gameplay,
no game systems, no roadmap features, no future-phase placeholders were created. The only
app code is the gameplay-free **walking skeleton** required to validate the build/test/device/
CI/release pipeline. The next action awaits **explicit founder approval**.
