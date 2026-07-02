import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/game_wiring.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/main.dart';

/// Real-device E2E for the Immersive Pet Experience: every room, every
/// transition, inventory + economy + sleep persistence — one continuous
/// walkthrough of the whole home on the connected device.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const day0 = 20000 * 86400000; // deterministic clock
  const hour = Duration.millisecondsPerHour;

  /// Scrolls the room dock to [roomId] and hops there (thumb-realistic).
  Future<void> hopTo(WidgetTester tester, String roomId) async {
    final chip = find.byKey(Key('room-dock-$roomId'));
    for (final direction in const [Offset(-128, 0), Offset(128, 0)]) {
      for (var i = 0; i < 8 && chip.evaluate().isEmpty; i++) {
        await tester.drag(find.byKey(const Key('room-dock')), direction);
        await tester.pumpAndSettle();
      }
      if (chip.evaluate().isNotEmpty) break;
    }
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  testWidgets('rooms journey: every room, shared state, sleep persists', (
    tester,
  ) async {
    final store = InMemoryLocalSaveStore();
    var now = day0;

    // ---- Session 1: adopt, then walk the whole home ----
    ServiceLocator.instance.reset();
    final config = bootstrap();
    final c1 = createGameController(
      sl: ServiceLocator.instance,
      store: store,
      clock: () => now,
    );
    await tester.pumpWidget(KindredPawsApp(config: config, controller: c1));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('rescue-next')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('choose-puppy')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name-field')), 'Biscuit');
    await tester.tap(find.byKey(const Key('confirm-adopt')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('companion-home')), findsOneWidget);
    expect(find.byKey(const Key('room-dock')), findsOneWidget);

    // Come back hungry so care is "needed" (earns full Kibble for shopping).
    await c1.onAppBackgrounded();
    now += 8 * hour;
    c1.onAppForegrounded();
    await tester.pumpAndSettle();

    // ---- Kitchen: feed from the pantry ----
    await hopTo(tester, 'kitchen');
    final bowls = c1.inventory.pantryCount(ItemCatalog.kibbleBowl.id);
    await tester.tap(find.byKey(const Key('pantry-food_kibble_bowl')));
    await tester.pumpAndSettle();
    expect(c1.inventory.pantryCount(ItemCatalog.kibbleBowl.id), bowls - 1);

    // ---- Bathroom: quick rinse + a real finger-scrub ----
    await hopTo(tester, 'bathroom');
    await tester.tap(find.byKey(const Key('bath-quick-rinse')));
    await tester.pumpAndSettle();
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('bath-scrub'))),
    );
    for (var i = 0; i < 8; i++) {
      await g.moveBy(Offset(i.isEven ? 12 : -12, 22));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();

    // ---- Play Garden: the starter ball earns affection ----
    await hopTo(tester, 'playRoom');
    await tester.tap(find.byKey(const Key('toy-toy_bouncy_ball')));
    await tester.pumpAndSettle();
    expect(c1.inventory.affinity(ItemCatalog.bouncyBall.id), 1);

    // ---- Grocery: needed-care Kibble buys a treat ----
    await hopTo(tester, 'groceryStore');
    expect(
      c1.pet!.wallet.kibble,
      greaterThanOrEqualTo(ItemCatalog.apple.kibblePrice),
    );
    final apples = c1.inventory.pantryCount(ItemCatalog.apple.id);
    await tester.tap(find.byKey(const Key('shelf-food_apple')));
    await tester.pumpAndSettle();
    expect(c1.inventory.pantryCount(ItemCatalog.apple.id), apples + 1);

    // ---- Care Corner: reassuring ritual + a vitamin ----
    await hopTo(tester, 'medicalRoom');
    await tester.tap(find.byKey(const Key('care-temp-check')));
    await tester.pumpAndSettle();
    expect(c1.lastMessage, contains('🌡️'));
    await tester.tap(find.byKey(const Key('supply-care_vitamin_chew')));
    await tester.pumpAndSettle();

    // ---- Wardrobe: closet + boutique render, premium is an invitation ----
    await hopTo(tester, 'wardrobe');
    expect(find.text('Boutique'), findsOneWidget);

    // ---- Bedroom: tuck in (the nap will survive the app restart) ----
    await hopTo(tester, 'bedroom');
    await tester.tap(find.byKey(const Key('bedroom-tuck-in')));
    await tester.pumpAndSettle();
    expect(c1.isSleeping, isTrue);
    expect(find.byKey(const Key('dream-bubble')), findsOneWidget);

    // ---- Session 2: reopen — inventory, affection, and the nap persist ----
    final kibble = c1.pet!.wallet.kibble;
    ServiceLocator.instance.reset();
    final config2 = bootstrap();
    now += 2 * hour;
    final c2 = createGameController(
      sl: ServiceLocator.instance,
      store: store,
      clock: () => now,
    );
    await tester.pumpWidget(KindredPawsApp(config: config2, controller: c2));
    await tester.pumpAndSettle();

    expect(c2.isSleeping, isTrue, reason: 'the nap continued while away');
    expect(c2.inventory.affinity(ItemCatalog.bouncyBall.id), 1);
    expect(c2.pet!.wallet.kibble, kibble);

    // Wake gently into the morning greeting.
    await hopTo(tester, 'bedroom');
    final energyAsleep = c2.pet!.meters.energy;
    await tester.tap(find.byKey(const Key('bedroom-wake')));
    await tester.pumpAndSettle();
    expect(c2.isSleeping, isFalse);
    expect(c2.pet!.meters.energy, greaterThan(energyAsleep));
  });
}
