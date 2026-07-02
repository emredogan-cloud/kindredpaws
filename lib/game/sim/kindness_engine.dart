/// The Daily Kindness engine (GE-1) — pure and deterministic. The same date +
/// pet always offers the same pair (no RNG object, no clock reads: callers
/// pass `nowMs`), the pair always spans two different triggers AND two
/// different rooms, and completion is detected from real care moments only.
library;

import '../model/kindness.dart';

class KindnessEngine {
  const KindnessEngine();

  /// Returns the state for the day containing [nowMs]: [prior] unchanged if it
  /// is already today's, else a fresh offer (yesterday's slate simply fades —
  /// nothing is "lost", per the Charter).
  KindnessState today({
    required int nowMs,
    required String petId,
    KindnessState? prior,
  }) {
    final day = nowMs ~/ Duration.millisecondsPerDay;
    if (prior != null && prior.dayEpoch == day && prior.offered.isNotEmpty) {
      return prior;
    }
    return KindnessState(dayEpoch: day, offered: offersFor(day, petId));
  }

  /// The deterministic daily pair: seed = FNV-1a(petId) mixed with the epoch
  /// day (stable across runs/platforms — never `String.hashCode`). The second
  /// pick is the first catalog walk hit with a different trigger AND room, so
  /// the pair always reads as two distinct little adventures.
  List<String> offersFor(int dayEpoch, String petId) {
    const defs = KindnessCatalog.all;
    if (defs.isEmpty) return const [];
    final seed = _seed(dayEpoch, petId);
    final firstIdx = seed % defs.length;
    final first = defs[firstIdx];
    // Walk the whole catalog from a seed-varied offset (full coverage, so a
    // partner is always found; the offset keeps pairings fresh day to day).
    final start = 1 + ((seed >> 8) % (defs.length - 1));
    KindnessDef? second;
    for (var j = 0; j < defs.length; j++) {
      final cand = defs[(firstIdx + start + j) % defs.length];
      if (cand.trigger != first.trigger && cand.room != first.room) {
        second = cand;
        break;
      }
    }
    // Catalog diversity guarantees a partner exists; guard anyway.
    return [first.id, if (second != null) second.id];
  }

  /// A concrete care moment happened: mark any offered, matching, not-yet-done
  /// kindness complete. Returns the (possibly unchanged) state plus the defs
  /// completed *by this moment* — the caller celebrates and pays the Kibble.
  ({KindnessState state, List<KindnessDef> completed}) record(
    KindnessState state,
    KindnessTrigger trigger, {
    String? itemId,
  }) {
    final done = <KindnessDef>[];
    for (final id in state.offered) {
      if (state.isCompleted(id)) continue;
      final def = KindnessCatalog.byId(id);
      if (def == null) continue; // retired id — inert, never an error
      if (def.matches(trigger, itemId: itemId)) done.add(def);
    }
    if (done.isEmpty) return (state: state, completed: const []);
    return (
      state: state.copyWith(
        completed: [...state.completed, ...done.map((d) => d.id)],
      ),
      completed: done,
    );
  }

  /// FNV-1a 32-bit over the pet id, then the day mixed in with one more round.
  static int _seed(int dayEpoch, String petId) {
    var h = 0x811C9DC5;
    for (final c in petId.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
    }
    h = ((h ^ dayEpoch) * 0x01000193) & 0xFFFFFFFF;
    return h;
  }
}
