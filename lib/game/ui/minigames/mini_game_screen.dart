/// The mini-game stage: one warm shell for every Play Garden game — timer,
/// growing score, the game canvas, and an ending that is ALWAYS a
/// celebration (no-fail upstream by engine design — [MiniGameEngine]).
/// Leaving early is a friendly choice, not a forfeit: whatever joy was
/// scored still counts. GE-4 generalized the shell over the engine kit;
/// adding a game = an engine + a painter + a gesture line.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../controller/game_controller.dart';
import '../../minigames/mini_games.dart';
import '../widgets/cozy.dart';

/// Which game this screen hosts.
enum MiniGameKind {
  bounce('Bounce!'),
  snackCatch('Snack Catch'),
  bubbleDrift('Bubble Drift'),
  starlightTrail('Starlight Trail');

  const MiniGameKind(this.title);
  final String title;
}

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
  late final MiniGameEngine _engine;
  Duration _last = Duration.zero;
  bool _wrappedUp = false;

  @override
  void initState() {
    super.initState();
    _engine = switch (widget.kind) {
      MiniGameKind.bounce => BounceGame(sessionSeconds: widget.sessionSeconds),
      MiniGameKind.snackCatch => SnackCatchGame(
        sessionSeconds: widget.sessionSeconds,
      ),
      MiniGameKind.bubbleDrift => BubbleDriftGame(
        sessionSeconds: widget.sessionSeconds,
      ),
      MiniGameKind.starlightTrail => StarlightTrailGame(
        sessionSeconds: widget.sessionSeconds,
      ),
    };
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    if (_engine.finished) {
      _ticker.stop();
      unawaited(_wrapUp());
      return;
    }
    setState(() => _engine.tick(dt));
  }

  Future<void> _wrapUp() async {
    if (_wrappedUp) return;
    _wrappedUp = true;
    await widget.controller.finishMiniGame(
      gameId: widget.kind.name,
      score: _engine.score,
    );
    if (mounted) setState(() {});
  }

  /// The warm no-penalty aside for the celebration card.
  String? get _celebrationNote => switch (_engine) {
    SnackCatchGame(:final sharedWithBirds) when sharedWithBirds > 0 =>
      'and the garden birds enjoyed $sharedWithBirds 🐦',
    BubbleDriftGame(:final cloudBound) when cloudBound > 0 =>
      'and $cloudBound floated off to see the clouds ☁️',
    StarlightTrailGame(:final twinkledOn) when twinkledOn > 0 =>
      'and $twinkledOn twinkled on across the night ✨',
    _ => null,
  };

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeLeft = (widget.sessionSeconds - _engine.elapsed).clamp(
      0,
      widget.sessionSeconds,
    );
    final night = widget.kind == MiniGameKind.starlightTrail;
    return Scaffold(
      key: const Key('minigame-screen'),
      backgroundColor: night
          ? const Color(0xFF232A44)
          : const Color(0xFFEAF4E2),
      appBar: AppBar(
        title: Text(widget.kind.title),
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
                  label: 'Score: ${_engine.score}',
                  child: Text(
                    '💛 ${_engine.score}',
                    key: const Key('minigame-score'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: night ? Colors.white : null,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '⏳ ${timeLeft.ceil()}s',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: night ? Colors.white70 : null,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _engine.finished
                ? _Celebration(
                    score: _engine.score,
                    kibble: miniGameKibble(_engine.score),
                    note: _celebrationNote,
                    onDone: () => Navigator.of(context).pop(),
                  )
                : _GameCanvas(engine: _engine),
          ),
        ],
      ),
    );
  }
}

class _GameCanvas extends StatelessWidget {
  const _GameCanvas({required this.engine});

  final MiniGameEngine engine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return switch (engine) {
          final BounceGame b => GestureDetector(
            key: const Key('bounce-tap'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => b.boop(),
            child: CustomPaint(size: size, painter: _BouncePainter(b)),
          ),
          final SnackCatchGame c => GestureDetector(
            key: const Key('catch-drag'),
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) =>
                c.moveBasket(c.basketX + d.delta.dx / size.width),
            onTapDown: (d) => c.moveBasket(d.localPosition.dx / size.width),
            child: CustomPaint(size: size, painter: _CatchPainter(c)),
          ),
          final BubbleDriftGame p => GestureDetector(
            key: const Key('bubble-tap'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => p.popAt(
              d.localPosition.dx / size.width,
              d.localPosition.dy / size.height,
            ),
            child: CustomPaint(size: size, painter: _BubblePainter(p)),
          ),
          final StarlightTrailGame t => GestureDetector(
            key: const Key('trail-hold'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => t.setHolding(true),
            onTapUp: (_) => t.setHolding(false),
            onTapCancel: () => t.setHolding(false),
            onPanDown: (_) => t.setHolding(true),
            onPanEnd: (_) => t.setHolding(false),
            onPanCancel: () => t.setHolding(false),
            child: CustomPaint(size: size, painter: _TrailPainter(t)),
          ),
          _ => const SizedBox.shrink(),
        };
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

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.game);
  final BubbleDriftGame game;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in game.bubbles) {
      final c = Offset(b.x * size.width, b.y * size.height);
      final r = b.r * size.shortestSide;
      if (b.popped) {
        // A soft sparkle bloom where the bubble was.
        final t = (b.popAge / 0.45).clamp(0.0, 1.0);
        final paint = Paint()
          ..color = Color(
            DriftBubble.tints[b.hueIndex],
          ).withValues(alpha: (1 - t) * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(c, r * (1 + t * 1.6), paint);
        for (var i = 0; i < 5; i++) {
          final a = i * 1.2566 + t * 0.8;
          final sp =
              c +
              Offset(
                r * (1 + t * 2) * 0.9 * math.cos(a),
                r * (1 + t * 2) * 0.9 * math.sin(a),
              );
          canvas.drawCircle(sp, 2.2 * (1 - t), Paint()..color = Colors.white);
        }
        continue;
      }
      canvas.drawCircle(
        c,
        r,
        Paint()..color = Color(DriftBubble.tints[b.hueIndex]),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      canvas.drawCircle(
        c.translate(-r * 0.35, -r * 0.35),
        r * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => true;
}

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.game);
  final StarlightTrailGame game;

  @override
  void paint(Canvas canvas, Size size) {
    // A calm night meadow line.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.95, size.width, size.height * 0.05),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF2E3A55),
    );
    // Glimmers streaming by.
    for (final g in game.glimmers) {
      final c = Offset(g.x * size.width, g.y * size.height);
      if (g.collected) {
        final t = (g.collectAge / 0.4).clamp(0.0, 1.0);
        canvas.drawCircle(
          c,
          10 * (1 + t),
          Paint()..color = Color.fromRGBO(255, 235, 170, (1 - t) * 0.7),
        );
        continue;
      }
      final glow = Paint()
        ..color = const Color(0x66FFE9A8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(c, 9, glow);
      canvas.drawCircle(c, 3.4, Paint()..color = const Color(0xFFFFF2C8));
    }
    // The firefly friend (a little warm glow with wings).
    final f = Offset(
      StarlightTrailGame.fireflyX * size.width,
      game.fireflyY * size.height,
    );
    canvas.drawCircle(
      f,
      16,
      Paint()
        ..color = const Color(0x55FFE9A8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawOval(
      Rect.fromCenter(center: f, width: 16, height: 12),
      Paint()..color = const Color(0xFFF4C95D),
    );
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: f.translate(side * 7, -6), width: 9, height: 6),
        Paint()..color = Colors.white.withValues(alpha: 0.75),
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => true;
}

/// Every ending is a party: score, the Kibble thank-you, and a kind word
/// for whatever drifted, twinkled, or was shared. One button: "Yay!".
class _Celebration extends StatelessWidget {
  const _Celebration({
    required this.score,
    required this.kibble,
    required this.note,
    required this.onDone,
  });

  final int score;
  final int kibble;
  final String? note;
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
            if (note != null)
              Text(note!, style: const TextStyle(fontStyle: FontStyle.italic)),
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
