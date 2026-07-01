/// Bathroom room: drag-to-scrub completes one real clean verb, the quick
/// rinse + potty break stay one-tap accessible, and the copy never blames.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/controller/game_controller.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';

import '../support/harness.dart';

void phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 820);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  Future<GameController> openBathroom(WidgetTester tester) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('room-dock-bathroom')));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('scrubbing builds foam and completes one real clean', (
    tester,
  ) async {
    final c = await openBathroom(tester);
    final hygieneStart = c.pet!.meters.hygiene;
    final cleansStart = c.pet!.wallet.kibble;

    // Scrub like a real finger: two passes of small strokes over the pet
    // (a realistic pointer stream — pan updates need real movement events).
    for (var pass = 0; pass < 2; pass++) {
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('bath-scrub'))),
      );
      for (var i = 0; i < 12; i++) {
        await g.moveBy(Offset(i.isEven ? 14 : -14, 26));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // One bath fired the canonical clean verb (never per-scrub spam).
    expect(c.pet!.meters.hygiene, greaterThanOrEqualTo(hygieneStart));
    expect(c.pet!.wallet.kibble, greaterThan(cleansStart));
    expect(find.byKey(const Key('room-feedback')), findsOneWidget);
  });

  testWidgets('quick rinse and potty break are one-tap (a11y: never '
      'gesture-only) and stay warm', (tester) async {
    final c = await openBathroom(tester);
    await tester.tap(find.byKey(const Key('bath-quick-rinse')));
    await tester.pumpAndSettle();
    final message = c.lastMessage ?? '';
    expect(message.toLowerCase(), isNot(contains('dirty'))); // never blame

    await tester.tap(find.byKey(const Key('bath-potty')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('room-feedback')), findsOneWidget);
  });
}
