# RELEASE_CANDIDATE.md — KindredPaws soft-launch RC (P5-8)

How a release candidate is built, what must be validated on it, and the
full-loop simulation that gates it. Authority: `GAME_MASTER_EXECUTION_ROADMAP`
(G4), `SOFT_LAUNCH_READINESS.md`, `CLOSED_BETA_BUILD.md`. Releases are automated
(Release Please) — never hand-edit versions/tags.

## 1. Building the RC (founder/credentialed step)

The signed store builds can't be produced in the autonomous sandbox (no signing
keys, no macOS for iOS). Founder steps:

### Android
```bash
flutter build appbundle --release \
  --dart-define=KP_FIREBASE_PROVISIONED=true \
  --dart-define=KP_BILLING=revenuecat
# → build/app/outputs/bundle/release/app-release.aab  → Play Console (closed/internal track)
```

### iOS (macOS + Xcode)
```bash
flutter build ipa --release \
  --dart-define=KP_FIREBASE_PROVISIONED=true \
  --dart-define=KP_BILLING=revenuecat
# → distribute the archive to TestFlight
```

Both need the gitignored platform config (`google-services.json` /
`GoogleService-Info.plist`) + the RevenueCat SDK keys (`REQUIRED_ENVIRONMENTS.md
§5`). Provisioning flips the leaf sinks to Firebase; `rewireDerivedServices`
re-wires the whole derived layer over them (the P5 audit fix), so telemetry, the
impact ledger, diagnostics, and the live kill-switches all use the real backends.
Until provisioned, the app runs the offline mock stack (what CI builds).

## 2. RC validation matrix

Each area has a host-side proof (the soft-launch simulation, CI-run) **and** an
on-device check on the RC before promotion.

| Area | Host-side proof (`soft_launch_simulation_test.dart`) | On-device RC check |
|---|---|---|
| **Upgrades** | A prior save migrates forward → no orphaned pet; personality persists (save v6). | Install the prior build, then the RC over it; pet + Bond + personality survive. |
| **Restores** | Reopen restores the save; the paywall `restore_success/empty` funnel. | Reinstall; sign in; pet returns. Restore a purchase on a real account. |
| **Notifications** | Scheduled on adopt (capped, killable); `notificationOpened`. | Receive a scheduled notification; tapping it opens + logs the event. |
| **Telemetry** | The PII-free taxonomy fires across the loop (every gate). | Events land in the Firebase console (verifies the re-wire — facade → Firebase sinks). |
| **Monetization** | Experiment exposure + paywall funnel + entitlement flip + revenue event. | A sandbox purchase flips entitlements; receipt validates server-side. |
| **Widgets** | `homeWidget.update` + `snapshots.write` publish the status snapshot. | The home-screen widget shows the live pet status. |
| **Persistence** | Save/reload survives across controller instances (session-2 reopen). | Force-kill + relaunch; state intact. Background/return catch-up correct. |

## 3. The soft-launch simulation (host-side, CI)

`test/unit/soft_launch_simulation_test.dart` walks the WHOLE loop in one
deterministic pass over the (rewired) in-memory stack: adopt → onboarding funnel
→ care → telemetry → widget/snapshot publish → experiment exposure → paywall
funnel + entitlement → beta-feedback triage → perf-budget gate → session-quality
→ PII-free diagnostics → reopen (persistence + restore + D1 retention milestone).
It's the fast proxy for the on-device E2E (`just e2e-android`), and it exercises
the cross-subsystem wiring the unit tests can't.

## 4. Promotion gate

Promote the RC to the soft-launch track only when: the §2 host-side column is
green in CI, the §2 on-device column is verified on the RC build, and
`SOFT_LAUNCH_READINESS.md §1` is fully green. Otherwise hold.
