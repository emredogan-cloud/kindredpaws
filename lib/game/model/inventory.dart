/// The pet-household inventory — pantry foods, owned toys (with affection
/// progression), care supplies, and the wardrobe closet. Immutable value
/// (copyWith), serialized in the save envelope (schema v7). Unknown item ids
/// deserialize untouched and stay inert, so a catalog change can never corrupt
/// or orphan a save (Risk R4).
library;

import 'items.dart';

class Inventory {
  const Inventory({
    this.pantry = const {},
    this.toys = const {},
    this.toyAffinity = const {},
    this.supplies = const {},
    this.closet = const {},
    this.equipped = const {},
    this.decor = const {},
    this.placements = const {},
    this.wishlistId,
  });

  /// foodId → count waiting in the kitchen.
  final Map<String, int> pantry;

  /// Owned toy ids (toys are forever).
  final Set<String> toys;

  /// toyId → times played together. Pure delight progression: a well-loved toy
  /// earns "favourite" badges; it never gates or boosts Bond (no pay-to-win).
  final Map<String, int> toyAffinity;

  /// careSupply id → count on the Care Corner shelf.
  final Map<String, int> supplies;

  /// Owned cosmetic ids.
  final Set<String> closet;

  /// Currently worn cosmetic ids (max one per [CosmeticSlot]).
  final Set<String> equipped;

  /// Owned décor ids (Cozy Corners, GE-3 — décor is forever).
  final Set<String> decor;

  /// Décor slot id → placed item id (a slot holds at most one piece).
  final Map<String, String> placements;

  /// The one wished-for item (the saving jar in the shop), or null. Pure
  /// expression of intent — never a notification, never a nag.
  final String? wishlistId;

  /// The rescue starter kit: a couple of meals, one beloved ball, one vitamin
  /// chew — so no room ever greets the player empty.
  factory Inventory.starter() => Inventory(
    pantry: {ItemCatalog.kibbleBowl.id: 2, ItemCatalog.apple.id: 1},
    toys: {ItemCatalog.bouncyBall.id},
    supplies: {ItemCatalog.vitaminChew.id: 1},
  );

  int pantryCount(String foodId) => pantry[foodId] ?? 0;
  int supplyCount(String id) => supplies[id] ?? 0;
  int affinity(String toyId) => toyAffinity[toyId] ?? 0;
  bool ownsToy(String toyId) => toys.contains(toyId);
  bool ownsCosmetic(String id) => closet.contains(id);
  bool isEquipped(String id) => equipped.contains(id);
  bool ownsDecor(String id) => decor.contains(id);

  /// The décor piece placed in [slotId], or null (empty spot).
  String? placedIn(String slotId) => placements[slotId];

  /// The cosmetic currently worn in [slot], or null.
  String? equippedIn(CosmeticSlot slot) {
    for (final id in equipped) {
      if (ItemCatalog.byId(id)?.slot == slot) return id;
    }
    return null;
  }

  Inventory copyWith({
    Map<String, int>? pantry,
    Set<String>? toys,
    Map<String, int>? toyAffinity,
    Map<String, int>? supplies,
    Set<String>? closet,
    Set<String>? equipped,
    Set<String>? decor,
    Map<String, String>? placements,
    String? wishlistId,
    bool clearWishlist = false,
  }) => Inventory(
    pantry: pantry ?? this.pantry,
    toys: toys ?? this.toys,
    toyAffinity: toyAffinity ?? this.toyAffinity,
    supplies: supplies ?? this.supplies,
    closet: closet ?? this.closet,
    equipped: equipped ?? this.equipped,
    decor: decor ?? this.decor,
    placements: placements ?? this.placements,
    wishlistId: clearWishlist ? null : (wishlistId ?? this.wishlistId),
  );

  /// Adds [count] of a stackable item ([ItemKind.food]/[ItemKind.careSupply])
  /// or marks a toy/cosmetic/décor owned.
  Inventory add(ItemDef item, {int count = 1}) => switch (item.kind) {
    ItemKind.food => copyWith(
      pantry: {...pantry, item.id: pantryCount(item.id) + count},
    ),
    ItemKind.careSupply => copyWith(
      supplies: {...supplies, item.id: supplyCount(item.id) + count},
    ),
    ItemKind.toy => copyWith(toys: {...toys, item.id}),
    ItemKind.cosmetic => copyWith(closet: {...closet, item.id}),
    ItemKind.decor => copyWith(decor: {...decor, item.id}),
  };

  /// Places an owned décor piece in [slotId] (replacing whatever sat there).
  /// No-op if the piece isn't owned — defense in depth, the UI gates too.
  Inventory place(String slotId, String itemId) {
    if (!decor.contains(itemId)) return this;
    return copyWith(placements: {...placements, slotId: itemId});
  }

  /// Empties [slotId] (the piece stays owned — back to the box, never lost).
  Inventory clearSlot(String slotId) =>
      copyWith(placements: {...placements}..remove(slotId));

  /// Consumes one stackable item; returns null if none left (caller surfaces
  /// a warm "we're out" message — never an error).
  Inventory? consume(ItemDef item) {
    final store = item.kind == ItemKind.food ? pantry : supplies;
    final left = store[item.id] ?? 0;
    if (left <= 0) return null;
    final next = {...store};
    if (left == 1) {
      next.remove(item.id);
    } else {
      next[item.id] = left - 1;
    }
    return item.kind == ItemKind.food
        ? copyWith(pantry: next)
        : copyWith(supplies: next);
  }

  /// Records one shared play with [toyId] (the affection progression).
  Inventory bumpAffinity(String toyId) =>
      copyWith(toyAffinity: {...toyAffinity, toyId: affinity(toyId) + 1});

  /// Wears [item], unequipping whatever held its slot. No-op if not owned.
  Inventory equip(ItemDef item) {
    if (!closet.contains(item.id) || item.slot == null) return this;
    final next = {
      for (final id in equipped)
        if (ItemCatalog.byId(id)?.slot != item.slot) id,
      item.id,
    };
    return copyWith(equipped: next);
  }

  Inventory unequip(String id) => copyWith(equipped: {...equipped}..remove(id));

  Map<String, Object?> toMap() => {
    'pantry': pantry,
    'toys': toys.toList(),
    'toyAffinity': toyAffinity,
    'supplies': supplies,
    'closet': closet.toList(),
    'equipped': equipped.toList(),
    'decor': decor.toList(),
    'placements': placements,
    'wishlistId': wishlistId,
  };

  factory Inventory.fromMap(Map<String, dynamic> m) {
    Map<String, int> counts(String key) =>
        ((m[key] as Map?)?.cast<String, dynamic>() ?? const {}).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        );
    Set<String> ids(String key) =>
        ((m[key] as List?) ?? const []).map((e) => e as String).toSet();
    return Inventory(
      pantry: counts('pantry'),
      toys: ids('toys'),
      toyAffinity: counts('toyAffinity'),
      supplies: counts('supplies'),
      closet: ids('closet'),
      equipped: ids('equipped'),
      decor: ids('decor'),
      placements:
          ((m['placements'] as Map?)?.cast<String, dynamic>() ?? const {}).map(
            (k, v) => MapEntry(k, v as String),
          ),
      wishlistId: m['wishlistId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Inventory &&
      _mapEq(other.pantry, pantry) &&
      _setEq(other.toys, toys) &&
      _mapEq(other.toyAffinity, toyAffinity) &&
      _mapEq(other.supplies, supplies) &&
      _setEq(other.closet, closet) &&
      _setEq(other.equipped, equipped) &&
      _setEq(other.decor, decor) &&
      _strMapEq(other.placements, placements) &&
      other.wishlistId == wishlistId;

  static bool _mapEq(Map<String, int> a, Map<String, int> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
  static bool _strMapEq(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
  static bool _setEq(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(
      pantry.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(toys),
    Object.hashAllUnordered(
      toyAffinity.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(
      supplies.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(closet),
    Object.hashAllUnordered(equipped),
    Object.hashAllUnordered(decor),
    Object.hashAllUnordered(
      placements.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    wishlistId,
  );
}
