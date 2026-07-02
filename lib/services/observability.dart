/// Observability facade (P1-2): one entry point that fans a signal out to the
/// [Logger], [CrashReporter], [PerformanceMonitor], and [AnalyticsService].
///
/// It also owns the two **mandatory leading-churn indicators** (brief §10):
/// "noticed AI repetition" and "felt guilt-tripped about the pet". These predict
/// D7/D30 collapse before raw retention moves, so they get first-class helpers
/// here (they emit the analytics event, a warn log, and a crash breadcrumb).
library;

import 'analytics_service.dart';
import 'crash_reporter.dart';
import 'logger.dart';
import 'performance_monitor.dart';
import 'session_health.dart';
import 'telemetry.dart';

class ObservabilityFacade {
  ObservabilityFacade({
    required this.logger,
    required this.crash,
    required this.performance,
    required this.analytics,
    SessionHealthMonitor? sessionHealth,
  }) : sessionHealth = sessionHealth ?? SessionHealthMonitor();

  final Logger logger;
  final CrashReporter crash;
  final PerformanceMonitor performance;
  final AnalyticsService analytics;

  /// Crash-correlation signal for the beta feedback loop (P5-5): bumped on every
  /// [recordError] so feedback can be tagged with whether the session crashed.
  final SessionHealthMonitor sessionHealth;

  /// Record a non-fatal error across all sinks (log + crash report + the
  /// session-health counter that feeds beta-feedback crash correlation).
  void recordError(
    Object error,
    StackTrace? stack, {
    String? context,
    Map<String, Object?> keys = const {},
  }) {
    logger.error(
      context ?? 'error',
      fields: {'error': error.toString(), ...keys},
    );
    crash.recordError(error, stack, context: context, keys: keys);
    sessionHealth.recordError(context: context);
  }

  /// Time a synchronous unit of work and record the trace + a perf log.
  T trace<T>(String name, T Function() body) {
    final t = performance.startTrace(name);
    try {
      return body();
    } finally {
      t.stop();
      performance.completeTrace(t);
      logger.debug('trace', fields: {'name': name, 'ms': t.durationMs});
    }
  }

  /// Log an analytics event + a breadcrumb (keeps a crash report contextual).
  ///
  /// Params are run through [Telemetry.sanitize] first: PII keys are dropped and
  /// (for an event with a declared schema) any key outside its contract is
  /// dropped, so the taxonomy is enforced at the single emit point. In debug, a
  /// missing required param warns loudly (never silently ships malformed data).
  void event(AnalyticsEvent e, [Map<String, Object?> params = const {}]) {
    final clean = Telemetry.sanitize(e, params);
    assert(() {
      final missing = Telemetry.missingRequired(e, params);
      if (missing.isNotEmpty) {
        logger.warn(
          'telemetry: ${e.name} missing required params',
          fields: {'missing': missing.join(',')},
        );
      }
      return true;
    }());
    analytics.log(e, clean);
    crash.addBreadcrumb('event:${e.name}');
  }

  /// Session-quality summary at session end (the daily-retention lever:
  /// `empty=false` ⇒ the session had ≥1 meaningful beat). The session lifecycle
  /// that calls this is wired in closed-beta instrumentation (P3-7).
  void recordSessionQuality({
    required int interactions,
    required int durationSeconds,
  }) {
    event(AnalyticsEvent.sessionQuality, {
      'empty': interactions == 0,
      'interactions_n': interactions,
      'duration_s': durationSeconds,
    });
  }

  /// LEADING CHURN INDICATOR #1 (Risk R3): the player noticed AI repetition.
  void flagAiRepetition({Map<String, Object?> context = const {}}) {
    analytics.log(
      AnalyticsEvent.aiRepetitionFlag,
      Telemetry.sanitize(AnalyticsEvent.aiRepetitionFlag, context),
    );
    logger.warn('leading-churn: ai_repetition', fields: context);
    crash.addBreadcrumb('churn:ai_repetition');
  }

  /// LEADING CHURN INDICATOR #2 (Risk R6): the player felt guilt-tripped.
  /// In a cozy game this should be ~zero by construction; any hit is a red flag.
  void flagGuilt({Map<String, Object?> context = const {}}) {
    analytics.log(
      AnalyticsEvent.guiltFlag,
      Telemetry.sanitize(AnalyticsEvent.guiltFlag, context),
    );
    logger.warn('leading-churn: guilt', fields: context);
    crash.addBreadcrumb('churn:guilt');
  }
}
