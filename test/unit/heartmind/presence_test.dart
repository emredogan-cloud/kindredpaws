import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/heartmind/presence.dart';
import 'package:kindredpaws/render/pet_renderer.dart';

void main() {
  group('DayPart.fromHour', () {
    test('maps hours to dayparts', () {
      expect(DayPart.fromHour(7), DayPart.morning);
      expect(DayPart.fromHour(13), DayPart.afternoon);
      expect(DayPart.fromHour(19), DayPart.evening);
      expect(DayPart.fromHour(23), DayPart.night);
      expect(DayPart.fromHour(2), DayPart.night);
    });
  });

  group('AmbientScheduler', () {
    const sched = AmbientScheduler();

    test('idle emotions come from the mood family', () {
      final e = sched.idleEmotion(
        mood: PetMood.joyful,
        dayPart: DayPart.afternoon,
        tick: 0,
      );
      expect(e.mood, PetMood.joyful);
    });

    test('night calms a non-joyful pet to sleepy', () {
      expect(
        sched.idleEmotion(
          mood: PetMood.content,
          dayPart: DayPart.night,
          tick: 3,
        ),
        PetEmotion.sleepy,
      );
    });

    test('rotates with the tick (no immediate repeat) + is deterministic', () {
      final a = sched.idleEmotion(
        mood: PetMood.content,
        dayPart: DayPart.afternoon,
        tick: 0,
      );
      final b = sched.idleEmotion(
        mood: PetMood.content,
        dayPart: DayPart.afternoon,
        tick: 1,
      );
      expect(a, isNot(b));
      // Deterministic: same tick → same emotion.
      expect(
        sched.idleEmotion(
          mood: PetMood.content,
          dayPart: DayPart.afternoon,
          tick: 0,
        ),
        a,
      );
    });
  });
}
