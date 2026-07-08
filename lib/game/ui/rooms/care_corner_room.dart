/// The Care Corner — gentle check-ups by the lamplit window. KindredPaws has
/// NO sickness, pain, or fear by design (the no-death floor; Health/Illness
/// was removed from canon as contradicting the cozy core): this room is where
/// care feels like being tucked under a blanket. The temperature check is
/// always reassuring, cuddles are the signature Comfort moment, and the
/// supply shelf (vitamin chew, soothing balm, warm broth) gives soft recovery
/// — meters only ever lift, nothing here can ever hurt.
library;

import 'package:flutter/material.dart';

import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../model/items.dart';
import '../../rooms/room_id.dart';
import '../widgets/cozy.dart';
import 'room_scaffold.dart';
import 'widgets/need_glow.dart';
import '../kp_tokens.dart';

class CareCornerRoom extends StatelessWidget {
  const CareCornerRoom({
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
    final supplies = ItemCatalog.ofKind(ItemKind.careSupply);

    return RoomScaffold(
      controller: controller,
      rig: rig,
      sceneAsset: KpAssets.rainyWindow,
      // The lamp's amber glow, a touch warmer than the rainy dusk outside.
      tint: const Color(0x1FFFC98A),
      content: ShelfPanel(
        title: 'Gentle care',
        trailing: NeedGlow(
          label: 'Comfy',
          value: pet.meters.lowest,
          icon: Icons.favorite_rounded,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The two wellness rituals — always available, always warm.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RitualButton(
                  key: const Key('care-temp-check'),
                  emoji: '🌡️',
                  label: 'Temp check',
                  onTap: controller.wellnessCheck,
                ),
                _RitualButton(
                  key: const Key('care-cuddle'),
                  emoji: '🤗',
                  label: 'Cuddle',
                  onTap: controller.comfortPet,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ShelfGrid(
                columns: 3,
                children: [
                  for (final supply in supplies)
                    ItemCard(
                      item: supply,
                      cardKey: Key('supply-${supply.id}'),
                      badge: '×${controller.inventory.supplyCount(supply.id)}',
                      enabled: controller.inventory.supplyCount(supply.id) > 0,
                      onTap: () => controller.useSupply(supply),
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('care-store-shortcut'),
                onPressed: () => goToRoom(RoomId.groceryStore),
                icon: const Icon(Icons.storefront_rounded, size: 18),
                label: const Text(
                  'Restock at the store',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft round ritual button (temperature check / cuddle).
class _RitualButton extends StatelessWidget {
  const _RitualButton({
    required this.emoji,
    required this.label,
    required this.onTap,
    super.key,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: KpColors.cream,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: KpText.caption,
                    fontWeight: FontWeight.w800,
                    color: KpColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
