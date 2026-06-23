/// Evolving personality (GAME_TECHNICAL_SYSTEMS.md §4.3). A small set of dials,
/// a few discrete levels each, that **drift slowly and deterministically** with
/// how the player interacts. In MVP the dials select WHICH bank lines are
/// eligible (the bank key includes a personality dial) — ~0 marginal cost, no
/// generation. "Only MY pet would say this" emerges from the dial combination +
/// memory-fact slots over shared assets (brief §8.7).
library;

enum PersonalityDial { playfulness, cuddliness, chattiness, bravery }

class PersonalityProfile {
  const PersonalityProfile({
    this.playfulness = 2,
    this.cuddliness = 2,
    this.chattiness = 2,
    this.bravery = 2,
  });

  /// Each dial is a small discrete level 0..[maxLevel]; 2 = neutral default.
  static const int maxLevel = 4;

  final int playfulness;
  final int cuddliness;
  final int chattiness;
  final int bravery;

  static const PersonalityProfile neutral = PersonalityProfile();

  int levelOf(PersonalityDial d) => switch (d) {
    PersonalityDial.playfulness => playfulness,
    PersonalityDial.cuddliness => cuddliness,
    PersonalityDial.chattiness => chattiness,
    PersonalityDial.bravery => bravery,
  };

  /// The bank's `personalityDial` key: the dominant dial, as a coarse style
  /// label the dialogue bank is authored against. Ties broken deterministically
  /// by dial order. Defaults to 'calm' when nothing stands out.
  String get bankKey {
    PersonalityDial? top;
    var topLevel = 2; // must exceed neutral to count as dominant
    for (final d in PersonalityDial.values) {
      if (levelOf(d) > topLevel) {
        topLevel = levelOf(d);
        top = d;
      }
    }
    return switch (top) {
      PersonalityDial.playfulness => 'playful',
      PersonalityDial.cuddliness => 'cuddly',
      PersonalityDial.chattiness => 'chatty',
      PersonalityDial.bravery => 'brave',
      null => 'calm',
    };
  }

  /// Nudges a dial up by one level (bounded). Drift is slow + deterministic
  /// (e.g. lots of play → playfulness up), keeping the pet recognizably itself.
  PersonalityProfile nudge(PersonalityDial d, [int by = 1]) {
    int clamp(int v) => v < 0 ? 0 : (v > maxLevel ? maxLevel : v);
    return PersonalityProfile(
      playfulness: clamp(
        playfulness + (d == PersonalityDial.playfulness ? by : 0),
      ),
      cuddliness: clamp(
        cuddliness + (d == PersonalityDial.cuddliness ? by : 0),
      ),
      chattiness: clamp(
        chattiness + (d == PersonalityDial.chattiness ? by : 0),
      ),
      bravery: clamp(bravery + (d == PersonalityDial.bravery ? by : 0)),
    );
  }

  Map<String, int> toMap() => {
    'playfulness': playfulness,
    'cuddliness': cuddliness,
    'chattiness': chattiness,
    'bravery': bravery,
  };

  factory PersonalityProfile.fromMap(Map<String, dynamic> m) =>
      PersonalityProfile(
        playfulness: (m['playfulness'] as num?)?.toInt() ?? 2,
        cuddliness: (m['cuddliness'] as num?)?.toInt() ?? 2,
        chattiness: (m['chattiness'] as num?)?.toInt() ?? 2,
        bravery: (m['bravery'] as num?)?.toInt() ?? 2,
      );

  @override
  bool operator ==(Object other) =>
      other is PersonalityProfile &&
      other.playfulness == playfulness &&
      other.cuddliness == cuddliness &&
      other.chattiness == chattiness &&
      other.bravery == bravery;

  @override
  int get hashCode => Object.hash(playfulness, cuddliness, chattiness, bravery);
}
