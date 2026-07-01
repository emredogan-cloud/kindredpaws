/// Visual joy layer (Product Evolution E1): deterministic one-shot particle
/// bursts over the pet (crumbs, sparkles, hearts, confetti) and the milestone
/// [CelebrationOverlay]. Everything is a bounded TweenAnimationBuilder —
/// settle-safe for tests — and every layout is index-hashed (no Random), so
/// replays and goldens are stable. Bursts react to the SAME controller state
/// every room shares; nothing here mutates gameplay.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controller/game_controller.dart';
import '../../model/bond.dart';
import '../../sim/interaction.dart';
import 'cozy.dart';

enum BurstKind { crumbs, sparkles, hearts, confetti }

/// A single one-shot particle burst. Re-key to replay.
class ParticleBurst extends StatelessWidget {
  const ParticleBurst({required this.kind, this.size = 160, super.key});

  final BurstKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          size: Size.square(size),
          painter: _BurstPainter(kind: kind, t: t),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.kind, required this.t});

  final BurstKind kind;
  final double t;

  static int _hash(int i) {
    var x = i * 2654435761;
    x ^= x >> 13;
    x *= 0x5bd1e995;
    x ^= x >> 15;
    return x & 0xFFFFFF;
  }

  static double _f(int h, int shift) => ((h >> shift) & 0xFF) / 255.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final c = size.center(Offset.zero);
    final fade = (1 - t).clamp(0.0, 1.0);
    final count = switch (kind) {
      BurstKind.confetti => 22,
      BurstKind.hearts => 8,
      _ => 12,
    };
    for (var i = 0; i < count; i++) {
      final h = _hash(i + kind.index * 97);
      final angle = _f(h, 0) * 2 * math.pi;
      final speed = 0.35 + 0.65 * _f(h, 8);
      // Confetti flutters down; other bursts bloom outward and drift up.
      final gravity = kind == BurstKind.confetti ? 60.0 * t * t : -22.0 * t;
      final p =
          c +
          Offset(math.cos(angle), math.sin(angle)) *
              (size.shortestSide * 0.42 * t * speed) +
          Offset(0, gravity);
      switch (kind) {
        case BurstKind.crumbs:
          canvas.drawCircle(
            p,
            2.2 + 1.6 * _f(h, 16),
            Paint()..color = const Color(0xFFB98A5A).withValues(alpha: fade),
          );
        case BurstKind.sparkles:
          final r = 3.0 + 2.5 * _f(h, 16);
          final paint = Paint()
            ..color = const Color(0xFFFFE9A8).withValues(alpha: fade)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(p.translate(-r, 0), p.translate(r, 0), paint);
          canvas.drawLine(p.translate(0, -r), p.translate(0, r), paint);
        case BurstKind.hearts:
          _heart(
            canvas,
            p,
            4.5 + 3.0 * _f(h, 16),
            const Color(0xFFE98FA5).withValues(alpha: fade),
          );
        case BurstKind.confetti:
          final paint = Paint()
            ..color = _confettiColors[i % _confettiColors.length].withValues(
              alpha: fade,
            );
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(angle + t * 6 * speed);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: 7, height: 4.5),
              const Radius.circular(1.5),
            ),
            paint,
          );
          canvas.restore();
      }
    }
  }

  static const _confettiColors = [
    Color(0xFFE8A46B),
    Color(0xFF8AB17D),
    Color(0xFF9CC8E0),
    Color(0xFFE98FA5),
    Color(0xFFFFE9A8),
  ];

  void _heart(Canvas canvas, Offset c, double r, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy + r * 0.55)
      ..cubicTo(
        c.dx - r * 1.1,
        c.dy - r * 0.25,
        c.dx - r * 0.5,
        c.dy - r * 0.95,
        c.dx,
        c.dy - r * 0.3,
      )
      ..cubicTo(
        c.dx + r * 0.5,
        c.dy - r * 0.95,
        c.dx + r * 1.1,
        c.dy - r * 0.25,
        c.dx,
        c.dy + r * 0.55,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.kind != kind;
}

/// Wraps the pet visual and pops the matching burst whenever a NEW care
/// outcome lands (identity-keyed — one burst per action, everywhere the pet
/// lives). Purely decorative; reads shared state, never writes it.
class PetFx extends StatefulWidget {
  const PetFx({required this.controller, required this.child, super.key});

  final GameController controller;
  final Widget child;

  @override
  State<PetFx> createState() => _PetFxState();
}

class _PetFxState extends State<PetFx> {
  int _lastOutcomeId = 0;
  int _burstSeq = 0;
  BurstKind? _kind;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final outcome = widget.controller.lastOutcome;
    if (outcome == null) return;
    final id = identityHashCode(outcome);
    if (id == _lastOutcomeId) return;
    _lastOutcomeId = id;
    final kind = outcome.grew
        ? BurstKind.confetti
        : outcome.comfortBeat
        ? BurstKind.hearts
        : switch (widget.controller.lastInteraction) {
            CareInteraction.feed => BurstKind.crumbs,
            CareInteraction.clean => BurstKind.sparkles,
            CareInteraction.play => BurstKind.sparkles,
            null => null,
          };
    if (kind == null || !mounted) return;
    setState(() {
      _kind = kind;
      _burstSeq++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_kind != null)
          Positioned.fill(
            child: ParticleBurst(
              key: ValueKey('burst-$_burstSeq'),
              kind: _kind!,
            ),
          ),
      ],
    );
  }
}

/// The milestone stage: a warm banner + confetti when the pet grows or the
/// Bond reaches a new stage. Watches the shared controller, celebrates each
/// milestone exactly once, fades on its own (one-shot — settle-safe).
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({required this.controller, super.key});

  final GameController controller;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  BondStage? _seenBondStage;
  String? _seenLifeStage;
  String? _banner;
  int _celebrationSeq = 0;

  @override
  void initState() {
    super.initState();
    final pet = widget.controller.pet;
    _seenBondStage = pet?.bond.stage;
    _seenLifeStage = pet?.lifeStage.id;
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final pet = widget.controller.pet;
    if (pet == null) return;
    String? banner;
    if (_seenLifeStage != null && pet.lifeStage.id != _seenLifeStage) {
      banner = '${pet.name} grew into a ${pet.lifeStage.displayName}! 🎉';
    } else if (_seenBondStage != null && pet.bond.stage != _seenBondStage) {
      banner =
          'You and ${pet.name} are ${pet.bond.stage.displayName}s '
          'now 💛';
    }
    _seenLifeStage = pet.lifeStage.id;
    _seenBondStage = pet.bond.stage;
    if (banner == null || !mounted) return;
    setState(() {
      _banner = banner;
      _celebrationSeq++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_banner == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('celebration-$_celebrationSeq'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 2400),
        curve: Curves.linear,
        onEnd: () => setState(() => _banner = null),
        builder: (context, t, _) {
          // Banner: quick in, hold, gentle out. Confetti rains through.
          final opacity = t < 0.12
              ? t / 0.12
              : t > 0.8
              ? (1 - t) / 0.2
              : 1.0;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BurstPainter(
                      kind: BurstKind.confetti,
                      t: (t * 1.4).clamp(0.0, 1.0),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.45),
                  child: CozyChip(
                    child: Text(
                      _banner!,
                      key: const Key('celebration-banner'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
