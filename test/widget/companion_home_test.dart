import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/companion_home_screen.dart';
import 'package:kindredpaws/game/ui/memory_book_screen.dart';

import '../support/harness.dart';

void main() {
  testWidgets(
    'Companion home shows pet, Care ring, Bond, and the three verbs',
    (tester) async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');

      await tester.pumpWidget(
        MaterialApp(home: CompanionHomeScreen(controller: c)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('companion-home')), findsOneWidget);
      expect(find.byKey(const Key('care-ring')), findsOneWidget);
      expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
      expect(find.byKey(const Key('bond-stage')), findsOneWidget);
      expect(find.byKey(const Key('feed-button')), findsOneWidget);
      expect(find.byKey(const Key('clean-button')), findsOneWidget);
      expect(find.byKey(const Key('play-button')), findsOneWidget);
      expect(find.text('Stranger'), findsOneWidget); // initial Bond stage
    },
  );

  testWidgets('tapping Feed grows Kibble + shows warm (never guilt) feedback', (
    tester,
  ) async {
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');

    await tester.pumpWidget(
      MaterialApp(home: CompanionHomeScreen(controller: c)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('play-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feed-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feedback-message')), findsOneWidget);
    expect(c.pet!.wallet.kibble, greaterThan(0));
  });

  testWidgets('Memory Book opens and shows the seeded memories', (
    tester,
  ) async {
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');

    await tester.pumpWidget(
      MaterialApp(home: CompanionHomeScreen(controller: c)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('memory-book-button')));
    await tester.pumpAndSettle();

    expect(find.byType(MemoryBookScreen), findsOneWidget);
    expect(find.byKey(const Key('memory-book')), findsOneWidget);
    expect(find.textContaining('Rescue Day'), findsWidgets);
  });

  testWidgets('home does not overflow on a short screen (cozy ring clamps)', (
    tester,
  ) async {
    // A realistic small phone (360×740 logical — smaller than most real devices).
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');

    await tester.pumpWidget(
      MaterialApp(home: CompanionHomeScreen(controller: c)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion-home')), findsOneWidget);
    expect(find.byKey(const Key('feed-button')), findsOneWidget);
    // No RenderFlex overflow / layout exception on the small surface.
    expect(tester.takeException(), isNull);
  });
}
