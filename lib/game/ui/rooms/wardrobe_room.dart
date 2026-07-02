/// The Wardrobe — the dress-up corner. A live preview of the dressed pet
/// above a closet rail of owned looks (tap to wear / take off, one per slot)
/// and a small boutique of common cosmetics for Kibble. Forever Friends
/// keepsakes are premium *cosmetics only* — the pet's wellbeing never depends
/// on them, they are never sold for Kibble, and locked cards open the ethical
/// paywall instead of pressuring. Pure delight, zero gameplay power.
library;

import 'package:flutter/material.dart';

import '../../../core/service_locator.dart';
import '../../../monetization/monetization_controller.dart';
import '../../../monetization/paywall_controller.dart';
import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../model/items.dart';
import '../../rooms/room_id.dart';
import '../paywall_sheet.dart';
import '../widgets/cozy.dart';
import 'room_scaffold.dart';

class WardrobeRoom extends StatelessWidget {
  const WardrobeRoom({
    required this.controller,
    required this.rig,
    required this.goToRoom,
    super.key,
  });

  final GameController controller;
  final PetRenderer rig;
  final void Function(RoomId) goToRoom;

  bool get _entitled => ServiceLocator.instance
      .get<MonetizationController>()
      .entitlements
      .foreverFriends;

  @override
  Widget build(BuildContext context) {
    final pet = controller.pet;
    if (pet == null) return const SizedBox.shrink();
    final cosmetics = ItemCatalog.ofKind(ItemKind.cosmetic);
    final owned = cosmetics
        .where((i) => controller.inventory.ownsCosmetic(i.id))
        .toList(growable: false);
    final boutique = cosmetics
        .where((i) => !controller.inventory.ownsCosmetic(i.id))
        .toList(growable: false);

    return RoomScaffold(
      controller: controller,
      rig: rig,
      sceneAsset: KpAssets.cozyRoomDay,
      // A soft boutique-lavender morning light.
      tint: const Color(0x1FB9A7D9),
      content: ShelfPanel(
        title: 'Closet',
        child: ListView(
          key: const Key('wardrobe-list'),
          padding: EdgeInsets.zero,
          children: [
            if (owned.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'The rail is waiting for its first look ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            else
              ShelfGrid(
                children: [
                  for (final item in owned)
                    ItemCard(
                      item: item,
                      cardKey: Key('closet-${item.id}'),
                      badge: controller.inventory.isEquipped(item.id)
                          ? 'wearing 💛'
                          : null,
                      onTap: () => controller.inventory.isEquipped(item.id)
                          ? controller.unequipCosmetic(item)
                          : controller.equipCosmetic(item, entitled: _entitled),
                    ),
                ],
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 8, 2, 6),
              child: Text(
                'Boutique',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7A6A58),
                ),
              ),
            ),
            ShelfGrid(
              children: [
                for (final item in boutique) _boutiqueCard(context, item),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _boutiqueCard(BuildContext context, ItemDef item) {
    if (item.premium) {
      final entitled = _entitled;
      return ItemCard(
        item: item,
        cardKey: Key('boutique-${item.id}'),
        badge: entitled ? 'gift 💛' : 'Forever Friends',
        onTap: () async {
          if (entitled) {
            await controller.equipCosmetic(item, entitled: true);
          } else {
            // The ethical paywall — an invitation, never a pressure gate.
            await showPaywall(
              context,
              ServiceLocator.instance.get<PaywallController>(),
              surface: 'wardrobe',
            );
          }
        },
      );
    }
    return ItemCard(
      item: item,
      cardKey: Key('boutique-${item.id}'),
      badge: '${item.kibblePrice}',
      badgeIcon: const Padding(
        padding: EdgeInsets.only(right: 2),
        child: CozyImage(KpAssets.iconKibble, width: 11, height: 11),
      ),
      onTap: () => controller.purchase(item),
    );
  }
}
