# CLOSED_BETA_INSTRUMENTATION.md — KindredPaws (P3-7)

The instrumentation that makes the closed beta (G3) measurable. Authority:
`GAME_TECHNICAL_SYSTEMS.md §10`, `GAME_MASTER_EXECUTION_ROADMAP.md` G3 gates
(D1 ≥40% / D7 ≥18%, crash-free ≥99%).

## 1. Session lifecycle → `sessionQuality`

The `GameController` owns the play session. A session **begins** on adopt, on
load-with-a-pet, and on app-foreground (`onAppForegrounded` → re-resolves offline
catch-up, greets, re-arms the clock). It **ends** on app-background
(`onAppBackgrounded`), which emits the deferred `sessionQuality` beat and persists.

`GameRoot` is a `WidgetsBindingObserver`; `didChangeAppLifecycleState` maps
`resumed → onAppForegrounded` and `inactive/paused/hidden/detached →
onAppBackgrounded`.

`sessionQuality {empty, interactions_n, duration_s}` (via
`ObservabilityFacade.recordSessionQuality`):
- `interactions_n` = care interactions this session (`SessionInteractions.total`).
- `empty = interactions_n == 0` — the daily-retention lever: an empty session
  (opened, did nothing) is the leading signal of a churning player.
- `duration_s` = wall-clock from session start to background.
- Emission is idempotent — a second background before the next foreground is a
  no-op (guards double-counting).

## 2. Crash + performance activation

`installCrashHandlers(CrashReporter)` (`lib/core/app_instrumentation.dart`),
called from `main()` right after bootstrap:
- `FlutterError.onError` → `recordError(..., fatal: false, context: 'flutter')`,
  then chains the prior handler (keeps the red screen / console in debug).
- `PlatformDispatcher.instance.onError` → `recordError(..., fatal: true,
  context: 'platform')` and returns `true` (handled) so a beta build degrades
  instead of dying on an uncaught async error.

`recordColdStart(PerformanceMonitor, elapsedMs:)` records `cold_start_ms`
(process start → first `runApp`). The real Crashlytics / Firebase Performance
sinks drop in at provisioning (`registerFirebaseServices`); the in-memory sinks
make all of this unit-testable with zero credentials.

## 3. Beta feedback hook

`FeedbackService` (`lib/services/feedback_service.dart`) is the seam the in-app
"how's it going?" affordance calls. `BetaFeedback` is PII-minimized by
construction: a 1–5 rating (clamped) + an optional trimmed, 280-char-capped note,
no identifiers. `NoopFeedbackService` is the offline default;
`BackendFeedbackService` appends to the internal append-only `beta_feedback`
stream (never shown to other players, so not a UGC surface) and is registered
over the authoritative backend in `registerFirebaseServices`.
`GameController.submitBetaFeedback` is the call site — best-effort, never throws
into the UI.
