import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/logger.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/performance_monitor.dart';
import 'package:kindredpaws/services/telemetry.dart';

void main() {
  group('Telemetry registry (canonical taxonomy SSOT)', () {
    test('every AnalyticsEvent has exactly one EventSpec (totality)', () {
      expect(Telemetry.debugAssertComplete(), isTrue);
      expect(Telemetry.specs.length, AnalyticsEvent.values.length);
      for (final e in AnalyticsEvent.values) {
        expect(
          Telemetry.specs.containsKey(e),
          isTrue,
          reason: 'no spec for $e',
        );
      }
    });

    test('the mandatory leading-churn indicators map to the churn gate', () {
      expect(
        Telemetry.specOf(AnalyticsEvent.aiRepetitionFlag).gate,
        TelemetryGate.leadingChurn,
      );
      expect(
        Telemetry.specOf(AnalyticsEvent.guiltFlag).gate,
        TelemetryGate.leadingChurn,
      );
    });

    test('the cost + AI-reliability gates are bound to their events', () {
      expect(
        Telemetry.specOf(AnalyticsEvent.llmCostEvent).gate,
        TelemetryGate.cost,
      );
      expect(
        Telemetry.specOf(AnalyticsEvent.memoryCallback).gate,
        TelemetryGate.aiReliability,
      );
    });

    test('every spec has a description and required keys ⊆ allowed keys', () {
      for (final spec in Telemetry.specs.values) {
        expect(spec.description.trim(), isNotEmpty);
        expect(spec.required.difference(spec.allowedKeys), isEmpty);
      }
    });
  });

  group('Telemetry.sanitize (contract enforcement)', () {
    test('drops PII-bearing keys for every event', () {
      final clean = Telemetry.sanitize(AnalyticsEvent.careAction, {
        'verb': 'feed',
        'petName': 'Biscuit', // PII — must be stripped
        'name': 'Ada', // PII — must be stripped
      });
      expect(clean.containsKey('petName'), isFalse);
      expect(clean.containsKey('name'), isFalse);
      expect(clean['verb'], 'feed');
    });

    test('drops keys outside a schema-bearing event\'s allowed set', () {
      final clean = Telemetry.sanitize(AnalyticsEvent.bondStageUp, {
        'stage': 'friend',
        'bogus': 1, // not in the contract — dropped
      });
      expect(clean.keys, ['stage']);
    });

    test('keeps arbitrary non-PII context for a schema-less event', () {
      final clean = Telemetry.sanitize(AnalyticsEvent.aiRepetitionFlag, {
        'line_id': 7,
        'dialogue': 'hi there', // still PII — dropped
      });
      expect(clean['line_id'], 7);
      expect(clean.containsKey('dialogue'), isFalse);
    });

    test('drops ANY String value on a schema-less event (P3-8 fix)', () {
      // A free-text value is the one way PII could ride an un-declared key on the
      // open-ended leading-churn flags — so non-blocked String values are
      // dropped too; coarse num/bool context still flows.
      final clean = Telemetry.sanitize(AnalyticsEvent.guiltFlag, {
        'note':
            'the pet said something sad', // non-blocked KEY, free-text VALUE
        'count': 2,
        'flagged': true,
      });
      expect(clean.containsKey('note'), isFalse);
      expect(clean['count'], 2);
      expect(clean['flagged'], isTrue);
    });

    test('missingRequired reports the absent required params', () {
      final missing = Telemetry.missingRequired(AnalyticsEvent.careAction, {
        'verb': 'feed',
      });
      expect(missing, {'bond_awarded', 'needed'});
    });
  });

  group('ObservabilityFacade enforces the taxonomy at the emit point', () {
    ObservabilityFacade build() => ObservabilityFacade(
      logger: InMemoryLogger(),
      crash: InMemoryCrashReporter(),
      performance: InMemoryPerformanceMonitor(),
      analytics: InMemoryAnalyticsService(),
    );

    test('event() strips PII before it reaches the sink', () {
      final o = build();
      o.event(AnalyticsEvent.lifeStageUp, {
        'stage': 'youngOne',
        'petName': 'Biscuit',
      });
      final recorded =
          (o.analytics as InMemoryAnalyticsService).recorded.single;
      expect(recorded.$1, AnalyticsEvent.lifeStageUp);
      expect(recorded.$2['stage'], 'youngOne');
      expect(recorded.$2.containsKey('petName'), isFalse);
    });

    test('recordSessionQuality emits the retention-lever event', () {
      final o = build();
      o.recordSessionQuality(interactions: 0, durationSeconds: 12);
      final rec = (o.analytics as InMemoryAnalyticsService).recorded.single;
      expect(rec.$1, AnalyticsEvent.sessionQuality);
      expect(rec.$2['empty'], isTrue); // 0 interactions ⇒ empty session
      expect(rec.$2['interactions_n'], 0);
      expect(rec.$2['duration_s'], 12);
    });
  });

  group('Sinks strip PII defensively (defense in depth)', () {
    test('InMemoryAnalyticsService drops blockedKeys on a direct log()', () {
      final a = InMemoryAnalyticsService();
      a.log(AnalyticsEvent.careAction, {'verb': 'play', 'email': 'x@y.z'});
      expect(a.recorded.single.$2.containsKey('email'), isFalse);
      expect(a.recorded.single.$2['verb'], 'play');
    });

    test('the blockedKey set is the logger\'s single source of truth', () {
      // Telemetry reuses LogRecord.blockedKeys — pin a couple of critical keys.
      expect(
        LogRecord.blockedKeys,
        containsAll(['petName', 'dialogue', 'fact']),
      );
    });
  });
}
