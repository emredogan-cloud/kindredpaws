# CLOSED_BETA_BUILD.md — KindredPaws closed-beta candidate (P4-9)

How to produce + validate the closed-beta build. CI builds + drives the Android
candidate on every PR; the iOS candidate is blocked on credentialed macOS tooling
(documented below). Authority: roadmap G3, REQUIRED_ENVIRONMENTS.md.

## Android closed-beta candidate

The app runs fully offline on safe defaults; the closed-beta candidate flips on
the provisioned backends via `--dart-define` (founder/credentialed — the values
are NOT committed):

```bash
just setup
flutter build appbundle --release \
  --dart-define=KP_ENV=beta \
  --dart-define=KP_BETA=true \
  --dart-define=KP_BACKEND=firebase \
  --dart-define=KP_FIREBASE_PROVISIONED=true \
  --dart-define=KP_BILLING=revenuecat \
  --dart-define=KP_PET_RENDERER=rive \
  --dart-define=KP_RIV_ASSET=assets/rigs/biscuit.riv
# → upload the .aab to the Play Console **Internal/Closed testing** track (NOT production)
```

Without the `--dart-define`s the same code builds the offline/mock build that CI
exercises (`just run-android`, `build-android`). Each provisioned flag is gated
so a missing credential degrades gracefully (Firebase → mocks, RevenueCat →
inert, Rive → stand-in) — the build never breaks on an absent credential.

## iOS closed-beta candidate — blockers

iOS is **prepared but blocked** in this environment (no macOS/Xcode/Apple
Developer access). Ready: the WidgetKit scaffold (`ios/PetWidget/`), the
RevenueCat/StoreKit seam, the compliance posture. Remaining founder/credentialed
steps (REQUIRED_ENVIRONMENTS §4): Xcode + macOS runner, Apple Developer team +
signing (`fastlane match`), add the WidgetKit extension target + App Group, then
`flutter build ipa` → **TestFlight**. No code change is required to unblock — only
the credentialed toolchain.

## Validation matrix

| Area | How it is validated |
|---|---|
| **Install / cold start** | `build-android` (CI) builds the app + AppWidget; `startup_perf` budget; on-device `integration-android` cold-launch |
| **Upgrade path / persistence** | `save_migration` (v1→v6 forward, no orphaned pet) + the closed-beta simulation reopen-restore; on-device E2E reopen |
| **Notifications** | `notification_scheduler` (5 kinds, ≤2/day, never-guilt SSOT) + the milestone-celebration integration |
| **Monetization** | `monetization` + the simulation's premium-gating (subscribe → ad-light); RevenueCat seam gated |
| **Telemetry** | `telemetry`/`observability` (PII-enforced) + the simulation asserts the funnel events fire |
| **Performance** | `startup_perf` + `render_perf` host budgets; on-device frame pacing via `flutter drive --profile` (founder, on real device) |
| **Crash-free** | `installCrashHandlers` routes uncaught errors → Crashlytics (G3 ≥99%) |

## Closed-beta simulation

`closed_beta_simulation_test.dart` walks the whole loop host-side
(adopt → care → telemetry → notifications → persist → reopen/restore → session
quality → feedback → premium gating → PII-free diagnostics) as a fast,
deterministic proxy for the on-device E2E. **Do not publish to production** — the
G3 legal sign-off (Open Decision #9) gates any public listing.
