@Tags(['performance'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/main.dart';

/// Performance smoke test (host-side, CI-safe budget). This is a coarse guard,
/// not a benchmark — real frame/jank profiling runs on-device via
/// `integration_test` + `flutter drive --profile` (see tool/android_e2e.sh).
void main() {
  testWidgets('cold widget build stays within budget', (tester) async {
    final sw = Stopwatch()..start();
    await tester.pumpWidget(const KindredPawsApp());
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
