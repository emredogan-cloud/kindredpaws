/// Mood derivation (GAMEPLAY_AND_PROGRESSION_BIBLE.md §5.3). Mood is computed,
/// never stored:
///   mood_score = 0.30·Happiness + 0.25·Hunger + 0.20·Energy + 0.15·Hygiene
///                + 0.10·recent_attention_bonus
/// then banded into Joyful / Content / Wistful / Low.
library;

import '../model/care_meters.dart';
import '../model/mood.dart';
import 'sim_config.dart';

class MoodResolver {
  const MoodResolver(this.config);

  final SimConfig config;

  /// 0–100 mood score. [recentAttentionBonus] (0–100) reflects how recently the
  /// pet got positive attention; defaults to 0 (no recent interaction).
  double score(CareMeters m, {double recentAttentionBonus = 0}) {
    final w = config.moodWeights;
    final s =
        (w[CareNeed.happiness] ?? 0) * m.happiness +
        (w[CareNeed.hunger] ?? 0) * m.hunger +
        (w[CareNeed.energy] ?? 0) * m.energy +
        (w[CareNeed.hygiene] ?? 0) * m.hygiene +
        config.recentAttentionWeight * recentAttentionBonus.clamp(0, 100);
    return s.clamp(0, 100);
  }

  Mood resolve(CareMeters m, {double recentAttentionBonus = 0}) =>
      Mood.fromScore(score(m, recentAttentionBonus: recentAttentionBonus));
}
