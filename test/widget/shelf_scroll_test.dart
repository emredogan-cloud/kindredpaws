/// Regression guard (Huawei real-device validation): the shop/closet shelves
/// must scroll by finger, and the standalone room grids must keep their own
/// scroll. `ShelfGrid` is a GridView; nested inside a scrolling ListView
/// (grocery, wardrobe) it must pass the vertical drag through to the parent
/// (else the Toy/Care/Décor shelves are unreachable — the E2E bug), but
/// standalone in a bounded box (kitchen/play/care) it must scroll its own
/// overflow so a second row stays reachable on short screens.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/ui/rooms/room_scaffold.dart';

List<Widget> cells(int n) => [
  for (var i = 0; i < n; i++)
    Container(key: Key('cell$i'), color: const Color(0xFFEEEEEE)),
];

void main() {
  testWidgets('a NESTED ShelfGrid lets a finger drag scroll the PARENT list '
      '(reproduces + guards the E2E bug)', (tester) async {
    // Pin the view so the geometry is deterministic regardless of test order.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    // A constrained-height ListView (like the shop panel) whose only tall
    // child before the tail is a ShelfGrid — exactly the layout that broke.
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 300,
              child: ListView(
                controller: controller,
                children: [
                  ShelfGrid(nested: true, children: cells(12)),
                  const SizedBox(height: 400, key: Key('later-section')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(controller.offset, 0);
    // A finger drag STARTING OVER THE GRID must scroll the parent — unlike
    // scrollUntilVisible (which drives the target Scrollable directly),
    // tester.drag goes through the gesture arena a real finger hits. The bug
    // was the grid swallowing this drag so the parent never moved. Drag from
    // the top cell (guaranteed on-screen inside the 300px viewport).
    await tester.drag(find.byKey(const Key('cell0')), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(
      controller.offset,
      greaterThan(0),
      reason: 'the parent list must scroll when the grid is dragged',
    );
  });

  testWidgets('a STANDALONE ShelfGrid keeps its own scroll physics (so its '
      'overflow rows stay reachable — must NOT be globally disabled)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ShelfGrid(children: cells(12))),
      ),
    );
    final grid = tester.widget<GridView>(find.byType(GridView));
    // The regression this guards: making ShelfGrid NeverScrollable *globally*
    // fixed grocery/wardrobe but silently clipped the bottom row in the
    // standalone kitchen/play/care grids. Default (non-nested) must scroll.
    expect(grid.physics, isNot(isA<NeverScrollableScrollPhysics>()));
    expect(grid.shrinkWrap, isTrue);
  });
}
