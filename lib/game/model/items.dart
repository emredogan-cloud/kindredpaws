/// The item catalog — foods, toys, care supplies, and wardrobe cosmetics for
/// the room-based home (Immersive Pet Experience sprint). All prices are in
/// **Kibble** (soft currency, §8.1: treats 10–30, mid delight 60–220, common
/// cosmetics 200–800). Nothing here is purchasable with real money, nothing
/// grants Bond/growth (no pay-to-win), and every line of copy stays warm and
/// child-safe. Premium cosmetics are entitlement-gated (Forever Friends) —
/// architecture only, never required for the pet's wellbeing.
library;

/// What an item fundamentally is (drives which room shows it and how it acts).
enum ItemKind {
  /// Consumed in the Kitchen — restores hunger (+ a little joy).
  food('food'),

  /// Owned forever; played with in the Play Garden (joy, costs energy).
  toy('toy'),

  /// Gentle Care Corner consumables (vitamin chew, soothing balm…).
  careSupply('careSupply'),

  /// Wardrobe cosmetics — pure delight, zero gameplay power.
  cosmetic('cosmetic');

  const ItemKind(this.id);
  final String id;
}

/// Wardrobe slot a cosmetic occupies (equipping replaces the same slot).
enum CosmeticSlot { hat, neck }

/// One catalog entry. Effect magnitudes are meter deltas (0–100 scale) applied
/// by the deterministic simulation; the sim clamps, so values here are safe.
class ItemDef {
  const ItemDef({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.flavor,
    required this.emoji,
    this.kibblePrice = 0,
    this.satiety = 0,
    this.joy = 0,
    this.energy = 0,
    this.hygiene = 0,
    this.slot,
    this.premium = false,
  });

  /// Stable id (persisted in saves — never rename).
  final String id;
  final ItemKind kind;
  final String displayName;

  /// One warm, child-safe line shown on shelves/cards.
  final String flavor;

  /// Sticker face shown until dedicated art lands (decorative; labels carry
  /// meaning for a11y).
  final String emoji;

  /// Kibble cost in the Grocery Store; 0 ⇒ not sold there (starter/premium).
  final int kibblePrice;

  /// Hunger restored when eaten (foods).
  final double satiety;

  /// Happiness delta (foods a little, toys a lot).
  final double joy;

  /// Energy delta (negative for lively toys, positive for restful supplies).
  final double energy;

  /// Hygiene delta (bath-time supplies).
  final double hygiene;

  /// Which wardrobe slot this cosmetic fills (cosmetics only).
  final CosmeticSlot? slot;

  /// True ⇒ needs the Forever Friends entitlement (cosmetic-only premium;
  /// the pet's wellbeing NEVER depends on it).
  final bool premium;

  bool get purchasable => kibblePrice > 0 && !premium;
}

/// The static launch catalog. Kept const + code-defined (same pattern as the
/// monetization `product_catalog.dart`) so the sim stays deterministic and
/// content changes are reviewable.
abstract final class ItemCatalog {
  // ── Foods (Kitchen / Grocery) — treats 10–30 Kibble (§8.1) ──────────────
  static const kibbleBowl = ItemDef(
    id: 'food_kibble_bowl',
    kind: ItemKind.food,
    displayName: 'Kibble Bowl',
    flavor: 'A hearty bowl of the classic crunch.',
    emoji: '🥣',
    kibblePrice: 12,
    satiety: 35,
    joy: 4,
  );
  static const apple = ItemDef(
    id: 'food_apple',
    kind: ItemKind.food,
    displayName: 'Crisp Apple',
    flavor: 'Sweet, crunchy, picked this morning.',
    emoji: '🍎',
    kibblePrice: 10,
    satiety: 18,
    joy: 4,
  );
  static const carrot = ItemDef(
    id: 'food_carrot',
    kind: ItemKind.food,
    displayName: 'Garden Carrot',
    flavor: 'Grown in the sunny garden patch.',
    emoji: '🥕',
    kibblePrice: 10,
    satiety: 15,
    joy: 3,
  );
  static const chickenBites = ItemDef(
    id: 'food_chicken_bites',
    kind: ItemKind.food,
    displayName: 'Chicken Bites',
    flavor: 'Warm little bites, made with love.',
    emoji: '🍗',
    kibblePrice: 22,
    satiety: 45,
    joy: 6,
  );
  static const salmonSnack = ItemDef(
    id: 'food_salmon_snack',
    kind: ItemKind.food,
    displayName: 'Salmon Snack',
    flavor: 'A fancy nibble for a fancy friend.',
    emoji: '🐟',
    kibblePrice: 24,
    satiety: 42,
    joy: 8,
  );
  static const berryTreat = ItemDef(
    id: 'food_berry_treat',
    kind: ItemKind.food,
    displayName: 'Berry Treat',
    flavor: 'Bursting with garden berries.',
    emoji: '🫐',
    kibblePrice: 14,
    satiety: 12,
    joy: 10,
  );
  static const honeyBiscuit = ItemDef(
    id: 'food_honey_biscuit',
    kind: ItemKind.food,
    displayName: 'Honey Biscuit',
    flavor: 'Baked golden, best shared.',
    emoji: '🍪',
    kibblePrice: 30,
    satiety: 25,
    joy: 14,
  );

  // ── Toys (Play Garden / Grocery) — owned forever, mid-tier delight ──────
  static const bouncyBall = ItemDef(
    id: 'toy_bouncy_ball',
    kind: ItemKind.toy,
    displayName: 'Bouncy Ball',
    flavor: 'Boing! Boing! The all-time favourite.',
    emoji: '🎾',
    kibblePrice: 60,
    joy: 30,
    energy: -10,
  );
  static const tugRope = ItemDef(
    id: 'toy_tug_rope',
    kind: ItemKind.toy,
    displayName: 'Tug Rope',
    flavor: 'For gentle, giggly tug-of-war.',
    emoji: '🪢',
    kibblePrice: 90,
    joy: 32,
    energy: -12,
  );
  static const featherWand = ItemDef(
    id: 'toy_feather_wand',
    kind: ItemKind.toy,
    displayName: 'Feather Wand',
    flavor: 'Swish, swish — pounce!',
    emoji: '🪶',
    kibblePrice: 110,
    joy: 34,
    energy: -11,
  );
  static const squeakyDuck = ItemDef(
    id: 'toy_squeaky_duck',
    kind: ItemKind.toy,
    displayName: 'Squeaky Duck',
    flavor: 'Squeak-squeak! Bath-time buddy approved.',
    emoji: '🦆',
    kibblePrice: 140,
    joy: 36,
    energy: -9,
  );
  static const puzzleBox = ItemDef(
    id: 'toy_puzzle_box',
    kind: ItemKind.toy,
    displayName: 'Puzzle Box',
    flavor: 'A clever snack-hiding challenge.',
    emoji: '🧩',
    kibblePrice: 180,
    joy: 38,
    energy: -8,
  );
  static const plushStar = ItemDef(
    id: 'toy_plush_star',
    kind: ItemKind.toy,
    displayName: 'Plush Star',
    flavor: 'Soft as a cloud, snuggle-certified.',
    emoji: '⭐',
    kibblePrice: 220,
    joy: 40,
    energy: -6,
  );

  // ── Care supplies (Care Corner / Grocery) — gentle, never medical-scary ─
  static const vitaminChew = ItemDef(
    id: 'care_vitamin_chew',
    kind: ItemKind.careSupply,
    displayName: 'Vitamin Chew',
    flavor: 'A tasty little boost of sunshine.',
    emoji: '🌟',
    kibblePrice: 15,
    satiety: 6,
    joy: 6,
    energy: 10,
  );
  static const soothingBalm = ItemDef(
    id: 'care_soothing_balm',
    kind: ItemKind.careSupply,
    displayName: 'Soothing Balm',
    flavor: 'Lavender-soft comfort for cozy paws.',
    emoji: '🫙',
    kibblePrice: 18,
    joy: 10,
    hygiene: 8,
  );
  static const warmBroth = ItemDef(
    id: 'care_warm_broth',
    kind: ItemKind.careSupply,
    displayName: 'Warm Broth',
    flavor: 'Sip by sip, warmth all the way down.',
    emoji: '🍵',
    kibblePrice: 20,
    satiety: 15,
    joy: 8,
    energy: 12,
  );

  // ── Wardrobe cosmetics — common 200–800 Kibble; premium = entitlement ───
  static const bobbleHat = ItemDef(
    id: 'wear_bobble_hat',
    kind: ItemKind.cosmetic,
    displayName: 'Bobble Hat',
    flavor: 'Hand-knitted, extra bobbly.',
    emoji: '🧶',
    kibblePrice: 250,
    slot: CosmeticSlot.hat,
  );
  static const flowerCrown = ItemDef(
    id: 'wear_flower_crown',
    kind: ItemKind.cosmetic,
    displayName: 'Flower Crown',
    flavor: 'Fresh from the garden patch.',
    emoji: '🌼',
    kibblePrice: 450,
    slot: CosmeticSlot.hat,
  );
  static const cozyBeanie = ItemDef(
    id: 'wear_cozy_beanie',
    kind: ItemKind.cosmetic,
    displayName: 'Cozy Beanie',
    flavor: 'Toasty ears, happy heart.',
    emoji: '🧢',
    kibblePrice: 300,
    slot: CosmeticSlot.hat,
  );
  static const bellCollar = ItemDef(
    id: 'wear_bell_collar',
    kind: ItemKind.cosmetic,
    displayName: 'Bell Collar',
    flavor: 'A tiny jingle wherever you go.',
    emoji: '🔔',
    kibblePrice: 300,
    slot: CosmeticSlot.neck,
  );
  static const starCharm = ItemDef(
    id: 'wear_star_charm',
    kind: ItemKind.cosmetic,
    displayName: 'Star Charm Collar',
    flavor: 'A little starlight to carry along.',
    emoji: '✨',
    kibblePrice: 380,
    slot: CosmeticSlot.neck,
  );
  static const heartBandana = ItemDef(
    id: 'wear_heart_bandana',
    kind: ItemKind.cosmetic,
    displayName: 'Heart Bandana',
    flavor: 'Worn closest to the heart.',
    emoji: '💛',
    kibblePrice: 260,
    slot: CosmeticSlot.neck,
  );
  static const sunbeamBandana = ItemDef(
    id: 'wear_sunbeam_bandana',
    kind: ItemKind.cosmetic,
    displayName: 'Sunbeam Bandana',
    flavor: 'A Forever Friends keepsake, warm as morning light.',
    emoji: '🌞',
    slot: CosmeticSlot.neck,
    premium: true,
  );
  static const moonlightCap = ItemDef(
    id: 'wear_moonlight_cap',
    kind: ItemKind.cosmetic,
    displayName: 'Moonlight Cap',
    flavor: 'A Forever Friends keepsake, soft as starlight.',
    emoji: '🌙',
    slot: CosmeticSlot.hat,
    premium: true,
  );

  /// Every catalog item (order = shelf display order).
  static const List<ItemDef> all = [
    // foods
    kibbleBowl, apple, carrot, chickenBites, salmonSnack, berryTreat,
    honeyBiscuit,
    // toys
    bouncyBall, tugRope, featherWand, squeakyDuck, puzzleBox, plushStar,
    // care supplies
    vitaminChew, soothingBalm, warmBroth,
    // cosmetics
    bobbleHat, flowerCrown, cozyBeanie, bellCollar, starCharm, heartBandana,
    sunbeamBandana, moonlightCap,
  ];

  static final Map<String, ItemDef> _byId = {for (final i in all) i.id: i};

  /// Looks up an item by stable id; null for unknown ids (saves survive
  /// catalog removals — unknown inventory entries are simply inert).
  static ItemDef? byId(String id) => _byId[id];

  static List<ItemDef> ofKind(ItemKind kind) =>
      all.where((i) => i.kind == kind).toList(growable: false);

  /// What the Grocery Store sells: everything Kibble-priced and non-premium.
  /// (Cosmetics live in the Wardrobe's little boutique, not the grocery.)
  static List<ItemDef> groceryShelf() => all
      .where((i) => i.purchasable && i.kind != ItemKind.cosmetic)
      .toList(growable: false);
}
