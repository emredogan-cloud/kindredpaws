/// Home room × Daily Kindnesses (GE-1): the invitation chip appears with the
/// pet, and opening it shows today's two cards — invitations with a visible
/// thank-you, never a claim button, never a countdown.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';

import '../support/harness.dart';

void phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 820);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  testWidgets('the kindness chip appears on Home and opens today\'s pair', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    final chip = find.byKey(const Key('kindness-chip'));
    expect(chip, findsOneWidget);

    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(find.text('Today\'s kindnesses 💛'), findsOneWidget);
    final cards = find.byWidgetPredicate(
      (w) => w.key != null && w.key.toString().contains('kindness-card-'),
    );
    expect(cards, findsNWidgets(2));
    // Cards are invitations — no claim button anywhere.
    expect(find.widgetWithText(ElevatedButton, 'Claim'), findsNothing);
  });
}
