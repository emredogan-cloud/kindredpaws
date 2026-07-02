import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/monetization/billing_service.dart';
import 'package:kindredpaws/monetization/entitlements.dart';
import 'package:kindredpaws/monetization/monetization_controller.dart';
import 'package:kindredpaws/monetization/paywall_controller.dart';
import 'package:kindredpaws/monetization/product_catalog.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/auth_service.dart';
import 'package:kindredpaws/services/backend_service.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/experiments.dart';
import 'package:kindredpaws/services/live_ops.dart';
import 'package:kindredpaws/services/logger.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/performance_monitor.dart';
import 'package:kindredpaws/services/remote_config_service.dart';

/// A billing seam that always reports a hard failure (not a user cancel).
class _FailingBilling implements BillingService {
  @override
  Future<Entitlements> entitlements() async => Entitlements.none;
  @override
  Future<PurchaseResult> purchase(Product p) async =>
      const PurchaseResult(success: false);
  @override
  Future<Entitlements> restore() async => Entitlements.none;
}

/// A billing seam where the user dismisses the sheet (cancel, not an error).
class _CancellingBilling implements BillingService {
  @override
  Future<Entitlements> entitlements() async => Entitlements.none;
  @override
  Future<PurchaseResult> purchase(Product p) async =>
      PurchaseResult.cancelledResult;
  @override
  Future<Entitlements> restore() async => Entitlements.none;
}

/// A billing seam that restores an existing subscription.
class _RestoringBilling implements BillingService {
  @override
  Future<Entitlements> entitlements() async => Entitlements.none;
  @override
  Future<PurchaseResult> purchase(Product p) async =>
      const PurchaseResult(success: true);
  @override
  Future<Entitlements> restore() async =>
      const Entitlements(foreverFriends: true);
}

PaywallController _make({
  BillingService? billing,
  Map<String, Object> rc = const {},
}) {
  final obs = ObservabilityFacade(
    logger: InMemoryLogger(),
    crash: InMemoryCrashReporter(),
    performance: InMemoryPerformanceMonitor(),
    analytics: InMemoryAnalyticsService(),
  );
  return PaywallController(
    monetization: MonetizationController(
      billing: billing ?? NoopBillingService(),
      observability: obs,
      backend: InMemoryBackendService(),
    ),
    experiments: Experiments(
      liveOps: LiveOps(DefaultRemoteConfig(rc)),
      observability: obs,
    ),
    observability: obs,
    auth: GuestAuthService(),
  );
}

InMemoryAnalyticsService _analytics(PaywallController c) =>
    c.observability.analytics as InMemoryAnalyticsService;

List<String> _steps(PaywallController c) => [
  for (final r in _analytics(c).recorded)
    if (r.$1 == AnalyticsEvent.paywallStep) r.$2['step'] as String,
];

void main() {
  group('PaywallController — purchase funnel diagnostics', () {
    test('shown / dismissed bookend the funnel with the surface tag', () {
      final c = _make();
      c.recordShown('home');
      c.recordDismissed('home');
      expect(_steps(c), ['shown', 'dismissed']);
      final first = _analytics(c).recorded.first;
      expect(first.$2['surface'], 'home');
    });

    test('a successful subscription emits start→success + entitles', () async {
      final c = _make(); // Noop: a subscription flips Forever Friends on
      final result = await c.buy(kForeverFriendsMonthly, surface: 'home');
      expect(result.success, isTrue);
      expect(c.entitlements.foreverFriends, isTrue);
      expect(_steps(c), ['purchase_start', 'purchase_success']);
    });

    test('a user cancel emits start→cancelled (not failed)', () async {
      final c = _make(billing: _CancellingBilling());
      await c.buy(kForeverFriendsMonthly, surface: 'home');
      expect(_steps(c), ['purchase_start', 'purchase_cancelled']);
    });

    test('a hard failure emits start→failed', () async {
      final c = _make(billing: _FailingBilling());
      await c.buy(kForeverFriendsMonthly, surface: 'home');
      expect(_steps(c), ['purchase_start', 'purchase_failed']);
    });

    test(
      'restore that finds a sub emits start→success + returns true',
      () async {
        final c = _make(billing: _RestoringBilling());
        final entitled = await c.restore(surface: 'settings');
        expect(entitled, isTrue);
        expect(_steps(c), ['restore_start', 'restore_success']);
      },
    );

    test('restore with nothing to restore emits start→empty', () async {
      final c = _make(); // Noop, nothing purchased
      final entitled = await c.restore(surface: 'settings');
      expect(entitled, isFalse);
      expect(_steps(c), ['restore_start', 'restore_empty']);
    });
  });

  group('PaywallController — pricing-framing experiment (price LOCKED)', () {
    test('off-by-default → control copy, monthly-first', () {
      final c = _make();
      final copy = c.resolveCopy();
      expect(copy.headline, 'Become a Forever Friend');
      expect(copy.annualFirst, isFalse);
    });

    test('resolveCopy logs exactly one exposure even if asked twice', () {
      final c = _make();
      c.resolveCopy();
      c.resolveCopy();
      expect(_analytics(c).countOf(AnalyticsEvent.experimentExposure), 1);
    });

    test('enabled → a valid framing variant (the price never changes)', () {
      final c = _make(rc: {'experiment.paywall_copy.enabled': true});
      final copy = c.resolveCopy();
      expect(
        copy.headline,
        anyOf(
          'Become a Forever Friend',
          'Forever Friends — best value yearly',
          'Forever Friends, real friends',
        ),
      );
      // The catalogue price is the single source of truth, never the variant.
      expect(kForeverFriendsMonthly.priceUsd, 5.99);
      expect(kForeverFriendsAnnual.priceUsd, 39.99);
    });
  });
}
