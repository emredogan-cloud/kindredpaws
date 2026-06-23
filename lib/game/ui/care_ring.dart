/// The Care ring (GAMEPLAY_AND_PROGRESSION_BIBLE.md §5.5): the player reads the
/// pet's needs as a soft ring whose four segments dim as meters drop — NOT as
/// "Hunger: 43%". Cozy, premium, empathy-first. Each need is one arc.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model/care_meters.dart';

class CareRing extends StatelessWidget {
  const CareRing({
    required this.meters,
    this.size = 200,
    this.child,
    super.key,
  });

  final CareMeters meters;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: _semanticLabel,
      child: SizedBox(
        key: const Key('care-ring'),
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CareRingPainter(
            meters: meters,
            track: scheme.surfaceContainerHighest,
            fill: scheme.primary,
            low: scheme.tertiary,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  String get _semanticLabel {
    // Coarse, kind phrasing — never a number, never accusatory.
    final lowest = meters.lowest;
    if (lowest > 60) return 'Your pet is thriving';
    if (lowest > 30) return 'Your pet could enjoy a little care';
    return 'Your pet would love some care';
  }
}

class _CareRingPainter extends CustomPainter {
  _CareRingPainter({
    required this.meters,
    required this.track,
    required this.fill,
    required this.low,
  });

  final CareMeters meters;
  final Color track;
  final Color fill;
  final Color low;

  static const double _gap = 0.12; // radians between segments
  static const double _stroke = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _stroke,
      _stroke,
      size.width - 2 * _stroke,
      size.height - 2 * _stroke,
    );
    final values = [
      meters.hunger,
      meters.energy,
      meters.hygiene,
      meters.happiness,
    ];
    const segment = (2 * math.pi / 4) - _gap;

    for (var i = 0; i < 4; i++) {
      final start = -math.pi / 2 + i * (segment + _gap);
      // Track.
      canvas.drawArc(
        rect,
        start,
        segment,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round
          ..color = track,
      );
      // Fill proportional to the meter; dims toward `low` when the need is low.
      final pct = (values[i] / 100).clamp(0.0, 1.0);
      final color = values[i] < 30 ? low : fill;
      canvas.drawArc(
        rect,
        start,
        segment * pct,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.4 + 0.6 * pct),
      );
    }
  }

  @override
  bool shouldRepaint(_CareRingPainter old) => old.meters != meters;
}
