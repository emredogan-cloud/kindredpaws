import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/companion_home_screen.dart';
import 'package:kindredpaws/game/ui/keepsake_screen.dart';

import '../support/harness.dart';

const _day0 = 20000 * 86400000;

void main() {
  testWidgets('Keepsakes open from home and show the Rescue Day card', (
    tester,
  ) async {
    final c = makeController(clock: () => _day0);
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');

    await tester.pumpWidget(
      MaterialApp(home: CompanionHomeScreen(controller: c)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('keepsakes-button')));
    await tester.pumpAndSettle();

    expect(find.byType(KeepsakeScreen), findsOneWidget);
    expect(find.byKey(const Key('keepsakes')), findsOneWidget);
    // The first card is the Rescue Day keepsake.
    expect(find.text('Rescue Day'), findsOneWidget);
    c.dispose();
  });

  testWidgets('empty scrapbook shows the warm placeholder', (tester) async {
    final c = makeController();
    // No pet adopted → no keepsakes.
    await tester.pumpWidget(MaterialApp(home: KeepsakeScreen(controller: c)));
    await tester.pumpAndSettle();
    expect(find.textContaining('beautiful cards'), findsOneWidget);
  });
}
