import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/game_wiring.dart';
import 'package:kindredpaws/main.dart';

/// End-to-end on a real device/emulator: the full Phase-1 core loop —
/// adopt (Rescue Day) → interact (affect needs + Bond) → SAVE → REOPEN →
/// CONTINUE. Proves the founder's vertical-slice requirement on-device.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const day0 = 20000 * 86400000; // deterministic clock

  testWidgets('adopt → interact → save → reopen → continue', (tester) async {
    final store = InMemoryLocalSaveStore();

    // --- First open: Rescue Day → adopt ---
    ServiceLocator.instance.reset();
    final config = bootstrap();
    final first = createGameController(
      sl: ServiceLocator.instance,
      store: store,
      clock: () => day0,
    );
    await tester.pumpWidget(KindredPawsApp(config: config, controller: first));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rescue-day')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('rescue-next')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('choose-puppy')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name-field')), 'Biscuit');
    await tester.tap(find.byKey(const Key('confirm-adopt')));
    await tester.pumpAndSettle();

    // --- Companion home: interact (affect needs + Bond) ---
    expect(find.byKey(const Key('companion-home')), findsOneWidget);
    await tester.tap(find.byKey(const Key('play-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feed-button')));
    await tester.pumpAndSettle();
    final bond = first.pet!.bond.value;
    final kibble = first.pet!.wallet.kibble;
    expect(bond, greaterThan(0));
    expect(kibble, greaterThan(0));

    // --- Reopen: a fresh controller over the SAME local store continues ---
    ServiceLocator.instance.reset();
    final config2 = bootstrap();
    final second = createGameController(
      sl: ServiceLocator.instance,
      store: store,
      clock: () => day0,
    );
    await tester.pumpWidget(
      KindredPawsApp(config: config2, controller: second),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion-home')), findsOneWidget);
    expect(find.text('Biscuit'), findsWidgets);
    expect(second.pet!.bond.value, bond); // continued, not reset
    expect(second.pet!.wallet.kibble, kibble);
  });
}
