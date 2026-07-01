/// Maps each [RoomId] to its dock icon and content builder. Only rooms listed
/// in [enabledRooms] appear in the home — the list grows as rooms ship, so the
/// dock never shows a dead door (no placeholder UX).
library;

import 'package:flutter/material.dart';

import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../rooms/room_id.dart';
import 'home_room.dart';
import 'kitchen_room.dart';

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
    id: RoomId.kitchen,
    icon: Icons.soup_kitchen_rounded,
    build: _kitchen,
  ),
  RoomDefinition(id: RoomId.home, icon: Icons.cottage_rounded, build: _home),
];

Widget _home(GameController c, PetRenderer rig, void Function(RoomId) go) =>
    HomeRoom(controller: c, rig: rig);

Widget _kitchen(GameController c, PetRenderer rig, void Function(RoomId) go) =>
    KitchenRoom(controller: c, rig: rig, goToRoom: go);
