import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/app_config.dart';
import 'package:kindredpaws/render/pet_renderer.dart';
import 'package:kindredpaws/render/pet_renderer_factory.dart';
import 'package:kindredpaws/render/rive_pet_renderer.dart';

void main() {
  group('RivePetRenderer (P1-0 animation spike seam)', () {
    testWidgets('builds the asset-free stand-in without the native runtime', (
      tester,
    ) async {
      const renderer = RivePetRenderer(); // assetPath null → no native call
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => renderer.build(
                  context,
                  mood: PetMood.joyful,
                  lifeStage: 'pupKit',
                ),
              ),
            ),
          ),
        ),
      );

      expect(renderer.backendId, 'rive');
      expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
      // The stand-in advertises the active backend so QA can tell seams apart.
      expect(find.text('rive'), findsOneWidget);
    });

    test('life-stage scale matches GAME_TECHNICAL_SYSTEMS §3.1', () {
      expect(lifeStageScale('pupKit'), 0.7);
      expect(lifeStageScale('youngOne'), 0.85);
      expect(lifeStageScale('grown'), 1.0);
      expect(lifeStageScale('anything-else'), 0.7); // safe default = infancy
    });

    testWidgets('render box scales down for infancy', (tester) async {
      const renderer = RivePetRenderer(size: 200);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => renderer.build(
              context,
              mood: PetMood.content,
              lifeStage: 'pupKit',
            ),
          ),
        ),
      );
      final box = tester.widget<SizedBox>(
        find.byKey(const Key('pet-renderer')),
      );
      expect(box.width, 200 * 0.7); // 140
      expect(box.height, 200 * 0.7);
    });
  });

  group('createPetRenderer factory', () {
    test('returns PlaceholderPetRenderer for the placeholder backend', () {
      final r = createPetRenderer(PetRendererBackend.placeholder);
      expect(r, isA<PlaceholderPetRenderer>());
      expect(r.backendId, 'placeholder');
    });

    test('returns RivePetRenderer for the rive backend', () {
      final r = createPetRenderer(PetRendererBackend.rive);
      expect(r, isA<RivePetRenderer>());
      expect(r.backendId, 'rive');
    });
  });
}
