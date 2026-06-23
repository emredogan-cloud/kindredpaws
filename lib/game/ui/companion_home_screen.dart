/// The Companion shell — the home screen of the core loop. Shows the pet (rig
/// seam) in its Nest, the Care ring, mood, the Bond, Kibble, the three care
/// verbs, and the Memory Book entry point. Cozy and number-light (§5.5); all
/// feedback is warm, never guilt (Risk R6).
library;

import 'package:flutter/material.dart';

import '../../core/service_locator.dart';
import '../../render/pet_renderer.dart';
import '../controller/game_controller.dart';
import '../model/bond.dart';
import '../sim/interaction.dart';
import 'care_ring.dart';
import 'memory_book_screen.dart';
import 'mood_visuals.dart';

class CompanionHomeScreen extends StatelessWidget {
  const CompanionHomeScreen({
    required this.controller,
    this.renderer,
    super.key,
  });

  final GameController controller;

  /// The rig renderer; defaults to the one wired in `bootstrap()`.
  final PetRenderer? renderer;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pet = controller.pet;
        if (pet == null) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final rig = renderer ?? ServiceLocator.instance.get<PetRenderer>();

        return Scaffold(
          key: const Key('companion-home'),
          appBar: AppBar(
            title: Text(pet.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: scheme.surface,
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Semantics(
                    label: 'Kibble: ${pet.wallet.kibble}',
                    child: Row(
                      key: const Key('kibble-count'),
                      children: [
                        const Text('🦴 '),
                        Text(
                          '${pet.wallet.kibble}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('memory-book-button'),
                icon: const Icon(Icons.menu_book),
                tooltip: 'The Memory Book',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MemoryBookScreen(controller: controller),
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [scheme.surfaceContainerHighest, scheme.surface],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _bondBar(context, pet.bond),
                  Expanded(
                    child: Center(
                      child: CareRing(
                        meters: pet.meters,
                        size: 240,
                        child: rig.build(
                          context,
                          mood: petMoodFor(controller.mood),
                          lifeStage: pet.lifeStage.id,
                          emotion: currentPetEmotion(controller),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      moodLine(pet.name, controller.mood),
                      key: const Key('mood-line'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (controller.lastMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Text(
                        controller.lastMessage!,
                        key: const Key('feedback-message'),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.primary),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _verbBar(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ExcludeSemantics(child: Text('💖 ')),
              Semantics(
                label: 'Bond level: ${bond.stage.displayName}',
                child: Text(
                  bond.stage.displayName,
                  key: const Key('bond-stage'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Spacer(),
              if (next != null)
                Text(
                  'next: ${next.displayName}',
                  style: Theme.of(context).textTheme.bodySmall,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _verbBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _verbButton(
          context,
          'feed-button',
          Icons.restaurant,
          'Feed',
          CareInteraction.feed,
        ),
        _verbButton(
          context,
          'clean-button',
          Icons.water_drop,
          'Clean',
          CareInteraction.clean,
        ),
        _verbButton(
          context,
          'play-button',
          Icons.sports_baseball,
          'Play',
          CareInteraction.play,
        ),
      ],
    );
  }

  Widget _verbButton(
    BuildContext context,
    String key,
    IconData icon,
    String label,
    CareInteraction interaction,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: label,
          child: FilledButton.tonal(
            key: Key(key),
            onPressed: () => controller.interact(interaction),
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(20),
            ),
            child: Semantics(
              label: label,
              button: true,
              child: Icon(icon, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
