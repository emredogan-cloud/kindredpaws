@Tags(['performance'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/main.dart';

/// Coarse host-side performance guard (CI-safe budget). Real frame/jank
/// profiling runs on-device via integration_test + flutter drive --profile.
void main() {
  testWidgets('cold widget build stays within budget', (tester) async {
    ServiceLocator.instance.reset();
    final sw = Stopwatch()..start();
    final config = bootstrap();
    await tester.pumpWidget(KindredPawsApp(config: config));
    await tester.pump();
    sw.stop();

    expect(
      sw.elapsedMilliseconds,
      lessThan(2000),
      reason:
          'cold widget build exceeded the 2000ms CI budget '
          '(${sw.elapsedMilliseconds}ms)',
    );
  });
}
