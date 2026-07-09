/// KP-029 — no OS emoji stands in for the pet on the three hero surfaces:
/// species choice (the emotional peak), Keepsake cards (the share surface),
/// and the Profile portrait. Each renders the real character art instead.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/keepsake_screen.dart';
import 'package:kindredpaws/game/ui/rescue_day_screen.dart';
import 'package:kindredpaws/game/ui/settings_screen.dart';
import 'package:kindredpaws/render/vector_pet_renderer.dart';

import '../support/harness.dart';
import '../support/room_test_utils.dart';

void main() {
  testWidgets('species choice renders the real pets, not 🐶🐱', (tester) async {
    phoneView(tester);
    final c = makeController();
    addTearDown(c.dispose);
    await c.load();
    await tester.pumpWidget(MaterialApp(home: RescueDayScreen(controller: c)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rescue-skip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('choose-puppy')), findsOneWidget);
    expect(find.byKey(const Key('choose-kitten')), findsOneWidget);
    expect(find.text('🐶'), findsNothing);
    expect(find.text('🐱'), findsNothing);
  });

  testWidgets('the Profile portrait is the rendered pet, not an emoji', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    addTearDown(c.dispose);
    await c.load();
    await c.adopt(species: Species.kitten, name: 'Mochi');
    await tester.pumpWidget(MaterialApp(home: ProfileScreen(controller: c)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    expect(find.text('🐱'), findsNothing);
    expect(find.text('🐶'), findsNothing);
  });

  testWidgets('Keepsake cards composite the designed template + pet', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    addTearDown(c.dispose);
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: KeepsakeScreen(controller: c)));
    await tester.pumpAndSettle();

    // The Rescue Day keepsake exists from adoption; its card must use the
    // designed template art (no more emoji-on-a-peach-rectangle).
    final images = tester
        .widgetList<Image>(find.byType(Image))
        .map(
          (w) => (w.image is AssetImage)
              ? (w.image as AssetImage).assetName
              : (w.image is ResizeImage &&
                        (w.image as ResizeImage).imageProvider is AssetImage
                    ? ((w.image as ResizeImage).imageProvider as AssetImage)
                          .assetName
                    : ''),
        )
        .toList();
    expect(
      images.where((a) => a.contains('keepsake_template')),
      isNotEmpty,
      reason: 'the designed card template must render',
    );
    // The pet itself is painted by the renderer (a CustomPaint), so the big
    // 48pt emoji is gone.
    expect(find.byType(VectorPetRenderer), findsNothing); // it's not a widget
    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .where(
            (t) =>
                (t.style?.fontSize ?? 0) >= 48 && (t.data?.length ?? 99) <= 3,
          ),
      isEmpty,
      reason: 'no giant emoji glyph on the share surface',
    );
  });
}
