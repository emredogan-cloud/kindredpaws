/// Play Garden: owned toys play through the real verb, affection badges grow
/// with shared play (hearts, never Bond), and tiredness invites a nap.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/rooms/play_room.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';

import '../support/harness.dart';

void phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 820);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  test('affection badges are heart-tiers, never raw power', () {
    expect(PlayRoom.affectionBadge(0), isNull);
    expect(PlayRoom.affectionBadge(5), 'loved 💕');
    expect(PlayRoom.affectionBadge(15), 'favourite ⭐');
    expect(PlayRoom.affectionBadge(40), 'best friend 💖');
  });

  testWidgets('playing with the starter ball deepens its affection', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('room-dock-playRoom')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('toy-toy_bouncy_ball')), findsOneWidget);
    await tester.tap(find.byKey(const Key('toy-toy_bouncy_ball')));
    await tester.pumpAndSettle();

    expect(c.inventory.affinity(ItemCatalog.bouncyBall.id), 1);
    expect(find.byKey(const Key('room-feedback')), findsOneWidget);
    expect(c.pet!.meters.energy, lessThan(100)); // play costs energy (canon)
  });
}
