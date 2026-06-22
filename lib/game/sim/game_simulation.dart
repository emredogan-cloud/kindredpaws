/// The deterministic core-loop orchestrator. Ties the Care-Meter decay, mood,
/// Bond, Care Streak, and life-stage engines into the two operations the game
/// performs: [resolveOnResume] (offline catch-up + greeting + growth) and
/// [interact] (feed/clean/play → meters, Bond, streak, comfort, growth).
///
/// Everything is a pure function of its inputs + an explicit `nowMs`, so the sim
/// is deterministic and server-validatable (gate G1). No wall-clock is read here.
library;

import '../model/care_meters.dart';
import '../model/mood.dart';
import '../model/pet_state.dart';
import 'bond_engine.dart';
import 'care_meter_simulator.dart';
import 'care_streak_engine.dart';
import 'interaction.dart';
import 'life_stage_engine.dart';
import 'mood_resolver.dart';
import 'sim_config.dart';

int dayOfMs(int ms) => ms ~/ Duration.millisecondsPerDay;

class ResumeOutcome {
  const ResumeOutcome({
    required this.state,
    required this.ledger,
    required this.mood,
    required this.offlineHours,
    required this.isNewDay,
    required this.greetingBond,
    required this.grewWhileAway,
  });

  final PetState state;
  final BondLedger ledger;
  final Mood mood;
  final double offlineHours;
  final bool isNewDay;
  final int greetingBond;
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
  final bool comfortBeat;
  final bool grew;
}

class GameSimulation {
  GameSimulation(this.config)
    : _meters = CareMeterSimulator(config),
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
  final CareMeterSimulator _meters;
  final MoodResolver _mood;
  final BondEngine _bond;
  final InteractionEngine _interaction;
  final CareStreakEngine _streak;
  final LifeStageEngine _life;

  MoodResolver get mood => _mood;

  /// Resolve elapsed time on foreground: decay (never below floor, longing not
  /// guilt), count the active day, award the first-daily greeting, and check
  /// growth. Pure in `nowMs`.
  ResumeOutcome resolveOnResume({
    required PetState state,
    required BondLedger ledger,
    required int nowMs,
  }) {
    final elapsed = nowMs - state.lastSimTimestampMs;
    final decayed = _meters.applyDecay(state.meters, elapsed);
    final offlineHours = _meters.effectiveDecayHours(elapsed < 0 ? 0 : elapsed);
    final today = dayOfMs(nowMs);

    final isNewDay = state.lastActiveDayEpoch != today;
    final activeDays = isNewDay ? state.activeDays + 1 : state.activeDays;

    var bond = state.bond;
    var workingLedger = ledger.forDay(today);
    var greetingBond = 0;
    if (isNewDay) {
      final award = _bond.award(
        bond: bond,
        rawPoints: config.bondPoints.firstDailyGreeting,
        mood: _mood.resolve(decayed),
        ledger: workingLedger,
        todayEpochDay: today,
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
        todayEpochDay: today,
        ignoreDailyCap: true, // macro milestone is exempt from the daily cap
      );
      bond = award.bond;
      workingLedger = award.ledger;
    }

    final next = state.copyWith(
      meters: decayed,
      bond: bond,
      lifeStage: life.stage,
      activeDays: activeDays,
      lastActiveDayEpoch: today,
      lastSimTimestampMs: nowMs,
    );

    return ResumeOutcome(
      state: next,
      ledger: workingLedger,
      mood: _mood.resolve(decayed),
      offlineHours: offlineHours,
      isNewDay: isNewDay,
      greetingBond: greetingBond,
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
  }) {
    final today = dayOfMs(nowMs);
    final preMood = _mood.resolve(state.meters);

    final effect = _interaction.apply(state.meters, interaction, session);
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

    final next = state.copyWith(
      meters: effect.meters,
      bond: bond,
      careStreak: streakUpdate.streak,
      wallet: state.wallet.addKibble(effect.kibble),
      lifeStage: life.stage,
      lastSimTimestampMs: nowMs,
    );

    return InteractionOutcome(
      state: next,
      session: effect.session,
      ledger: workingLedger,
      mood: postMood,
      bondAwarded: totalAwarded,
      kibbleAwarded: effect.kibble,
      wasNeeded: effect.wasNeeded,
      streakIncremented: streakUpdate.isNewCareDay,
      freezeUsed: streakUpdate.freezeUsed,
      comfortBeat: comfortBeat,
      grew: life.advanced,
    );
  }

  /// Current mood for [meters] (UI read).
  Mood moodOf(CareMeters meters, {double recentAttentionBonus = 0}) =>
      _mood.resolve(meters, recentAttentionBonus: recentAttentionBonus);
}
