/// The Play Garden — toys & giggles in the sunny garden. Every owned toy is a
/// mini play interaction through the canonical play verb; sharing more play
/// with a toy deepens its affection badge (pure delight progression — hearts,
/// never numbers, never Bond). A tired pet is met with a warm bedtime hint
/// instead of a locked door, and new toys are an invitation to the store.
library;

import 'package:flutter/material.dart';

import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../model/care_meters.dart';
import '../../model/items.dart';
import '../../rooms/room_id.dart';
import '../../sim/ambient_presence.dart';
import '../minigames/mini_game_screen.dart';
import '../widgets/ambient_scene.dart';
import '../widgets/cozy.dart';
import 'room_scaffold.dart';
import 'widgets/need_glow.dart';

class PlayRoom extends StatelessWidget {
  const PlayRoom({
    required this.controller,
    required this.rig,
    required this.goToRoom,
    super.key,
  });

  final GameController controller;
  final PetRenderer rig;
  final void Function(RoomId) goToRoom;

  /// The affection badge for a toy (§: delight, not power — hearts only).
  static String? affectionBadge(int plays) {
    if (plays >= 40) return 'best friend 💖';
    if (plays >= 15) return 'favourite ⭐';
    if (plays >= 5) return 'loved 💕';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pet = controller.pet;
    if (pet == null) return const SizedBox.shrink();
    final owned = ItemCatalog.ofKind(
      ItemKind.toy,
    ).where((t) => controller.inventory.ownsToy(t.id)).toList(growable: false);
    final tired =
        pet.meters.energy <= controller.config.playEnergyCost + 5 &&
        !controller.isSleeping;

    return RoomScaffold(
      controller: controller,
      rig: rig,
      sceneAsset: KpAssets.gardenDay,
      // Butterflies always drift here; the songbird visits a happy,
      // played-in garden (ambient presence — a reflection, never a chore).
      ambient: AmbientScene(
        variant: AmbientVariant.gardenButterflies,
        visitor: gardenVisitorVisible(
          happiness: pet.meters.happiness,
          playsThisSession: controller.session.play,
        ),
      ),
      decorRoom: RoomId.playRoom,
      petFooter: tired
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: CozyChip(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '${pet.name} is getting sleepy — a nap would '
                        'feel lovely',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      key: const Key('play-bedtime-hint'),
                      onPressed: () => goToRoom(RoomId.bedroom),
                      child: const Text(
                        'Bedroom 🌙',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      content: ShelfPanel(
        title: 'Toy basket',
        trailing: NeedGlow(
          label: 'Energy',
          value: pet.meters.of(CareNeed.energy),
          icon: Icons.bolt_rounded,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Garden games — tiny, warm, no-fail (E4).
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _GameCard(
                  key: const Key('minigame-bounce'),
                  emoji: '🎈',
                  label: 'Bounce!',
                  onTap: () => _openGame(context, MiniGameKind.bounce),
                ),
                _GameCard(
                  key: const Key('minigame-catch'),
                  emoji: '🧺',
                  label: 'Snack Catch',
                  onTap: () => _openGame(context, MiniGameKind.snackCatch),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ShelfGrid(
                children: [
                  for (final toy in owned)
                    ItemCard(
                      item: toy,
                      cardKey: Key('toy-${toy.id}'),
                      badge: affectionBadge(
                        controller.inventory.affinity(toy.id),
                      ),
                      onTap: () => controller.playWith(toy),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('play-store-shortcut'),
                onPressed: () => goToRoom(RoomId.groceryStore),
                icon: const Icon(Icons.storefront_rounded, size: 18),
                label: const Text(
                  'New toys at the store',
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

extension on PlayRoom {
  void _openGame(BuildContext context, MiniGameKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MiniGameScreen(controller: controller, kind: kind),
      ),
    );
  }
}

/// A little garden-game invitation card.
class _GameCard extends StatelessWidget {
  const _GameCard({
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
        color: const Color(0xFFFFF6EC),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4A3F38),
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
