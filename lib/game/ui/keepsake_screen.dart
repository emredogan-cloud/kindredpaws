/// The Keepsake scrapbook (GAMEPLAY_AND_PROGRESSION_BIBLE.md §14, P2-5). A
/// collectible, shareable gallery of the milestones + memories the player has
/// lived with their pet — the emotional payoff + the MVP viral surface ("the
/// endearing card IS the ambient ad", §8.6). Cards are composed locally; the
/// native share sheet is a documented fast-follow (REQUIRED_ENVIRONMENTS).
library;

import 'package:flutter/material.dart';

import '../../keepsake/keepsake.dart';
import '../../services/share_service.dart';
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
              children: [
                for (final k in cards)
                  _KeepsakeCard(
                    keepsake: k,
                    onShare: () => controller.shareKeepsake(k),
                  ),
              ],
            ),
    );
  }
}

class _KeepsakeCard extends StatelessWidget {
  const _KeepsakeCard({required this.keepsake, required this.onShare});

  final Keepsake keepsake;

  /// Shares the card (records the `keepsakeShare` virality event in the
  /// controller) and reports the outcome for the snackbar.
  final Future<ShareOutcome> Function() onShare;

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
                Text(
                  keepsake.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
                    icon: const Icon(Icons.ios_share),
                    tooltip: 'Share',
                    onPressed: () async {
                      // Capture the messenger before the await (no use of a
                      // stale BuildContext across the async gap).
                      final messenger = ScaffoldMessenger.of(context);
                      final outcome = await onShare();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            outcome.shared
                                ? 'Keepsake shared! 💛'
                                : 'Maybe next time. 💛',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
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
