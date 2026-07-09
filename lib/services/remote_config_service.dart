/// Remote-config abstraction (ADR-009 / Risk R8): all balance numbers are
/// data-driven so live-ops can tune them without an app update. This is built
/// in MVP even though live-ops *content* is Deferred.
///
/// The default values below mirror the launch defaults in
/// `game-os/GAMEPLAY_AND_PROGRESSION_BIBLE.md` §5.8 / §7.1 (remote-config keys)
/// — they are the *config schema + safe fallbacks*, NOT the simulation that
/// consumes them (that is Phase 1). The brief/bible remain canonical.
library;

abstract interface class RemoteConfigService {
  double getDouble(String key);
  int getInt(String key);
  bool getBool(String key);
}

/// Ships the canonical launch defaults locally; a real remote-config backend
/// (Firebase Remote Config) overrides them at runtime once provisioned.
class DefaultRemoteConfig implements RemoteConfigService {
  const DefaultRemoteConfig([this._overrides = const {}]);

  final Map<String, Object> _overrides;

  /// Canonical launch defaults (GAMEPLAY_AND_PROGRESSION_BIBLE.md §5.8, §7.1).
  static const Map<String, Object> defaults = {
    // Care Meter decay (per real hour) + the no-death floor (Risk R4).
    'decay.hunger_per_h': 5.0,
    'decay.energy_per_h': 3.5,
    'decay.hygiene_per_h': 2.5,
    'decay.happiness_per_h': 4.0,
    'meter.floor': 15.0, // never 0 — the pet can never die/suffer (D-008)
    // Offline catch-up (longing-not-guilt model, Risk R6).
    'offline.grace_hours': 8.0,
    'offline.grace_decay_mult': 0.5,
    'offline.max_catchup_days': 7.0,
    // The Bond (monotonic, gain-only).
    'bond.daily_soft_cap': 55,
    'bond.memory_callback_pts': 8,
    // Bond stage thresholds: Stranger/Friend/Companion/Kindred/Soulmate.
    'bond.stage_friend': 250,
    'bond.stage_companion': 1200,
    'bond.stage_kindred': 4000,
    'bond.stage_soulmate': 10000,
    // Economy guards (KP-014): care-action Kibble is a bounded daily
    // faucet, not an infinite one (tapered in GameSimulation.interact).
    'economy.care_kibble_daily_cap': 30,
    // Retention guards.
    'notifications.daily_cap': 2,
    'ads.rewarded_daily_cap': 6,
    'streak.warmth_cap': 2,
    // LLM cost guard (Risk R2 / gate G4): live chat is gated by these.
    'heartmind.live_chat_enabled': false,
    'heartmind.live_daily_turn_cap': 20,
    'heartmind.output_token_cap': 90,
    // LiveOps (P4-3): emergency kill-switches (false = feature lives) — the
    // founder's no-app-update incident "off switch" (Risk R8).
    'killswitch.live_chat': false,
    'killswitch.rewarded_ads': false,
    'killswitch.keepsake_share': false,
    'killswitch.notifications': false,
    'killswitch.beta_feedback': false,
    'killswitch.rescue_bundles': false,
    'killswitch.seasons': false, // GE-5: neutral world on demand
    // LiveOps rollout percentages (0..100; 100 = fully rolled out).
    'rollout.live_chat.pct': 100,
    'rollout.rewarded_ads.pct': 100,
    'rollout.keepsake_share.pct': 100,
    'rollout.notifications.pct': 100,
    'rollout.beta_feedback.pct': 100,
    'rollout.rescue_bundles.pct': 100,
    'rollout.seasons.pct': 100,
    // Content-hotfix coordination: the dialogue-bank version the live config
    // expects (bumped when a Remote Config top-up ships; see Content OS).
    'liveops.content_version': 1,
    // A/B experiments (P5-3) — OFF by default (everyone gets the safe `control`
    // baseline); the founder flips one on to start the experiment, no app update.
    'experiment.paywall_copy.enabled': false,
    'experiment.onboarding_pace.enabled': false,
    'experiment.notification_cadence.enabled': false,
  };

  @override
  double getDouble(String key) => (_value(key) as num).toDouble();

  @override
  int getInt(String key) => (_value(key) as num).toInt();

  @override
  bool getBool(String key) => _value(key) as bool;

  Object _value(String key) {
    final v = _overrides[key] ?? defaults[key];
    if (v == null) throw ArgumentError('Unknown remote-config key: $key');
    return v;
  }
}
