/// Seasons of Us progress (GE-5, schema v10): active days spent in the
/// current season-window. Missed days never reset anything — the count
/// only pauses; a NEW season simply starts a fresh window (last season's
/// count retires quietly, and that season returns next year).
library;

class SeasonProgress {
  const SeasonProgress({required this.windowKey, required this.days});

  /// The season-window this count belongs to (e.g. `winter-2027`).
  final String windowKey;

  /// Distinct active days spent in this window so far.
  final int days;

  SeasonProgress copyWith({String? windowKey, int? days}) => SeasonProgress(
    windowKey: windowKey ?? this.windowKey,
    days: days ?? this.days,
  );

  Map<String, dynamic> toMap() => {'windowKey': windowKey, 'days': days};

  factory SeasonProgress.fromMap(Map<String, dynamic> m) => SeasonProgress(
    windowKey: m['windowKey'] as String? ?? '',
    days: (m['days'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      other is SeasonProgress &&
      other.windowKey == windowKey &&
      other.days == days;

  @override
  int get hashCode => Object.hash(windowKey, days);
}
