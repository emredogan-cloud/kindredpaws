import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/monetization/billing_service.dart';
import 'package:kindredpaws/monetization/monetization_controller.dart';
import 'package:kindredpaws/monetization/paywall_controller.dart';
import 'package:kindredpaws/game/ui/paywall_sheet.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/auth_service.dart';
import 'package:kindredpaws/services/backend_service.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/experiments.dart';
import 'package:kindredpaws/services/live_ops.dart';
import 'package:kindredpaws/services/logger.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/performance_monitor.dart';
import 'package:kindredpaws/services/remote_config_service.dart';
import 'package:kindredpaws/core/legal_links.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/services/link_opener.dart';

PaywallController _controller() {
  final obs = ObservabilityFacade(
    logger: InMemoryLogger(),
    crash: InMemoryCrashReporter(),
    performance: InMemoryPerformanceMonitor(),
    analytics: InMemoryAnalyticsService(),
  );
  return PaywallController(
    monetization: MonetizationController(
      billing: NoopBillingService(),
      observability: obs,
      backend: InMemoryBackendService(),
    ),
    experiments: Experiments(
      liveOps: const LiveOps(DefaultRemoteConfig()),
      observability: obs,
    ),
    observability: obs,
    auth: GuestAuthService(),
  );
}

Future<void> _pumpSheet(WidgetTester tester, PaywallController c) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: PaywallSheet(controller: c)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders plans, the ethical wall + restore — and ONLY honest '
      'products (KP-006/KP-007)', (tester) async {
    await _pumpSheet(tester, _controller());

    expect(find.byKey(const Key('paywall-sheet')), findsOneWidget);
    expect(find.byKey(const Key('paywall-plan-monthly')), findsOneWidget);
    expect(find.byKey(const Key('paywall-plan-annual')), findsOneWidget);
    expect(find.byKey(const Key('paywall-restore')), findsOneWidget);
    // The ethical-wall promise is always visible.
    expect(find.byKey(const Key('paywall-ethical-note')), findsOneWidget);
    // Launch posture: no Heartstone bundles until they can be spent (KP-007),
    // no Rescue Bundles / giving-split claims until donations are operational
    // (KP-006). The paywall must not advertise what the build cannot do.
    expect(find.text('Heartstones'), findsNothing);
    expect(find.text('Rescue Bundles'), findsNothing);
    expect(find.textContaining('goes to real rescues'), findsNothing);
  });

  testWidgets('POS disclosures: auto-renew terms + working Terms/Privacy '
      'links sit beside the plans (KP-003)', (tester) async {
    ServiceLocator.instance.reset();
    final opener = RecordingLinkOpener();
    ServiceLocator.instance.registerSingleton<LinkOpener>(opener);
    await _pumpSheet(tester, _controller());

    expect(find.byKey(const Key('paywall-disclosures')), findsOneWidget);
    expect(find.textContaining('renew automatically'), findsOneWidget);
    expect(
      find.textContaining('cancel anytime', findRichText: true),
      findsWidgets,
    );

    await tester.tap(find.byKey(const Key('paywall-terms-link')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('paywall-privacy-link')));
    await tester.pump();
    expect(opener.opened, [kTermsOfUseUrl, kPrivacyPolicyUrl]);
  });

  testWidgets('disclosures hide once entitled (no plans on screen)', (
    tester,
  ) async {
    ServiceLocator.instance.reset();
    ServiceLocator.instance.registerSingleton<LinkOpener>(
      RecordingLinkOpener(),
    );
    await _pumpSheet(tester, _controller());
    await tester.tap(find.byKey(const Key('paywall-plan-monthly')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('paywall-entitled')), findsOneWidget);
    expect(find.byKey(const Key('paywall-disclosures')), findsNothing);
  });

  testWidgets('buying the monthly plan flips to the entitled state', (
    tester,
  ) async {
    await _pumpSheet(tester, _controller());

    expect(find.byKey(const Key('paywall-entitled')), findsNothing);
    await tester.tap(find.byKey(const Key('paywall-plan-monthly')));
    await tester.pumpAndSettle();

    // Entitlement UX: the upsell is replaced by the thank-you state.
    expect(find.byKey(const Key('paywall-entitled')), findsOneWidget);
    expect(find.byKey(const Key('paywall-plan-monthly')), findsNothing);
    expect(find.textContaining('Forever Friend'), findsWidgets);
  });

  testWidgets('restore with nothing to restore tells the player gently', (
    tester,
  ) async {
    await _pumpSheet(tester, _controller());

    await tester.ensureVisible(find.byKey(const Key('paywall-restore')));
    await tester.tap(find.byKey(const Key('paywall-restore')));
    await tester.pumpAndSettle();

    // The outcome is surfaced in the in-sheet live region (not just a SnackBar,
    // which the modal sheet occludes) — the a11y fix.
    expect(
      find.descendant(
        of: find.byKey(const Key('paywall-status')),
        matching: find.textContaining('Nothing to restore'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('showPaywall logs the shown→dismissed funnel bookends', (
    tester,
  ) async {
    final c = _controller();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showPaywall(context, c, surface: 'test'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final analytics = c.observability.analytics as InMemoryAnalyticsService;
    expect(analytics.countOf(AnalyticsEvent.paywallStep), 1); // shown

    // Dismiss by tapping the modal barrier.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    final steps = [
      for (final r in analytics.recorded)
        if (r.$1 == AnalyticsEvent.paywallStep) r.$2['step'],
    ];
    expect(steps, containsAll(<String>['shown', 'dismissed']));
  });
}
