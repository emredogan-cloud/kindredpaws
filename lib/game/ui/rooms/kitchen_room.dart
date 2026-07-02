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
import '../widgets/ambient_scene.dart';
import '../widgets/cozy.dart';
import 'room_scaffold.dart';
import 'widgets/need_glow.dart';

class KitchenRoom extends StatefulWidget {
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
  State<KitchenRoom> createState() => _KitchenRoomState();
}

class _KitchenRoomState extends State<KitchenRoom> {
  GameController get controller => widget.controller;
  PetRenderer get rig => widget.rig;
  void Function(RoomId) get goToRoom => widget.goToRoom;

  /// The snack currently flying from the shelf to the pet (eating animation);
  /// re-keyed per feed so each meal flies fresh. One-shot — settle-safe.
  String? _flyingEmoji;
  int _flightSeq = 0;

  Future<void> _feed(ItemDef food) async {
    if (controller.inventory.pantryCount(food.id) > 0 &&
        !controller.isSleeping) {
      setState(() {
        _flyingEmoji = food.emoji;
        _flightSeq++;
      });
    }
    await controller.feedWith(food);
  }

  @override
  Widget build(BuildContext context) {
    final pet = controller.pet;
    if (pet == null) return const SizedBox.shrink();
    final foods = ItemCatalog.ofKind(ItemKind.food);
    final stocked = foods
        .where((f) => controller.inventory.pantryCount(f.id) > 0)
        .toList(growable: false);

    return Stack(
      fit: StackFit.expand,
      children: [
        RoomScaffold(
          controller: controller,
          rig: rig,
          sceneAsset: KpAssets.kitchenScene,
          ambient: const AmbientScene(variant: AmbientVariant.kitchenSteam),
          decorRoom: RoomId.kitchen,
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
                                onTap: () => _feed(food),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      _GroceryShortcut(goToRoom: goToRoom),
                    ],
                  ),
          ),
        ),
        // The meal on its way — shelf to snoot (the eating animation's first
        // half; the pet's munch reaction + crumbs finish the story).
        if (_flyingEmoji != null)
          IgnorePointer(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('flight-$_flightSeq'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeInOutCubic,
              onEnd: () => setState(() => _flyingEmoji = null),
              builder: (context, t, _) {
                final align = Alignment.lerp(
                  const Alignment(0, 0.42),
                  const Alignment(0, -0.5),
                  t,
                )!;
                return Align(
                  alignment: align,
                  child: Opacity(
                    opacity: t > 0.85 ? (1 - t) / 0.15 : 1,
                    child: Transform.scale(
                      scale: 1.15 - 0.45 * t,
                      child: Text(
                        _flyingEmoji!,
                        key: const Key('flying-snack'),
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
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
