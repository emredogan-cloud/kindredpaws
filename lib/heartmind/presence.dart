/// Companion Presence helpers (GAME_TECHNICAL_SYSTEMS.md §6, P2-4): daypart
/// awareness + the ambient idle scheduler that makes the pet feel alive between
/// care actions. Pure + deterministic (no wall-clock read here; the hour/tick
/// are passed in) so it stays testable. NEVER guilt/punish/shame — every beat
/// reinforces attachment (Risk R6).
library;

import '../render/pet_renderer.dart';

enum DayPart {
  morning('morning'),
  afternoon('afternoon'),
  evening('evening'),
  night('night');

  const DayPart(this.id);
  final String id;

  static DayPart fromHour(int hour) {
    if (hour >= 5 && hour < 12) return DayPart.morning;
    if (hour >= 12 && hour < 17) return DayPart.afternoon;
    if (hour >= 17 && hour < 22) return DayPart.evening;
    return DayPart.night;
  }
}

/// A weighted, deterministic ambient idle scheduler. Picks the pet's next idle
/// expression from the emotions in the current mood family, nudged by daypart
/// (night → sleepier, morning → friskier). `tick` advances the rotation so the
/// pet doesn't repeat the same idle twice in a row.
class AmbientScheduler {
  const AmbientScheduler();

  /// The idle expression for the given [mood] + [dayPart] + [tick].
  PetEmotion idleEmotion({
    required PetMood mood,
    required DayPart dayPart,
    required int tick,
  }) {
    // Night calms everyone down; morning lifts joyful pets to friskier idles.
    if (dayPart == DayPart.night && mood != PetMood.joyful) {
      return PetEmotion.sleepy;
    }
    final pool = _idlePool(mood, dayPart);
    return pool[tick.abs() % pool.length];
  }

  List<PetEmotion> _idlePool(PetMood mood, DayPart dayPart) {
    switch (mood) {
      case PetMood.joyful:
        return dayPart == DayPart.morning
            ? const [PetEmotion.excited, PetEmotion.playful, PetEmotion.happy]
            : const [
                PetEmotion.playful,
                PetEmotion.happy,
                PetEmotion.affectionate,
              ];
      case PetMood.content:
        return const [PetEmotion.content, PetEmotion.calm, PetEmotion.curious];
      case PetMood.wistful:
        return const [PetEmotion.curious, PetEmotion.lonely, PetEmotion.sleepy];
      case PetMood.low:
        return const [PetEmotion.comforted, PetEmotion.sleepy];
    }
  }
}
