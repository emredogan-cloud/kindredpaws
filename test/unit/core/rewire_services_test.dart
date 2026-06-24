import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/monetization/monetization_controller.dart';
import 'package:kindredpaws/monetization/paywall_controller.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/backend_service.dart';
import 'package:kindredpaws/services/beta_diagnostics.dart';
import 'package:kindredpaws/services/beta_feedback_pipeline.dart';
import 'package:kindredpaws/services/live_ops.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/remote_config_service.dart';

/// Regression guard for the P5 audit CRITICAL: the derived service layer (the
/// ObservabilityFacade + everything that reads it) captures its dependencies at
/// construction, so it MUST be rebuilt when a leaf is swapped — otherwise it
/// keeps writing to the dead in-memory sink. `rewireDerivedServices` is the swap
/// path (run for real in registerFirebaseServices); here we drive it with
/// in-memory leaf swaps so the behavior is covered without Firebase.
void main() {
  final sl = ServiceLocator.instance;

  setUp(() {
    sl.reset();
    bootstrap(locator: sl);
  });

  test('the ObservabilityFacade is rebuilt over a swapped analytics sink', () {
    final newAnalytics = InMemoryAnalyticsService();
    sl.registerSingleton<AnalyticsService>(newAnalytics);

    rewireDerivedServices(sl);

    expect(
      identical(sl.get<ObservabilityFacade>().analytics, newAnalytics),
      isTrue,
      reason: 'facade must point at the swapped analytics, not the boot one',
    );
  });

  test('every facade-consumer reads the SAME rebuilt facade', () {
    sl.registerSingleton<AnalyticsService>(InMemoryAnalyticsService());
    rewireDerivedServices(sl);

    final facade = sl.get<ObservabilityFacade>();
    expect(
      identical(sl.get<BetaFeedbackPipeline>().observability, facade),
      isTrue,
    );
    expect(
      identical(sl.get<PaywallController>().observability, facade),
      isTrue,
    );
  });

  test(
    'MonetizationController follows the swapped backend (impact ledger)',
    () {
      final newBackend = InMemoryBackendService();
      sl.registerSingleton<BackendService>(newBackend);

      rewireDerivedServices(sl);

      expect(
        identical(sl.get<MonetizationController>().backend, newBackend),
        isTrue,
        reason: 'the impact ledger must write to the authoritative backend',
      );
    },
  );

  test('BetaDiagnostics reflects the swapped LiveOps kill-switch state', () {
    // Simulate the Firebase Remote Config arriving with a live kill-switch.
    sl.registerSingleton<LiveOps>(
      const LiveOps(DefaultRemoteConfig({'killswitch.rewarded_ads': true})),
    );

    rewireDerivedServices(sl);

    expect(
      sl.get<BetaDiagnostics>().snapshot().killedFeatures,
      contains('rewarded_ads'),
      reason: 'the incident snapshot must show the LIVE flag state',
    );
  });

  test('a re-wire preserves the session-health monitor', () {
    sl.get<ObservabilityFacade>().recordError(
      StateError('boot blip'),
      null,
      context: 'boot',
    );

    rewireDerivedServices(sl);

    expect(
      sl.get<ObservabilityFacade>().sessionHealth.hadCrash,
      isTrue,
      reason: 'a boot-time crash signal must survive the Firebase re-wire',
    );
  });
}
