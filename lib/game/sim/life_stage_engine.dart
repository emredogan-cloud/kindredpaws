/// Life-stage advancement (GAMEPLAY_AND_PROGRESSION_BIBLE.md §6.1,
/// GAME_TECHNICAL_SYSTEMS.md §3.1). A **dual gate**: advancement needs BOTH a
/// Bond stage AND elapsed *active* days, so growth is lived, never bought (R7).
/// One-directional and terminal at Grown — the pet never regresses or ages to
/// decline (§6.4).
library;

import '../model/bond.dart';
import '../model/life_stage.dart';

class LifeStageUpdate {
  const LifeStageUpdate({required this.stage, required this.advanced});

  final LifeStage stage;

  /// True if this evaluation advanced the stage (triggers the +50 Bond
  /// milestone + stage-up ceremony).
  final bool advanced;
}

class LifeStageEngine {
  const LifeStageEngine({
    this.youngOneMinBondRank = 1, // Friend
    this.youngOneMinActiveDays = 5,
    this.grownMinBondRank = 2, // Companion
    this.grownMinActiveDays = 28,
  });

  final int youngOneMinBondRank;
  final int youngOneMinActiveDays;
  final int grownMinBondRank;
  final int grownMinActiveDays;

  /// The highest stage [current] may advance to given [bondStage] + [activeDays].
  /// Never regresses (returns the max of current and eligible).
  LifeStageUpdate evaluate({
    required LifeStage current,
    required BondStage bondStage,
    required int activeDays,
  }) {
    LifeStage eligible = LifeStage.pupKit;
    if (bondStage.rank >= grownMinBondRank &&
        activeDays >= grownMinActiveDays) {
      eligible = LifeStage.grown;
    } else if (bondStage.rank >= youngOneMinBondRank &&
        activeDays >= youngOneMinActiveDays) {
      eligible = LifeStage.youngOne;
    }

    // One-directional: never below the current stage.
    final next = eligible.index > current.index ? eligible : current;
    return LifeStageUpdate(stage: next, advanced: next.index > current.index);
  }
}
