/// The three life stages (GAMEPLAY_AND_PROGRESSION_BIBLE.md §6.1,
/// GAME_TECHNICAL_SYSTEMS.md §3.1). Advancement is a DUAL gate — both a Bond
/// stage AND elapsed *active* days — so growth is lived, never bought (R7).
/// Visual delta is rig scale/param only, never a new rig.
library;

enum LifeStage {
  pupKit('pupKit', 'Pup/Kit', 0.7),
  youngOne('youngOne', 'Young One', 0.85),
  grown('grown', 'Grown', 1.0);

  const LifeStage(this.id, this.displayName, this.scale);

  /// Stable serialization id (also the key the renderer scales on).
  final String id;
  final String displayName;

  /// Rig render scale for this stage (GAME_TECHNICAL_SYSTEMS.md §3.1).
  final double scale;

  static LifeStage fromId(String id) =>
      values.firstWhere((s) => s.id == id, orElse: () => LifeStage.pupKit);
}
