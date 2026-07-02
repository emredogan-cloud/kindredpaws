/// The mini-game stage: one warm shell for every Play Garden game — timer
/// ring, growing score hearts, the game canvas, and an ending that is ALWAYS
/// a celebration (no-fail upstream by engine design). Leaving early is a
/// friendly choice, not a forfeit: whatever joy was scored still counts.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../controller/game_controller.dart';
import '../../minigames/mini_games.dart';
import '../widgets/cozy.dart';

/// Which game this screen hosts.
enum MiniGameKind { bounce, snackCatch }

class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({
    required this.controller,
    required this.kind,
    this.sessionSeconds = 45,
    super.key,
  });

  final GameController controller;
  final MiniGameKind kind;
  final double sessionSeconds;

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  BounceGame? _bounce;
  SnackCatchGame? _catch;
  bool _wrappedUp = false;

  int get _score => _bounce?.bounces ?? _catch?.caught ?? 0;
  bool get _finished => (_bounce?.finished ?? _catch?.finished) == true;
  double get _elapsed => _bounce?.elapsed ?? _catch?.elapsed ?? 0;

  @override
  void initState() {
    super.initState();
    switch (widget.kind) {
      case MiniGameKind.bounce:
        _bounce = BounceGame(sessionSeconds: widget.sessionSeconds);
      case MiniGameKind.snackCatch:
        _catch = SnackCatchGame(sessionSeconds: widget.sessionSeconds);
    }
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    if (_finished) {
      _ticker.stop();
      unawaited(_wrapUp());
      return;
    }
    setState(() {
      _bounce?.tick(dt);
      _catch?.tick(dt);
    });
  }

  Future<void> _wrapUp() async {
    if (_wrappedUp) return;
    _wrappedUp = true;
    await widget.controller.finishMiniGame(
      gameId: widget.kind.name,
      score: _score,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeLeft = (widget.sessionSeconds - _elapsed).clamp(
      0,
      widget.sessionSeconds,
    );
    return Scaffold(
      key: const Key('minigame-screen'),
      backgroundColor: const Color(0xFFEAF4E2),
      appBar: AppBar(
        title: Text(
          widget.kind == MiniGameKind.bounce ? 'Bounce!' : 'Snack Catch',
        ),
        leading: IconButton(
          key: const Key('minigame-leave'),
          tooltip: 'Done playing',
          icon: const Icon(Icons.check_rounded),
          onPressed: () async {
            _ticker.stop();
            await _wrapUp();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Semantics(
                  label: 'Score: $_score',
                  child: Text(
                    '💛 $_score',
                    key: const Key('minigame-score'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '⏳ ${timeLeft.ceil()}s',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: _finished
                ? _Celebration(
                    score: _score,
                    kibble: miniGameKibble(_score),
                    shared: _catch?.sharedWithBirds ?? 0,
                    onDone: () => Navigator.of(context).pop(),
                  )
                : _GameCanvas(bounce: _bounce, snackCatch: _catch),
          ),
        ],
      ),
    );
  }
}

class _GameCanvas extends StatelessWidget {
  const _GameCanvas({this.bounce, this.snackCatch});

  final BounceGame? bounce;
  final SnackCatchGame? snackCatch;

  @override
  Widget build(BuildContext context) {
    final b = bounce;
    final c = snackCatch;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (b != null) {
          return GestureDetector(
            key: const Key('bounce-tap'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => b.boop(),
            child: CustomPaint(size: size, painter: _BouncePainter(b)),
          );
        }
        final catcher = c!;
        return GestureDetector(
          key: const Key('catch-drag'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) =>
              catcher.moveBasket(catcher.basketX + d.delta.dx / size.width),
          onTapDown: (d) => catcher.moveBasket(d.localPosition.dx / size.width),
          child: CustomPaint(size: size, painter: _CatchPainter(catcher)),
        );
      },
    );
  }
}

class _BouncePainter extends CustomPainter {
  _BouncePainter(this.game);
  final BounceGame game;

  @override
  void paint(Canvas canvas, Size size) {
    // Cushion.
    final cushion = Paint()..color = const Color(0xFFF2D8B8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.94, size.width, size.height * 0.06),
        const Radius.circular(12),
      ),
      cushion,
    );
    // The ball — a warm sun-yellow boop-able friend.
    final center = Offset(game.ballX * size.width, game.ballY * size.height);
    final r = size.shortestSide * 0.055;
    canvas.drawCircle(
      center.translate(0, r * 0.35),
      r * 0.9,
      Paint()..color = const Color(0x22000000),
    );
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFF4C95D));
    canvas.drawCircle(
      center.translate(-r * 0.3, -r * 0.3),
      r * 0.28,
      Paint()..color = const Color(0xAAFFFFFF),
    );
    if (game.resting) {
      final tp = TextPainter(
        text: const TextSpan(text: '💤', style: TextStyle(fontSize: 18)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center.translate(r * 0.6, -r * 1.8));
    }
  }

  @override
  bool shouldRepaint(_BouncePainter old) => true;
}

class _CatchPainter extends CustomPainter {
  _CatchPainter(this.game);
  final SnackCatchGame game;

  @override
  void paint(Canvas canvas, Size size) {
    // Falling snacks (emoji faces — same sticker language as the shelves).
    for (final snack in game.snacks) {
      final tp = TextPainter(
        text: TextSpan(text: snack.face, style: const TextStyle(fontSize: 30)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(snack.x * size.width - tp.width / 2, snack.y * size.height),
      );
    }
    // The basket.
    final bx = game.basketX * size.width;
    final by = size.height * 0.9;
    final basket = Paint()..color = const Color(0xFFB98A5A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(bx, by),
          width: size.width * 0.22,
          height: 26,
        ),
        const Radius.circular(10),
      ),
      basket,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(bx, by - 10),
          width: size.width * 0.24,
          height: 8,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF8A6543),
    );
  }

  @override
  bool shouldRepaint(_CatchPainter old) => true;
}

/// Every ending is a party: score, the Kibble thank-you, and (for Snack
/// Catch) a kind word for the garden birds. One button: "Yay!".
class _Celebration extends StatelessWidget {
  const _Celebration({
    required this.score,
    required this.kibble,
    required this.shared,
    required this.onDone,
  });

  final int score;
  final int kibble;
  final int shared;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CozyChip(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            Text(
              'What a game! 💛 $score',
              key: const Key('minigame-final-score'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            if (kibble > 0)
              Text(
                '+$kibble Kibble 🦴',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            if (shared > 0)
              Text(
                'and the garden birds enjoyed $shared 🐦',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 10),
            FilledButton(
              key: const Key('minigame-done'),
              onPressed: onDone,
              child: const Text('Yay!'),
            ),
          ],
        ),
      ),
    );
  }
}
