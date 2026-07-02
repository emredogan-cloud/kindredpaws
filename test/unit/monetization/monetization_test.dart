import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/monetization/billing_service.dart';
import 'package:kindredpaws/monetization/entitlements.dart';
import 'package:kindredpaws/monetization/monetization_controller.dart';
import 'package:kindredpaws/monetization/product_catalog.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/backend_service.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/logger.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/performance_monitor.dart';

ObservabilityFacade _obs() => ObservabilityFacade(
  logger: InMemoryLogger(),
  crash: InMemoryCrashReporter(),
  performance: InMemoryPerformanceMonitor(),
  analytics: InMemoryAnalyticsService(),
);

/// Billing that always reports the user cancelled.
class _CancellingBilling implements BillingService {
  @override
  Future<Entitlements> entitlements() async => Entitlements.none;
  @override
  Future<PurchaseResult> purchase(Product product) async =>
      PurchaseResult.cancelledResult;
  @override
  Future<Entitlements> restore() async => Entitlements.none;
}

void main() {
  group('Product catalog — locked tier + ethical wall', () {
    test('Forever Friends is the single sub tier at the locked prices', () {
      expect(kForeverFriendsMonthly.priceUsd, 5.99);
      expect(kForeverFriendsAnnual.priceUsd, 39.99);
      expect(kForeverFriendsMonthly.isSubscription, isTrue);
      expect(kForeverFriendsAnnual.isSubscription, isTrue);
    });

    test('every product grants ONLY cosmetic/QoL (no pay-to-win, §18)', () {
      for (final p in kProductCatalog) {
        expect(
          grantsOnlyCosmeticOrQoL(p),
          isTrue,
          reason: '${p.sku} confers a non-cosmetic/QoL grant',
        );
      }
      // The allowed set itself contains no gameplay-advantage grant by design
      // (there is no Grant value that touches Bond/meters/memory).
      expect(kAllowedMonetizationGrants, isNotEmpty);
    });

    test('heartstone bundles are one-time IAP cosmetic currency', () {
      expect(kHeartstoneBundles, isNotEmpty);
      for (final b in kHeartstoneBundles) {
        expect(b.stream, MonetizationStream.iap);
        expect(b.grants, [Grant.heartstones]);
      }
    });
  });

  group('Entitlements — cosmetic/QoL only', () {
    test('none grants nothing', () {
      expect(Entitlements.none.foreverFriends, isFalse);
      expect(Entitlements.none.removesInterstitials, isFalse);
      expect(Entitlements.none.dailyKibbleBonus, isFalse);
    });

    test('Forever Friends drives ad-light + daily bonus (never gameplay)', () {
      const e = Entitlements(foreverFriends: true);
      expect(e.removesInterstitials, isTrue);
      expect(e.dailyKibbleBonus, isTrue);
    });
  });

  group('NoopBillingService', () {
    test('a subscription purchase flips Forever Friends on', () async {
      final b = NoopBillingService();
      expect((await b.entitlements()).foreverFriends, isFalse);
      final r = await b.purchase(kForeverFriendsMonthly);
      expect(r.success, isTrue);
      expect((await b.entitlements()).foreverFriends, isTrue);
    });

    test(
      'a one-time bundle succeeds without granting a subscription',
      () async {
        final b = NoopBillingService();
        final r = await b.purchase(kHeartstoneBundles.first);
        expect(r.success, isTrue);
        expect((await b.entitlements()).foreverFriends, isFalse);
      },
    );
  });

  group('MonetizationController — purchase emits monetizationEvent', () {
    test(
      'a successful sub purchase emits {stream, sku, value} + entitles',
      () async {
        final obs = _obs();
        final c = MonetizationController(
          billing: NoopBillingService(),
          observability: obs,
          backend: InMemoryBackendService(),
        );
        final r = await c.purchase(kForeverFriendsAnnual);
        expect(r.success, isTrue);
        expect(c.entitlements.foreverFriends, isTrue);

        final analytics = obs.analytics as InMemoryAnalyticsService;
        expect(analytics.countOf(AnalyticsEvent.monetizationEvent), 1);
        final rec = analytics.recorded.single;
        expect(rec.$2['stream'], 'subscription');
        expect(rec.$2['sku'], 'forever_friends_annual');
        expect(rec.$2['value'], 39.99);
      },
    );

    test('a cancelled purchase emits nothing and grants nothing', () async {
      final obs = _obs();
      final c = MonetizationController(
        billing: _CancellingBilling(),
        observability: obs,
        backend: InMemoryBackendService(),
      );
      final r = await c.purchase(kForeverFriendsMonthly);
      expect(r.success, isFalse);
      expect(r.cancelled, isTrue);
      expect(c.entitlements.foreverFriends, isFalse);
      expect(
        (obs.analytics as InMemoryAnalyticsService).countOf(
          AnalyticsEvent.monetizationEvent,
        ),
        0,
      );
    });

    test('load + restore reflect store entitlements', () async {
      final billing = NoopBillingService();
      await billing.purchase(kForeverFriendsMonthly);
      final c = MonetizationController(
        billing: billing,
        observability: _obs(),
        backend: InMemoryBackendService(),
      );
      await c.load();
      expect(c.entitlements.foreverFriends, isTrue);
      await c.restore();
      expect(c.entitlements.foreverFriends, isTrue);
    });
  });

  group('Rescue Bundles — commercial, disclosed donation slice (P3-5b)', () {
    test('bundles disclose a donation slice and are still cosmetic/QoL', () {
      expect(kRescueBundles, isNotEmpty);
      for (final b in kRescueBundles) {
        expect(b.isRescueBundle, isTrue);
        expect(b.donationSliceUsd, greaterThan(0)); // disclosed
        expect(b.donationSliceUsd, lessThan(b.priceUsd)); // a slice, not all
        expect(grantsOnlyCosmeticOrQoL(b), isTrue); // never pay-to-win
      }
    });

    test('non-bundle products disclose no donation slice', () {
      expect(kForeverFriendsMonthly.isRescueBundle, isFalse);
      expect(kForeverFriendsMonthly.donationSliceUsd, 0);
      expect(kHeartstoneBundles.first.isRescueBundle, isFalse);
    });
  });

  group('Compassion Coins mint — anti-fraud gated impact ledger (P3-5b)', () {
    MonetizationController build(InMemoryBackendService backend) =>
        MonetizationController(
          billing: NoopBillingService(),
          observability: _obs(),
          backend: backend,
        );

    test(
      'a VALIDATED mint appends to the ledger + emits + returns coins',
      () async {
        final backend = InMemoryBackendService();
        final c = build(backend);
        final minted = await c.mintCompassionCoins(
          source: 'sub',
          amount: 50,
          validated: true,
        );
        expect(minted, 50);
        final ledger = backend.entriesOf(
          MonetizationController.impactLedgerStream,
        );
        expect(ledger, hasLength(1));
        expect(ledger.single['amount'], 50);
        expect(ledger.single['validated'], true);
        final a = c.observability.analytics as InMemoryAnalyticsService;
        final rec = a.recorded.single;
        expect(rec.$1, AnalyticsEvent.compassionCoinMint);
        expect(rec.$2['source'], 'sub');
        expect(rec.$2['amount'], 50);
        expect(rec.$2['validated'], true);
      },
    );

    test(
      'an UNVALIDATED mint is rejected: no ledger write, mints nothing',
      () async {
        final backend = InMemoryBackendService();
        final c = build(backend);
        final minted = await c.mintCompassionCoins(
          source: 'ad',
          amount: 50,
          validated: false, // fraudulent / unconfirmed
        );
        expect(minted, 0);
        expect(
          backend.entriesOf(MonetizationController.impactLedgerStream),
          isEmpty,
        );
        // The attempt is still recorded for fraud monitoring (validated:false).
        final rec = (c.observability.analytics as InMemoryAnalyticsService)
            .recorded
            .single;
        expect(rec.$2['validated'], false);
        expect(rec.$2['amount'], 0);
      },
    );

    test('free players mint via ads — impact never requires payment', () async {
      final backend = InMemoryBackendService();
      final minted = await build(backend).mintCompassionCoins(
        source: 'ad',
        amount: 5,
        validated: true, // a signed S2S ad postback
      );
      expect(minted, 5);
      expect(
        backend
            .entriesOf(MonetizationController.impactLedgerStream)
            .single['source'],
        'ad',
      );
    });
  });

  group('RevenueCat activation + premium gating (P4-5)', () {
    MonetizationController controller(BillingService billing) =>
        MonetizationController(
          billing: billing,
          observability: _obs(),
          backend: InMemoryBackendService(),
        );

    test('RevenueCatBillingService is inert until provisioned', () async {
      const b = RevenueCatBillingService();
      expect(b.isProvisioned, isFalse);
      expect(await b.entitlements(), Entitlements.none);
      final r = await b.purchase(kForeverFriendsMonthly);
      expect(r.success, isFalse);
      expect(r.cancelled, isTrue);
      expect(await b.restore(), Entitlements.none);
    });

    test(
      'subscribing unlocks the premium entitlements (gating flows)',
      () async {
        final c = controller(NoopBillingService());
        await c.load();
        expect(c.entitlements.foreverFriends, isFalse);
        expect(c.entitlements.removesInterstitials, isFalse);

        final r = await c.purchase(kForeverFriendsMonthly);
        expect(r.success, isTrue);
        expect(c.entitlements.foreverFriends, isTrue);
        expect(c.entitlements.removesInterstitials, isTrue); // premium gating
        expect(c.entitlements.dailyKibbleBonus, isTrue);
      },
    );

    test('restore re-resolves the active subscription', () async {
      final billing = NoopBillingService();
      final c = controller(billing);
      await c.purchase(kForeverFriendsMonthly);
      // A fresh controller over the same billing restores the entitlement.
      final c2 = controller(billing);
      await c2.restore();
      expect(c2.entitlements.foreverFriends, isTrue);
    });

    test('the unprovisioned RevenueCat seam grants nothing', () async {
      final c = controller(const RevenueCatBillingService());
      await c.load();
      final r = await c.purchase(kForeverFriendsMonthly);
      expect(r.success, isFalse);
      expect(c.entitlements.foreverFriends, isFalse);
    });
  });
}
