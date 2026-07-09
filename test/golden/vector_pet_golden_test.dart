@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/render/pet_renderer.dart';
import 'package:kindredpaws/render/vector_pet_renderer.dart';

/// Pins the temporary vector pet's look: every mood idle (frozen at the
/// deterministic test phase) across the three life stages, for both species.
/// Linux-rendered to match CI. Regenerate: `just goldens-update`.
void main() {
  Widget grid(Species species) {
    final rig = VectorPetRenderer(
      speciesOf: () => species,
      continuousMotion: false,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF6EC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final stage in ['pupKit', 'youngOne', 'grown'])
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final mood in PetMood.values)
                      Padding(
                        padding: const EdgeInsets.all(2),
                        child: Builder(
                          builder: (context) =>
                              rig.build(context, mood: mood, lifeStage: stage),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('vector puppy — moods × stages', (tester) async {
    tester.view.physicalSize = const Size(700, 620);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(grid(Species.puppy));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/vector_pet_puppy.png'),
    );
  });

  testWidgets('vector kitten — moods × stages', (tester) async {
    tester.view.physicalSize = const Size(700, 620);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(grid(Species.kitten));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/vector_pet_kitten.png'),
    );
  });

  testWidgets('vector pet — tangible care cues (GE-2)', (tester) async {
    // Both species carrying each cue (plus all three at once): mussed coat,
    // drowsy lids, peckish glance — warm, readable, never alarming.
    const cueSets = [
      PetCareCues(mussed: true),
      PetCareCues(drowsy: true),
      PetCareCues(peckish: true),
      PetCareCues(mussed: true, drowsy: true, peckish: true),
    ];
    tester.view.physicalSize = const Size(700, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFFFF6EC),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final species in [Species.puppy, Species.kitten])
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final cues in cueSets)
                        Padding(
                          padding: const EdgeInsets.all(2),
                          child: Builder(
                            builder: (context) =>
                                VectorPetRenderer(
                                  speciesOf: () => species,
                                  continuousMotion: false,
                                ).build(
                                  context,
                                  mood: PetMood.content,
                                  lifeStage: 'grown',
                                  cues: cues,
                                ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/vector_pet_cues.png'),
    );
  });
}
