/// Cozy Corners décor (GE-3): fixed, named slots per room and warm themed
/// sets. Décor is pure expression — Kibble-only, owned forever, zero
/// gameplay power (the ethical translation of the genre's furniture/AddOn
/// store: collection joy with visible contents, no rarity, no chance).
library;

import 'package:flutter/widgets.dart' show Alignment;

import '../rooms/room_id.dart';
import 'items.dart';

/// One décor slot: a fixed, warmly-named spot in a room's scene. Placement is
/// two taps (slot → owned item); every slot is optional and starts empty.
class DecorSlot {
  const DecorSlot({
    required this.id,
    required this.room,
    required this.label,
    required this.alignment,
    this.width = 64,
  });

  /// Stable id (persisted in placements — never rename).
  final String id;
  final RoomId room;

  /// Child-readable spot name ("the bedside table").
  final String label;

  /// Where the sticker sits within the full-bleed scene.
  final Alignment alignment;

  /// Sticker render width (logical px).
  final double width;
}

/// The 12 launch slots (roadmap GE-3: Home ×3, Bedroom ×3, Play Garden ×3,
/// Kitchen ×2, Bathroom ×1).
abstract final class DecorSlots {
  static const homeShelf = DecorSlot(
    id: 'slot_home_shelf',
    room: RoomId.home,
    label: 'the hearth shelf',
    alignment: Alignment(-0.78, -0.28),
  );
  static const homeWall = DecorSlot(
    id: 'slot_home_wall',
    room: RoomId.home,
    label: 'the wall nook',
    alignment: Alignment(0.8, -0.42),
  );
  static const homeFloor = DecorSlot(
    id: 'slot_home_floor',
    room: RoomId.home,
    label: 'the floor corner',
    alignment: Alignment(-0.82, 0.32),
    width: 84,
  );
  static const bedroomBedside = DecorSlot(
    id: 'slot_bedroom_bedside',
    room: RoomId.bedroom,
    label: 'the bedside table',
    alignment: Alignment(-0.8, -0.1),
  );
  static const bedroomWall = DecorSlot(
    id: 'slot_bedroom_wall',
    room: RoomId.bedroom,
    label: 'the wall above the bed',
    alignment: Alignment(0.05, -0.55),
    width: 92,
  );
  static const bedroomWindow = DecorSlot(
    id: 'slot_bedroom_window',
    room: RoomId.bedroom,
    label: 'the window corner',
    alignment: Alignment(0.82, -0.3),
  );
  static const gardenStump = DecorSlot(
    id: 'slot_garden_stump',
    room: RoomId.playRoom,
    label: 'the old stump',
    alignment: Alignment(-0.8, 0.05),
  );
  static const gardenFence = DecorSlot(
    id: 'slot_garden_fence',
    room: RoomId.playRoom,
    label: 'the fence post',
    alignment: Alignment(0.82, -0.18),
  );
  static const gardenFlowerbed = DecorSlot(
    id: 'slot_garden_flowerbed',
    room: RoomId.playRoom,
    label: 'the flower bed',
    alignment: Alignment(0.05, 0.18),
    width: 76,
  );
  static const kitchenCounter = DecorSlot(
    id: 'slot_kitchen_counter',
    room: RoomId.kitchen,
    label: 'the counter top',
    alignment: Alignment(-0.78, -0.15),
  );
  static const kitchenWall = DecorSlot(
    id: 'slot_kitchen_wall',
    room: RoomId.kitchen,
    label: 'the kitchen wall',
    alignment: Alignment(0.8, -0.4),
  );
  static const bathroomShelf = DecorSlot(
    id: 'slot_bathroom_shelf',
    room: RoomId.bathroom,
    label: 'the bath shelf',
    alignment: Alignment(0.8, -0.32),
  );

  static const List<DecorSlot> all = [
    homeShelf,
    homeWall,
    homeFloor,
    bedroomBedside,
    bedroomWall,
    bedroomWindow,
    gardenStump,
    gardenFence,
    gardenFlowerbed,
    kitchenCounter,
    kitchenWall,
    bathroomShelf,
  ];

  static List<DecorSlot> forRoom(RoomId room) =>
      all.where((s) => s.room == room).toList(growable: false);

  static DecorSlot? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null; // a retired slot id in an old save stays inert
  }
}

/// A themed set: contents fully visible upfront, completion mints a Keepsake.
/// Never gacha, never rarity — just a little collection story to finish.
class DecorSet {
  const DecorSet({
    required this.id,
    required this.title,
    required this.flavor,
    required this.emoji,
    required this.itemIds,
  });

  final String id;
  final String title;
  final String flavor;
  final String emoji;
  final Set<String> itemIds;

  bool completedBy(Set<String> ownedDecor) =>
      itemIds.every(ownedDecor.contains);
}

abstract final class DecorSets {
  static const starryNight = DecorSet(
    id: 'set_starry_night',
    title: 'Starry Night',
    flavor: 'A bedroom that dreams along with you.',
    emoji: '🌟',
    itemIds: {'decor_star_lamp', 'decor_moon_tapestry', 'decor_dream_mobile'},
  );
  static const sunnyMeadow = DecorSet(
    id: 'set_sunny_meadow',
    title: 'Sunny Meadow',
    flavor: 'The garden hums, blooms, and buzzes.',
    emoji: '🌻',
    itemIds: {'decor_sunflower_pot', 'decor_bee_house', 'decor_picnic_gnome'},
  );

  static const List<DecorSet> all = [starryNight, sunnyMeadow];

  /// Sets that include [itemId] (for completion checks on purchase).
  static List<DecorSet> containing(String itemId) =>
      all.where((s) => s.itemIds.contains(itemId)).toList(growable: false);
}

/// Convenience: the décor items of one room's slots (for the decorate sheet).
List<ItemDef> decorItemsForRoom(RoomId room) {
  final slotIds = DecorSlots.forRoom(room).map((s) => s.id).toSet();
  return ItemCatalog.ofKind(ItemKind.decor)
      .where((i) => i.decorSlotId != null && slotIds.contains(i.decorSlotId))
      .toList(growable: false);
}
