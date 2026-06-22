import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/care_meters.dart';
import 'package:kindredpaws/game/model/mood.dart';
import 'package:kindredpaws/game/sim/mood_resolver.dart';
import 'package:kindredpaws/game/sim/sim_config.dart';

void main() {
  const resolver = MoodResolver(SimConfig());

  CareMeters all(double v) =>
      CareMeters(hunger: v, energy: v, hygiene: v, happiness: v);

  test(
    'score uses the canonical §5.3 weights (0.30/0.25/0.20/0.15 + 0.10 attn)',
    () {
      // all 100, no attention → 0.90 * 100 = 90.
      expect(resolver.score(all(100)), closeTo(90, 1e-9));
      // attention bonus contributes 0.10 * 100 = 10 → 100.
      expect(
        resolver.score(all(100), recentAttentionBonus: 100),
        closeTo(100, 1e-9),
      );
    },
  );

  test('bands map to the four moods', () {
    expect(resolver.resolve(all(100)), Mood.joyful); // 90 ≥ 75
    expect(resolver.resolve(all(60)), Mood.content); // 54 ∈ [50,74]
    expect(resolver.resolve(all(40)), Mood.wistful); // 36 ∈ [30,49]
    expect(resolver.resolve(all(15)), Mood.low); // 13.5 < 30
  });

  test('low mood never carries a Bond-gain penalty (Risk R6)', () {
    for (final m in Mood.values) {
      expect(m.bondGainModifier, greaterThanOrEqualTo(1.0));
    }
    expect(Mood.joyful.bondGainModifier, 1.15);
  });

  test('recent attention can lift a content pet toward joyful', () {
    final base = resolver.resolve(all(80)); // 72 → content
    final lifted = resolver.resolve(
      all(80),
      recentAttentionBonus: 100,
    ); // 82 → joyful
    expect(base, Mood.content);
    expect(lifted, Mood.joyful);
  });
}
