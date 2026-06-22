/// Bond awarding (GAMEPLAY_AND_PROGRESSION_BIBLE.md §5.3, §5.4). Applies the
/// mood-gain modifier (×1.15 only when Joyful; never <1.0 — Risk R6) and the
/// daily soft cap (~55/day) so the player can't binge to the top tier; calendar
/// time is required. The Bond itself is monotonic (enforced by [Bond.add]).
library;

import '../model/bond.dart';
import '../model/mood.dart';
import 'sim_config.dart';

/// Tracks Bond points accrued within a single UTC day for the soft cap. Resets
/// automatically when the day rolls over.
class BondLedger {
  const BondLedger({required this.dayEpoch, required this.earnedToday});

  final int? dayEpoch;
  final int earnedToday;

  static const BondLedger empty = BondLedger(dayEpoch: null, earnedToday: 0);

  BondLedger forDay(int today) =>
      dayEpoch == today ? this : BondLedger(dayEpoch: today, earnedToday: 0);

  Map<String, dynamic> toMap() => {
    'dayEpoch': dayEpoch,
    'earnedToday': earnedToday,
  };

  factory BondLedger.fromMap(Map<String, dynamic> m) => BondLedger(
    dayEpoch: (m['dayEpoch'] as num?)?.toInt(),
    earnedToday: (m['earnedToday'] as num?)?.toInt() ?? 0,
  );
}

class BondAward {
  const BondAward({
    required this.bond,
    required this.ledger,
    required this.awarded,
  });

  final Bond bond;
  final BondLedger ledger;

  /// Points actually added after the mood modifier + daily cap.
  final int awarded;
}

class BondEngine {
  const BondEngine(this.config);

  final SimConfig config;

  /// Awards [rawPoints] (already diminished by interaction) to [bond], applying
  /// the [mood] modifier and clamping to the remaining daily soft cap.
  /// [todayEpochDay] rolls the ledger over. Bond never decreases.
  BondAward award({
    required Bond bond,
    required double rawPoints,
    required Mood mood,
    required BondLedger ledger,
    required int todayEpochDay,
    bool ignoreDailyCap = false,
  }) {
    final today = ledger.forDay(todayEpochDay);
    final modified = rawPoints * mood.bondGainModifier;

    var grant = modified.round();
    if (grant < 0) grant = 0;

    if (!ignoreDailyCap) {
      final remaining = config.bondDailySoftCap - today.earnedToday;
      final room = remaining < 0 ? 0 : remaining;
      if (grant > room) grant = room;
    }

    return BondAward(
      bond: bond.add(grant, thresholds: config.bondStageThresholds),
      ledger: BondLedger(
        dayEpoch: todayEpochDay,
        earnedToday: today.earnedToday + grant,
      ),
      awarded: grant,
    );
  }
}
