import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kindredpaws/main.dart';

/// End-to-end smoke test. Runs on a real device/emulator via:
///   flutter test integration_test/app_smoke_test.dart
/// or driven (with screenshots/video) via tool/android_e2e.sh.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots and the interaction flow works end-to-end', (
    tester,
  ) async {
    await tester.pumpWidget(const KindredPawsApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('healthcheck-banner')), findsOneWidget);

    for (var i = 1; i <= 3; i++) {
      await tester.tap(find.byKey(const Key('increment-fab')));
      await tester.pumpAndSettle();
      expect(find.text('$i'), findsOneWidget);
    }
  });
}
