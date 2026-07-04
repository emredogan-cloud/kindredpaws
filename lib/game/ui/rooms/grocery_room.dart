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
      // Cozy Corners homeware (GE-3): long-press a piece to wish for it.
      ('Homeware · long-press to wish 💫', ItemCatalog.ofKind(ItemKind.decor)),
    ];
    final wished = controller.inventory.wishlistId == null
        ? null
        : ItemCatalog.byId(controller.inventory.wishlistId!);

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
          key: const Key('grocery-list'),
          padding: EdgeInsets.zero,
          children: [
            if (wished != null)
              _WishJar(
                controller: controller,
                item: wished,
                balance: pet.wallet.kibble,
              ),
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
                nested: true, // inside the multi-section shop ListView
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
      ItemKind.decor => controller.inventory.ownsDecor(item.id),
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
      // The saving jar (GE-3): one wished-for piece, pure intent, never a nag.
      onLongPress: item.kind == ItemKind.decor && !ownedForever
          ? () => controller.setWishlist(item)
          : null,
    );
  }
}

/// The child-legible saving goal: how the Kibble on hand measures up to the
/// one wished-for piece. Appears only here on the shelf — no notifications,
/// no badges, no countdowns (Charter: saving made visible, never pressured).
class _WishJar extends StatelessWidget {
  const _WishJar({
    required this.controller,
    required this.item,
    required this.balance,
  });

  final GameController controller;
  final ItemDef item;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final progress = (balance / item.kibblePrice).clamp(0.0, 1.0);
    final ready = balance >= item.kibblePrice;
    return Container(
      key: const Key('wish-jar'),
      margin: const EdgeInsets.fromLTRB(2, 4, 2, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE9A178).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  label:
                      'Wish jar: saving for the ${item.displayName}, '
                      '$balance of ${item.kibblePrice} Kibble',
                  child: Text(
                    ready
                        ? 'The ${item.displayName} is within reach! 💛'
                        : 'Saving for the ${item.displayName} · '
                              '$balance/${item.kibblePrice}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('wish-jar-clear'),
                tooltip: 'Let this wish go',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: () => controller.setWishlist(null),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              key: const Key('wish-jar-progress'),
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE9A178).withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
