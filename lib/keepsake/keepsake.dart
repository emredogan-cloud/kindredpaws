/// Keepsake Cards (GAMEPLAY_AND_PROGRESSION_BIBLE.md §14, GAME_CONTENT_FACTORY
/// §3.2, P2-5). Shareable, collectible emotional artifacts auto-composed at
/// runtime from the pet's milestones + memories — the emotional scrapbook and
/// the MVP viral moment ("the endearing card IS the ambient ad", §8.6). Composed
/// from existing assets at ~0 incremental art cost.
library;

/// The card kinds, aligned to the seven canonical viral moments (brief §8).
enum KeepsakeKind {
  rescueDay('Rescue Day', '🏠'),
  gotchaDay('Gotcha Day', '🎉'),
  beforeAfterGrowth('Before & After', '🌱'),
  longMemoryCallback('It Remembered', '💭'),
  unpromptedComfort('A Quiet Comfort', '💗'),
  bondMilestone('A New Bond', '💛'),
  streakMilestone('Days Together', '🔥'),
  personalityReveal('Only My Pet', '✨'),
  decorSet('A Cozy Corner', '🛋️'),
  season('A Season Together', '🌤️');

  const KeepsakeKind(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

class Keepsake {
  const Keepsake({
    required this.id,
    required this.kind,
    required this.title,
    required this.caption,
    required this.petName,
    required this.species,
    required this.lifeStage,
    required this.createdAtMs,
  });

  final String id;
  final KeepsakeKind kind;
  final String title;
  final String caption;
  final String petName;
  final String species; // 'puppy' | 'kitten'
  final String lifeStage; // 'pupKit' | 'youngOne' | 'grown'
  final int createdAtMs;

  /// The composed card image reference (the native/render layer composes the rig
  /// snapshot + frame + caption + watermark at share time; §3.2). Deterministic.
  String get imageRef => '${species}_${lifeStage}_${kind.name}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'caption': caption,
    'petName': petName,
    'species': species,
    'lifeStage': lifeStage,
    'createdAtMs': createdAtMs,
  };

  factory Keepsake.fromJson(Map<String, dynamic> j) => Keepsake(
    id: j['id'] as String,
    kind: KeepsakeKind.values.byName(j['kind'] as String),
    title: j['title'] as String,
    caption: j['caption'] as String,
    petName: j['petName'] as String,
    species: j['species'] as String,
    lifeStage: j['lifeStage'] as String,
    createdAtMs: (j['createdAtMs'] as num).toInt(),
  );

  @override
  bool operator ==(Object other) =>
      other is Keepsake &&
      other.id == id &&
      other.kind == kind &&
      other.title == title &&
      other.caption == caption &&
      other.petName == petName &&
      other.species == species &&
      other.lifeStage == lifeStage &&
      other.createdAtMs == createdAtMs;

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    title,
    caption,
    petName,
    species,
    lifeStage,
    createdAtMs,
  );
}
