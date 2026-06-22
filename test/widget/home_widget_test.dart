import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/main.dart';

void main() {
  group('EnvironmentCheckPage (widget layer)', () {
    testWidgets('renders the health banner and counter', (tester) async {
      await tester.pumpWidget(const KindredPawsApp());

      expect(find.byKey(const Key('healthcheck-banner')), findsOneWidget);
      expect(find.byKey(const Key('counter-text')), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('tapping the FAB increments the self-check counter', (
      tester,
    ) async {
      await tester.pumpWidget(const KindredPawsApp());

      await tester.tap(find.byKey(const Key('increment-fab')));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('increment-fab')));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
    });
  });
}
