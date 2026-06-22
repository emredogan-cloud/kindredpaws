/// The Bond — the single most important number (GAMEPLAY_AND_PROGRESSION_BIBLE.md
/// §5.4, §7.1). A **monotonically non-decreasing** lifetime relationship score:
/// it NEVER goes down. Neglect/low mood only dampen *gain* (Risk R6).
library;

/// The five canonical Bond stages with their entry thresholds (§7.1).
enum BondStage {
  stranger('Stranger', 0),
  friend('Friend', 250),
  companion('Companion', 1200),
  kindred('Kindred', 4000),
  soulmate('Soulmate', 10000);

  const BondStage(this.displayName, this.threshold);

  final String displayName;

  /// Bond points required to ENTER this stage (launch defaults; remote-config
  /// key `bond.stage_thresholds`).
  final int threshold;

  /// 0-based rank (Stranger=0 … Soulmate=4); lets us compare stage gates.
  int get rank => index;
}

class Bond {
  const Bond({required this.value, required this.stage});

  /// Lifetime points (monotonic non-decreasing).
  final int value;
  final BondStage stage;

  static const Bond initial = Bond(value: 0, stage: BondStage.stranger);

  /// Resolves the stage for a given point [value] against [thresholds]
  /// (defaults to the canonical §7.1 thresholds; overridable via remote config).
  static BondStage stageFor(int value, {List<int>? thresholds}) {
    final t = thresholds ?? BondStage.values.map((s) => s.threshold).toList();
    var stage = BondStage.stranger;
    for (var i = 0; i < BondStage.values.length; i++) {
      if (value >= t[i]) stage = BondStage.values[i];
    }
    return stage;
  }

  /// Adds [points] (never negative; the Bond cannot fall) and re-resolves stage.
  Bond add(int points, {List<int>? thresholds}) {
    final next = value + (points < 0 ? 0 : points);
    return Bond(
      value: next,
      stage: stageFor(next, thresholds: thresholds),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Bond && other.value == value && other.stage == stage;

  @override
  int get hashCode => Object.hash(value, stage);
}
