/// Closed-beta feedback UX (P4-7) — a warm, lightweight sheet for beta testers
/// to rate the experience (1–5) + leave an optional note. Submits via
/// [GameController.submitBetaFeedback] (PII-minimized: rating + a capped note,
/// no identifiers). Shown from a beta-only entry (gated on `AppConfig` beta), so
/// it never affects the default/golden UI.
library;

import 'package:flutter/material.dart';

import '../controller/game_controller.dart';

/// Shows the beta feedback sheet and submits the result (best-effort).
Future<void> showBetaFeedback(BuildContext context, GameController controller) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BetaFeedbackSheet(
      onSubmit: (rating, comment) =>
          controller.submitBetaFeedback(rating: rating, comment: comment),
    ),
  );
}

class BetaFeedbackSheet extends StatefulWidget {
  const BetaFeedbackSheet({required this.onSubmit, super.key});

  /// Called with the (rating, optional comment) when the tester submits.
  final void Function(int rating, String? comment) onSubmit;

  @override
  State<BetaFeedbackSheet> createState() => _BetaFeedbackSheetState();
}

class _BetaFeedbackSheetState extends State<BetaFeedbackSheet> {
  int _rating = 0;
  final TextEditingController _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const Key('beta-feedback-sheet'),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How is it going?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Your honest thoughts help us make KindredPaws cozier. 💛',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  key: Key('beta-star-$star'),
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('beta-comment'),
            controller: _comment,
            maxLength: 280,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Anything you loved, or anything we could improve?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('beta-submit'),
              // Submit is enabled once a rating is chosen.
              onPressed: _rating == 0
                  ? null
                  : () {
                      final text = _comment.text.trim();
                      widget.onSubmit(_rating, text.isEmpty ? null : text);
                      Navigator.of(context).maybePop();
                    },
              child: const Text('Send feedback'),
            ),
          ),
        ],
      ),
    );
  }
}
