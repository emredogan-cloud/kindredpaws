import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/game_wiring.dart';
import 'package:kindredpaws/main.dart';
import 'package:kindredpaws/services/analytics_service.dart';

/// Real-device E2E for the full required journey (P6 validation sprint):
/// Rescue Day → adopt → feed/play/clean → Bond + Care change → Heartmind line →
/// Memory Book → Keepsakes → analytics emitted → reopen continues. Drives the
/// real app widget tree on the connected device via `flutter test -d <device>`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const day0 = 20000 * 86400000; // deterministic clock

  testWidgets('full journey: onboard → care → memory → keepsakes → reopen', (
    tester,
  ) async {
    final store = InMemoryLocalSaveStore();

    // ---- Session 1: Rescue Day onboarding → adopt ----
    ServiceLocator.instance.reset();
    final config = bootstrap();
    final c1 = createGameController(
      sl: ServiceLocator.instance,
      store: store,
      clock: () => day0,
    );
    final analytics = c1.observability.analytics as InMemoryAnalyticsService;

    await tester.pumpWidget(KindredPawsApp(config: config, controller: c1));
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

    // ---- Companion Home: all three care verbs ----
    expect(find.byKey(const Key('companion-home')), findsOneWidget);
    for (final verb in ['feed-button', 'clean-button', 'play-button']) {
      await tester.tap(find.byKey(Key(verb)));
      await tester.pumpAndSettle();
    }

    // Care + Bond changed; the pet spoke (Heartmind) at least once.
    expect(c1.pet!.bond.value, greaterThan(0));
    expect(c1.pet!.wallet.kibble, greaterThan(0));
    expect(c1.petLine, isNotNull, reason: 'Heartmind surfaced a line');

    // Analytics emitted (PII-free taxonomy) on the mock stack.
    expect(analytics.countOf(AnalyticsEvent.rescueDayComplete), 1);
    expect(analytics.countOf(AnalyticsEvent.careAction), 3);

    // ---- Memory Book: opens + renders ----
    await tester.tap(find.byKey(const Key('memory-book-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memory-book')), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // ---- Keepsakes: opens + the Rescue Day keepsake is present ----
    await tester.tap(find.byKey(const Key('keepsakes-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('keepsakes')), findsWidgets);
    expect(c1.keepsakes, isNotEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('companion-home')), findsOneWidget);

    // ---- Reopen: a fresh controller over the same store continues ----
    final bond = c1.pet!.bond.value;
    ServiceLocator.instance.reset();
    final config2 = bootstrap();
    final c2 = createGameController(
      sl: ServiceLocator.instance,
      store: store,
      clock: () => day0,
    );
    await tester.pumpWidget(KindredPawsApp(config: config2, controller: c2));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion-home')), findsOneWidget);
    expect(find.text('Biscuit'), findsWidgets); // no re-onboarding
    expect(c2.pet!.bond.value, bond); // continued, not reset
  });
}
