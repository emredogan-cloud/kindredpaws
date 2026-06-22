/// Care Streak + Streak Warmth (GAMEPLAY_AND_PROGRESSION_BIBLE.md §11.1–11.2,
/// Risk R6). Forgiving by design: a broken streak NEVER harms the pet or the
/// Bond. Streak Warmth (banked freezes) auto-protects a missed day; a lapse can
/// be repaired once. "Your streak stayed warm 🔥", never "STREAK LOST".
library;

class CareStreak {
  const CareStreak({
    required this.count,
    required this.lastCareDayEpoch,
    required this.warmthBanked,
  });

  /// Consecutive care-days.
  final int count;

  /// Epoch *day* number (days since Unix epoch, UTC) of the last care day; null
  /// before the first care action ever.
  final int? lastCareDayEpoch;

  /// Banked Streak-Warmth freezes available to auto-protect a missed day.
  final int warmthBanked;

  static const CareStreak initial = CareStreak(
    count: 0,
    lastCareDayEpoch: null,
    warmthBanked: 0,
  );

  CareStreak copyWith({
    int? count,
    int? lastCareDayEpoch,
    bool clearLastCareDay = false,
    int? warmthBanked,
  }) => CareStreak(
    count: count ?? this.count,
    lastCareDayEpoch: clearLastCareDay
        ? null
        : (lastCareDayEpoch ?? this.lastCareDayEpoch),
    warmthBanked: warmthBanked ?? this.warmthBanked,
  );

  Map<String, dynamic> toMap() => {
    'count': count,
    'lastCareDay': lastCareDayEpoch,
    'warmthBanked': warmthBanked,
  };

  factory CareStreak.fromMap(Map<String, dynamic> m) => CareStreak(
    count: (m['count'] as num?)?.toInt() ?? 0,
    lastCareDayEpoch: (m['lastCareDay'] as num?)?.toInt(),
    warmthBanked: (m['warmthBanked'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      other is CareStreak &&
      other.count == count &&
      other.lastCareDayEpoch == lastCareDayEpoch &&
      other.warmthBanked == warmthBanked;

  @override
  int get hashCode => Object.hash(count, lastCareDayEpoch, warmthBanked);
}
