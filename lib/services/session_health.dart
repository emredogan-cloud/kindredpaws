/// Session-health monitor (P5-5) — the crash-correlation signal for the beta
/// feedback loop. A tiny in-memory counter the [ObservabilityFacade] bumps on
/// every `recordError`, so when a tester sends feedback we can tag whether *this
/// session* hit an error and attach the last error's (PII-free) context. That
/// turns "the app feels broken" into a routed P1 crash report. Per-process, no
/// PII (an error context string is an internal label, never player data), reset
/// at session start. Authority: GAME_TECHNICAL_SYSTEMS §10.
library;

class SessionHealthMonitor {
  int _errorCount = 0;
  String? _lastContext;

  /// How many non-fatal errors/crashes were recorded this session.
  int get errorCount => _errorCount;

  /// Whether this session hit at least one error/crash (crash-correlation flag).
  bool get hadCrash => _errorCount > 0;

  /// The most recent error's context label (an internal code, never PII), or
  /// null if the session has been healthy.
  String? get lastContext => _lastContext;

  /// Called from the single error funnel ([ObservabilityFacade.recordError]).
  void recordError({String? context}) {
    _errorCount++;
    if (context != null && context.isNotEmpty) _lastContext = context;
  }

  /// Resets at the start of a fresh session.
  void reset() {
    _errorCount = 0;
    _lastContext = null;
  }
}
