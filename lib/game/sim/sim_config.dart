/// All simulation tuning in one place (GAMEPLAY_AND_PROGRESSION_BIBLE.md §5–§7,
/// §11). Launch defaults are canonical; [SimConfig.fromRemoteConfig] overlays
/// live values from Remote Config (ADR-009) so balance can change without an app
/// update. The hard invariants (floor, gain-only Bond) are enforced in the
/// engines, not here — config only tunes magnitudes within safe ranges.
library;

import '../../services/remote_config_service.dart';
import '../model/care_meters.dart';

/// Bond point awards per action (§5.4 launch defaults).
class BondPoints {
  const BondPoints({
    this.firstDailyGreeting = 5,
    this.feedWhenHungry = 2,
    this.cleanWhenDirty = 2,
    this.playWhenWilling = 3,
    this.pettingTouch = 0.5,
    this.talkOrdinary = 2,
    this.memoryCallback = 8,
    this.comfortLowMood = 10,
    this.careStreakDay = 6,
    this.lifeStageMilestone = 50,
  });

  final double firstDailyGreeting;
  final double feedWhenHungry;
  final double cleanWhenDirty;
  final double playWhenWilling;
  final double pettingTouch;
  final double talkOrdinary;
  final double memoryCallback;
  final double comfortLowMood;
  final double careStreakDay;
  final double lifeStageMilestone;
}

class SimConfig {
  const SimConfig({
    this.decayPerHour = const {
      CareNeed.hunger: 5.0,
      CareNeed.energy: 3.5,
      CareNeed.hygiene: 2.5,
      CareNeed.happiness: 4.0,
    },
    this.floor = 15.0,
    this.graceHours = 8.0,
    this.graceDecayMult = 0.5,
    this.maxCatchupDays = 7.0,
    this.happinessPassivePerHour = 1.0,
    this.happinessPassiveThreshold = 60.0,
    this.bondDailySoftCap = 55,
    this.bondStageThresholds = const [0, 250, 1200, 4000, 10000],
    this.bondPoints = const BondPoints(),
    this.diminishingFactor = 0.6,
    this.feedRestore = 35.0,
    this.cleanRestore = 40.0,
    this.playHappiness = 30.0,
    this.playEnergyCost = 10.0,
    this.feedHappiness = 10.0,
    this.lowMoodComfortThreshold = 29.0,
    this.needsCareThreshold = 30.0,
    this.moodWeights = const {
      CareNeed.happiness: 0.30,
      CareNeed.hunger: 0.25,
      CareNeed.energy: 0.20,
      CareNeed.hygiene: 0.15,
    },
    this.recentAttentionWeight = 0.10,
    this.sleepRegenPerHour = 20.0,
    this.dailyKibbleBonus = 50,
    this.careKibbleDailyCap = 30,
    this.streakWarmthCap = 2,
    this.streakRepairKibbleCost = 100,
    this.youngOneMinBondStage = 1, // Friend
    this.youngOneMinActiveDays = 5,
    this.grownMinBondStage = 2, // Companion
    this.grownMinActiveDays = 28,
  });

  final Map<CareNeed, double> decayPerHour;
  final double floor;
  final double graceHours;
  final double graceDecayMult;
  final double maxCatchupDays;
  final double happinessPassivePerHour;
  final double happinessPassiveThreshold;
  final int bondDailySoftCap;

  /// Entry thresholds for [Stranger, Friend, Companion, Kindred, Soulmate].
  final List<int> bondStageThresholds;
  final BondPoints bondPoints;

  /// Within-session diminishing-returns base (§5.6): effective = base × f^n.
  final double diminishingFactor;
  final double feedRestore;
  final double cleanRestore;
  final double playHappiness;
  final double playEnergyCost;
  final double feedHappiness;

  /// Upper bound of the "Low" mood band — at/below this, the Comfort beat unlocks.
  final double lowMoodComfortThreshold;

  /// At/below this, the pet shows gentle "I miss you" body language (§5.2).
  final double needsCareThreshold;

  final Map<CareNeed, double> moodWeights;
  final double recentAttentionWeight;

  /// Energy restored per real hour asleep (§5.1: rest +20/h). Applied as a
  /// wake-time credit for the whole nap, on top of normal offline decay.
  final double sleepRegenPerHour;

  /// Kibble granted on the first open of a new day (§8.1: daily first-open
  /// +50) — a welcome, never a hook; missing days costs nothing.
  final int dailyKibbleBonus;

  /// Daily ceiling on Kibble minted by care actions (feed/clean/play taps) —
  /// full value up to ⅔ of this, a 1-Kibble trickle to the cap, then zero
  /// until tomorrow (KP-014: the faucet used to be uncapped, 5/tap forever).
  final int careKibbleDailyCap;

  final int streakWarmthCap;
  final int streakRepairKibbleCost;
  final int youngOneMinBondStage;
  final int youngOneMinActiveDays;
  final int grownMinBondStage;
  final int grownMinActiveDays;

  /// Overlays live Remote Config values onto the canonical defaults. Only the
  /// keys present in [DefaultRemoteConfig] are read; everything else keeps the
  /// canonical default.
  factory SimConfig.fromRemoteConfig(RemoteConfigService rc) => SimConfig(
    decayPerHour: {
      CareNeed.hunger: rc.getDouble('decay.hunger_per_h'),
      CareNeed.energy: rc.getDouble('decay.energy_per_h'),
      CareNeed.hygiene: rc.getDouble('decay.hygiene_per_h'),
      CareNeed.happiness: rc.getDouble('decay.happiness_per_h'),
    },
    floor: rc.getDouble('meter.floor'),
    graceHours: rc.getDouble('offline.grace_hours'),
    graceDecayMult: rc.getDouble('offline.grace_decay_mult'),
    maxCatchupDays: rc.getDouble('offline.max_catchup_days'),
    bondDailySoftCap: rc.getInt('bond.daily_soft_cap'),
    bondStageThresholds: [
      0,
      rc.getInt('bond.stage_friend'),
      rc.getInt('bond.stage_companion'),
      rc.getInt('bond.stage_kindred'),
      rc.getInt('bond.stage_soulmate'),
    ],
    streakWarmthCap: rc.getInt('streak.warmth_cap'),
    careKibbleDailyCap: rc.getInt('economy.care_kibble_daily_cap'),
  );
}
