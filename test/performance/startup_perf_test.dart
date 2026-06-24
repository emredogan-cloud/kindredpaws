@Tags(['performance'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/performance_budgets.dart';
import 'package:kindredpaws/game/ui/game_root.dart';

import '../support/harness.dart';

/// Coarse host-side performance guard (CI-safe budget). Real frame/jank
/// profiling runs on-device via integration_test + flutter drive --profile.
void main() {
  testWidgets('cold widget build stays within budget', (tester) async {
    final controller = makeController();
    await controller.load(); // no save → Rescue Day, deterministic

    final sw = Stopwatch()..start();
    await tester.pumpWidget(
      MaterialApp(home: GameRoot(controller: controller, autoLoad: false)),
    );
    await tester.pump();
    sw.stop();

    expect(
      PerfBudget.coldWidgetBuild.isWithin(sw.elapsedMilliseconds),
      isTrue,
      reason:
          'cold widget build exceeded the '
          '${PerfBudget.coldWidgetBuild.ceilingMs}ms CI budget '
          '(${sw.elapsedMilliseconds}ms)',
    );
  });
}
