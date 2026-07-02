import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/render/pet_renderer.dart';

void main() {
  group('PetEmotion → PetMood mapping (GAME_CONTENT_FACTORY §5.1, 12 → 4)', () {
    test('joyful family', () {
      for (final e in [
        PetEmotion.happy,
        PetEmotion.excited,
        PetEmotion.playful,
        PetEmotion.affectionate,
      ]) {
        expect(e.mood, PetMood.joyful, reason: e.name);
      }
    });

    test('content family', () {
      for (final e in [PetEmotion.content, PetEmotion.proud, PetEmotion.calm]) {
        expect(e.mood, PetMood.content, reason: e.name);
      }
    });

    test('wistful family', () {
      for (final e in [
        PetEmotion.sleepy,
        PetEmotion.curious,
        PetEmotion.lonely,
      ]) {
        expect(e.mood, PetMood.wistful, reason: e.name);
      }
    });

    test('low family (sad but safe)', () {
      for (final e in [PetEmotion.hungry, PetEmotion.comforted]) {
        expect(e.mood, PetMood.low, reason: e.name);
      }
    });

    test('all 12 canonical emotion motions are present', () {
      expect(PetEmotion.values.length, 12);
    });
  });

  group('restingFor', () {
    test('each mood has a resting expression in its own family', () {
      for (final m in PetMood.values) {
        expect(PetEmotion.restingFor(m).mood, m);
      }
    });
  });

  group('petLifeStageScale', () {
    test('matches §3.1 scales', () {
      expect(petLifeStageScale('pupKit'), 0.7);
      expect(petLifeStageScale('youngOne'), 0.85);
      expect(petLifeStageScale('grown'), 1.0);
      expect(petLifeStageScale('?'), 0.7);
    });
  });
}
