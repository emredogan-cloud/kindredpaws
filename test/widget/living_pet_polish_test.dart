/// E5 living-pet polish: stroking the pet is a real (capped) cuddle, meals
/// visibly fly from the shelf to the snoot, and the system reduced-motion
/// setting stills every loop.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';
import 'package:kindredpaws/render/pet_renderer.dart';
import 'package:kindredpaws/render/vector_pet_renderer.dart';

import '../support/harness.dart';
import '../support/room_test_utils.dart';

void main() {
  testWidgets('stroking the pet lands a cuddle (petting bond, capped)', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    // The Kitchen hosts a PetStage (the Home pet keeps its tap-only ring).
    await hopToRoom(tester, 'kitchen');
    final bondBefore = c.pet!.bond.value;

    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('room-pet-tap'))),
    );
    for (var i = 0; i < 14; i++) {
      await g.moveBy(Offset(i.isEven ? 22 : -22, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();

    expect(c.pet!.bond.value, greaterThanOrEqualTo(bondBefore));
    expect(c.petLine, isNotNull); // the pet responded to the cuddle
  });

  testWidgets('feeding flies the meal from the shelf to the pet', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await hopToRoom(tester, 'kitchen');
    await tester.tap(find.byKey(const Key('pantry-food_kibble_bowl')));
    await tester.pump(const Duration(milliseconds: 200)); // mid-flight
    expect(find.byKey(const Key('flying-snack')), findsOneWidget);
    await tester.pumpAndSettle(); // one-shot — lands and clears
    expect(find.byKey(const Key('flying-snack')), findsNothing);
  });

  testWidgets('reduced motion stills the vector idle loop (a11y)', (
    tester,
  ) async {
    const rig = VectorPetRenderer(); // motion on by default
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => rig.build(
                context,
                mood: PetMood.joyful,
                lifeStage: 'pupKit',
              ),
            ),
          ),
        ),
      ),
    );
    // With reduced motion the idle never loops: this settles instead of
    // timing out.
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
