/// The deterministic core-loop orchestrator. Ties the Care-Meter decay, mood,
/// Bond, Care Streak, and life-stage engines into the two operations the game
/// performs: [resolveOnResume] (offline catch-up + greeting + growth) and
/// [interact] (feed/clean/play → meters, Bond, streak, comfort, growth).
///
/// Everything is a pure function of its inputs + an explicit `nowMs`, so the sim
/// is deterministic and server-validatable (gate G1). No wall-clock is read here.
library;

import '../../core/local_day.dart';
import '../model/care_meters.dart';
import '../model/care_streak.dart';
import '../model/items.dart';
import '../model/mood.dart';
import '../model/pet_state.dart';
import 'bond_engine.dart';
import 'care_meter_simulator.dart';
import 'care_streak_engine.dart';
import 'interaction.dart';
import 'life_stage_engine.dart';
import 'mood_resolver.dart';
import 'sim_config.dart';

/// UTC-frame day (legacy helper). The sim itself uses its injected
/// [UtcOffsetAt] so day boundaries flip at the PLAYER's midnight (KP-018).
int dayOfMs(int ms) => ms ~/ Duration.millisecondsPerDay;

class ResumeOutcome {
  const ResumeOutcome({
    required this.state,
    required this.ledger,
    required this.mood,
    required this.offlineHours,
    required this.isNewDay,
    required this.greetingBond,
    required this.dailyKibble,
    required this.grewWhileAway,
  });

  final PetState state;
  final BondLedger ledger;
  final Mood mood;
  final double offlineHours;
  final bool isNewDay;
  final int greetingBond;

  /// Kibble granted for the first open of the day (§8.1), 0 otherwise.
  final int dailyKibble;
  final bool grewWhileAway;
}

class InteractionOutcome {
  const InteractionOutcome({
    required this.state,
    required this.session,
    required this.ledger,
    required this.mood,
    required this.bondAwarded,
    required this.kibbleAwarded,
    required this.wasNeeded,
    required this.streakIncremented,
    required this.freezeUsed,
    required this.streakBrokeFromCount,
    required this.comfortBeat,
    required this.grew,
  });

  final PetState state;
  final SessionInteractions session;
  final BondLedger ledger;
  final Mood mood;
  final int bondAwarded;
  final int kibbleAwarded;
  final bool wasNeeded;
  final bool streakIncremented;
  final bool freezeUsed;

  /// If > 0, the streak reset with this count before the break — the UI may
  /// offer the one-time Streak Repair (welcome-back framing, never penalty).
  final int streakBrokeFromCount;
  final bool comfortBeat;
  final bool grew;
}

class GameSimulation {
  GameSimulation(this.config, {UtcOffsetAt utcOffsetAt = utcOffsetNone})
    : _utcOffsetAt = utcOffsetAt,
      _meters = CareMeterSimulator(config),
      _mood = MoodResolver(config),
      _bond = BondEngine(config),
      _interaction = InteractionEngine(config),
      _streak = CareStreakEngine(config),
      _life = LifeStageEngine(
        youngOneMinBondRank: config.youngOneMinBondStage,
        youngOneMinActiveDays: config.youngOneMinActiveDays,
        grownMinBondRank: config.grownMinBondStage,
        grownMinActiveDays: config.grownMinActiveDays,
      );

  final SimConfig config;

  /// Local calendar frame (KP-018): tests keep the deterministic UTC default;
  /// production injects the device offset so days flip at local midnight.
  final UtcOffsetAt _utcOffsetAt;
  final CareMeterSimulator _meters;
  final MoodResolver _mood;
  final BondEngine _bond;
  final InteractionEngine _interaction;
  final CareStreakEngine _streak;
  final LifeStageEngine _life;

  MoodResolver get mood => _mood;

  /// The LOCAL calendar day used for daily caps/streaks, clamped monotonic
  /// against the ledger's recorded day: a backward clock must not roll the
  /// ledger to "yesterday" and reset the daily Bond cap (KP-015/KP-018).
  int _workingDay(int nowMs, BondLedger ledger) {
    final today = localDayOf(nowMs, _utcOffsetAt);
    final anchor = ledger.dayEpoch;
    return anchor != null && today < anchor ? anchor : today;
  }

  /// The tapered care-Kibble mint for this tap (KP-014): [base] until ⅔ of
  /// the daily cap is reached, then 1/tap, then 0. Never negative.
  int _taperCareKibble(int base, BondLedger ledger) {
    final cap = config.careKibbleDailyCap;
    final earned = ledger.careKibbleToday;
    if (earned >= cap) return 0;
    final softCap = (cap * 2) ~/ 3;
    final allowance = earned >= softCap ? 1 : base;
    final room = cap - earned;
    return allowance < room ? allowance : room;
  }

  /// One-time Streak Repair (§11.2): restores a just-broken streak to
  /// [toCount]. The caller charges the Kibble (config.streakRepairKibbleCost).
  CareStreak repairStreak(CareStreak streak, int toCount) =>
      _streak.repair(streak, toCount);

  /// Resolve elapsed time on foreground: decay (never below floor, longing not
  /// guilt), count the active day, award the first-daily greeting, and check
  /// growth. Pure in `nowMs`.
  ResumeOutcome resolveOnResume({
    required PetState state,
    required BondLedger ledger,
    required int nowMs,
  }) {
    // A backward clock (or cross-zone travel) can make elapsed negative —
    // clamp to zero so meters never mutate from time running "backwards"
    // (KP-015: no state may be minted or lost from clock manipulation).
    final elapsed = (nowMs - state.lastSimTimestampMs).clamp(
      0,
      1 << 48, // effectively unbounded upper — decay itself caps at 7 days
    );
    final decayed = _meters.applyDecay(state.meters, elapsed);
    final offlineHours = _meters.effectiveDecayHours(elapsed);
    final today = localDayOf(nowMs, _utcOffsetAt);

    // Day advance is MONOTONIC (KP-015): only a strictly FORWARD calendar day
    // is a new day. `!=` let any clock change (backward included) re-grant
    // the +50 daily bonus, the greeting Bond, and an activeDays growth tick,
    // repeatably, on every resume.
    final lastActive = state.lastActiveDayEpoch;
    final isNewDay = lastActive == null || today > lastActive;
    final activeDays = isNewDay ? state.activeDays + 1 : state.activeDays;
    // The working day is clamped monotonic too: on a backward clock the
    // ledger must keep TODAY's earned-Bond tally (a fresh `forDay(yesterday)`
    // would reset the daily cap → farmable), and the stored anchor must never
    // move backward.
    final effectiveToday = lastActive != null && today < lastActive
        ? lastActive
        : today;

    var bond = state.bond;
    var workingLedger = ledger.forDay(effectiveToday);
    var greetingBond = 0;
    if (isNewDay) {
      final award = _bond.award(
        bond: bond,
        rawPoints: config.bondPoints.firstDailyGreeting,
        mood: _mood.resolve(decayed),
        ledger: workingLedger,
        todayEpochDay: effectiveToday,
      );
      bond = award.bond;
      workingLedger = award.ledger;
      greetingBond = award.awarded;
    }

    // Growth can trigger purely from the active-day increment (dual gate).
    final life = _life.evaluate(
      current: state.lifeStage,
      bondStage: bond.stage,
      activeDays: activeDays,
    );
    if (life.advanced) {
      final award = _bond.award(
        bond: bond,
        rawPoints: config.bondPoints.lifeStageMilestone,
        mood: Mood.content,
        ledger: workingLedger,
        todayEpochDay: effectiveToday,
        ignoreDailyCap: true, // macro milestone is exempt from the daily cap
      );
      bond = award.bond;
      workingLedger = award.ledger;
    }

    final dailyKibble = isNewDay ? config.dailyKibbleBonus : 0;
    final next = state.copyWith(
      meters: decayed,
      bond: bond,
      lifeStage: life.stage,
      wallet: state.wallet.addKibble(dailyKibble),
      activeDays: activeDays,
      lastActiveDayEpoch: effectiveToday,
      // The sim clock is monotonic as well: a backward wall-clock never
      // rewinds the anchor (elapsed stays 0 until real time catches up).
      lastSimTimestampMs: nowMs > state.lastSimTimestampMs
          ? nowMs
          : state.lastSimTimestampMs,
    );

    return ResumeOutcome(
      state: next,
      ledger: workingLedger,
      mood: _mood.resolve(decayed),
      offlineHours: offlineHours,
      isNewDay: isNewDay,
      greetingBond: greetingBond,
      dailyKibble: dailyKibble,
      grewWhileAway: life.advanced,
    );
  }

  /// Apply one care interaction. Awards meters + Bond (mood-modified, daily-
  /// capped, diminishing), Kibble, the streak day, the Comfort beat (caring a
  /// Low pet back up), and checks growth. Pure in `nowMs`.
  InteractionOutcome interact({
    required PetState state,
    required CareInteraction interaction,
    required SessionInteractions session,
    required BondLedger ledger,
    required int nowMs,
    ItemDef? item,
    int toyAffinity = 0,
  }) {
    final today = _workingDay(nowMs, ledger);
    final preMood = _mood.resolve(state.meters);

    final effect = _interaction.apply(
      state.meters,
      interaction,
      session,
      item: item,
      toyAffinity: toyAffinity,
    );
    final postMood = _mood.resolve(effect.meters, recentAttentionBonus: 100);

    var bond = state.bond;
    var workingLedger = ledger.forDay(today);
    var totalAwarded = 0;

    BondAward grant(double pts, {bool ignoreCap = false}) {
      final a = _bond.award(
        bond: bond,
        rawPoints: pts,
        mood: postMood,
        ledger: workingLedger,
        todayEpochDay: today,
        ignoreDailyCap: ignoreCap,
      );
      bond = a.bond;
      workingLedger = a.ledger;
      totalAwarded += a.awarded;
      return a;
    }

    // 1) The interaction's own Bond.
    grant(effect.rawBondPoints);

    // 2) Care Streak day (forgiving freeze logic).
    final streakUpdate = _streak.registerCareDay(state.careStreak, today);
    if (streakUpdate.isNewCareDay) {
      grant(config.bondPoints.careStreakDay);
    }

    // 3) Comfort beat: caring a Low-mood pet back up out of the Low band.
    final comfortBeat = preMood == Mood.low && postMood != Mood.low;
    if (comfortBeat) {
      grant(config.bondPoints.comfortLowMood);
    }

    // 4) Growth check after the Bond change.
    final life = _life.evaluate(
      current: state.lifeStage,
      bondStage: bond.stage,
      activeDays: state.activeDays,
    );
    if (life.advanced) {
      grant(config.bondPoints.lifeStageMilestone, ignoreCap: true);
    }

    // KP-014: care-action Kibble is a bounded daily faucet. Full value up to
    // ⅔ of the cap, a 1-Kibble trickle to the cap, then zero until tomorrow —
    // earning stays rewarding, tap-farming does not (the meter floor made
    // "willing" permanently true, so play minted 5/tap forever).
    final minted = _taperCareKibble(effect.kibble, workingLedger);
    workingLedger = workingLedger.mintCareKibble(minted);

    final next = state.copyWith(
      meters: effect.meters,
      bond: bond,
      careStreak: streakUpdate.streak,
      wallet: state.wallet.addKibble(minted),
      lifeStage: life.stage,
      lastSimTimestampMs: nowMs,
    );

    return InteractionOutcome(
      state: next,
      session: effect.session,
      ledger: workingLedger,
      mood: postMood,
      bondAwarded: totalAwarded,
      kibbleAwarded: minted,
      wasNeeded: effect.wasNeeded,
      streakIncremented: streakUpdate.isNewCareDay,
      freezeUsed: streakUpdate.freezeUsed,
      streakBrokeFromCount: streakUpdate.brokeFromCount,
      comfortBeat: comfortBeat,
      grew: life.advanced,
    );
  }

  /// Current mood for [meters] (UI read).
  Mood moodOf(CareMeters meters, {double recentAttentionBonus = 0}) =>
      _mood.resolve(meters, recentAttentionBonus: recentAttentionBonus);

  /// Applies a gentle care supply (Care Corner): the item's comfort profile
  /// lifts the meters (clamped, floor-safe). Supplies are aids, not care
  /// verbs — they award no verb Bond and never touch the Care Streak (so the
  /// streak can't be farmed from a shelf) — but comforting a Low pet back out
  /// of the Low band still earns the Comfort beat (§5.4, the signature moment).
  SupplyOutcome applySupply({
    required PetState state,
    required ItemDef item,
    required BondLedger ledger,
    required int nowMs,
  }) {
    final today = _workingDay(nowMs, ledger);
    final preMood = _mood.resolve(state.meters);
    double clamp(double v) => v.clamp(config.floor, 100.0);
    final lifted = CareMeters(
      hunger: clamp(state.meters.hunger + item.satiety),
      energy: clamp(state.meters.energy + item.energy),
      hygiene: clamp(state.meters.hygiene + item.hygiene),
      happiness: clamp(state.meters.happiness + item.joy),
    );
    final postMood = _mood.resolve(lifted, recentAttentionBonus: 100);

    var bond = state.bond;
    var workingLedger = ledger.forDay(today);
    var awarded = 0;
    final comfortBeat = preMood == Mood.low && postMood != Mood.low;
    if (comfortBeat) {
      final a = _bond.award(
        bond: bond,
        rawPoints: config.bondPoints.comfortLowMood,
        mood: postMood,
        ledger: workingLedger,
        todayEpochDay: today,
      );
      bond = a.bond;
      workingLedger = a.ledger;
      awarded = a.awarded;
    }

    return SupplyOutcome(
      state: state.copyWith(
        meters: lifted,
        bond: bond,
        lastSimTimestampMs: nowMs,
      ),
      ledger: workingLedger,
      mood: postMood,
      bondAwarded: awarded,
      comfortBeat: comfortBeat,
    );
  }

  /// A comfort touch (petting/cuddle — Care Corner & Bedroom): tiny Bond
  /// (§5.4 petting +0.5, its own diminishing session track), a little joy,
  /// and the Comfort beat when it lifts a Low pet. Never touches the streak.
  ComfortOutcome comfort({
    required PetState state,
    required SessionInteractions session,
    required BondLedger ledger,
    required int nowMs,
  }) {
    final today = _workingDay(nowMs, ledger);
    final preMood = _mood.resolve(state.meters);
    final soothed = state.meters.copyWith(
      happiness:
          (state.meters.happiness +
                  config.bondPoints.pettingTouch *
                      10 *
                      _pettingDiminish(session.petting))
              .clamp(config.floor, 100.0),
    );
    final postMood = _mood.resolve(soothed, recentAttentionBonus: 100);

    var bond = state.bond;
    var workingLedger = ledger.forDay(today);
    var awarded = 0;

    void grant(double pts) {
      final a = _bond.award(
        bond: bond,
        rawPoints: pts,
        mood: postMood,
        ledger: workingLedger,
        todayEpochDay: today,
      );
      bond = a.bond;
      workingLedger = a.ledger;
      awarded += a.awarded;
    }

    grant(config.bondPoints.pettingTouch * _pettingDiminish(session.petting));
    final comfortBeat = preMood == Mood.low && postMood != Mood.low;
    if (comfortBeat) grant(config.bondPoints.comfortLowMood);

    return ComfortOutcome(
      state: state.copyWith(
        meters: soothed,
        bond: bond,
        lastSimTimestampMs: nowMs,
      ),
      session: session.incrementPetting(),
      ledger: workingLedger,
      mood: postMood,
      bondAwarded: awarded,
      comfortBeat: comfortBeat,
    );
  }

  double _pettingDiminish(int priorPets) =>
      _pow(config.diminishingFactor, priorPets);

  static double _pow(double base, int n) {
    var v = 1.0;
    for (var i = 0; i < n; i++) {
      v *= base;
    }
    return v;
  }

  /// Wakes a sleeping pet: credits +[SimConfig.sleepRegenPerHour] energy per
  /// hour napped (on top of the ordinary resume decay, so a full night still
  /// nets a bright-eyed morning), capped at the catch-up window. Pure in
  /// `nowMs`; a no-op for an awake pet.
  WakeOutcome wake({required PetState state, required int nowMs}) {
    final since = state.sleepingSinceMs;
    if (since == null) {
      return WakeOutcome(
        state: state,
        mood: _mood.resolve(state.meters),
        sleptHours: 0,
      );
    }
    final cappedMs = (nowMs - since).clamp(
      0,
      (config.maxCatchupDays * Duration.millisecondsPerDay).round(),
    );
    final hours = cappedMs / Duration.millisecondsPerHour;
    final rested = state.meters.copyWith(
      energy: (state.meters.energy + hours * config.sleepRegenPerHour).clamp(
        config.floor,
        100.0,
      ),
    );
    final next = state
        .copyWith(meters: rested, lastSimTimestampMs: nowMs)
        .wokenUp();
    return WakeOutcome(
      state: next,
      mood: _mood.resolve(rested, recentAttentionBonus: 100),
      sleptHours: hours,
    );
  }
}

/// Outcome of a Care Corner supply (meters lifted; Comfort beat when earned).
class SupplyOutcome {
  const SupplyOutcome({
    required this.state,
    required this.ledger,
    required this.mood,
    required this.bondAwarded,
    required this.comfortBeat,
  });

  final PetState state;
  final BondLedger ledger;
  final Mood mood;
  final int bondAwarded;
  final bool comfortBeat;
}

/// Outcome of a comfort touch (tiny capped Bond; Comfort beat when earned).
class ComfortOutcome {
  const ComfortOutcome({
    required this.state,
    required this.session,
    required this.ledger,
    required this.mood,
    required this.bondAwarded,
    required this.comfortBeat,
  });

  final PetState state;
  final SessionInteractions session;
  final BondLedger ledger;
  final Mood mood;
  final int bondAwarded;
  final bool comfortBeat;
}

/// Outcome of waking up (energy credited for the nap).
class WakeOutcome {
  const WakeOutcome({
    required this.state,
    required this.mood,
    required this.sleptHours,
  });

  final PetState state;
  final Mood mood;
  final double sleptHours;
}
