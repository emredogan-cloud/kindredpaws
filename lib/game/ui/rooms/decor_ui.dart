/// Cozy Corners UI (GE-3): the in-scene décor layer and the two-tap
/// decorate sheet. Décor is pure expression — placing is instant, removing
/// never loses the piece, and empty spots invite warmly (never nag).
library;

import 'package:flutter/material.dart';

import '../../controller/game_controller.dart';
import '../../model/decor.dart';
import '../../model/items.dart';
import '../../rooms/room_id.dart';

/// Placed décor stickers composed into the room scene (decorative layer —
/// pointer-transparent; the sheet carries the accessible interaction).
class DecorLayer extends StatelessWidget {
  const DecorLayer({required this.controller, required this.room, super.key});

  final GameController controller;
  final RoomId room;

  @override
  Widget build(BuildContext context) {
    final placed = <(DecorSlot, ItemDef)>[];
    for (final slot in DecorSlots.forRoom(room)) {
      final id = controller.inventory.placedIn(slot.id);
      if (id == null) continue;
      final item = ItemCatalog.byId(id);
      if (item != null) placed.add((slot, item));
    }
    if (placed.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final (slot, item) in placed)
              Align(
                alignment: slot.alignment,
                child: SizedBox(
                  key: Key('decor-placed-${slot.id}'),
                  width: slot.width,
                  height: slot.width,
                  child: Image.asset(
                    item.artPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        item.emoji,
                        style: TextStyle(fontSize: slot.width * 0.55),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The little "decorate" invitation, pinned to a room corner.
class DecorateButton extends StatelessWidget {
  const DecorateButton({
    required this.controller,
    required this.room,
    super.key,
  });

  final GameController controller;
  final RoomId room;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Decorate the ${room.displayName}',
      child: Material(
        color: const Color(0xFFFFFBF5).withValues(alpha: 0.85),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          key: Key('decorate-button-${room.id}'),
          customBorder: const CircleBorder(),
          onTap: () => showDecorateSheet(context, controller, room),
          child: const Padding(
            padding: EdgeInsets.all(9),
            child: Text('🛋️', style: TextStyle(fontSize: 17)),
          ),
        ),
      ),
    );
  }
}

void showDecorateSheet(
  BuildContext context,
  GameController controller,
  RoomId room,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFFFFFBF5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final slots = DecorSlots.forRoom(room);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Decorate · ${room.displayName} 🛋️',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a spot, pick a piece — swap any time, nothing is '
                  'ever lost.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                for (final slot in slots) ...[
                  _SlotRow(controller: controller, slot: slot),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.controller, required this.slot});

  final GameController controller;
  final DecorSlot slot;

  @override
  Widget build(BuildContext context) {
    final inv = controller.inventory;
    final placedId = inv.placedIn(slot.id);
    final choices = ItemCatalog.ofKind(ItemKind.decor)
        .where((i) => i.decorSlotId == slot.id && inv.ownsDecor(i.id))
        .toList(growable: false);

    return Container(
      key: Key('decor-slot-${slot.id}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE9A178).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'On ${slot.label}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 6),
          if (choices.isEmpty)
            Text(
              'Pieces for this spot live at the Grocery 🧺',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in choices)
                  ChoiceChip(
                    key: Key('decor-choice-${slot.id}-${item.id}'),
                    label: Text('${item.emoji} ${item.displayName}'),
                    selected: placedId == item.id,
                    onSelected: (_) => controller.placeDecor(slot, item),
                  ),
                if (placedId != null)
                  ActionChip(
                    key: Key('decor-clear-${slot.id}'),
                    label: const Text('back to the box'),
                    onPressed: () => controller.clearDecor(slot),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
