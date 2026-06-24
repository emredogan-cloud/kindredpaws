import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/performance_budgets.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/logger.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/performance_monitor.dart';

void main() {
  group('PerfBudget — canonical ceilings (SSOT)', () {
    test('the soft-launch targets are pinned', () {
      expect(PerfBudget.coldStart.ceilingMs, 2500); // startup < 2.5s
      expect(PerfBudget.frame.ceilingMs, 16); // 60fps
      expect(PerfBudget.reactionBeat.ceilingMs, 150); // bible §3.2
    });

    test('isWithin is inclusive at the ceiling', () {
      expect(PerfBudget.coldStart.isWithin(2500), isTrue);
      expect(PerfBudget.coldStart.isWithin(2499), isTrue);
      expect(PerfBudget.coldStart.isWithin(2501), isFalse);
    });

    test('every budget has a unique, snake_case metric id', () {
      final ids = PerfBudget.values.map((b) => b.id).toList();
      expect(ids.toSet().length, ids.length); // unique
      for (final id in ids) {
        expect(id, matches(RegExp(r'^[a-z0-9_]+$')));
      }
    });
  });

  group('PerformanceBudgetMonitor — runtime gate', () {
    late InMemoryLogger logger;
    late InMemoryCrashReporter crash;
    late PerformanceBudgetMonitor monitor;

    setUp(() {
      logger = InMemoryLogger();
      crash = InMemoryCrashReporter();
      monitor = PerformanceBudgetMonitor(
        observability: ObservabilityFacade(
          logger: logger,
          crash: crash,
          performance: InMemoryPerformanceMonitor(),
          analytics: InMemoryAnalyticsService(),
        ),
      );
    });

    test('within budget ⇒ true, silent (no warn, no breadcrumb)', () {
      expect(monitor.check(PerfBudget.coldStart, 1800), isTrue);
      expect(logger.countAtLeast(LogLevel.warn), 0);
      expect(crash.breadcrumbs, isEmpty);
    });

    test('over budget ⇒ false, warns + drops a crash breadcrumb', () {
      expect(monitor.check(PerfBudget.coldStart, 4200), isFalse);
      expect(logger.countAtLeast(LogLevel.warn), 1);
      expect(logger.records.last.fields['budget'], 'cold_start_ms');
      expect(crash.breadcrumbs, contains('perf:cold_start_ms:over'));
    });

    test('a breach never throws (perf monitoring must not disrupt play)', () {
      expect(
        () => monitor.check(PerfBudget.reactionBeat, 9999),
        returnsNormally,
      );
    });
  });
}
