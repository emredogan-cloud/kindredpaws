import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/performance_budgets.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/monetization/monetization_controller.dart';
import 'package:kindredpaws/monetization/paywall_controller.dart';
import 'package:kindredpaws/monetization/product_catalog.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/beta_diagnostics.dart';
import 'package:kindredpaws/services/home_widget_service.dart';
import 'package:kindredpaws/services/notification_scheduler.dart';

import '../support/harness.dart';

/// Full soft-launch simulation (P5-8): one deterministic host-side walk that
/// proves the RC validation areas — **upgrades/persistence, restores,
/// notifications, telemetry, monetization, widgets** — integrate end-to-end over
/// the (rewired) service stack. It is the fast CI proxy for the on-device E2E
/// matrix in `docs/RELEASE_CANDIDATE.md` (run via `just e2e-android`).
void main() {
  test('RC simulation: the whole loop, validated across a reopen', () async {
    final store = makeStore();
    var now = kDay0;
    final sl = ServiceLocator.instance;

    // ---- Session 1: adopt → onboarding funnel → care -----------------------
    final c1 = makeController(store: store, clock: () => now);
    await c1.load();
    expect(c1.hasPet, isFalse); // no save ⇒ Rescue Day
    c1.recordOnboardingStep('reach_out');
    c1.recordOnboardingStep('species_selected');
    await c1.adopt(species: Species.puppy, name: 'Biscuit');
    await c1.interact(CareInteraction.feed);
    await c1.interact(CareInteraction.play);

    final analytics = c1.observability.analytics as InMemoryAnalyticsService;

    // TELEMETRY — the PII-free taxonomy fired across the loop.
    expect(analytics.countOf(AnalyticsEvent.rescueDayComplete), 1);
    expect(analytics.countOf(AnalyticsEvent.careAction), 2);
    expect(analytics.countOf(AnalyticsEvent.onboardingStep), greaterThan(0));
    // Crash-correlation baseline: a healthy session.
    expect(c1.observability.sessionHealth.hadCrash, isFalse);

    // NOTIFICATIONS — scheduled on adopt (warm, capped, killable).
    final notes = c1.notifications as InMemoryNotificationScheduler;
    expect(notes.scheduled, isNotEmpty);

    // WIDGETS — care persists a status snapshot to the home-widget bridge.
    final widget = sl.get<HomeWidgetService>() as NoopHomeWidgetService;
    expect(widget.updates, greaterThan(0));
    expect(widget.lastPublished, isNotNull);
    expect(c1.statusSnapshot, isNotNull);

    // MONETIZATION — experiment exposure + paywall funnel + entitlement.
    final paywall = sl.get<PaywallController>();
    paywall.resolveCopy(); // logs experimentExposure once
    expect(analytics.countOf(AnalyticsEvent.experimentExposure), 1);
    final res = await paywall.buy(kForeverFriendsMonthly, surface: 'sim');
    expect(res.success, isTrue);
    expect(
      sl.get<MonetizationController>().entitlements.foreverFriends,
      isTrue,
    );
    expect(analytics.countOf(AnalyticsEvent.paywallStep), greaterThan(0));
    expect(analytics.countOf(AnalyticsEvent.monetizationEvent), 1);

    // BETA FEEDBACK — routes through the pipeline → triaged betaFeedback event.
    await c1.submitBetaFeedback(rating: 5, comment: 'so cozy 💛');
    expect(analytics.countOf(AnalyticsEvent.betaFeedback), 1);

    // PERFORMANCE — the budget gate is wired + healthy.
    expect(
      sl.get<PerformanceBudgetMonitor>().check(PerfBudget.coldStart, 1200),
      isTrue,
    );

    // Backgrounding emits the session-quality retention beat.
    now = kDay0 + 90 * 60 * 1000; // +90 min
    await c1.onAppBackgrounded();
    expect(analytics.countOf(AnalyticsEvent.sessionQuality), 1);

    // DIAGNOSTICS — PII-free, reflects the purchase.
    final report = sl.get<BetaDiagnostics>().snapshot();
    expect(report.toJson().containsKey('petName'), isFalse);
    expect(report.subscriber, isTrue);

    // Capture state to prove it survives the reopen (UPGRADES/PERSISTENCE).
    final bondBefore = c1.pet!.bond.value;
    final personalityBefore = c1.personality;
    c1.dispose();

    // ---- Session 2 (fresh launch): PERSISTENCE + RESTORE + retention -------
    final c2 = makeController(store: store, clock: () => kDay0 + 26 * 3600000);
    await c2.load();
    expect(c2.hasPet, isTrue, reason: 'cloud-save restore — no orphaned pet');
    expect(c2.pet!.name, 'Biscuit');
    expect(
      c2.pet!.bond.value,
      greaterThanOrEqualTo(bondBefore),
      reason: 'Bond is monotonic across the reopen (+greeting)',
    );
    expect(
      c2.personality,
      personalityBefore,
      reason: 'the pet\'s drifted personality persists (save v6, P3-4)',
    );
    final a2 = c2.observability.analytics as InMemoryAnalyticsService;
    expect(
      a2.countOf(AnalyticsEvent.retentionMilestone),
      greaterThan(0),
      reason: 'reopening on day 1 fires the D1 retention milestone',
    );
    c2.dispose();
  });
}
