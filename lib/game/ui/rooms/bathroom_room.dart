/// The Bathroom — splash & sparkle (UX bible §2.4: the rich form of the Clean
/// verb). Scrub the pet with your finger: foam builds, and when the bath is
/// done the pet shakes off into its `comforted` glow. A one-tap Quick Rinse
/// keeps cleaning fully accessible (never gesture-only), and the potty break
/// is a giggly, gentle hygiene moment. Copy is always "let's freshen up 🫧" —
/// never "you were dirty" (no blame, ever).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../model/care_meters.dart';
import '../../rooms/room_id.dart';
import '../../sim/interaction.dart';
import '../mood_visuals.dart';
import '../widgets/cozy.dart';
import 'room_host.dart' show kRoomDockClearance;
import 'widgets/need_glow.dart';

class BathroomRoom extends StatefulWidget {
  const BathroomRoom({
    required this.controller,
    required this.rig,
    required this.goToRoom,
    super.key,
  });

  final GameController controller;
  final PetRenderer rig;
  final void Function(RoomId) goToRoom;

  @override
  State<BathroomRoom> createState() => _BathroomRoomState();
}

class _BathroomRoomState extends State<BathroomRoom> {
  /// 0..1 scrub build-up; a full scrub completes one bath (the clean verb).
  double _scrub = 0;

  /// Counts completed baths (keys the one-shot shake-off pop).
  int _baths = 0;

  void _onScrub(DragUpdateDetails d) {
    if (widget.controller.isSleeping) return;
    final delta = d.delta.distance / 500; // a comfy few seconds of scrubbing
    final next = (_scrub + delta).clamp(0.0, 1.0);
    if (next >= 1.0) {
      setState(() {
        _scrub = 0;
        _baths++;
      });
      widget.controller.interact(CareInteraction.clean);
    } else {
      setState(() => _scrub = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final pet = c.pet;
    if (pet == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return CozyBackground(
      asset: KpAssets.bathroomScene,
      child: SafeArea(
        child: Column(
          children: [
            if (c.petLine != null)
              Padding(
                padding: const EdgeInsets.only(top: 52),
                child: CozySpeechBubble(text: c.petLine!),
              )
            else
              const SizedBox(height: 64),
            // The pet at the tub, scrubbable, wearing its foam.
            Expanded(
              child: Align(
                alignment: const Alignment(0, 0.1),
                child: GestureDetector(
                  key: const Key('bath-scrub'),
                  onTap: c.nudgeAmbient,
                  onPanUpdate: _onScrub,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      widget.rig.build(
                        context,
                        mood: petMoodFor(c.mood),
                        lifeStage: pet.lifeStage.id,
                        emotion: currentPetEmotion(c),
                      ),
                      // Foam builds with the scrub (deterministic bubbles).
                      if (_scrub > 0.02)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _FoamPainter(progress: _scrub),
                            ),
                          ),
                        ),
                      // Shake-off sparkle pop when a bath completes.
                      if (_baths > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(_baths),
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (context, t, _) =>
                                  CustomPaint(painter: _SparklePainter(t: t)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (c.lastMessage != null)
              CozyChip(
                child: Text(
                  c.lastMessage!,
                  key: const Key('room-feedback'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            CozyChip(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: Text(
                          'Rub-a-dub! Scrub with your finger',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      NeedGlow(
                        label: 'Sparkle',
                        value: pet.meters.of(CareNeed.hygiene),
                        icon: Icons.bubble_chart_rounded,
                      ),
                    ],
                  ),
                  if (_scrub > 0.02) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        key: const Key('scrub-progress'),
                        value: _scrub,
                        minHeight: 8,
                        color: const Color(0xFF9CC8E0),
                        backgroundColor: const Color(
                          0xFF9CC8E0,
                        ).withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CozyImageButton(
                  asset: KpAssets.btnClean,
                  label: 'Quick rinse',
                  tapKey: const Key('bath-quick-rinse'),
                  onTap: () => c.interact(CareInteraction.clean),
                ),
                _PottyButton(controller: c),
              ],
            ),
            const SizedBox(height: kRoomDockClearance),
          ],
        ),
      ),
    );
  }
}

/// The gentle, giggly potty break — a real hygiene moment through the same
/// canonical clean verb (child-safe humour, zero mess ever shown).
class _PottyButton extends StatelessWidget {
  const _PottyButton({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Potty break',
          child: Material(
            color: const Color(0xFFFFF6EC),
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              key: const Key('bath-potty'),
              customBorder: const CircleBorder(),
              onTap: () => controller.interact(CareInteraction.clean),
              child: const SizedBox(
                width: 68,
                height: 68,
                child: Center(
                  child: Text('🚽', style: TextStyle(fontSize: 30)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Potty break',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4A3F38),
            shadows: const [
              Shadow(color: Color(0xE6FFF6EC), blurRadius: 6),
              Shadow(color: Color(0xE6FFF6EC), blurRadius: 3),
            ],
          ),
        ),
      ],
    );
  }
}

/// Soap foam that grows with scrub progress. Bubble layout is deterministic
/// (index-hashed positions, no Random) so tests and replays are stable.
class _FoamPainter extends CustomPainter {
  _FoamPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final count = (progress * 18).round() + 2;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final rim = Paint()
      ..color = const Color(0xFFBFE3F2).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < count; i++) {
      final h = _hash(i);
      final cx = size.width * (0.18 + 0.64 * _frac(h));
      final cy = size.height * (0.25 + 0.6 * _frac(h >> 8));
      final r = 4.0 + 7.0 * _frac(h >> 16) * (0.5 + progress);
      canvas.drawCircle(Offset(cx, cy), r, paint);
      canvas.drawCircle(Offset(cx, cy), r, rim);
      canvas.drawCircle(
        Offset(cx - r * 0.3, cy - r * 0.3),
        r * 0.25,
        Paint()..color = Colors.white,
      );
    }
  }

  static int _hash(int i) {
    var x = i * 2654435761;
    x ^= x >> 13;
    x *= 0x5bd1e995;
    x ^= x >> 15;
    return x & 0xFFFFFF;
  }

  static double _frac(int h) => (h & 0xFF) / 255.0;

  @override
  bool shouldRepaint(_FoamPainter old) => old.progress != progress;
}

/// The clean shake-off: a ring of soft sparkles that bloom and fade once.
class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * (0.3 + 0.35 * t);
    final paint = Paint()
      ..color = const Color(0xFFFFE9A8).withValues(alpha: (1 - t))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + t * 0.6;
      final p = center + Offset(math.cos(a), math.sin(a)) * radius;
      const s = 5.0;
      canvas.drawLine(p.translate(-s, 0), p.translate(s, 0), paint);
      canvas.drawLine(p.translate(0, -s), p.translate(0, s), paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}
