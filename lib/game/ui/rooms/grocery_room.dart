/// The Grocery Store — soft-currency shelves only. Foods, treats, toys, and
/// gentle care supplies, all priced in **Kibble** earned by caring; there is
/// no real-money purchase anywhere in this room (the ethical wall). Coming up
/// short is an invitation ("a few more care moments"), never pressure — and
/// nothing sold here can ever buy Bond or growth.
library;

import 'package:flutter/material.dart';

import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../model/items.dart';
import '../../rooms/room_id.dart';
import '../widgets/cozy.dart';
import 'room_scaffold.dart';

class GroceryRoom extends StatelessWidget {
  const GroceryRoom({
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

    final sections = <(String, List<ItemDef>)>[
      ('Fresh & tasty', ItemCatalog.ofKind(ItemKind.food)),
      ('Toy corner', ItemCatalog.ofKind(ItemKind.toy)),
      ('Gentle care', ItemCatalog.ofKind(ItemKind.careSupply)),
    ];

    return RoomScaffold(
      controller: controller,
      rig: rig,
      sceneAsset: KpAssets.groceryScene,
      content: ShelfPanel(
        title: 'Grocery Store',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CozyImage(KpAssets.iconKibble, width: 18, height: 18),
            const SizedBox(width: 3),
            Text(
              '${pet.wallet.kibble}',
              key: const Key('grocery-kibble'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF4A3F38),
              ),
            ),
          ],
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            for (final (label, items) in sections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7A6A58),
                  ),
                ),
              ),
              ShelfGrid(
                children: [
                  for (final item in items.where((i) => i.purchasable))
                    _shelfCard(item),
                ],
              ),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _shelfCard(ItemDef item) {
    final ownedForever = switch (item.kind) {
      ItemKind.toy => controller.inventory.ownsToy(item.id),
      ItemKind.cosmetic => controller.inventory.ownsCosmetic(item.id),
      _ => false,
    };
    return ItemCard(
      item: item,
      cardKey: Key('shelf-${item.id}'),
      badge: ownedForever ? 'yours 💛' : '${item.kibblePrice}',
      badgeIcon: ownedForever
          ? null
          : const Padding(
              padding: EdgeInsets.only(right: 2),
              child: CozyImage(KpAssets.iconKibble, width: 11, height: 11),
            ),
      enabled: !ownedForever,
      onTap: () => controller.purchase(item),
    );
  }
}
