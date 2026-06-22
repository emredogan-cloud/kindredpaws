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

class ObservabilityFacade {
  ObservabilityFacade({
    required this.logger,
    required this.crash,
    required this.performance,
    required this.analytics,
  });

  final Logger logger;
  final CrashReporter crash;
  final PerformanceMonitor performance;
  final AnalyticsService analytics;

  /// Record a non-fatal error across all sinks (log + crash report).
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
  void event(AnalyticsEvent e, [Map<String, Object?> params = const {}]) {
    analytics.log(e, params);
    crash.addBreadcrumb('event:${e.name}');
  }

  /// LEADING CHURN INDICATOR #1 (Risk R3): the player noticed AI repetition.
  void flagAiRepetition({Map<String, Object?> context = const {}}) {
    analytics.log(AnalyticsEvent.aiRepetitionFlag, context);
    logger.warn('leading-churn: ai_repetition', fields: context);
    crash.addBreadcrumb('churn:ai_repetition');
  }

  /// LEADING CHURN INDICATOR #2 (Risk R6): the player felt guilt-tripped.
  /// In a cozy game this should be ~zero by construction; any hit is a red flag.
  void flagGuilt({Map<String, Object?> context = const {}}) {
    analytics.log(AnalyticsEvent.guiltFlag, context);
    logger.warn('leading-churn: guilt', fields: context);
    crash.addBreadcrumb('churn:guilt');
  }
}
