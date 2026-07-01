/// Shared helpers for room widget tests: a realistic phone-portrait surface
/// and dock navigation that scrolls the (lazy) room dock before tapping —
/// exactly what a thumb does when the home grows wider than the screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A realistic phone-portrait surface so room layouts match the shipped
/// experience (the default 800×600 test view squeezes portrait rooms).
void phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 820);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

/// Scrolls the room dock until [roomId]'s chip is visible (a thumb swipe on
/// the dock itself), then hops there. Swipes left first (rooms grow
/// rightward), then right, so any chip is reachable from any position.
Future<void> hopToRoom(WidgetTester tester, String roomId) async {
  final chip = find.byKey(Key('room-dock-$roomId'));
  for (final direction in const [Offset(-128, 0), Offset(128, 0)]) {
    for (var i = 0; i < 8 && chip.evaluate().isEmpty; i++) {
      await tester.drag(find.byKey(const Key('room-dock')), direction);
      await tester.pumpAndSettle();
    }
    if (chip.evaluate().isNotEmpty) break;
  }
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}
