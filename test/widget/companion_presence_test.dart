import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/companion_home_screen.dart';
import 'package:kindredpaws/heartmind/safety_filter.dart';

import '../support/harness.dart';

const _day = 86400000;
const _hour = 3600000;
const _day0 = 20000 * _day;

void main() {
  group('Companion Presence (the pet feels alive)', () {
    test('the pet speaks a warm line on adopt + on care', () async {
      final c = makeController(clock: () => _day0);
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      expect(c.petLine, isNotNull); // first words
      final greeting = c.petLine;

      await c.interact(CareInteraction.play);
      expect(c.petLine, isNotNull);
      // The line changed to a care acknowledgement.
      expect(c.petLine, isNot(greeting));
      c.dispose();
    });

    test('every spoken line is safe — never guilt (Risk R1/R6)', () async {
      final c = makeController(clock: () => _day0);
      await c.load();
      await c.adopt(species: Species.kitten, name: 'Mochi');
      for (final i in CareInteraction.values) {
        await c.interact(i);
        expect(const SafetyFilter().validateOutput(c.petLine!).safe, isTrue);
      }
      c.dispose();
    });

    test('nudgeAmbient gives an idle line + ambient expression', () async {
      final c = makeController(clock: () => _day0);
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      c.nudgeAmbient();
      expect(c.ambientEmotion, isNotNull);
      expect(c.petLine, isNotNull);
      c.dispose();
    });

    test(
      'returning after a real absence still greets warmly (never guilt)',
      () async {
        final store = makeStore();
        final first = makeController(store: store, clock: () => _day0);
        await first.load();
        await first.adopt(species: Species.puppy, name: 'Biscuit');
        first.dispose();

        // Reopen 2 days later → a "returning" beat.
        final next = makeController(
          store: store,
          clock: () => _day0 + 2 * _day + _hour,
        );
        await next.load();
        expect(next.petLine, isNotNull);
        expect(const SafetyFilter().validateOutput(next.petLine!).safe, isTrue);
        next.dispose();
      },
    );

    testWidgets('home shows the speech bubble + the pet is tappable', (
      tester,
    ) async {
      final c = makeController(clock: () => _day0);
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');

      await tester.pumpWidget(
        MaterialApp(home: CompanionHomeScreen(controller: c)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pet-speech')), findsOneWidget);

      await tester.tap(find.byKey(const Key('pet-tap')));
      await tester.pumpAndSettle();
      expect(c.ambientEmotion, isNotNull);
      c.dispose();
    });
  });
}
