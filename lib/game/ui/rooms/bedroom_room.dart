/// The Bedroom — sleepy snuggles under the fairy lights. Tucking the pet in
/// starts a real, persisted nap (it keeps sleeping across app restarts and
/// wakes with the whole nap's energy credited, §5.1 rest +20/h). While it
/// sleeps the room dims to a starlit hush and the pet dreams of things it
/// actually remembers (the Memory Book), and a gentle wake brings a warm
/// morning greeting. Never a lockout: waking is always one tap away.
library;

import 'package:flutter/material.dart';

import '../../../heartmind/memory_fact.dart';
import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../model/care_meters.dart';
import '../../rooms/room_id.dart';
import '../widgets/ambient_scene.dart';
import '../widgets/cozy.dart';
import 'room_scaffold.dart';
import 'widgets/need_glow.dart';

class BedroomRoom extends StatelessWidget {
  const BedroomRoom({
    required this.controller,
    required this.rig,
    required this.goToRoom,
    super.key,
  });

  final GameController controller;
  final PetRenderer rig;
  final void Function(RoomId) goToRoom;

  /// What the pet dreams about — a real remembered thing (Memory Book),
  /// falling back to tomorrow's adventures.
  static String dreamLine(List<MemoryFact> facts) {
    for (final fact in facts) {
      if (fact.key == FactKey.likesActivity) {
        return 'dreaming of ${fact.value} 💭';
      }
    }
    return 'dreaming of tomorrow\'s adventures 💭';
  }

  @override
  Widget build(BuildContext context) {
    final pet = controller.pet;
    if (pet == null) return const SizedBox.shrink();
    final sleeping = controller.isSleeping;

    return Stack(
      fit: StackFit.expand,
      children: [
        RoomScaffold(
          controller: controller,
          rig: rig,
          sceneAsset: KpAssets.bedroomScene,
          ambient: const AmbientScene(variant: AmbientVariant.bedroomStars),
          decorRoom: RoomId.bedroom,
          // Deep starlit hush while sleeping; soft dusk otherwise.
          tint: sleeping ? const Color(0x59283B5C) : const Color(0x26283B5C),
          petFooter: sleeping
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CozyChip(
                    child: Text(
                      dreamLine(controller.facts),
                      key: const Key('dream-bubble'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              : null,
          content: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CozyChip(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        sleeping
                            ? '${pet.name} is fast asleep 💤'
                            : 'The bed is turned down and cozy',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeedGlow(
                      label: 'Energy',
                      value: pet.meters.of(CareNeed.energy),
                      icon: Icons.bolt_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (sleeping)
                _BigSoftButton(
                  key: const Key('bedroom-wake'),
                  emoji: '☀️',
                  label: 'Wake up gently',
                  onTap: controller.wakeUp,
                )
              else
                _BigSoftButton(
                  key: const Key('bedroom-tuck-in'),
                  emoji: '🌙',
                  label: 'Tuck in',
                  onTap: controller.tuckIn,
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        // A sprinkle of stars while the pet sleeps (deterministic layout).
        if (sleeping)
          IgnorePointer(
            child: CustomPaint(painter: _StarsPainter(), size: Size.infinite),
          ),
      ],
    );
  }
}

class _BigSoftButton extends StatelessWidget {
  const _BigSoftButton({
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
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: const Color(0xFFFFFBF5).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        elevation: 3,
        shadowColor: const Color(0x66283B5C),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: scheme.primary,
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

/// A calm, fixed constellation over the sleeping room (index-hashed layout —
/// no Random, no animation controllers: settle-safe and replay-stable).
class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xCCFFE9A8);
    for (var i = 0; i < 26; i++) {
      var h = i * 2654435761;
      h ^= h >> 13;
      h *= 0x5bd1e995;
      h ^= h >> 15;
      final dx = size.width * ((h & 0xFF) / 255.0);
      final dy = size.height * 0.42 * (((h >> 8) & 0xFF) / 255.0);
      final r = 0.8 + 1.6 * (((h >> 16) & 0xFF) / 255.0);
      canvas.drawCircle(Offset(dx, dy), r, paint);
      if (i % 5 == 0) {
        final sparkle = Paint()
          ..color = const Color(0x88FFE9A8)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(dx - r * 2.4, dy),
          Offset(dx + r * 2.4, dy),
          sparkle,
        );
        canvas.drawLine(
          Offset(dx, dy - r * 2.4),
          Offset(dx, dy + r * 2.4),
          sparkle,
        );
      }
    }
    // A soft crescent moon.
    final moon = Offset(size.width * 0.82, size.height * 0.12);
    canvas.drawCircle(moon, 16, Paint()..color = const Color(0xEEFFF3C4));
    canvas.drawCircle(
      moon.translate(6, -3),
      13,
      Paint()..color = const Color(0xFF3A4A66).withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}
