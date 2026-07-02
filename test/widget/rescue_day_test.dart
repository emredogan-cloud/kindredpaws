import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/ui/game_root.dart';
import 'package:kindredpaws/services/analytics_service.dart';

import '../support/harness.dart';

void main() {
  testWidgets('Rescue Day cold-open → adopt → routes to the Nest', (
    tester,
  ) async {
    final controller = makeController();
    await tester.pumpWidget(
      MaterialApp(home: GameRoot(controller: controller)),
    );
    await tester.pumpAndSettle(); // runs load() → no save → Rescue Day

    expect(find.byKey(const Key('rescue-day')), findsOneWidget);

    // Walk the three emotional beats.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('rescue-next')));
      await tester.pumpAndSettle();
    }

    // Choose a species.
    expect(find.byKey(const Key('choose-puppy')), findsOneWidget);
    await tester.tap(find.byKey(const Key('choose-puppy')));
    await tester.pumpAndSettle();

    // Name + adopt.
    await tester.enterText(find.byKey(const Key('name-field')), 'Biscuit');
    await tester.tap(find.byKey(const Key('confirm-adopt')));
    await tester.pumpAndSettle();

    // The app routes to the Companion home with the adopted pet.
    expect(find.byKey(const Key('companion-home')), findsOneWidget);
    expect(find.text('Biscuit'), findsWidgets);
    expect(controller.hasPet, isTrue);
  });

  testWidgets('the onboarding funnel is instrumented step by step (P5-1)', (
    tester,
  ) async {
    final controller = makeController();
    final analytics =
        controller.observability.analytics as InMemoryAnalyticsService;
    await tester.pumpWidget(
      MaterialApp(home: GameRoot(controller: controller)),
    );
    await tester
        .pumpAndSettle(); // load → no save → Rescue Day (initState fires)

    Iterable<String> steps() => analytics.recorded
        .where((e) => e.$1 == AnalyticsEvent.onboardingStep)
        .map((e) => '${e.$2['step']}');

    // The first beat fires `reach_out` on mount.
    expect(steps(), contains('reach_out'));

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('rescue-next')));
      await tester.pumpAndSettle();
    }
    expect(steps(), contains('choose_species'));

    await tester.tap(find.byKey(const Key('choose-puppy')));
    await tester.pumpAndSettle();
    expect(steps(), contains('species_selected'));

    // The default name is pre-filled → one-tap adopt is friction-free.
    await tester.tap(find.byKey(const Key('confirm-adopt')));
    await tester.pumpAndSettle();
    expect(analytics.countOf(AnalyticsEvent.rescueDayComplete), 1);
    expect(controller.hasPet, isTrue);
  });

  testWidgets('a disallowed name is gently blocked, then a clean one adopts', (
    tester,
  ) async {
    final controller = makeController();
    await tester.pumpWidget(
      MaterialApp(home: GameRoot(controller: controller)),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('rescue-next')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('choose-puppy')));
    await tester.pumpAndSettle();

    // A profane name is rejected: a warm nudge shows + no pet is adopted.
    await tester.enterText(find.byKey(const Key('name-field')), 'shithead');
    await tester.tap(find.byKey(const Key('confirm-adopt')));
    await tester.pumpAndSettle();
    expect(controller.hasPet, isFalse);
    expect(find.byKey(const Key('rescue-day')), findsOneWidget);
    expect(find.textContaining('kinder name'), findsOneWidget);

    // Fixing the name clears the nudge and lets the adopt go through.
    await tester.enterText(find.byKey(const Key('name-field')), 'Biscuit');
    await tester.pumpAndSettle();
    expect(find.textContaining('kinder name'), findsNothing);
    await tester.tap(find.byKey(const Key('confirm-adopt')));
    await tester.pumpAndSettle();
    expect(controller.hasPet, isTrue);
    expect(find.byKey(const Key('companion-home')), findsOneWidget);
  });
}
