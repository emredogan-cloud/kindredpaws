import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/compliance_config.dart';
import 'package:kindredpaws/monetization/ad_config.dart';
import 'package:kindredpaws/monetization/ad_service.dart';
import 'package:kindredpaws/monetization/ads_controller.dart';
import 'package:kindredpaws/services/analytics_service.dart';
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

// The shipped default: a child-safe (unknown ⇒ under-13) ad config.
final _childSafeAd = AdConfig.fromCompliance(const ComplianceConfig());

AdsController _ads({
  AdService? service,
  Map<String, Object> rc = const {},
  ObservabilityFacade? obs,
}) {
  final config = DefaultRemoteConfig(rc);
  return AdsController(
    ads: service ?? const NoopAdService(),
    adConfig: _childSafeAd,
    liveOps: LiveOps(config),
    remoteConfig: config,
    observability: obs ?? _obs(),
  );
}

void main() {
  group('AdService seam', () {
    test('Noop simulates a completed rewarded watch', () async {
      final r = await const NoopAdService().showRewarded(_childSafeAd);
      expect(r.earned, isTrue);
      expect(r.rewardCoins, greaterThan(0));
    });

    test('AdMob seam is inert (no-fill) until provisioned', () async {
      const a = AdMobAdService();
      expect(a.isProvisioned, isFalse);
      final r = await a.showRewarded(_childSafeAd);
      expect(r.status, RewardedStatus.unavailable);
    });
  });

  group('child-safe by construction', () {
    test('the ad config is contextual-only with COPPA/GDPR-K kids flags', () {
      expect(_childSafeAd.personalizedAdsAllowed, isFalse); // no behavioral
      expect(_childSafeAd.tagForChildDirectedTreatment, isTrue); // COPPA
      expect(_childSafeAd.tagForUnderAgeOfConsent, isTrue); // GDPR-K
      expect(_childSafeAd.maxAdContentRating, AdContentRating.g);
    });
  });

  group('rewarded ads — opt-in, capped, mints via the server postback', () {
    test(
      'a completed watch increments the count + emits monetizationEvent',
      () async {
        final obs = _obs();
        final ads = _ads(obs: obs);
        final r = await ads.showRewarded();
        expect(r.earned, isTrue);
        expect(ads.rewardedToday, 1);
        final a = obs.analytics as InMemoryAnalyticsService;
        expect(a.countOf(AnalyticsEvent.monetizationEvent), 1);
        expect(a.recorded.single.$2['stream'], 'rewardedAd');
      },
    );

    test(
      'respects the daily cap (default 6); the 7th is unavailable',
      () async {
        final ads = _ads(); // ads.rewarded_daily_cap defaults to 6
        for (var i = 0; i < 6; i++) {
          expect((await ads.showRewarded()).earned, isTrue);
        }
        expect(ads.rewardedAvailable, isFalse);
        expect((await ads.showRewarded()).status, RewardedStatus.unavailable);
        expect(ads.rewardedToday, 6);
      },
    );

    test('the kill-switch disables rewarded ads live', () async {
      final ads = _ads(rc: {'killswitch.rewarded_ads': true});
      expect(ads.rewardedAvailable, isFalse);
      expect((await ads.showRewarded()).status, RewardedStatus.unavailable);
    });
  });

  group('interstitials — sparse, never intrusive (no dark patterns)', () {
    test('at most one per session', () async {
      final ads = _ads();
      expect(
        await ads.maybeShowInterstitial(
          duringEmotionalBeat: false,
          removesInterstitials: false,
        ),
        isTrue,
      );
      expect(
        await ads.maybeShowInterstitial(
          duringEmotionalBeat: false,
          removesInterstitials: false,
        ),
        isFalse, // 2nd blocked
      );
      ads.resetSession();
      expect(
        await ads.maybeShowInterstitial(
          duringEmotionalBeat: false,
          removesInterstitials: false,
        ),
        isTrue, // allowed again next session
      );
    });

    test('NEVER during an emotional beat', () async {
      final ads = _ads();
      expect(
        ads.canShowInterstitial(
          duringEmotionalBeat: true,
          removesInterstitials: false,
        ),
        isFalse,
      );
    });

    test('never for Forever Friends subscribers (ad-light)', () async {
      final ads = _ads();
      expect(
        await ads.maybeShowInterstitial(
          duringEmotionalBeat: false,
          removesInterstitials: true,
        ),
        isFalse,
      );
    });

    test('killable live', () async {
      final ads = _ads(rc: {'killswitch.rewarded_ads': true});
      expect(
        ads.canShowInterstitial(
          duringEmotionalBeat: false,
          removesInterstitials: false,
        ),
        isFalse,
      );
    });
  });
}
