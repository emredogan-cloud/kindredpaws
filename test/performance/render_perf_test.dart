@Tags(['performance'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/render/pet_renderer.dart';
import 'package:kindredpaws/render/rive_pet_renderer.dart';

/// Coarse host-side render budget (P4-2). A frame-pacing proxy for the on-device
/// "stable 60 fps on mid-tier Android" target — real frame profiling runs via
/// integration_test + `flutter drive --profile`. Here we sweep mood × emotion
/// rebuilds and assert the host stays comfortably within budget (no pathological
/// rebuild cost), and that the input-mapping is allocation-light.
void main() {
  testWidgets('a full mood × emotion render sweep stays within budget', (
    tester,
  ) async {
    const renderer = RivePetRenderer(); // asset-free stand-in (no native rive)
    Widget tree(PetMood mood, PetEmotion e) => MaterialApp(
      home: Builder(
        builder: (c) =>
            renderer.build(c, mood: mood, lifeStage: 'grown', emotion: e),
      ),
    );

    final sw = Stopwatch()..start();
    for (final mood in PetMood.values) {
      for (final e in PetEmotion.values) {
        await tester.pumpWidget(tree(mood, e));
        await tester.pump();
      }
    }
    sw.stop();

    // 48 rebuilds (4 moods × 12 emotions). Generous CI budget; on-device the
    // real rig self-advances and only the 3 inputs are pushed per change.
    expect(
      sw.elapsedMilliseconds,
      lessThan(4000),
      reason: 'render sweep exceeded budget (${sw.elapsedMilliseconds}ms)',
    );
    expect(tester.takeException(), isNull);
  });

  test('the state-machine input mappings are pure + cheap', () {
    final sw = Stopwatch()..start();
    for (var i = 0; i < 100000; i++) {
      riveMoodValue(PetMood.values[i % 4]);
      riveEmotionValue(PetEmotion.values[i % 12]);
      riveLifeStageValue('grown');
    }
    sw.stop();
    expect(sw.elapsedMilliseconds, lessThan(500));
  });
}
