import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/logger.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/performance_monitor.dart';
import 'package:kindredpaws/services/session_health.dart';

void main() {
  group('SessionHealthMonitor', () {
    test('starts healthy', () {
      final m = SessionHealthMonitor();
      expect(m.hadCrash, isFalse);
      expect(m.errorCount, 0);
      expect(m.lastContext, isNull);
    });

    test('recording an error flips hadCrash + keeps the last context', () {
      final m = SessionHealthMonitor();
      m.recordError(context: 'save_failed');
      m.recordError(context: 'rive_missing');
      expect(m.hadCrash, isTrue);
      expect(m.errorCount, 2);
      expect(m.lastContext, 'rive_missing');
    });

    test('reset returns it to a clean session', () {
      final m = SessionHealthMonitor()..recordError(context: 'x');
      m.reset();
      expect(m.hadCrash, isFalse);
      expect(m.errorCount, 0);
      expect(m.lastContext, isNull);
    });
  });

  group('ObservabilityFacade feeds the monitor (single error funnel)', () {
    test('recordError bumps the session-health monitor', () {
      final monitor = SessionHealthMonitor();
      final obs = ObservabilityFacade(
        logger: InMemoryLogger(),
        crash: InMemoryCrashReporter(),
        performance: InMemoryPerformanceMonitor(),
        analytics: InMemoryAnalyticsService(),
        sessionHealth: monitor,
      );
      expect(obs.sessionHealth.hadCrash, isFalse);
      obs.recordError(StateError('boom'), StackTrace.current, context: 'tick');
      expect(monitor.hadCrash, isTrue);
      expect(monitor.lastContext, 'tick');
    });

    test('defaults to its own monitor when none is injected', () {
      final obs = ObservabilityFacade(
        logger: InMemoryLogger(),
        crash: InMemoryCrashReporter(),
        performance: InMemoryPerformanceMonitor(),
        analytics: InMemoryAnalyticsService(),
      );
      obs.recordError(StateError('x'), null);
      expect(obs.sessionHealth.hadCrash, isTrue);
    });
  });
}
