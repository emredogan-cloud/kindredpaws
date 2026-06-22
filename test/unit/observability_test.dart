import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/firebase_provisioning.dart';
import 'package:kindredpaws/services/logger.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/performance_monitor.dart';

void main() {
  group('InMemoryLogger (structured, privacy-by-design)', () {
    test('drops PII-bearing fields before storing (Risk R1)', () {
      final log = InMemoryLogger();
      log.info(
        'pet greeting',
        fields: {'petName': 'Biscuit', 'bondStage': 'Friend', 'lifeStage': 1},
      );
      final rec = log.records.single;
      expect(rec.fields.containsKey('petName'), isFalse); // PII removed
      expect(rec.fields['bondStage'], 'Friend'); // coarse state kept
      expect(rec.fields['lifeStage'], 1);
    });

    test('respects the minLevel gate', () {
      final log = InMemoryLogger(minLevel: LogLevel.warn);
      log.debug('noise');
      log.info('noise');
      log.warn('kept');
      log.error('kept');
      expect(log.records.length, 2);
      expect(log.countAtLeast(LogLevel.warn), 2);
    });

    test('sanitizedFields blocks every known PII key', () {
      final rec = LogRecord(
        level: LogLevel.info,
        message: 'x',
        fields: {'name': 'a', 'email': 'b', 'userText': 'c', 'screen': 'home'},
      );
      expect(rec.sanitizedFields.keys, ['screen']);
    });
  });

  group('InMemoryCrashReporter', () {
    test('records errors with merged custom keys + breadcrumbs', () {
      final crash = InMemoryCrashReporter();
      crash.setCustomKey('build', 'dev');
      crash.addBreadcrumb('opened home');
      crash.recordError(
        StateError('boom'),
        StackTrace.current,
        keys: {'screen': 'home'},
      );
      final e = crash.errors.single;
      expect(e.fatal, isFalse);
      expect(e.keys['build'], 'dev'); // persistent key merged
      expect(e.keys['screen'], 'home');
      expect(crash.breadcrumbs, ['opened home']);
    });
  });

  group('InMemoryPerformanceMonitor', () {
    test('records a completed trace with a duration + metric', () {
      final perf = InMemoryPerformanceMonitor();
      final t = perf.startTrace('rescue_day');
      t.incrementMetric('beats', 5);
      t.stopWith(1200); // deterministic duration
      perf.completeTrace(t);
      final got = perf.traceNamed('rescue_day')!;
      expect(got.durationMs, 1200);
      expect(got.metrics['beats'], 5);
    });
  });

  group('ObservabilityFacade', () {
    ObservabilityFacade build() {
      return ObservabilityFacade(
        logger: InMemoryLogger(),
        crash: InMemoryCrashReporter(),
        performance: InMemoryPerformanceMonitor(),
        analytics: InMemoryAnalyticsService(),
      );
    }

    test('recordError fans out to log + crash', () {
      final o = build();
      o.recordError(StateError('x'), StackTrace.current, context: 'sim');
      expect((o.crash as InMemoryCrashReporter).errors, hasLength(1));
      expect((o.logger as InMemoryLogger).countAtLeast(LogLevel.error), 1);
    });

    test('trace records a completed perf trace', () {
      final o = build();
      final r = o.trace<int>('work', () => 21 * 2);
      expect(r, 42);
      expect(
        (o.performance as InMemoryPerformanceMonitor).completed,
        hasLength(1),
      );
    });

    test('flagAiRepetition emits the mandatory churn indicator', () {
      final o = build();
      o.flagAiRepetition(context: {'line_id': 7});
      final a = o.analytics as InMemoryAnalyticsService;
      expect(a.countOf(AnalyticsEvent.aiRepetitionFlag), 1);
      expect(
        (o.crash as InMemoryCrashReporter).breadcrumbs,
        contains('churn:ai_repetition'),
      );
    });

    test(
      'flagGuilt emits the mandatory churn indicator (should be ~0 in prod)',
      () {
        final o = build();
        o.flagGuilt();
        expect(
          (o.analytics as InMemoryAnalyticsService).countOf(
            AnalyticsEvent.guiltFlag,
          ),
          1,
        );
      },
    );

    test('event logs analytics + a breadcrumb', () {
      final o = build();
      o.event(AnalyticsEvent.careAction, {'verb': 'feed'});
      expect(
        (o.analytics as InMemoryAnalyticsService).countOf(
          AnalyticsEvent.careAction,
        ),
        1,
      );
      expect(
        (o.crash as InMemoryCrashReporter).breadcrumbs,
        contains('event:careAction'),
      );
    });
  });

  group('FirebaseProvisioning (inert until credentialed)', () {
    test('defaults to not provisioned', () {
      expect(FirebaseProvisioning.isProvisioned, isFalse);
    });

    test('initialize() never throws and reports unprovisioned', () async {
      final status = await FirebaseProvisioning.initialize();
      expect(status.provisioned, isFalse);
      expect(status.detail, contains('not provisioned'));
    });

    test('documents the six integrated products + activation steps', () {
      expect(FirebaseProvisioning.products.length, 6);
      expect(
        FirebaseProvisioning.activationSteps,
        contains(predicate<String>((s) => s.contains('flutterfire configure'))),
      );
    });
  });
}
