/// GE-2 Living Pet: the pet visibly carries its state end-to-end — a
/// low-hygiene save renders with cues, care clears them the moment the meter
/// recovers (cause → effect), and the ambient layers stay deterministic in
/// tests (motion master switch off ⇒ everything settles).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/data/kindred_save_state.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/model/care_meters.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/ui/rooms/room_scaffold.dart';
import 'package:kindredpaws/game/ui/widgets/ambient_scene.dart';
import 'package:kindredpaws/render/pet_renderer.dart';

import '../support/harness.dart';

/// A probe renderer that records what the room hands the rig — proving the
/// cue plumb-through without depending on pixels.
class _ProbeRenderer implements PetRenderer {
  PetCareCues? lastCues;
  PetMood? lastMood;

  @override
  String get backendId => 'probe';

  @override
  Widget build(
    BuildContext context, {
    required PetMood mood,
    required String lifeStage,
    PetEmotion? emotion,
    PetCareCues? cues,
  }) {
    lastMood = mood;
    lastCues = cues;
    return const SizedBox(width: 40, height: 40);
  }
}

/// Seeds a store with a pet whose meters are exactly [meters].
Future<LocalSaveStore> storeWithMeters(CareMeters meters) async {
  final store = makeStore();
  final base = KindredSaveState.newPet(
    petId: kTestPetId,
    species: 'puppy',
    name: 'Biscuit',
    nowMs: kDay0,
  );
  final state = base.copyWith(pet: base.pet.copyWith(meters: meters));
  await store.write(state.toEnvelope().toJsonString());
  return store;
}

void main() {
  testWidgets('a scruffy, sleepy, peckish save reaches the rig as cues', (
    tester,
  ) async {
    final store = await storeWithMeters(
      const CareMeters(hunger: 30, energy: 25, hygiene: 35, happiness: 80),
    );
    final c = makeController(store: store, clock: () => kDay0 + 3600000);
    await c.load();

    final probe = _ProbeRenderer();
    await tester.pumpWidget(
      MaterialApp(
        // Real rooms listen to the controller (PetStage); mirror that here.
        home: ListenableBuilder(
          listenable: c,
          builder: (_, _) => DressedPet(controller: c, rig: probe),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(probe.lastCues, isNotNull);
    expect(probe.lastCues!.mussed, isTrue);
    expect(probe.lastCues!.drowsy, isTrue);
    expect(probe.lastCues!.peckish, isTrue);
    c.dispose();
  });

  testWidgets('care clears the cue the moment the meter recovers', (
    tester,
  ) async {
    final store = await storeWithMeters(
      const CareMeters(hunger: 30, energy: 90, hygiene: 90, happiness: 80),
    );
    final c = makeController(store: store, clock: () => kDay0 + 3600000);
    await c.load();

    final probe = _ProbeRenderer();
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: c,
          builder: (_, _) => DressedPet(controller: c, rig: probe),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(probe.lastCues!.peckish, isTrue);

    // One real meal (+35 hunger: 30 → 65, above the 40 threshold).
    await c.interact(CareInteraction.feed);
    await tester.pumpAndSettle();
    expect(probe.lastCues!.peckish, isFalse, reason: 'fed ⇒ glance gone');
    c.dispose();
  });

  testWidgets('ambient scenes render statically in tests and never block '
      'pumpAndSettle', (tester) async {
    expect(AmbientScene.motionEnabled, isFalse); // the test-safety invariant
    await tester.pumpWidget(
      const MaterialApp(
        home: Stack(
          children: [
            AmbientScene(variant: AmbientVariant.kitchenSteam),
            AmbientScene(variant: AmbientVariant.bedroomStars),
            AmbientScene(
              variant: AmbientVariant.gardenButterflies,
              visitor: true,
            ),
            AmbientScene(variant: AmbientVariant.homeMotes),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle(); // settles because nothing loops
    expect(find.byType(AmbientScene), findsNWidgets(4));
  });

  testWidgets('reduced motion keeps ambient still even with motion enabled', (
    tester,
  ) async {
    AmbientScene.motionEnabled = true;
    addTearDown(() => AmbientScene.motionEnabled = false);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AmbientScene(variant: AmbientVariant.homeMotes),
        ),
      ),
    );
    await tester.pumpAndSettle(); // reduced-motion ⇒ no controller ⇒ settles
    expect(find.byType(AmbientScene), findsOneWidget);
  });
}
