/// Ad coordination (P4-6) — the ethical rules around showing ads, tying together
/// the child-safe [AdConfig] (P3-6a), the live kill-switch + Remote Config caps
/// (P4-3), and the subscriber ad-light entitlement (P4-5). Rewarded-first; no
/// dark patterns. Authority: brief §5, GAME_TECHNICAL_SYSTEMS §7.1/§7.4, R1.
///
/// The hard rules enforced here:
///  - **Rewarded is opt-in**, capped at `ads.rewarded_daily_cap` (~4–6/day).
///  - **Interstitials are sparse**: max 1 / session, **NEVER mid-emotion**, never
///    for Forever Friends subscribers (ad-light), killable live.
///  - **Child-safe**: the [AdConfig] passed to the SDK is contextual-only (no
///    behavioral targeting) with COPPA/GDPR-K kids flags.
///  - **Every rewarded watch mints Compassion Coins** — server-side, after the
///    signed S2S postback (the client emits the `monetizationEvent` signal and
///    never self-mints; the impact ledger is the source of truth, §7.4).
library;

import '../services/analytics_service.dart';
import '../services/live_ops.dart';
import '../services/observability.dart';
import '../services/remote_config_service.dart';
import 'ad_config.dart';
import 'ad_service.dart';
import 'product_catalog.dart';

class AdsController {
  AdsController({
    required this.ads,
    required this.adConfig,
    required this.liveOps,
    required this.remoteConfig,
    required this.observability,
  });

  final AdService ads;
  final AdConfig adConfig;
  final LiveOps liveOps;
  final RemoteConfigService remoteConfig;
  final ObservabilityFacade observability;

  /// Max interstitials per play session (sparse, rewarded-first).
  static const int maxInterstitialsPerSession = 1;

  int _rewardedToday = 0;
  int _interstitialsThisSession = 0;

  int get rewardedToday => _rewardedToday;
  int get rewardedDailyCap => remoteConfig.getInt('ads.rewarded_daily_cap');

  bool get _adsKilled => liveOps.isKilled(LiveFeature.rewardedAds);

  /// Whether a rewarded ad can be offered right now (opt-in surface gating).
  bool get rewardedAvailable =>
      !_adsKilled && _rewardedToday < rewardedDailyCap;

  /// Show a rewarded ad (the player opted in). Respects the kill-switch + daily
  /// cap + the child-safe [AdConfig]. On completion emits a `monetizationEvent`
  /// (stream=rewardedAd) — the server's S2S postback then mints the Compassion
  /// Coins. Returns the outcome; coins are credited from the validated mint.
  Future<RewardedOutcome> showRewarded() async {
    if (!rewardedAvailable) return RewardedOutcome.unavailable;
    final outcome = await ads.showRewarded(adConfig);
    if (outcome.earned) {
      _rewardedToday++;
      observability.event(AnalyticsEvent.monetizationEvent, {
        'stream': MonetizationStream.rewardedAd.name,
        'sku': 'rewarded_coins',
        'value': 0, // ad revenue is network-side; the watch is the signal
      });
    }
    return outcome;
  }

  /// Whether an interstitial may show right now — rewarded-first, sparse, and
  /// never intrusive: not for subscribers, **never during an emotional beat**,
  /// max 1/session, and killable live.
  bool canShowInterstitial({
    required bool duringEmotionalBeat,
    required bool removesInterstitials,
  }) =>
      !removesInterstitials &&
      !duringEmotionalBeat &&
      !_adsKilled &&
      _interstitialsThisSession < maxInterstitialsPerSession;

  /// Show an interstitial iff allowed. Returns whether it was shown.
  Future<bool> maybeShowInterstitial({
    required bool duringEmotionalBeat,
    required bool removesInterstitials,
  }) async {
    if (!canShowInterstitial(
      duringEmotionalBeat: duringEmotionalBeat,
      removesInterstitials: removesInterstitials,
    )) {
      return false;
    }
    await ads.showInterstitial(adConfig);
    _interstitialsThisSession++;
    return true;
  }

  /// Reset the per-session interstitial budget (call on a new session).
  void resetSession() => _interstitialsThisSession = 0;

  /// Reset the per-day rewarded budget (call on a new calendar day).
  void resetDay() => _rewardedToday = 0;
}
