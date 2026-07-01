/// Shared building blocks for every room: the [RoomScaffold] layout (scene +
/// pet stage + room content), the living [PetStage] (the pet, its speech, and
/// warm feedback — identical simulation state in every room), cozy shelf
/// panels, and item cards. One vocabulary so the whole home feels like one
/// place (§0.1: scene is everything; the pet is the subject; warmth first).
library;

import 'package:flutter/material.dart';

import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../model/items.dart';
import '../mood_visuals.dart';
import '../widgets/cozy.dart';
import 'room_host.dart' show kRoomDockClearance;

/// A room's canvas: full-bleed scene, an optional warm tint that gives the
/// room its own light, the pet living mid-scene, and the room content below.
class RoomScaffold extends StatelessWidget {
  const RoomScaffold({
    required this.controller,
    required this.rig,
    required this.sceneAsset,
    required this.content,
    this.tint,
    this.petFooter,
    super.key,
  });

  final GameController controller;
  final PetRenderer rig;
  final String sceneAsset;

  /// Room-specific area under the pet (shelves, tub, bed…).
  final Widget content;

  /// Optional soft color wash that keys the room's mood (kept subtle).
  final Color? tint;

  /// Optional line pinned directly under the pet (e.g. sleep hint).
  final Widget? petFooter;

  @override
  Widget build(BuildContext context) {
    return CozyBackground(
      asset: sceneAsset,
      scrim: tint,
      child: SafeArea(
        child: Column(
          children: [
            PetStage(controller: controller, rig: rig),
            ?petFooter,
            Expanded(child: content),
            const SizedBox(height: kRoomDockClearance),
          ],
        ),
      ),
    );
  }
}

/// The pet, alive on the room's scene: speech bubble, tap-to-ambient, the
/// mood line, and the transient warm feedback chip. Reads the SAME controller
/// as every other room — walking between rooms never resets a thing.
class PetStage extends StatelessWidget {
  const PetStage({
    required this.controller,
    required this.rig,
    this.petScale = 1.0,
    super.key,
  });

  final GameController controller;
  final PetRenderer rig;
  final double petScale;

  @override
  Widget build(BuildContext context) {
    final pet = controller.pet;
    if (pet == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (controller.petLine != null)
          Padding(
            padding: const EdgeInsets.only(top: 52),
            child: CozySpeechBubble(text: controller.petLine!),
          )
        else
          const SizedBox(height: 64),
        GestureDetector(
          key: const Key('room-pet-tap'),
          onTap: controller.nudgeAmbient,
          child: Transform.scale(
            scale: petScale,
            child: rig.build(
              context,
              mood: petMoodFor(controller.mood),
              lifeStage: pet.lifeStage.id,
              emotion: currentPetEmotion(controller),
            ),
          ),
        ),
        if (controller.lastMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: CozyChip(
              child: Text(
                controller.lastMessage!,
                key: const Key('room-feedback'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A cozy titled panel — the room's "furniture" (pantry shelf, toy basket,
/// store shelves, closet rail). Cream, pillow-soft, never boxy.
class ShelfPanel extends StatelessWidget {
  const ShelfPanel({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE9A178).withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A3F38),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// One shelf good: sticker face, name, and a count/price chip. Disabled cards
/// stay visible but calm (never an error state, never pressure).
class ItemCard extends StatelessWidget {
  const ItemCard({
    required this.item,
    required this.onTap,
    this.badge,
    this.badgeIcon,
    this.enabled = true,
    this.cardKey,
    super.key,
  });

  final ItemDef item;
  final VoidCallback? onTap;

  /// Small trailing label (a pantry count, a Kibble price, a "worn" tag).
  final String? badge;
  final Widget? badgeIcon;
  final bool enabled;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${item.displayName}${badge == null ? '' : ' — $badge'}',
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Material(
          color: const Color(0xFFFFF6EC),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            key: cardKey,
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A3F38),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      // Scales down instead of overflowing on narrow cells.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ?badgeIcon,
                            Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The standard shelf grid for item cards.
class ShelfGrid extends StatelessWidget {
  const ShelfGrid({required this.children, this.columns = 4, super.key});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 0.78,
      children: children,
    );
  }
}
