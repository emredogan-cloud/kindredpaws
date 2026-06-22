@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/main.dart';

/// Golden / snapshot test for the Phase-0 provisioning shell. Reference images
/// live in `test/golden/goldens/` and are Linux-rendered to match CI.
/// Regenerate with: flutter test --update-goldens --tags golden
void main() {
  testWidgets('provisioning page matches golden', (tester) async {
    ServiceLocator.instance.reset();
    final config = bootstrap();
    await tester.pumpWidget(KindredPawsApp(config: config));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home.png'),
    );
  });
}
