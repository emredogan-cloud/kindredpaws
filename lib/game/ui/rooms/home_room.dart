/// The Home room — the cozy hearth of the core loop and the emotional hub of
/// the room-based home. The pet lives in an animated scene with the Care ring,
/// Bond, speech, and the three care verbs. Cozy and number-light (§5.5); all
/// feedback is warm, never guilt (Risk R6). Extracted from the former
/// single-screen `CompanionHomeScreen` when the home grew rooms.
library;

import 'package:flutter/material.dart';

import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../model/bond.dart';
import '../../sim/interaction.dart';
import '../care_ring.dart';
import '../mood_visuals.dart';
import '../widgets/cozy.dart';
import 'room_host.dart' show kRoomDockClearance;
import 'room_scaffold.dart' show DressedPet;

class HomeRoom extends StatelessWidget {
  const HomeRoom({required this.controller, required this.rig, super.key});

  final GameController controller;

  /// The pet renderer (resolved once by the shell — same rig in every room).
  final PetRenderer rig;

  /// The cozy scene for the current time of day.
  static String sceneFor(DateTime now) => (now.hour >= 7 && now.hour < 19)
      ? KpAssets.cozyRoomDay
      : KpAssets.cozyRoomNight;

  @override
  Widget build(BuildContext context) {
    final pet = controller.pet;
    if (pet == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return CozyBackground(
      asset: sceneFor(DateTime.now()),
      child: SafeArea(
        child: Column(
          children: [
            _bondBar(context, pet.bond),
            if (controller.streakRepairOffer != null)
              _RepairOfferChip(controller: controller),
            if (controller.petLine != null)
              CozySpeechBubble(text: controller.petLine!),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Clamp the ring so it can never overflow a squeezed Expanded
                  // on short screens (responsive fix).
                  final ringSize = constraints.maxHeight.isFinite
                      ? constraints.maxHeight.clamp(0.0, 232.0)
                      : 232.0;
                  return Align(
                    alignment: const Alignment(0, 0.35),
                    child: GestureDetector(
                      key: const Key('pet-tap'),
                      onTap: controller.nudgeAmbient,
                      child: CareRing(
                        meters: pet.meters,
                        size: ringSize,
                        child: DressedPet(controller: controller, rig: rig),
                      ),
                    ),
                  );
                },
              ),
            ),
            CozyChip(
              child: Text(
                moodLine(pet.name, controller.mood),
                key: const Key('mood-line'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (controller.lastMessage != null) ...[
              const SizedBox(height: 6),
              CozyChip(
                child: Text(
                  controller.lastMessage!,
                  key: const Key('feedback-message'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _verbBar(context),
            const SizedBox(height: kRoomDockClearance),
          ],
        ),
      ),
    );
  }

  Widget _bondBar(BuildContext context, Bond bond) {
    const stages = BondStage.values;
    final next = bond.stage.rank < stages.length - 1
        ? stages[bond.stage.rank + 1]
        : null;
    final from = bond.stage.threshold;
    final to = next?.threshold ?? bond.value;
    final progress = next == null
        ? 1.0
        : ((bond.value - from) / (to - from)).clamp(0.0, 1.0);
    final streak = controller.pet!.careStreak;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: CozyChip(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ExcludeSemantics(child: Text('💖 ')),
                Flexible(
                  child: Semantics(
                    label: 'Bond level: ${bond.stage.displayName}',
                    child: Text(
                      bond.stage.displayName,
                      key: const Key('bond-stage'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (next != null)
                  Flexible(
                    child: Text(
                      'next: ${next.displayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const Spacer(),
                if (streak.count > 0)
                  Semantics(
                    label:
                        'Care streak: ${streak.count} days'
                        '${streak.warmthBanked > 0 ? ', ${streak.warmthBanked} warmth saved' : ''}',
                    child: Text(
                      '🔥${streak.count}'
                      '${streak.warmthBanked > 0 ? ' ❄️${streak.warmthBanked}' : ''}',
                      key: const Key('streak-chip'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                key: const Key('bond-progress'),
                value: progress,
                minHeight: 8,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verbBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CozyImageButton(
          asset: KpAssets.btnFeed,
          label: 'Feed',
          tapKey: const Key('feed-button'),
          onTap: () => controller.interact(CareInteraction.feed),
        ),
        CozyImageButton(
          asset: KpAssets.btnClean,
          label: 'Clean',
          tapKey: const Key('clean-button'),
          onTap: () => controller.interact(CareInteraction.clean),
        ),
        CozyImageButton(
          asset: KpAssets.btnPlay,
          label: 'Play',
          tapKey: const Key('play-button'),
          onTap: () => controller.interact(CareInteraction.play),
        ),
      ],
    );
  }
}

/// The one-time Streak Repair invitation (§11.2): appears only right after a
/// streak breaks, reads as a welcome-back, and can be dismissed for free —
/// ignoring it never costs anything and the pet never minds.
class _RepairOfferChip extends StatelessWidget {
  const _RepairOfferChip({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final offer = controller.streakRepairOffer;
    if (offer == null) return const SizedBox.shrink();
    final cost = controller.config.streakRepairKibbleCost;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: CozyChip(
        child: Row(
          children: [
            Flexible(
              child: Text(
                'Your $offer-day streak can be rekindled 🔥',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              key: const Key('streak-repair'),
              onPressed: controller.repairStreak,
              child: Text(
                '$cost 🦴',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              key: const Key('streak-repair-dismiss'),
              tooltip: 'No thanks',
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () {
                controller.streakRepairOffer = null;
                controller.nudgeAmbient(); // a warm shrug — nothing lost
              },
            ),
          ],
        ),
      ),
    );
  }
}
