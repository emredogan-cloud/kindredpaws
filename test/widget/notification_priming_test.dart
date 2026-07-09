/// KP-023 — the ONE notification-permission prompt is spent wisely: never at
/// cold boot (it used to pop over the rainy cold-open's first beat), only
/// after the player is invested, via the warm priming card.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';
import 'package:kindredpaws/services/notification_scheduler.dart';
import 'package:kindredpaws/services/prefs_service.dart';

import '../support/harness.dart';
import '../support/room_test_utils.dart';

void main() {
  InMemoryNotificationScheduler scheduler() =>
      ServiceLocator.instance.get<NotificationScheduler>()
          as InMemoryNotificationScheduler;

  testWidgets('no OS prompt at boot; the card waits for investment', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    // Cold boot + adoption: the one prompt has NOT been spent.
    expect(scheduler().permissionRequests, 0);
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    expect(scheduler().permissionRequests, 0);

    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();
    // Adopted but not yet interacted → still no card, still no prompt.
    expect(find.byKey(const Key('notification-priming')), findsNothing);

    // The first care action lands → the invested moment → the card appears.
    await c.interact(CareInteraction.feed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notification-priming')), findsOneWidget);
    expect(scheduler().permissionRequests, 0); // card ≠ prompt

    // Accepting spends the one prompt — exactly once — and thanks warmly.
    await tester.tap(find.byKey(const Key('notification-priming-accept')));
    await tester.pumpAndSettle();
    expect(scheduler().permissionRequests, 1);
    expect(find.byKey(const Key('notification-priming')), findsNothing);
    c.dispose();
  });

  testWidgets('declining never prompts and never re-offers', (tester) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await c.interact(CareInteraction.feed);
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification-priming-decline')));
    await tester.pumpAndSettle();
    expect(scheduler().permissionRequests, 0);
    expect(find.byKey(const Key('notification-priming')), findsNothing);
    // The choice is device-persistent (the hints seen-set), so it never
    // re-offers — Settings remains the path.
    expect(
      ServiceLocator.instance.get<PrefsService>().seenHints,
      contains('notification_priming'),
    );
    c.dispose();
  });
}
