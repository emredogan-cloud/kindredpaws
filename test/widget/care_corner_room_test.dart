/// Care Corner: always-reassuring wellness rituals, supply-shelf comfort, and
/// zero frightening presentation — no sickness exists in this game at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';

import '../support/harness.dart';
import '../support/room_test_utils.dart';

void main() {
  testWidgets('temperature check reassures; cuddle comforts; supplies '
      'consume from the shelf', (tester) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await hopToRoom(tester, 'medicalRoom');

    await tester.tap(find.byKey(const Key('care-temp-check')));
    await tester.pumpAndSettle();
    expect(c.lastMessage, contains('🌡️'));
    // The warm wall: no scary medical words, ever.
    for (final banned in ['sick', 'ill', 'fever', 'pain', 'hurt']) {
      expect(c.lastMessage!.toLowerCase(), isNot(contains(banned)));
    }

    await tester.tap(find.byKey(const Key('care-cuddle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('room-feedback')), findsOneWidget);

    // The starter vitamin chew is on the shelf; using it consumes it.
    await tester.tap(find.byKey(const Key('supply-care_vitamin_chew')));
    await tester.pumpAndSettle();
    expect(c.inventory.supplyCount(ItemCatalog.vitaminChew.id), 0);
  });
}
