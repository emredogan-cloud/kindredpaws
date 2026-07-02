# PERFORMANCE.md — KindredPaws performance hardening (P5-6)

The soft-launch performance contract + how it's enforced. Authority:
`KINDREDPAWS_CANONICAL_DECISION_BRIEF.md` (G4), `GAMEPLAY_AND_PROGRESSION_BIBLE.md
§3.2` (reaction beat), `GAME_TECHNICAL_SYSTEMS.md §10`.

## Budgets (single source of truth)

All budgets live in `lib/core/performance_budgets.dart` (`PerfBudget`). The perf
tests, the runtime monitor, and this doc read the same enum — change a ceiling in
exactly one place.

| Budget | Ceiling | What it guards |
|---|---|---|
| `coldStart` | **2500 ms** | Process start → first frame. The soft-launch startup target (< 2.5 s). |
| `coldWidgetBuild` | 2000 ms | Host-side cold widget build — the CI-safe proxy for cold start. |
| `frame` | 16 ms | One frame at **60 fps**. On-device frame pacing. |
| `reactionBeat` | 150 ms | Tap → the pet's reaction beat begins (bible §3.2). |
| `interaction` | 100 ms | A care interaction resolves (sim + UI feedback). |
| `renderSweep` | 4000 ms | 48 mood × emotion rebuilds — no pathological rebuild cost. |
| `inputMapping` | 500 ms | 100k rig input mappings — the per-frame push stays allocation-light. |

## How each target is enforced

### Startup < 2.5 s
- **Runtime gate:** `main()` measures boot → `runApp`, records `cold_start_ms`
  (→ Firebase Performance), then `PerformanceBudgetMonitor.check(coldStart, …)`.
  A breach warns + drops a `perf:cold_start_ms:over` breadcrumb so a regression
  is visible in beta triage / Crashlytics (it never throws).
- **CI gate:** `test/performance/startup_perf_test.dart` asserts the cold widget
  build stays within `coldWidgetBuild`.
- **Why it holds:** bootstrap is pure in-memory wiring (zero network, zero
  credentials); Firebase SDKs are dormant until provisioned + activated off the
  boot path; the save loads once and migrates forward in memory.

### Stable 60 fps
- **CI proxy:** `render_perf_test.dart` sweeps every mood × emotion rebuild
  within `renderSweep`, and pins the rig input-mapping is allocation-light
  (`inputMapping`).
- **Design:** the Rive rig **self-advances** on the GPU; per change we push only
  3 state-machine inputs (mood / lifeStage / emotion) — no per-frame widget
  rebuild of the pet. The care ring + meters are cheap `CustomPainter`s.
- **On-device truth:** real frame/jank profiling runs via `just e2e-android`
  (integration_test) + `flutter drive --profile` (see below).

### No memory leaks
- `ChangeNotifier`s (`GameController`, `MonetizationController`) are long-lived
  singletons; transient listeners (e.g. the paywall sheet's `ListenableBuilder`)
  are torn down by the framework on dispose. The Rive seam disposes its
  controller; image/keepsake data is bounded (capped lists).
- **On-device truth:** watch the DevTools memory timeline across a
  foreground/background/return cycle during the `flutter drive --profile` run —
  resident set should return to baseline after a GC.

### Low battery impact
- No busy loops or high-frequency timers: the sim resolves **on session
  resume**, not on a wall-clock tick; ambient nudges are user/idle-driven.
- Notifications are scheduled (OS-batched), not polled. Analytics + crash sinks
  are fire-and-forget and dormant until provisioned.

## On-device profiling (founder step)

Host-side budgets are a floor; the real numbers come from a mid-tier Android
device/emulator:

```bash
just emulator                       # boot the KVM-accelerated AVD
flutter drive --profile \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/<flow>_test.dart
# then open DevTools → Performance (frame chart) + Memory (timeline)
```

Capture: cold-start ms (vs `coldStart`), the frame chart over a care loop (target
≤ `frame`), and the memory timeline over a background/return cycle. File any
breach as a P1/P2 via the beta feedback loop (`BETA_FEEDBACK_LOOP.md`).

## Adding / changing a budget

Edit the `PerfBudget` enum (one line), then reference it from the test or runtime
check. Never hard-code a millisecond literal in a test — read the enum so the
budget stays single-sourced.
