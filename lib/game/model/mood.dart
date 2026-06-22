/// Mood state machine (GAMEPLAY_AND_PROGRESSION_BIBLE.md §5.3). Mood is a
/// **derived** value (never stored): computed each tick from meters + recent
/// attention. Four states; low mood is an *opportunity* (Comfort beat), never a
/// punishment — it dampens nothing and unlocks the signature comfort moment.
///
/// Kept Flutter-free; the UI maps [Mood] → `PetMood` (render layer).
library;

enum Mood {
  /// 75–100. Bond gain ×1.15 (the only non-1.0 modifier).
  joyful('Joyful', 75, 1.15),

  /// 50–74.
  content('Content', 50, 1.0),

  /// 30–49. Looks toward the door; never penalized.
  wistful('Wistful', 30, 1.0),

  /// 15–29 (the floor band). Unlocks the Comfort moment.
  low('Low', 0, 1.0);

  const Mood(this.displayName, this.minScore, this.bondGainModifier);

  final String displayName;

  /// Inclusive lower bound of this band on the 0–100 mood score.
  final int minScore;

  /// Multiplier applied to Bond *gain* while in this mood (§5.3). Never < 1.0
  /// for low moods — we never penalize the pet being low (Risk R6).
  final double bondGainModifier;

  /// Resolves a mood from a 0–100 [score]. Highest matching band wins.
  static Mood fromScore(double score) {
    if (score >= Mood.joyful.minScore) return Mood.joyful;
    if (score >= Mood.content.minScore) return Mood.content;
    if (score >= Mood.wistful.minScore) return Mood.wistful;
    return Mood.low;
  }
}
