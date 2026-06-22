import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/main.dart';

void main() {
  setUp(ServiceLocator.instance.reset);

  testWidgets('renders provisioning status, pet seam, and cost gate', (
    tester,
  ) async {
    final config = bootstrap();
    await tester.pumpWidget(KindredPawsApp(config: config));

    expect(find.byKey(const Key('provisioning-status')), findsOneWidget);
    expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
    expect(find.byKey(const Key('cost-gate-banner')), findsOneWidget);
    expect(find.textContaining('PASS'), findsWidgets);
  });

  testWidgets('defaults are offline-safe: mock backend, live chat off', (
    tester,
  ) async {
    final config = bootstrap();
    await tester.pumpWidget(KindredPawsApp(config: config));

    expect(find.textContaining('OFF (deferred)'), findsOneWidget);
    expect(find.textContaining('mock'), findsWidgets);
  });
}
