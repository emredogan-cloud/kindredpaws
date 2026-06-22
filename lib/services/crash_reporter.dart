/// Crash + non-fatal error reporting seam (P1-2 observability → Crashlytics).
///
/// Crash-free target is a gate KPI (≥99% at G3, ≥99.5% at G5 —
/// GAME_TECHNICAL_SYSTEMS.md §10.3). This abstraction is wired everywhere now;
/// the Firebase Crashlytics body drops in once provisioned (see
/// `firebase_provisioning.dart` + REQUIRED_ENVIRONMENTS.md). Reporting MUST be
/// best-effort and NEVER throw — observability can't be the thing that crashes.
library;

/// A recorded error (in-memory backend; mirrors a Crashlytics non-fatal).
class RecordedError {
  RecordedError({
    required this.error,
    required this.fatal,
    this.context,
    this.keys = const {},
  });

  final Object error;
  final bool fatal;
  final String? context;
  final Map<String, Object?> keys;
}

abstract interface class CrashReporter {
  /// Record a (usually non-fatal) error with optional [context] + custom [keys]
  /// (no PII — keys are coarse state like lifeStage/bondStage/screen).
  void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? context,
    Map<String, Object?> keys = const {},
  });

  /// Leave a breadcrumb that will accompany the next crash report.
  void addBreadcrumb(String message);

  /// Set a persistent custom key attached to all subsequent reports.
  void setCustomKey(String key, Object? value);
}

/// In-memory implementation: fully functional for dev/CI; records errors,
/// breadcrumbs, and keys for inspection/tests. Never throws.
class InMemoryCrashReporter implements CrashReporter {
  final List<RecordedError> errors = [];
  final List<String> breadcrumbs = [];
  final Map<String, Object?> customKeys = {};

  @override
  void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? context,
    Map<String, Object?> keys = const {},
  }) {
    errors.add(
      RecordedError(
        error: error,
        fatal: fatal,
        context: context,
        keys: {...customKeys, ...keys},
      ),
    );
  }

  @override
  void addBreadcrumb(String message) => breadcrumbs.add(message);

  @override
  void setCustomKey(String key, Object? value) => customKeys[key] = value;
}
