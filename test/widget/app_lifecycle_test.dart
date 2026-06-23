import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/game_root.dart';
import 'package:kindredpaws/services/analytics_service.dart';

import '../support/harness.dart';

void main() {
  testWidgets('GameRoot forwards app-background to the controller (P3-7)', (
    tester,
  ) async {
    final controller = makeController(clock: () => kDay0);
    await controller.load();
    await controller.adopt(
      species: Species.puppy,
      name: 'Biscuit',
    ); // arms session

    // autoLoad:false — the controller is already loaded/adopted above.
    await tester.pumpWidget(
      MaterialApp(home: GameRoot(controller: controller, autoLoad: false)),
    );
    await tester.pumpAndSettle();

    final analytics =
        controller.observability.analytics as InMemoryAnalyticsService;
    expect(analytics.countOf(AnalyticsEvent.sessionQuality), 0);

    // The OS backgrounds the app → the observer ends the session.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(analytics.countOf(AnalyticsEvent.sessionQuality), 1);
  });
}
