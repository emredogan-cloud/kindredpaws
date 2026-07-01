/// Maps each [RoomId] to its dock icon and content builder. Only rooms listed
/// in [enabledRooms] appear in the home — the list grows as rooms ship, so the
/// dock never shows a dead door (no placeholder UX).
library;

import 'package:flutter/material.dart';

import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../rooms/room_id.dart';
import 'bathroom_room.dart';
import 'grocery_room.dart';
import 'home_room.dart';
import 'kitchen_room.dart';
import 'play_room.dart';

/// One room's UI wiring: a friendly rounded dock icon + the room content.
/// Content receives the shared [GameController], the shell-resolved rig, and
/// [goToRoom] (immediate in-home navigation, e.g. the Kitchen's grocery
/// shortcut) so every room drives the same simulation and the same pet.
class RoomDefinition {
  const RoomDefinition({
    required this.id,
    required this.icon,
    required this.build,
  });

  final RoomId id;
  final IconData icon;
  final Widget Function(
    GameController controller,
    PetRenderer rig,
    void Function(RoomId) goToRoom,
  )
  build;
}

/// The rooms currently open, in spatial (swipe) order — a subset of
/// [RoomId.values] that grows as the Immersive Pet Experience rooms land.
List<RoomDefinition> enabledRooms() => const [
  RoomDefinition(
    id: RoomId.groceryStore,
    icon: Icons.storefront_rounded,
    build: _grocery,
  ),
  RoomDefinition(
    id: RoomId.kitchen,
    icon: Icons.soup_kitchen_rounded,
    build: _kitchen,
  ),
  RoomDefinition(
    id: RoomId.bathroom,
    icon: Icons.bathtub_rounded,
    build: _bathroom,
  ),
  RoomDefinition(id: RoomId.home, icon: Icons.cottage_rounded, build: _home),
  RoomDefinition(id: RoomId.playRoom, icon: Icons.toys_rounded, build: _play),
];

Widget _home(GameController c, PetRenderer rig, void Function(RoomId) go) =>
    HomeRoom(controller: c, rig: rig);

Widget _kitchen(GameController c, PetRenderer rig, void Function(RoomId) go) =>
    KitchenRoom(controller: c, rig: rig, goToRoom: go);

Widget _grocery(GameController c, PetRenderer rig, void Function(RoomId) go) =>
    GroceryRoom(controller: c, rig: rig, goToRoom: go);

Widget _bathroom(GameController c, PetRenderer rig, void Function(RoomId) go) =>
    BathroomRoom(controller: c, rig: rig, goToRoom: go);

Widget _play(GameController c, PetRenderer rig, void Function(RoomId) go) =>
    PlayRoom(controller: c, rig: rig, goToRoom: go);
