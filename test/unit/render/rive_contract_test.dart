import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/render/pet_renderer.dart';
import 'package:kindredpaws/render/rive_pet_renderer.dart';

/// Pins the rig ↔ client contract documented in `docs/RIVE_CONTRACTOR_HANDOFF.md`
/// so the doc and the code can never silently drift (P4-2). If the rig is
/// re-authored or these names/encodings change, this test (and the handoff doc)
/// must change together.
void main() {
  group('Rive contract — state machine + input names', () {
    test('names match the handoff spec exactly (case-sensitive)', () {
      expect(kRiveStateMachine, 'PetStateMachine');
      expect(kRiveMoodInput, 'mood');
      expect(kRiveLifeStageInput, 'lifeStage');
      expect(kRiveEmotionInput, 'emotion');
    });
  });

  group('Rive contract — input encodings', () {
    test('mood → 0..3 in joyful/content/wistful/low order', () {
      expect(PetMood.values.map(riveMoodValue).toList(), [0.0, 1.0, 2.0, 3.0]);
      expect(PetMood.joyful.index, 0);
      expect(PetMood.low.index, 3);
    });

    test('emotion → 0..11 in the canonical 12-motion order', () {
      const expected = <PetEmotion, double>{
        PetEmotion.happy: 0,
        PetEmotion.excited: 1,
        PetEmotion.playful: 2,
        PetEmotion.affectionate: 3,
        PetEmotion.content: 4,
        PetEmotion.proud: 5,
        PetEmotion.calm: 6,
        PetEmotion.sleepy: 7,
        PetEmotion.curious: 8,
        PetEmotion.lonely: 9,
        PetEmotion.hungry: 10,
        PetEmotion.comforted: 11,
      };
      expect(PetEmotion.values.length, 12);
      expected.forEach((emotion, value) {
        expect(riveEmotionValue(emotion), value, reason: emotion.name);
      });
    });

    test('lifeStage → 0..2 with a safe default to infancy', () {
      expect(riveLifeStageValue('pupKit'), 0.0);
      expect(riveLifeStageValue('youngOne'), 1.0);
      expect(riveLifeStageValue('grown'), 2.0);
      expect(riveLifeStageValue('anything-unknown'), 0.0);
    });

    test('life-stage render scale matches the spec (0.7/0.85/1.0)', () {
      expect(lifeStageScale('pupKit'), 0.7);
      expect(lifeStageScale('youngOne'), 0.85);
      expect(lifeStageScale('grown'), 1.0);
    });
  });
}
