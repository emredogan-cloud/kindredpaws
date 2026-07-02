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

  group('Rive state-machine input mappings (the rig contract, in code)', () {
    test('mood / emotion / lifeStage map to the documented input ranges', () {
      expect(riveMoodValue(PetMood.joyful), 0);
      expect(riveMoodValue(PetMood.content), 1);
      expect(riveMoodValue(PetMood.wistful), 2);
      expect(riveMoodValue(PetMood.low), 3);

      expect(riveEmotionValue(PetEmotion.happy), PetEmotion.happy.index);
      expect(
        riveEmotionValue(PetEmotion.comforted),
        PetEmotion.comforted.index,
      );

      expect(riveLifeStageValue('pupKit'), 0);
      expect(riveLifeStageValue('youngOne'), 1);
      expect(riveLifeStageValue('grown'), 2);
      expect(riveLifeStageValue('unknown'), 0); // safe default = infancy
    });
  });

  group('RivePetRenderer graceful degradation (P3-2)', () {
    testWidgets(
      'a missing/unloadable asset falls back to the stand-in + reports a '
      'diagnostic (never crashes play)',
      (tester) async {
        final codes = <String>[];
        final renderer = RivePetRenderer(
          assetPath: 'assets/rigs/__does_not_exist__.riv',
          onDiagnostic: (code, {Map<String, Object?> fields = const {}}) =>
              codes.add(code),
        );
        // runAsync lets the real async asset load (and its failure) complete.
        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => renderer.build(
                  context,
                  mood: PetMood.content,
                  lifeStage: 'grown',
                  emotion: PetEmotion.calm,
                ),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(codes, contains('rive_load_failed'));
        // Degraded gracefully: still the expressive stand-in, no exception.
        expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
        expect(find.text('rive'), findsOneWidget);
        expect(find.byIcon(PetEmotion.calm.icon), findsOneWidget);
      },
    );

    testWidgets('rebuilds without error when state changes while degraded', (
      tester,
    ) async {
      Widget tree(PetMood mood) => MaterialApp(
        home: Builder(
          builder: (context) => const RivePetRenderer(
            assetPath: 'assets/rigs/__does_not_exist__.riv',
          ).build(context, mood: mood, lifeStage: 'grown'),
        ),
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(tree(PetMood.joyful));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      // Changing gameplay state rebuilds the rig widget (didUpdateWidget) — must
      // stay graceful (no exception) even though the rig never loaded.
      await tester.pumpWidget(tree(PetMood.low));
      await tester.pump();
      expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'the canonical founder mascot drop-in path (assets/rive/interactive_dog.riv) '
      'is handled by the same path-agnostic seam — graceful fallback until the '
      'real .riv is supplied',
      (tester) async {
        // Pins the founder-brief / design-bible drop-in location so the seam can
        // never silently stop honoring it. The dir is bundled (pubspec) but the
        // .riv is not yet delivered (paid Rive export — see the integration
        // report), so the load fails and we degrade to the stand-in, never crash.
        final codes = <String>[];
        final renderer = RivePetRenderer(
          assetPath: 'assets/rive/interactive_dog.riv',
          onDiagnostic: (code, {Map<String, Object?> fields = const {}}) =>
              codes.add(code),
        );
        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => renderer.build(
                  context,
                  mood: PetMood.joyful,
                  lifeStage: 'pupKit',
                  emotion: PetEmotion.happy,
                ),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(codes, contains('rive_load_failed'));
        expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
        expect(find.text('rive'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('RivePetRenderer reactive binding (P4-2)', () {
    testWidgets('the asset-free seam reflects emotion changes on rebuild', (
      tester,
    ) async {
      Widget tree(PetEmotion e) => MaterialApp(
        home: Builder(
          builder: (context) => const RivePetRenderer().build(
            context,
            mood: PetMood.joyful,
            lifeStage: 'grown',
            emotion: e,
          ),
        ),
      );
      // No assetPath ⇒ the synchronous expressive stand-in; it must re-render
      // the new emotion when gameplay state changes (the reactive contract that
      // the real rig honors via didUpdateWidget → _apply).
      await tester.pumpWidget(tree(PetEmotion.happy));
      await tester.pumpAndSettle();
      expect(find.byIcon(PetEmotion.happy.icon), findsOneWidget);

      await tester.pumpWidget(tree(PetEmotion.playful));
      await tester.pumpAndSettle();
      expect(find.byIcon(PetEmotion.playful.icon), findsOneWidget);
      expect(find.byIcon(PetEmotion.happy.icon), findsNothing);
      expect(tester.takeException(), isNull);
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
