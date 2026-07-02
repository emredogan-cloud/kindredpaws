/// Daily Kindnesses (GE-1, MASTER_KINDREDPAWS_PRODUCT_ROADMAP.md) — two gentle,
/// varied care invitations each day. The ethical translation of the genre's
/// daily-challenge loop: deterministic visible rewards, no countdowns, no
/// expiry drama — an uncompleted kindness simply makes way for tomorrow's,
/// and the pet never minds (Charter §4: variety without pressure).
library;

/// Which real care moment completes a kindness. Every trigger maps to an
/// existing, honest interaction hook — kindnesses are *detected*, never
/// claimed via a button (the moment itself is the proof).
enum KindnessTrigger {
  /// Any Kitchen/Home feed (generic or pantry food).
  feed('feed'),

  /// Any clean — the bath scrub or a quick rinse.
  clean('clean'),

  /// Any play — the Home verb, a toy, or a mini-game round.
  play('play'),

  /// A comfort cuddle (Care Corner / Bedroom).
  comfort('comfort'),

  /// Using a gentle care supply (vitamin chew, soothing balm…).
  supply('supply'),

  /// Tucking the pet in for the night.
  tuckIn('tuckIn'),

  /// Finishing a Play Garden mini-game round (any score — no-fail).
  miniGame('miniGame'),

  /// Wearing something from the Wardrobe.
  dressUp('dressUp'),

  /// Bringing something home from the Grocery Store.
  grocery('grocery'),

  /// The always-reassuring Care Corner temperature check.
  wellness('wellness');

  const KindnessTrigger(this.id);
  final String id;

  static KindnessTrigger fromId(String id) =>
      values.firstWhere((t) => t.id == id, orElse: () => KindnessTrigger.feed);
}

/// One kindness template. Copy is a warm *invitation* — never a chore, never
/// guilt (validated in tests against the forbidden-guilt vocabulary).
class KindnessDef {
  const KindnessDef({
    required this.id,
    required this.trigger,
    required this.title,
    required this.invitation,
    required this.emoji,
    required this.room,
    required this.kibble,
    this.itemIds,
    this.requiresItem = false,
  });

  /// Stable id (persisted in saves — never rename).
  final String id;
  final KindnessTrigger trigger;

  /// Short warm title ("Bubble-bath time").
  final String title;

  /// One inviting line shown on the card.
  final String invitation;

  /// Sticker face for the card + completion toast.
  final String emoji;

  /// Where the moment naturally happens (a hint, not a requirement — the
  /// trigger is room-agnostic wherever the verb is).
  final String room;

  /// Kibble thank-you on completion (canon band 10–20).
  final int kibble;

  /// When set, only these item ids complete it (e.g. garden-fresh foods).
  final Set<String>? itemIds;

  /// When true, the moment must involve a specific item (e.g. a real toy).
  final bool requiresItem;

  /// Whether a concrete moment (trigger + optional item) completes this.
  bool matches(KindnessTrigger t, {String? itemId}) {
    if (t != trigger) return false;
    if (requiresItem && itemId == null) return false;
    final ids = itemIds;
    if (ids != null && (itemId == null || !ids.contains(itemId))) return false;
    return true;
  }
}

/// The static kindness catalog — const + code-defined (same reviewable pattern
/// as `ItemCatalog`). One def per trigger flavor; the daily pair always mixes
/// two different triggers AND two different rooms, so every day feels new.
abstract final class KindnessCatalog {
  static const shareAMeal = KindnessDef(
    id: 'kind_share_a_meal',
    trigger: KindnessTrigger.feed,
    title: 'Share a meal',
    invitation: 'A tasty something from the pantry would hit the spot.',
    emoji: '🍽️',
    room: 'Kitchen',
    kibble: 12,
  );
  static const gardenCrunch = KindnessDef(
    id: 'kind_garden_crunch',
    trigger: KindnessTrigger.feed,
    title: 'Something garden-fresh',
    invitation: 'An apple or a garden carrot — crisp, crunchy, delightful.',
    emoji: '🍎',
    room: 'Kitchen',
    kibble: 16,
    itemIds: {'food_apple', 'food_carrot'},
  );
  static const bubbleBath = KindnessDef(
    id: 'kind_bubble_bath',
    trigger: KindnessTrigger.clean,
    title: 'Bubble-bath time',
    invitation: 'A warm scrub and a rinse — pure bliss.',
    emoji: '🫧',
    room: 'Bathroom',
    kibble: 14,
  );
  static const gardenRomp = KindnessDef(
    id: 'kind_garden_romp',
    trigger: KindnessTrigger.play,
    title: 'A garden romp',
    invitation: 'Time to bounce around together!',
    emoji: '🌿',
    room: 'Play Garden',
    kibble: 12,
  );
  static const favoriteToy = KindnessDef(
    id: 'kind_favorite_toy',
    trigger: KindnessTrigger.play,
    title: 'Play with a toy',
    invitation: 'Pick any toy from the basket — joy guaranteed.',
    emoji: '🧸',
    room: 'Play Garden',
    kibble: 15,
    requiresItem: true,
  );
  static const gentleCuddle = KindnessDef(
    id: 'kind_gentle_cuddle',
    trigger: KindnessTrigger.comfort,
    title: 'A gentle cuddle',
    invitation: 'A quiet comfort moment, just the two of you.',
    emoji: '💛',
    room: 'Care Corner',
    kibble: 12,
  );
  static const cozyTreat = KindnessDef(
    id: 'kind_cozy_treat',
    trigger: KindnessTrigger.supply,
    title: 'A cozy little treat',
    invitation: 'A vitamin chew or a soothing balm — extra snug.',
    emoji: '✨',
    room: 'Care Corner',
    kibble: 15,
  );
  static const tuckInTonight = KindnessDef(
    id: 'kind_tuck_in_tonight',
    trigger: KindnessTrigger.tuckIn,
    title: 'Tuck-in time',
    invitation: 'Lights low, blanket snug — sweet dreams ahead.',
    emoji: '🌙',
    room: 'Bedroom',
    kibble: 12,
  );
  static const gameTogether = KindnessDef(
    id: 'kind_game_together',
    trigger: KindnessTrigger.miniGame,
    title: 'A little game together',
    invitation: 'One round of anything — playing together is the win.',
    emoji: '🎈',
    room: 'Play Garden',
    kibble: 15,
  );
  static const dressUpDay = KindnessDef(
    id: 'kind_dress_up_day',
    trigger: KindnessTrigger.dressUp,
    title: 'Dress-up moment',
    invitation: 'Try a look from the Wardrobe — any look!',
    emoji: '🎀',
    room: 'Wardrobe',
    kibble: 12,
  );
  static const pantryRestock = KindnessDef(
    id: 'kind_pantry_restock',
    trigger: KindnessTrigger.grocery,
    title: 'A grocery trip',
    invitation: 'Pick up something nice for the pantry shelf.',
    emoji: '🧺',
    room: 'Grocery',
    kibble: 10,
  );
  static const wellnessRitual = KindnessDef(
    id: 'kind_wellness_ritual',
    trigger: KindnessTrigger.wellness,
    title: 'A wellness moment',
    invitation: 'The Care Corner thermometer — always reassuring.',
    emoji: '🌡️',
    room: 'Care Corner',
    kibble: 10,
  );

  static const List<KindnessDef> all = [
    shareAMeal,
    gardenCrunch,
    bubbleBath,
    gardenRomp,
    favoriteToy,
    gentleCuddle,
    cozyTreat,
    tuckInTonight,
    gameTogether,
    dressUpDay,
    pantryRestock,
    wellnessRitual,
  ];

  static KindnessDef? byId(String id) {
    for (final def in all) {
      if (def.id == id) return def;
    }
    return null; // a retired id in an old save is simply inert
  }
}

/// Today's offered pair + what's been completed. Persisted (schema v8) so the
/// day survives restarts; a new day quietly brings a fresh pair.
class KindnessState {
  const KindnessState({
    required this.dayEpoch,
    required this.offered,
    this.completed = const [],
  });

  /// Epoch day (days since Unix epoch, UTC — same convention as the streak).
  final int dayEpoch;

  /// The two offered kindness ids (stable order for the UI).
  final List<String> offered;

  /// Completed ids, in completion order. Subset of [offered].
  final List<String> completed;

  bool isCompleted(String id) => completed.contains(id);
  bool get allDone => offered.isNotEmpty && completed.length >= offered.length;

  KindnessState copyWith({List<String>? completed}) => KindnessState(
    dayEpoch: dayEpoch,
    offered: offered,
    completed: completed ?? this.completed,
  );

  Map<String, dynamic> toMap() => {
    'dayEpoch': dayEpoch,
    'offered': offered,
    'completed': completed,
  };

  factory KindnessState.fromMap(Map<String, dynamic> m) => KindnessState(
    dayEpoch: (m['dayEpoch'] as num?)?.toInt() ?? 0,
    offered: (m['offered'] as List? ?? const [])
        .map((e) => e as String)
        .toList(),
    completed: (m['completed'] as List? ?? const [])
        .map((e) => e as String)
        .toList(),
  );

  @override
  bool operator ==(Object other) =>
      other is KindnessState &&
      other.dayEpoch == dayEpoch &&
      _listEq(other.offered, offered) &&
      _listEq(other.completed, completed);

  @override
  int get hashCode =>
      Object.hash(dayEpoch, Object.hashAll(offered), Object.hashAll(completed));

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
