/// The Kitchen — mealtime together. The pantry shelf holds the foods you've
/// stocked; offering one feeds the pet through the canonical feed verb (same
/// bond/streak/diminishing rules), the pet plays its eating reaction, and a
/// soft fullness glow gives number-light nutrition feedback (§5.5). An empty
/// shelf nudges the Grocery Store — warmly, never as an error.
library;

import 'package:flutter/material.dart';

import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../model/care_meters.dart';
import '../../model/items.dart';
import '../../rooms/room_id.dart';
import '../widgets/cozy.dart';
import 'room_scaffold.dart';
import 'widgets/need_glow.dart';

class KitchenRoom extends StatelessWidget {
  const KitchenRoom({
    required this.controller,
    required this.rig,
    required this.goToRoom,
    super.key,
  });

  final GameController controller;
  final PetRenderer rig;
  final void Function(RoomId) goToRoom;

  @override
  Widget build(BuildContext context) {
    final pet = controller.pet;
    if (pet == null) return const SizedBox.shrink();
    final foods = ItemCatalog.ofKind(ItemKind.food);
    final stocked = foods
        .where((f) => controller.inventory.pantryCount(f.id) > 0)
        .toList(growable: false);

    return RoomScaffold(
      controller: controller,
      rig: rig,
      sceneAsset: KpAssets.cozyRoomDay,
      // A warm, buttery morning-kitchen light.
      tint: const Color(0x2EFFD9A0),
      content: ShelfPanel(
        title: 'Pantry',
        trailing: NeedGlow(
          label: 'Fullness',
          value: pet.meters.of(CareNeed.hunger),
          icon: Icons.restaurant_rounded,
        ),
        child: stocked.isEmpty
            ? _EmptyPantry(goToRoom: goToRoom)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ShelfGrid(
                      children: [
                        for (final food in stocked)
                          ItemCard(
                            item: food,
                            cardKey: Key('pantry-${food.id}'),
                            badge:
                                '×${controller.inventory.pantryCount(food.id)}',
                            onTap: () => controller.feedWith(food),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _GroceryShortcut(goToRoom: goToRoom),
                ],
              ),
      ),
    );
  }
}

class _EmptyPantry extends StatelessWidget {
  const _EmptyPantry({required this.goToRoom});
  final void Function(RoomId) goToRoom;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🧺', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 6),
        const Text(
          'The pantry is waiting for goodies!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _GroceryShortcut(goToRoom: goToRoom),
      ],
    );
  }
}

/// The mission's shopping shortcut: one hop to the Grocery Store.
class _GroceryShortcut extends StatelessWidget {
  const _GroceryShortcut({required this.goToRoom});
  final void Function(RoomId) goToRoom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        key: const Key('kitchen-grocery-shortcut'),
        onPressed: () => goToRoom(RoomId.groceryStore),
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        icon: const Icon(Icons.storefront_rounded, size: 18),
        label: const Text('Grocery Store'),
      ),
    );
  }
}
