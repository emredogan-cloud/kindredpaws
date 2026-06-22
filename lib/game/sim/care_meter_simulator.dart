/// Deterministic, elapsed-time Care-Meter decay + offline catch-up
/// (GAMEPLAY_AND_PROGRESSION_BIBLE.md §5.7, GAME_TECHNICAL_SYSTEMS.md §3.3).
///
/// Hard invariants (Risk R4/R6), enforced here regardless of config:
///  - no meter EVER drops below the floor ("sad but safe");
///  - the first `graceHours` of absence decay at a reduced rate ("the pet
///    napped"), softening the return;
///  - total decay is capped at `maxCatchupDays` so a long-lapsed player never
///    meets a pet that "neglected itself for a month" (longing, not guilt);
///  - negative elapsed time (clock skew) is clamped to zero.
library;

import '../model/care_meters.dart';
import 'sim_config.dart';

class CareMeterSimulator {
  const CareMeterSimulator(this.config);

  final SimConfig config;

  /// Effective decay-hours for an absence of [elapsedMs], applying the grace
  /// multiplier to the first `graceHours` and the MAX_CATCHUP cap. Pure.
  double effectiveDecayHours(int elapsedMs) {
    if (elapsedMs <= 0) return 0;
    final maxMs = (config.maxCatchupDays * Duration.millisecondsPerDay).round();
    final cappedMs = elapsedMs > maxMs ? maxMs : elapsedMs;
    final hours = cappedMs / Duration.millisecondsPerHour;
    final graceH = hours < config.graceHours ? hours : config.graceHours;
    final fullH = hours - graceH;
    return graceH * config.graceDecayMult + fullH;
  }

  /// Applies decay for [elapsedMs] of real time. Deterministic: identical inputs
  /// always yield identical output (server-validatable, G1).
  CareMeters applyDecay(CareMeters meters, int elapsedMs) {
    final h = effectiveDecayHours(elapsedMs);
    if (h == 0) return meters;

    double decayed(CareNeed need, double v) {
      final next = v - (config.decayPerHour[need] ?? 0) * h;
      return _clampFloor(next);
    }

    final hunger = decayed(CareNeed.hunger, meters.hunger);
    final energy = decayed(CareNeed.energy, meters.energy);
    final hygiene = decayed(CareNeed.hygiene, meters.hygiene);
    var happiness = decayed(CareNeed.happiness, meters.happiness);

    // Small passive happiness recovery (§5.1): +rate/h while the other three
    // are comfortably high. Won't fire over long absences (they decay first).
    final t = config.happinessPassiveThreshold;
    if (hunger > t && energy > t && hygiene > t) {
      happiness = _clampFloor(happiness + config.happinessPassivePerHour * h);
    }

    return CareMeters(
      hunger: hunger,
      energy: energy,
      hygiene: hygiene,
      happiness: happiness,
    );
  }

  double _clampFloor(double v) {
    if (v < config.floor) return config.floor;
    if (v > 100) return 100;
    return v;
  }
}
