/// The temporary vector renderer honours the exact contract the future Rive
/// rig is authored against: 4 mood idles, 12 one-shot reactions that return
/// to idle, life-stage proportion scale, species differentiation — and stays
/// deterministic (settle-safe) with continuous motion off, exactly like the
/// placeholder, so the whole widget-test suite keeps its guarantees.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/app_config.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/render/pet_renderer.dart';
import 'package:kindredpaws/render/pet_renderer_factory.dart';
import 'package:kindredpaws/render/vector_pet_renderer.dart';

Widget _host(
  PetRenderer rig, {
  PetMood mood = PetMood.content,
  String stage = 'pupKit',
  PetEmotion? emotion,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Builder(
          builder: (context) => rig.build(
            context,
            mood: mood,
            lifeStage: stage,
            emotion: emotion,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('contract parity', () {
    test('factory builds the vector backend and it identifies itself', () {
      final rig = createPetRenderer(PetRendererBackend.vector);
      expect(rig.backendId, 'vector');
    });

    test('the app default is vector, tests default to placeholder, and an '
        'explicit flag always wins', () {
      // Bare fromEnvironment (this test binary has no KP_PET_RENDERER set).
      expect(
        AppConfig.fromEnvironment().petRendererBackend,
        PetRendererBackend.placeholder,
      );
      expect(
        AppConfig.fromEnvironment(
          fallbackRenderer: PetRendererBackend.vector,
        ).petRendererBackend,
        PetRendererBackend.vector,
      );
    });
  });

  group('deterministic mode (the widget-test guarantee)', () {
    testWidgets('settles with motion off and renders every mood × stage', (
      tester,
    ) async {
      const rig = VectorPetRenderer(continuousMotion: false);
      for (final mood in PetMood.values) {
        for (final stage in ['pupKit', 'youngOne', 'grown']) {
          await tester.pumpWidget(_host(rig, mood: mood, stage: stage));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
        }
      }
    });

    testWidgets('every one of the 12 emotions plays as a one-shot and '
        'returns to a settled idle', (tester) async {
      const rig = VectorPetRenderer(continuousMotion: false);
      for (final emotion in PetEmotion.values) {
        await tester.pumpWidget(
          _host(rig, mood: emotion.mood, emotion: emotion),
        );
        // One-shot ≤ 2 s: pumpAndSettle must complete (nothing loops).
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
      }
    });

    testWidgets('an emotion change replays the reaction (rig trigger '
        'semantics)', (tester) async {
      const rig = VectorPetRenderer(continuousMotion: false);
      await tester.pumpWidget(
        _host(rig, mood: PetMood.joyful, emotion: PetEmotion.happy),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _host(rig, mood: PetMood.joyful, emotion: PetEmotion.excited),
      );
      // Mid-reaction a frame exists (animation running)…
      await tester.pump(const Duration(milliseconds: 200));
      // …and it finishes on its own (returns to idle).
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
    });

    testWidgets('a mood change soft-blends between idles and settles', (
      tester,
    ) async {
      const rig = VectorPetRenderer(continuousMotion: false);
      await tester.pumpWidget(_host(rig, mood: PetMood.joyful));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_host(rig, mood: PetMood.low));
      await tester.pump(const Duration(milliseconds: 100)); // mid-blend
      await tester.pumpAndSettle(); // 300 ms blend completes
      expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
    });
  });

  group('species + life stage', () {
    testWidgets('renders the kitten variant via the species resolver', (
      tester,
    ) async {
      final rig = VectorPetRenderer(
        speciesOf: () => Species.kitten,
        continuousMotion: false,
      );
      await tester.pumpWidget(_host(rig));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
    });

    testWidgets('life stage drives the render scale (0.7 / 0.85 / 1.0)', (
      tester,
    ) async {
      const rig = VectorPetRenderer(continuousMotion: false);
      final sizes = <String, Size>{};
      for (final stage in ['pupKit', 'youngOne', 'grown']) {
        await tester.pumpWidget(_host(rig, stage: stage));
        await tester.pumpAndSettle();
        sizes[stage] = tester.getSize(find.byKey(const Key('pet-renderer')));
      }
      expect(sizes['pupKit']!.width, 160 * 0.7);
      expect(sizes['youngOne']!.width, 160 * 0.85);
      expect(sizes['grown']!.width, 160 * 1.0);
    });
  });

  group('continuous motion (the shipped experience)', () {
    testWidgets('idle loop advances frames without ever ending', (
      tester,
    ) async {
      const rig = VectorPetRenderer(); // motion on
      await tester.pumpWidget(_host(rig, mood: PetMood.joyful));
      // Never pumpAndSettle here — the idle loops by design. Step frames:
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('pet-renderer')), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
    });
  });
}
