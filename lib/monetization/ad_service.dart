/// Ad delivery seam (P4-6). Abstracts the mediation SDK (AdMob/ironSource) so the
/// game stays decoupled from it — same gated-seam pattern as billing/backend.
/// **Child-safe by construction**: every call takes the [AdConfig] derived from
/// the compliance policy (P3-6a) — COPPA TFCD + GDPR-K TFUA, **contextual-only /
/// no behavioral targeting**, G-rated for child-safe bands. Rewarded-first; the
/// caps + timing + ethical rules live in [AdsController].
///
/// `NoopAdService` simulates a completed rewarded watch offline (CI/dev, no SDK
/// dependency). `AdMobAdService` is the gated stub that becomes real once
/// `google_mobile_ads` + ad-unit IDs are provisioned (REQUIRED_ENVIRONMENTS §6).
library;

import 'ad_config.dart';

/// The outcome of a rewarded-ad attempt.
enum RewardedStatus { completed, dismissed, noFill, unavailable }

class RewardedOutcome {
  const RewardedOutcome(this.status, {this.rewardCoins = 0});

  final RewardedStatus status;

  /// Compassion Coins the **server** mints after the validated S2S postback —
  /// the client never self-mints (anti-fraud, §7.4). This is the optimistic
  /// display amount; the impact ledger is the source of truth.
  final int rewardCoins;

  bool get earned => status == RewardedStatus.completed;

  static const RewardedOutcome unavailable = RewardedOutcome(
    RewardedStatus.unavailable,
  );
}

abstract interface class AdService {
  /// Show a rewarded ad with the child-safe [config]. Never throws into the game.
  Future<RewardedOutcome> showRewarded(AdConfig config);

  /// Show an interstitial (the caller has already checked caps/timing).
  Future<void> showInterstitial(AdConfig config);
}

/// Offline/dev: shows nothing but reports a completed rewarded watch so the
/// reward + coin-mint flow is exercisable deterministically. No SDK dependency.
class NoopAdService implements AdService {
  const NoopAdService({this.rewardCoins = 5});

  final int rewardCoins;

  @override
  Future<RewardedOutcome> showRewarded(AdConfig config) async =>
      RewardedOutcome(RewardedStatus.completed, rewardCoins: rewardCoins);

  @override
  Future<void> showInterstitial(AdConfig config) async {}
}

/// AdMob/mediation seam (gated). INERT until provisioned (no `google_mobile_ads`
/// dependency yet) — rewarded returns `unavailable` (no-fill), so selecting it
/// without the SDK never breaks the game.
///
/// To activate (founder step, REQUIRED_ENVIRONMENTS §6):
///   1. `flutter pub add google_mobile_ads`; set the AdMob app id + ad-unit ids.
///   2. `MobileAds.instance.updateRequestConfiguration(...)` with TFCD/TFUA from
///      [AdConfig] (COPPA/GDPR-K) and `maxAdContentRating` G; tag for kids.
///   3. Load + show `RewardedAd` / `InterstitialAd`; on rewarded completion the
///      ad network sends a signed S2S postback → our server validates + mints.
class AdMobAdService implements AdService {
  const AdMobAdService();

  /// True once the real SDK bodies replace the inert ones below.
  bool get isProvisioned => false;

  @override
  Future<RewardedOutcome> showRewarded(AdConfig config) async =>
      RewardedOutcome.unavailable;

  @override
  Future<void> showInterstitial(AdConfig config) async {}
}
