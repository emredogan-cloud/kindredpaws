/// Save-recovery screen (KP-010). Shown instead of Rescue Day whenever a save
/// EXISTS but cannot be read, so a recoverable pet is never silently replaced.
/// Tone: calm and reassuring — the player may be worried about their friend.
library;

import 'package:flutter/material.dart';

import '../controller/game_controller.dart';

class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({required this.controller, super.key});

  final GameController controller;

  bool get _appTooOld => controller.recovery == RecoveryKind.appTooOld;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('save-recovery'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🏠',
                    style: TextStyle(fontSize: 56),
                    semanticsLabel: '',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _appTooOld ? 'Your home is waiting' : 'Your friend is safe',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _appTooOld
                        ? 'This home was made with a newer version of '
                              'KindredPaws. Update the app and everything '
                              'will be right where you left it.'
                        : 'We kept everything tucked away safely, but we '
                              'need a moment to read it. Trying again '
                              'usually helps.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    key: const Key('recovery-retry'),
                    onPressed: controller.retryLoad,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: Text('Try again'),
                    ),
                  ),
                  if (!_appTooOld) ...[
                    const SizedBox(height: 40),
                    TextButton(
                      key: const Key('recovery-fresh-start'),
                      onPressed: () => _confirmFreshStart(context),
                      child: Text(
                        'Start over with a new friend',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
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

  Future<void> _confirmFreshStart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('recovery-fresh-start-confirm'),
        title: const Text('Start over?'),
        content: const Text(
          'A safety copy of your old home is kept on this device, but a new '
          'friend will live here from now on. This cannot be undone from '
          'inside the app.',
        ),
        actions: [
          TextButton(
            key: const Key('recovery-fresh-start-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep waiting'),
          ),
          FilledButton(
            key: const Key('recovery-fresh-start-yes'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start over'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) controller.beginFreshStart();
  }
}
