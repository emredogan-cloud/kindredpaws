/// The Companion shell — the home screen of the core loop. The pet lives in a
/// cozy animated scene (premium UI integration), with the Care ring, mood, Bond,
/// Kibble, the three care verbs, a side-navigation drawer, and quick actions.
/// Cozy and number-light (§5.5); all feedback is warm, never guilt (Risk R6).
library;

import 'package:flutter/material.dart';

import '../../core/service_locator.dart';
import '../../monetization/paywall_controller.dart';
import '../../render/pet_renderer.dart';
import '../controller/game_controller.dart';
import '../model/bond.dart';
import '../sim/interaction.dart';
import 'care_ring.dart';
import 'keepsake_screen.dart';
import 'memory_book_screen.dart';
import 'mood_visuals.dart';
import 'paywall_sheet.dart';
import 'widgets/cozy.dart';

class CompanionHomeScreen extends StatelessWidget {
  const CompanionHomeScreen({
    required this.controller,
    this.renderer,
    super.key,
  });

  final GameController controller;

  /// The rig renderer; defaults to the one wired in `bootstrap()`.
  final PetRenderer? renderer;

  /// The cozy scene for the current time of day.
  static String _sceneFor(DateTime now) => (now.hour >= 7 && now.hour < 19)
      ? KpAssets.cozyRoomDay
      : KpAssets.cozyRoomNight;

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
          extendBodyBehindAppBar: true,
          drawer: _CozyDrawer(controller: controller),
          appBar: AppBar(
            title: Text(pet.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Semantics(
                    label: 'Kibble: ${pet.wallet.kibble}',
                    child: Row(
                      key: const Key('kibble-count'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CozyImage(
                          KpAssets.iconKibble,
                          width: 26,
                          height: 26,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${pet.wallet.kibble}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('keepsakes-button'),
                icon: const Icon(Icons.photo_album),
                tooltip: 'Keepsakes',
                onPressed: () =>
                    _open(context, KeepsakeScreen(controller: controller)),
              ),
              IconButton(
                key: const Key('memory-book-button'),
                icon: const Icon(Icons.menu_book),
                tooltip: 'The Memory Book',
                onPressed: () =>
                    _open(context, MemoryBookScreen(controller: controller)),
              ),
              IconButton(
                key: const Key('paywall-button'),
                icon: const Icon(Icons.favorite_border),
                tooltip: 'Forever Friends',
                onPressed: () => showPaywall(
                  context,
                  ServiceLocator.instance.get<PaywallController>(),
                ),
              ),
            ],
          ),
          body: CozyBackground(
            asset: _sceneFor(DateTime.now()),
            child: Stack(
              children: [
                // Soft top scrim so the app-bar title + icons stay legible over
                // any scene (esp. the dark night room) — visual QA fix.
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 160,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xCCFFF6EC), Color(0x00FFF6EC)],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _bondBar(context, pet.bond),
                      if (controller.petLine != null)
                        _SpeechBubble(text: controller.petLine!),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Clamp the ring so it can never overflow a squeezed
                            // Expanded on short screens (responsive fix).
                            // Never exceed the room the Expanded actually got
                            // (so the ring can't overflow a short screen).
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
                                  child: rig.build(
                                    context,
                                    mood: petMoodFor(controller.mood),
                                    lifeStage: pet.lifeStage.id,
                                    emotion: currentPetEmotion(controller),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      _CozyChip(
                        child: Text(
                          moodLine(pet.name, controller.mood),
                          key: const Key('mood-line'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (controller.lastMessage != null) ...[
                        const SizedBox(height: 6),
                        _CozyChip(
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
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _open(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

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
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: _CozyChip(
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
                  Text(
                    'next: ${next.displayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// A soft translucent cream chip — makes text legible over the busy cozy scene
/// without hiding it (premium readability).
class _CozyChip extends StatelessWidget {
  const _CozyChip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE9A178).withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// The pet's spoken line (Heartmind Companion Presence). Warm, never guilt; a
/// cozy cream bubble that reads clearly over the scene.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: _CozyChip(
        child: Container(
          key: const Key('pet-speech'),
          constraints: const BoxConstraints(minWidth: double.infinity),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

/// The side navigation (UX bible): wardrobe · keepsakes · memory book · shop ·
/// settings · profile. Existing screens route; not-yet-built screens give a
/// warm "coming soon" (honest — those screens are a future deliverable).
class _CozyDrawer extends StatelessWidget {
  const _CozyDrawer({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFFF6EC),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'KindredPaws',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            _item(
              context,
              KpAssets.iconWardrobe,
              'Wardrobe',
              'drawer-wardrobe',
              () => _soon(context, 'Wardrobe'),
            ),
            _item(
              context,
              KpAssets.iconKeepsakes,
              'Keepsakes',
              'drawer-keepsakes',
              () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => KeepsakeScreen(controller: controller),
                  ),
                );
              },
            ),
            _item(
              context,
              KpAssets.iconMemory,
              'Memory Book',
              'drawer-memory',
              () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MemoryBookScreen(controller: controller),
                  ),
                );
              },
            ),
            _item(context, KpAssets.iconShop, 'Shop', 'drawer-shop', () {
              Navigator.of(context).pop();
              showPaywall(
                context,
                ServiceLocator.instance.get<PaywallController>(),
                surface: 'shop',
              );
            }),
            _item(
              context,
              KpAssets.iconSettings,
              'Settings',
              'drawer-settings',
              () => _soon(context, 'Settings'),
            ),
            _item(
              context,
              KpAssets.iconBond,
              'Profile',
              'drawer-profile',
              () => _soon(context, 'Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String icon,
    String label,
    String key,
    VoidCallback onTap,
  ) {
    return ListTile(
      key: Key(key),
      leading: CozyImage(icon, width: 34, height: 34),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  void _soon(BuildContext context, String what) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$what is on its way — coming soon 🐾')),
      );
  }
}
