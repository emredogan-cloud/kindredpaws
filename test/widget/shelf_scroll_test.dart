/// Regression guard (Huawei real-device validation): the shop/closet shelves
/// must scroll by finger. `ShelfGrid` is a GridView nested inside a scrolling
/// ListView (grocery, wardrobe); without NeverScrollableScrollPhysics the
/// inner grid swallows the vertical drag in its area and the parent list
/// can't be scrolled past the first section — the Toy/Care/Décor shelves
/// become unreachable on a real device. (The pre-existing scroll tests missed
/// this because `scrollUntilVisible` drags the target Scrollable directly,
/// bypassing the gesture arena a real finger hits.)
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/ui/rooms/room_scaffold.dart';

void main() {
  testWidgets('ShelfGrid never captures the parent list\'s vertical drag', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShelfGrid(
            children: [for (var i = 0; i < 8; i++) SizedBox(key: Key('c$i'))],
          ),
        ),
      ),
    );
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(
      grid.physics,
      isA<NeverScrollableScrollPhysics>(),
      reason:
          'ShelfGrid must not scroll on its own — else it eats the drag and '
          'the parent shop/closet list cannot be finger-scrolled.',
    );
    expect(grid.shrinkWrap, isTrue);
  });
}
