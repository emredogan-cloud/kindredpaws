import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/monetization/monetization_controller.dart';
import 'package:kindredpaws/monetization/product_catalog.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/beta_diagnostics.dart';
import 'package:kindredpaws/services/notification_scheduler.dart';

import '../support/harness.dart';

/// Closed-beta simulation (P4-9): one host-side walk through the whole loop,
/// proving the subsystems integrate — adopt → care → telemetry → notifications →
/// persist → reopen/restore → session quality → feedback → premium gating →
/// PII-free diagnostics. The real on-device E2E runs via `integration_test` on
/// the CI emulator; this is the fast, deterministic cross-system proxy.
void main() {
  test('a beta session runs the full loop and survives a reopen', () async {
    final store = makeStore();
    var now = kDay0;

    // --- Session 1: adopt + care -------------------------------------------
    final c1 = makeController(store: store, clock: () => now);
    await c1.load();
    expect(c1.hasPet, isFalse); // no save ⇒ Rescue Day

    await c1.adopt(species: Species.puppy, name: 'Biscuit');
    expect(c1.hasPet, isTrue);
    expect(c1.pet!.name, 'Biscuit');

    await c1.interact(CareInteraction.feed);
    await c1.interact(CareInteraction.play);
    final bondAfterCare = c1.pet!.bond.value;
    expect(bondAfterCare, greaterThan(0));

    // Telemetry fired (PII-free taxonomy).
    final analytics = c1.observability.analytics as InMemoryAnalyticsService;
    expect(analytics.countOf(AnalyticsEvent.rescueDayComplete), 1);
    expect(analytics.countOf(AnalyticsEvent.careAction), 2);

    // Notifications scheduled on adopt (warm, capped, never guilt).
    final notes = c1.notifications as InMemoryNotificationScheduler;
    expect(notes.scheduled, isNotEmpty);

    // Backgrounding emits the session-quality retention beat.
    now = kDay0 + 90 * 60 * 1000; // +90 min
    await c1.onAppBackgrounded();
    expect(analytics.countOf(AnalyticsEvent.sessionQuality), 1);

    // Beta feedback submits without throwing.
    await c1.submitBetaFeedback(rating: 5, comment: 'so cozy 💛');
    c1.dispose();

    // --- Session 2 (a fresh launch): the pet survives ----------------------
    final c2 = makeController(store: store, clock: () => kDay0 + 26 * 3600000);
    await c2.load();
    expect(c2.hasPet, isTrue, reason: 'cloud-save restore (no orphaned pet)');
    expect(c2.pet!.name, 'Biscuit');
    expect(
      c2.pet!.bond.value,
      greaterThanOrEqualTo(bondAfterCare),
      reason: 'Bond is monotonic across reopen (+greeting)',
    );
    c2.dispose();
  });

  test('premium gating + PII-free diagnostics in the live build', () async {
    // makeController bootstraps the monetization + diagnostics stack.
    makeController();
    final sl = ServiceLocator.instance;
    final monetization = sl.get<MonetizationController>();
    final diagnostics = sl.get<BetaDiagnostics>();

    // Before purchase: no premium, diagnostics report it, PII-free.
    expect(monetization.entitlements.removesInterstitials, isFalse);
    var report = diagnostics.snapshot();
    expect(report.subscriber, isFalse);
    expect(report.childSafe, isTrue); // ships child-safe-for-all (D-007)
    expect(report.toJson().containsKey('petName'), isFalse); // no player data

    // After subscribing: premium gating flips; diagnostics reflect it.
    await monetization.purchase(kForeverFriendsMonthly);
    expect(monetization.entitlements.removesInterstitials, isTrue);
    report = diagnostics.snapshot();
    expect(report.subscriber, isTrue);
  });
}
