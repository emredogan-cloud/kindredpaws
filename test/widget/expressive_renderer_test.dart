import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/ui/mood_visuals.dart';
import 'package:kindredpaws/render/pet_renderer.dart';
import 'package:kindredpaws/render/rive_pet_renderer.dart';

import '../support/harness.dart';

void main() {
  group('Expressive placeholder renderer', () {
    testWidgets('shows the given emotion and settles (test-safe animation)', (
      tester,
    ) async {
      const renderer = PlaceholderPetRenderer();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => renderer.build(
              context,
              mood: PetMood.joyful,
              lifeStage: 'pupKit',
              emotion: PetEmotion.playful,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(); // one-shot pop settles
      expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
      expect(find.byIcon(PetEmotion.playful.icon), findsOneWidget);
    });

    testWidgets('defaults to the resting expression when no emotion given', (
      tester,
    ) async {
      const renderer = PlaceholderPetRenderer();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) =>
                renderer.build(context, mood: PetMood.low, lifeStage: 'grown'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byIcon(PetEmotion.restingFor(PetMood.low).icon),
        findsOneWidget,
      );
    });
  });

  group('Rive seam renderer', () {
    testWidgets('asset-free stand-in shows the emotion + the rive badge', (
      tester,
    ) async {
      const renderer = RivePetRenderer();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => renderer.build(
              context,
              mood: PetMood.content,
              lifeStage: 'youngOne',
              emotion: PetEmotion.proud,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(renderer.backendId, 'rive');
      expect(find.text('rive'), findsOneWidget);
      expect(find.byIcon(PetEmotion.proud.icon), findsOneWidget);
    });
  });

  group('reaction-emotion mapping (game/ui)', () {
    test('each care verb produces its reaction expression', () {
      expect(petEmotionForReaction(CareInteraction.feed), PetEmotion.happy);
      expect(
        petEmotionForReaction(CareInteraction.feed, comfort: true),
        PetEmotion.comforted,
      );
      expect(petEmotionForReaction(CareInteraction.clean), PetEmotion.proud);
      expect(petEmotionForReaction(CareInteraction.play), PetEmotion.playful);
    });

    testWidgets('currentPetEmotion reacts to the last verb, else rests', (
      tester,
    ) async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      // No interaction yet → resting expression for the mood.
      expect(currentPetEmotion(c).mood, petMoodFor(c.mood));

      await c.interact(CareInteraction.play);
      expect(currentPetEmotion(c), PetEmotion.playful);
      c.dispose();
    });
  });
}
