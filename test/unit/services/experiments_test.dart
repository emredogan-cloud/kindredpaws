import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/experiments.dart';
import 'package:kindredpaws/services/live_ops.dart';
import 'package:kindredpaws/services/logger.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/performance_monitor.dart';
import 'package:kindredpaws/services/remote_config_service.dart';

LiveOps _ops([Map<String, Object> rc = const {}]) =>
    LiveOps(DefaultRemoteConfig(rc));

void main() {
  group('LiveOps.assignVariant (A/B, off-by-default)', () {
    test(
      'an experiment is control for everyone until enabled (safe baseline)',
      () {
        final ops = _ops();
        for (final id in ['a', 'b', 'c', 'd']) {
          expect(
            ops.assignVariant(Experiment.paywallCopy, unitId: id),
            ExperimentVariant.control,
          );
        }
      },
    );

    test('emergency rollback (enabled→false) returns everyone to control', () {
      final on = _ops({'experiment.paywall_copy.enabled': true});
      final off = _ops({'experiment.paywall_copy.enabled': false});
      // Find a user assigned to a treatment while on...
      final treated = [for (var i = 0; i < 50; i++) 'u$i'].firstWhere(
        (id) =>
            on.assignVariant(Experiment.paywallCopy, unitId: id) !=
            ExperimentVariant.control,
      );
      // ...rolling back puts them back in control.
      expect(
        off.assignVariant(Experiment.paywallCopy, unitId: treated),
        ExperimentVariant.control,
      );
    });

    test('an enabled A/B splits the population ~evenly + is sticky', () {
      final ops = _ops({'experiment.paywall_copy.enabled': true});
      var control = 0;
      for (var i = 0; i < 1000; i++) {
        final v = ops.assignVariant(Experiment.paywallCopy, unitId: 'user-$i');
        if (v == ExperimentVariant.control) control++;
        // Sticky: same unit, same variant.
        expect(ops.assignVariant(Experiment.paywallCopy, unitId: 'user-$i'), v);
      }
      expect(control, inInclusiveRange(400, 600)); // ~50% control
    });

    test('treatments:2 yields a three-arm split (control/A/B)', () {
      final ops = _ops({'experiment.onboarding_pace.enabled': true});
      final seen = <ExperimentVariant>{};
      for (var i = 0; i < 300; i++) {
        seen.add(
          ops.assignVariant(
            Experiment.onboardingPace,
            unitId: 'u$i',
            treatments: 2,
          ),
        );
      }
      expect(seen.length, 3); // control, treatment, treatmentB all present
    });
  });

  group('Experiments.expose — variant + exposure telemetry', () {
    ObservabilityFacade obs() => ObservabilityFacade(
      logger: InMemoryLogger(),
      crash: InMemoryCrashReporter(),
      performance: InMemoryPerformanceMonitor(),
      analytics: InMemoryAnalyticsService(),
    );

    test('emits experimentExposure once per (experiment, unit)', () {
      final o = obs();
      final exp = Experiments(
        liveOps: _ops({'experiment.paywall_copy.enabled': true}),
        observability: o,
      );
      final v1 = exp.expose(Experiment.paywallCopy, unitId: 'u1');
      final v2 = exp.expose(Experiment.paywallCopy, unitId: 'u1'); // deduped
      expect(v1, v2); // sticky
      final a = o.analytics as InMemoryAnalyticsService;
      expect(a.countOf(AnalyticsEvent.experimentExposure), 1);
      final rec = a.recorded.single;
      expect(rec.$2['experiment'], 'paywall_copy');
      expect(rec.$2['variant'], v1.name);
    });

    test('different units each get one exposure', () {
      final o = obs();
      final exp = Experiments(
        liveOps: _ops({'experiment.paywall_copy.enabled': true}),
        observability: o,
      );
      exp.expose(Experiment.paywallCopy, unitId: 'a');
      exp.expose(Experiment.paywallCopy, unitId: 'b');
      expect(
        (o.analytics as InMemoryAnalyticsService).countOf(
          AnalyticsEvent.experimentExposure,
        ),
        2,
      );
    });
  });
}
