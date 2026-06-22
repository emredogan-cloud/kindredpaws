@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/main.dart';

/// Golden / snapshot test. Reference images live in `test/golden/goldens/`.
///
/// Goldens are font-renderer sensitive, so they are generated and verified on
/// the **same OS as CI** (Ubuntu/Linux). Regenerate with:
///   flutter test --update-goldens --tags golden
void main() {
  testWidgets('home page matches golden', (tester) async {
    await tester.pumpWidget(const KindredPawsApp());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home.png'),
    );
  });
}
