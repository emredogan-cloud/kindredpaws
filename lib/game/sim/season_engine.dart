/// Seasons of Us (GE-5): the home turns gently with the real year. Pure
/// date math — no clocks read here, no server needed, and nothing ever
/// expires: every season returns, every seasonal keepsake is earnable
/// again next year (Charter: anti-FOMO by construction).
library;

/// The four nature seasons (deliberately not holidays — cultural/religious
/// calendar content stays a founder decision, roadmap §7).
enum NatureSeason {
  spring('Spring', '🌸'),
  summer('Summer', '🌞'),
  autumn('Autumn', '🍂'),
  winter('Winter', '❄️');

  const NatureSeason(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

/// The season containing [nowMs] (UTC). Northern by default; [southern]
/// shifts by half a year (the Settings toggle, for friends below the
/// equator).
NatureSeason seasonFor(int nowMs, {bool southern = false}) {
  final month = DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true).month;
  final northern = switch (month) {
    3 || 4 || 5 => NatureSeason.spring,
    6 || 7 || 8 => NatureSeason.summer,
    9 || 10 || 11 => NatureSeason.autumn,
    _ => NatureSeason.winter,
  };
  if (!southern) return northern;
  return switch (northern) {
    NatureSeason.spring => NatureSeason.autumn,
    NatureSeason.summer => NatureSeason.winter,
    NatureSeason.autumn => NatureSeason.spring,
    NatureSeason.winter => NatureSeason.summer,
  };
}

/// A stable key for one season-window (e.g. `winter-2027`): December belongs
/// to the WINDOW of the season it starts (northern winter Dec 2026 + Jan/Feb
/// 2027 share `winter-2027`), so a mid-season new year never resets the
/// gentle 5-day keepsake count.
String seasonWindowKey(int nowMs, {bool southern = false}) {
  final date = DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true);
  final season = seasonFor(nowMs, southern: southern);
  // The Dec-spanning season (winter N / summer S) files December under the
  // coming year; all other months use their own year.
  final year = date.month == 12 ? date.year + 1 : date.year;
  return '${season.name}-$year';
}

/// Active days in one season-window before its keepsake is earned. Five
/// gentle visits — presence, not streak pressure (missed days never reset).
const int seasonKeepsakeDays = 5;
