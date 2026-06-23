/// The Keepsake scrapbook (GAMEPLAY_AND_PROGRESSION_BIBLE.md §14, P2-5). A
/// collectible, shareable gallery of the milestones + memories the player has
/// lived with their pet — the emotional payoff + the MVP viral surface ("the
/// endearing card IS the ambient ad", §8.6). Cards are composed locally; the
/// native share sheet is a documented fast-follow (REQUIRED_ENVIRONMENTS).
library;

import 'package:flutter/material.dart';

import '../../keepsake/keepsake.dart';
import '../controller/game_controller.dart';

class KeepsakeScreen extends StatelessWidget {
  const KeepsakeScreen({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final cards = controller.keepsakes;
    return Scaffold(
      key: const Key('keepsakes'),
      appBar: AppBar(title: const Text('Keepsakes')),
      body: cards.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Special moments with your pet will be saved here as '
                  'beautiful cards to keep and share. 💛',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [for (final k in cards) _KeepsakeCard(keepsake: k)],
            ),
    );
  }
}

class _KeepsakeCard extends StatelessWidget {
  const _KeepsakeCard({required this.keepsake});

  final Keepsake keepsake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      key: Key('keepsake-${keepsake.id}'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: scheme.secondaryContainer,
              alignment: Alignment.center,
              child: ExcludeSemantics(
                child: Text(
                  keepsake.kind.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(keepsake.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  keepsake.caption,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    key: Key('keepsake-share-${keepsake.id}'),
                    icon: const Icon(Icons.ios_share, size: 18),
                    tooltip: 'Share',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Keepsake ready to share! 💛'),
                        duration: Duration(seconds: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
