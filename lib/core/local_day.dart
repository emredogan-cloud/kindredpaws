/// The device-local calendar frame (KP-016/KP-018). One seam converts
/// absolute epoch instants into the player's LOCAL day/hour so streak days,
/// the daily bonus, kindness rollovers, season windows, and notification
/// anchors all flip at the player's midnight — not UTC's (a UTC+13 player's
/// "new day" used to arrive mid-afternoon; a "10am hello" at 2am California
/// time).
///
/// Injectable + pure so the sim stays deterministic: tests pass a fixed
/// offset ([utcOffsetNone] keeps the historical UTC frame), production wires
/// [deviceUtcOffsetAt] (the OS timezone database via Dart's local DateTime —
/// DST-correct because the offset is evaluated AT the queried instant).
library;

/// The UTC offset in effect at [epochMs] (half-hour and 45-minute zones are
/// real — always a [Duration], never whole hours).
typedef UtcOffsetAt = Duration Function(int epochMs);

/// Fixed UTC frame — the deterministic default for tests and pure fixtures.
Duration utcOffsetNone(int epochMs) => Duration.zero;

/// The device's real offset at [epochMs] (production wiring; DST-correct).
Duration deviceUtcOffsetAt(int epochMs) =>
    DateTime.fromMillisecondsSinceEpoch(epochMs).timeZoneOffset;

/// The LOCAL calendar day (days since epoch in the local frame) containing
/// [ms].
int localDayOf(int ms, UtcOffsetAt offsetAt) =>
    (ms + offsetAt(ms).inMilliseconds) ~/ Duration.millisecondsPerDay;

/// The absolute instant of local wall-clock [hour] on local calendar day
/// [localDay]. Evaluates the offset at the TARGET (with one refinement pass)
/// so an anchor across a DST change still lands on the wall-clock hour.
int msAtLocalHour(int localDay, int hour, UtcOffsetAt offsetAt) {
  final wall =
      localDay * Duration.millisecondsPerDay +
      hour * Duration.millisecondsPerHour;
  final guess = wall - offsetAt(wall).inMilliseconds;
  return wall - offsetAt(guess).inMilliseconds;
}

/// [ms] shifted into the local frame — feed this to pure date math that
/// expects "UTC" fields (e.g. month-of-year for seasons) to read local dates.
int toLocalFrame(int ms, UtcOffsetAt offsetAt) =>
    ms + offsetAt(ms).inMilliseconds;
