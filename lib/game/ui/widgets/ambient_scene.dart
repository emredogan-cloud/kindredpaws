/// Ambient room life (GE-2): a whisper-quiet decorative layer — kitchen
/// steam, bedroom stars, garden butterflies, home dust motes, and the
/// occasional garden songbird. Purely presentational (IgnorePointer,
/// semantics-silent), budgeted (≤ 12 shapes/room), deterministic (no
/// Random — everything derives from the loop phase), and test-safe:
/// [motionEnabled] is OFF by default so `pumpAndSettle` always settles;
/// `main()` switches it on for the real app, and the system reduced-motion
/// setting always wins (a calm static frame).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AmbientVariant { homeMotes, kitchenSteam, bedroomStars, gardenButterflies }

class AmbientScene extends StatefulWidget {
  const AmbientScene({required this.variant, this.visitor = false, super.key});

  final AmbientVariant variant;

  /// The garden songbird — visits while the garden is happy and played-in
  /// (an ambient companion moment, never a chore or a meter).
  final bool visitor;

  /// Master motion switch. OFF by default (deterministic tests/CI); the app
  /// enables it once in `main()`. Reduced-motion overrides it regardless.
  static bool motionEnabled = false;

  @override
  State<AmbientScene> createState() => _AmbientSceneState();
}

class _AmbientSceneState extends State<AmbientScene>
    with SingleTickerProviderStateMixin {
  AnimationController? _loop;

  bool get _shouldAnimate =>
      AmbientScene.motionEnabled &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shouldAnimate && _loop == null) {
      _loop = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 7),
      )..repeat();
    } else if (!_shouldAnimate && _loop != null) {
      _loop!.dispose();
      _loop = null;
    }
  }

  @override
  void dispose() {
    _loop?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loop = _loop;
    Widget paint(double t) => CustomPaint(
      size: Size.infinite,
      painter: _AmbientPainter(
        variant: widget.variant,
        visitor: widget.visitor,
        t: t,
      ),
    );
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: loop == null
              // A gentle still frame (tests, reduced-motion) — mid-phase so
              // the scene still looks inhabited, just calm.
              ? paint(0.35)
              : AnimatedBuilder(
                  animation: loop,
                  builder: (context, _) => paint(loop.value),
                ),
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.variant,
    required this.visitor,
    required this.t,
  });

  final AmbientVariant variant;
  final bool visitor;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    switch (variant) {
      case AmbientVariant.homeMotes:
        _motes(canvas, size);
      case AmbientVariant.kitchenSteam:
        _steam(canvas, size);
      case AmbientVariant.bedroomStars:
        _stars(canvas, size);
      case AmbientVariant.gardenButterflies:
        _butterflies(canvas, size);
    }
    if (visitor) _songbird(canvas, size);
  }

  /// Six warm dust motes drifting slowly upward through the hearth light.
  void _motes(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x1AFFE1B0);
    for (var i = 0; i < 6; i++) {
      final phase = (t + i * 0.17) % 1.0;
      final x =
          size.width * (0.14 + 0.13 * i) +
          6 * math.sin(2 * math.pi * (t + i * 0.31));
      final y = size.height * (0.85 - 0.6 * phase);
      canvas.drawCircle(Offset(x, y), 2.2 + (i % 3) * 0.8, paint);
    }
  }

  /// Three soft steam wisps rising over the stove corner.
  void _steam(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x21FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (var i = 0; i < 3; i++) {
      final phase = (t + i * 0.33) % 1.0;
      final baseX = size.width * (0.68 + 0.09 * i);
      final y = size.height * (0.42 - 0.22 * phase);
      final sway = 7 * math.sin(2 * math.pi * (phase * 2 + i));
      canvas.drawCircle(
        Offset(baseX + sway, y),
        7 + 5 * phase, // wisps grow as they rise, then fade out
        paint..color = Color.fromRGBO(255, 255, 255, 0.13 * (1 - phase)),
      );
    }
  }

  /// Seven tiny stars twinkling in the upper half (bedtime calm).
  void _stars(Canvas canvas, Size size) {
    const spots = [
      Offset(0.12, 0.10),
      Offset(0.28, 0.05),
      Offset(0.45, 0.13),
      Offset(0.62, 0.07),
      Offset(0.78, 0.15),
      Offset(0.88, 0.06),
      Offset(0.35, 0.21),
    ];
    for (var i = 0; i < spots.length; i++) {
      final twinkle =
          0.22 + 0.18 * (0.5 + 0.5 * math.sin(2 * math.pi * (t + i * 0.14)));
      final c = Offset(spots[i].dx * size.width, spots[i].dy * size.height);
      final paint = Paint()..color = Color.fromRGBO(255, 244, 214, twinkle);
      canvas.drawCircle(c, 1.6, paint);
      // A soft four-point sparkle on the two brightest.
      if (i.isEven && twinkle > 0.32) {
        final line = Paint()
          ..color = paint.color
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(c.translate(-4, 0), c.translate(4, 0), line);
        canvas.drawLine(c.translate(0, -4), c.translate(0, 4), line);
      }
    }
  }

  /// Two butterflies on gentle looping paths, wings flapping softly.
  void _butterflies(Canvas canvas, Size size) {
    const tints = [Color(0xCCE9A8B7), Color(0xCCB7A8E9)];
    for (var i = 0; i < 2; i++) {
      final phi = i * math.pi;
      final x =
          size.width * (0.32 + 0.24 * math.sin(2 * math.pi * t * 0.9 + phi));
      final y =
          size.height *
          (0.20 + 0.10 * math.sin(4 * math.pi * t * 0.9 + phi + 1.3));
      final flap = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(14 * math.pi * t + phi));
      final paint = Paint()..color = tints[i];
      canvas.save();
      canvas.translate(x, y);
      for (final side in const [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(side * 3.4 * flap, 0),
            width: 6.4 * flap,
            height: 4.6,
          ),
          paint,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 1.8, height: 5.2),
        Paint()..color = const Color(0xB36B5844),
      );
      canvas.restore();
    }
  }

  /// The songbird — perched high near the tree, bobbing contentedly.
  void _songbird(Canvas canvas, Size size) {
    final bob = 1.6 * math.sin(4 * math.pi * t);
    final c = Offset(size.width * 0.82, size.height * 0.18 + bob);
    final body = Paint()..color = const Color(0xE68FB7D9);
    final belly = Paint()..color = const Color(0xE6FFF4DE);
    // Body, belly, head.
    canvas.drawOval(Rect.fromCenter(center: c, width: 15, height: 11), body);
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0.5, 2.2), width: 9, height: 6),
      belly,
    );
    canvas.drawCircle(c.translate(6.4, -4.6), 4.6, body);
    // Beak, eye, wing, tail.
    final beak = Path()
      ..moveTo(c.dx + 10.4, c.dy - 5.2)
      ..lineTo(c.dx + 13.6, c.dy - 4.2)
      ..lineTo(c.dx + 10.2, c.dy - 3.2)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFE9B178));
    canvas.drawCircle(
      c.translate(7.4, -5.4),
      0.9,
      Paint()..color = const Color(0xFF4A3F38),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(-1.5, -1), width: 8, height: 5.4),
      Paint()..color = const Color(0xE67AA3C8),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(-8.5, 1.5), width: 7, height: 3.4),
      Paint()..color = const Color(0xE67AA3C8),
    );
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.t != t || old.variant != variant || old.visitor != visitor;
}
