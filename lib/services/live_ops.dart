/// Live operations control plane (P4-3) — lets the founder change product
/// behavior **without shipping a new app** (Risk R8). A thin, typed layer over
/// [RemoteConfigService] that exposes three live levers:
///
///  * **Kill-switches** — an emergency "off" for a feature during an incident.
///  * **%-rollout** — deterministic, sticky bucketing so a feature can be turned
///    on for a slice of users (canary) and grown without flip-flopping anyone.
///  * **Content version** — coordinates a Remote Config dialogue-bank hotfix.
///
/// Live *balancing* (decay/Bond/cap tuning) already flows through
/// [RemoteConfigService] → `SimConfig.fromRemoteConfig`; live *content* hotfixes
/// flow through `mergeRemoteContent` (Content OS). This file adds the rollout +
/// kill-switch control surface on top. Authority: GAME_TECHNICAL_SYSTEMS.md §9,
/// brief §11 R8, GAME_CONTENT_FACTORY §11.
library;

import 'remote_config_service.dart';

/// A feature whose live state the founder can control. Each maps to its Remote
/// Config key suffix (`killswitch.<key>`, `rollout.<key>.pct`).
enum LiveFeature {
  liveChat('live_chat'),
  rewardedAds('rewarded_ads'),
  keepsakeShare('keepsake_share'),
  notifications('notifications'),
  betaFeedback('beta_feedback'),
  rescueBundles('rescue_bundles');

  const LiveFeature(this.key);

  /// The Remote Config key suffix for this feature.
  final String key;
}

/// Reads the LiveOps control surface from [RemoteConfigService].
class LiveOps {
  const LiveOps(this._rc);

  final RemoteConfigService _rc;

  /// Emergency disable. A killed feature is OFF regardless of rollout — the
  /// founder's incident off-switch, no app update required.
  bool isKilled(LiveFeature f) => _rc.getBool('killswitch.${f.key}');

  /// Whether [f] is within its rollout for a stable [unitId] (e.g. the account
  /// id). The unit is hashed into a sticky 0..99 bucket; the feature is in
  /// rollout when `bucket < pct`. The same unit always lands the same way (no
  /// flip-flop), and each feature uses its own salt so rollouts don't correlate.
  bool isInRollout(LiveFeature f, {required String unitId}) {
    final pct = _rc.getInt('rollout.${f.key}.pct');
    if (pct >= 100) return true;
    if (pct <= 0) return false;
    return rolloutBucket(unitId, f.key) < pct;
  }

  /// A feature is LIVE for this user iff it is not killed AND within rollout.
  bool isLive(LiveFeature f, {required String unitId}) =>
      !isKilled(f) && isInRollout(f, unitId: unitId);

  /// The dialogue-bank content version the live config expects (a Remote Config
  /// top-up bumps this so the client + content stay coordinated).
  int get contentVersion => _rc.getInt('liveops.content_version');

  /// Assigns a **sticky** A/B variant for [exp] to [unitId] (P5-3). An experiment
  /// is **OFF by default** — everyone is `control` (the safe baseline *and* the
  /// emergency-rollback state); the founder enables it via
  /// `experiment.<key>.enabled`. When on, users split deterministically + evenly
  /// across `control` + [treatments] treatment arms (1 ⇒ control/A, 2 ⇒
  /// control/A/B) by a per-experiment salted bucket — no flip-flop, no app update.
  ExperimentVariant assignVariant(
    Experiment exp, {
    required String unitId,
    int treatments = 1,
  }) {
    if (!_rc.getBool('experiment.${exp.key}.enabled')) {
      return ExperimentVariant.control;
    }
    final arms = (treatments + 1).clamp(2, 3); // control + 1..2 treatments
    final arm = (rolloutBucket(unitId, 'exp:${exp.key}') * arms) ~/ 100;
    return ExperimentVariant.values[arm];
  }
}

/// A soft-launch A/B experiment (LiveOps cohort). OFF by default; the founder
/// flips `experiment.<key>.enabled` in Remote Config to start it. Add a key here
/// + its default to run a new experiment.
enum Experiment {
  paywallCopy('paywall_copy'),
  onboardingPace('onboarding_pace'),
  notificationCadence('notification_cadence');

  const Experiment(this.key);

  final String key;
}

/// The arm a user is assigned to. `control` is the safe baseline (and the state
/// when the experiment is off / rolled back). Order matters — indexed by bucket.
enum ExperimentVariant { control, treatment, treatmentB }

/// A stable `0..99` bucket from FNV-1a over `"salt:unitId"`. Pure + deterministic
/// (no RNG) so a user's rollout assignment never changes between sessions.
int rolloutBucket(String unitId, String salt) {
  var hash = 0x811c9dc5; // FNV offset basis (32-bit)
  for (final c in '$salt:$unitId'.codeUnits) {
    hash ^= c;
    hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime, keep 32-bit
  }
  return hash % 100;
}
