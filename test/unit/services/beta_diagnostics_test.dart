import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/app_config.dart';
import 'package:kindredpaws/core/compliance_config.dart';
import 'package:kindredpaws/monetization/billing_service.dart';
import 'package:kindredpaws/monetization/monetization_controller.dart';
import 'package:kindredpaws/monetization/product_catalog.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/backend_service.dart';
import 'package:kindredpaws/services/beta_diagnostics.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/live_ops.dart';
import 'package:kindredpaws/services/logger.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/performance_monitor.dart';
import 'package:kindredpaws/services/remote_config_service.dart';

ObservabilityFacade _obs() => ObservabilityFacade(
  logger: InMemoryLogger(),
  crash: InMemoryCrashReporter(),
  performance: InMemoryPerformanceMonitor(),
  analytics: InMemoryAnalyticsService(),
);

BetaDiagnostics _diag({
  Map<String, Object> rc = const {},
  MonetizationController? monetization,
}) => BetaDiagnostics(
  appConfig: AppConfig.fromEnvironment(),
  compliance: const ComplianceConfig(),
  monetization:
      monetization ??
      MonetizationController(
        billing: NoopBillingService(),
        observability: _obs(),
        backend: InMemoryBackendService(),
      ),
  liveOps: LiveOps(DefaultRemoteConfig(rc)),
);

void main() {
  group('BetaDiagnostics — PII-free support export (P4-7)', () {
    test('captures the build config + compliance posture + versions', () {
      final r = _diag().snapshot();
      expect(r.env, 'dev');
      expect(r.backend, 'mock');
      expect(r.billing, 'noop');
      expect(r.ageBand, 'unknown'); // child-safe default (D-007)
      expect(r.childSafe, isTrue);
      expect(r.subscriber, isFalse);
      expect(r.saveSchemaVersion, greaterThanOrEqualTo(6));
      expect(r.killedFeatures, isEmpty);
    });

    test('reflects live kill-switches (incident state)', () {
      final r = _diag(rc: {'killswitch.rewarded_ads': true}).snapshot();
      expect(r.killedFeatures, contains('rewarded_ads'));
    });

    test('reflects an active subscription', () async {
      final c = MonetizationController(
        billing: NoopBillingService(),
        observability: _obs(),
        backend: InMemoryBackendService(),
      );
      await c.purchase(kForeverFriendsMonthly);
      expect(_diag(monetization: c).snapshot().subscriber, isTrue);
    });

    test('is PII-free — no player data in the export', () {
      final r = _diag().snapshot();
      final json = r.toJson();
      // Only config/flag/version keys — never a name/id/save field.
      for (final blocked in ['name', 'petName', 'userId', 'email', 'save']) {
        expect(json.containsKey(blocked), isFalse);
      }
      expect(r.exportText(), contains('no personal data'));
      expect(r.exportText(), contains('ageBand=unknown'));
    });
  });
}
