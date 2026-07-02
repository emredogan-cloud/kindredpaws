/// Bedroom: tuck-in starts the persisted nap (dream bubble from real Memory
/// Book facts, starlit hush, sleepy pet in every room), waking is always one
/// tap and greets the morning with the nap's energy credited.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/rooms/bedroom_room.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';
import 'package:kindredpaws/heartmind/memory_fact.dart';

import '../support/harness.dart';
import '../support/room_test_utils.dart';

void main() {
  test('dreams come from the Memory Book (real remembered likes)', () {
    final facts = [
      MemoryFact(
        key: FactKey.likesActivity,
        value: 'chasing the ball',
        source: FactSource.onboarding,
        confidence: 1,
        createdAtMs: 0,
      ),
    ];
    expect(BedroomRoom.dreamLine(facts), contains('chasing the ball'));
    expect(BedroomRoom.dreamLine(const []), contains('adventures'));
  });

  testWidgets('tuck in → starlit dream → gentle wake with morning greeting', (
    tester,
  ) async {
    phoneView(tester);
    var now = kDay0;
    final c = makeController(clock: () => now);
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await hopToRoom(tester, 'bedroom');

    await tester.tap(find.byKey(const Key('bedroom-tuck-in')));
    await tester.pumpAndSettle();
    expect(c.isSleeping, isTrue);
    expect(find.byKey(const Key('dream-bubble')), findsOneWidget);
    expect(find.textContaining('chasing the ball'), findsOneWidget);

    // Sleep hushes care everywhere: hop to the kitchen and try to feed.
    await hopToRoom(tester, 'kitchen');
    await tester.tap(find.byKey(const Key('pantry-food_kibble_bowl')));
    await tester.pumpAndSettle();
    expect(c.lastMessage, contains('asleep'));

    // Back to the bedroom for a gentle two-hour-later wake.
    await hopToRoom(tester, 'bedroom');
    now += 2 * Duration.millisecondsPerHour;
    await tester.tap(find.byKey(const Key('bedroom-wake')));
    await tester.pumpAndSettle();
    expect(c.isSleeping, isFalse);
    expect(find.byKey(const Key('bedroom-tuck-in')), findsOneWidget);
  });
}
