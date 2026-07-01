/// The **temporary character renderer** (Immersive Pet Experience sprint) —
/// an original, hand-authored vector pet drawn with Flutter's [CustomPainter].
/// No third-party art, no copied assets: every shape is composed here in the
/// canonical storybook palette (cream/peach, soft rounded forms, big bright
/// eyes with a catchlight, never sharp or scary — child-safe by construction).
///
/// It fills the seam until the commissioned `.riv` rig lands and honours the
/// SAME state contract the Rive rig is authored against
/// (`assets/rive/README.md`, `rive_pet_renderer.dart`):
///
///   * `mood` (0–3)      → one of 4 continuous idle loops (breathing pace,
///                          posture, ear/tail carriage differ per mood; a mood
///                          change soft-blends between idles),
///   * `emotion` (0–11)  → a one-shot reaction ≤ 2 s that returns to the
///                          current mood's idle,
///   * `lifeStage` (0–2) → proportion + scale blend (head:body ≈ 1:1.6 pupKit
///                          → 1:2.2 grown; render scale 0.7 / 0.85 / 1.0),
///
/// plus the always-on micro-layer (breathe, deterministic blink, tail sway).
/// Swapping the real rig in requires **zero code change**: build with
/// `KP_PET_RENDERER=rive` + `KP_RIV_ASSET=assets/rive/<file>.riv`.
///
/// Determinism: with [continuousMotion] false (widget/golden tests) the idle
/// loop freezes at a fixed phase and only one-shot reaction pops play, so
/// `pumpAndSettle` always settles — the same guarantee the placeholder gives.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/model/species.dart';
import 'pet_renderer.dart';

class VectorPetRenderer implements PetRenderer {
  const VectorPetRenderer({
    this.speciesOf,
    this.size = 160,
    this.continuousMotion = true,
  });

  /// Resolves the adopted species at build time (puppy ↔ kitten look). Falls
  /// back to puppy pre-adoption — mirrors the per-species `.riv` plan.
  final Species Function()? speciesOf;

  /// Edge length (logical px) of the square render area at `grown` scale.
  final double size;

  /// False freezes the idle loop (deterministic tests); reactions still play
  /// (one-shot, so `pumpAndSettle` settles).
  final bool continuousMotion;

  @override
  String get backendId => 'vector';

  @override
  Widget build(
    BuildContext context, {
    required PetMood mood,
    required String lifeStage,
    PetEmotion? emotion,
  }) {
    final expression = emotion ?? PetEmotion.restingFor(mood);
    final box = size * petLifeStageScale(lifeStage);
    return Semantics(
      label: 'pet ($lifeStage, ${mood.name}, ${expression.displayName})',
      child: SizedBox(
        key: const Key('pet-renderer'),
        width: box,
        height: box,
        child: _VectorPet(
          mood: mood,
          emotion: expression,
          lifeStage: lifeStage,
          species: speciesOf?.call() ?? Species.puppy,
          continuousMotion: continuousMotion,
        ),
      ),
    );
  }
}

/// Stage blend 0 (pupKit) → 1 (grown): drives the head:body proportion shift.
double _stageT(String lifeStage) => switch (lifeStage) {
  'youngOne' => 0.5,
  'grown' => 1.0,
  _ => 0.0,
};

class _VectorPet extends StatefulWidget {
  const _VectorPet({
    required this.mood,
    required this.emotion,
    required this.lifeStage,
    required this.species,
    required this.continuousMotion,
  });

  final PetMood mood;
  final PetEmotion emotion;
  final String lifeStage;
  final Species species;
  final bool continuousMotion;

  @override
  State<_VectorPet> createState() => _VectorPetState();
}

class _VectorPetState extends State<_VectorPet> with TickerProviderStateMixin {
  /// Continuous idle loop (breathe/tail/blink). Runs only in motion mode.
  late final AnimationController _idle;

  /// One-shot reaction envelope (≤ 2 s, returns to idle) — the contract's
  /// "reaction state per emotion".
  late final AnimationController _reaction;

  /// Soft cross-blend when the mood (idle) changes — the contract's ~0.3 s
  /// idle-to-idle blend.
  late final AnimationController _moodBlend;
  PetMood? _previousMood;

  /// Idle loop duration per mood (bible §6.1: joyful 3–4 s … low 5–6 s).
  static Duration _idleDuration(PetMood mood) => switch (mood) {
    PetMood.joyful => const Duration(milliseconds: 3400),
    PetMood.content => const Duration(milliseconds: 4400),
    PetMood.wistful => const Duration(milliseconds: 5200),
    PetMood.low => const Duration(milliseconds: 5800),
  };

  /// Reaction length per emotion (bible §6.2 — every one ≤ 2.0 s).
  static Duration _reactionDuration(PetEmotion e) => switch (e) {
    PetEmotion.happy => const Duration(milliseconds: 1200),
    PetEmotion.excited => const Duration(milliseconds: 1500),
    PetEmotion.playful => const Duration(milliseconds: 1600),
    PetEmotion.affectionate => const Duration(milliseconds: 1500),
    PetEmotion.content => const Duration(milliseconds: 1000),
    PetEmotion.proud => const Duration(milliseconds: 1400),
    PetEmotion.calm => const Duration(milliseconds: 1600),
    PetEmotion.sleepy => const Duration(milliseconds: 1800),
    PetEmotion.curious => const Duration(milliseconds: 1200),
    PetEmotion.lonely => const Duration(milliseconds: 1600),
    PetEmotion.hungry => const Duration(milliseconds: 1400),
    PetEmotion.comforted => const Duration(milliseconds: 1500),
  };

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: _idleDuration(widget.mood),
      // A fixed mid-cycle phase keeps the frozen (test) pose natural.
      value: 0.35,
    );
    _reaction = AnimationController(
      vsync: this,
      duration: _reactionDuration(widget.emotion),
    );
    _moodBlend = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1,
    );
    if (widget.continuousMotion) _idle.repeat();
    // The first expression plays as a greeting pop only when it's a real
    // reaction (not the resting face) — matches the rig's trigger semantics.
    if (widget.emotion != PetEmotion.restingFor(widget.mood)) {
      _reaction.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_VectorPet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      // Contract: setting `emotion` replays its one-shot reaction.
      _reaction.duration = _reactionDuration(widget.emotion);
      _reaction.forward(from: 0);
    }
    if (oldWidget.mood != widget.mood) {
      // Contract: mood changes blend idles (~0.3 s), never cut.
      _previousMood = oldWidget.mood;
      _idle.duration = _idleDuration(widget.mood);
      _moodBlend.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _reaction.dispose();
    _moodBlend.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _reaction, _moodBlend]),
      builder: (context, _) {
        return CustomPaint(
          isComplex: true,
          size: Size.infinite,
          painter: _PetPainter(
            mood: widget.mood,
            previousMood: _moodBlend.isAnimating ? _previousMood : null,
            moodBlend: Curves.easeOut.transform(_moodBlend.value),
            emotion: widget.emotion,
            reactionT: _reaction.isAnimating ? _reaction.value : 1.0,
            reactionActive: _reaction.isAnimating,
            idlePhase: _idle.value,
            stageT: _stageT(widget.lifeStage),
            species: widget.species,
          ),
        );
      },
    );
  }
}

/// The pose vocabulary — every drawable parameter the mood idles and emotion
/// reactions blend over. All values are normalized (0..1 or -1..1).
class _Pose {
  const _Pose({
    this.breatheAmp = 0.5,
    this.earLift = 0.5,
    this.tailLift = 0.5,
    this.tailWag = 0.3,
    this.headTilt = 0,
    this.headDrop = 0,
    this.squash = 0,
    this.hop = 0,
    this.chestUp = 0,
    this.eyeOpen = 1,
    this.smile = 0.55,
    this.mouthOpen = 0,
    this.browSoft = 0,
    this.blush = 0,
    this.heartEyes = false,
    this.sparkleEyes = false,
    this.tongue = false,
    this.closedHappyEyes = false,
  });

  final double breatheAmp; // chest rise amplitude
  final double earLift; // 0 droopy … 1 perky
  final double tailLift; // tail carriage
  final double tailWag; // wag speed/energy
  final double headTilt; // -1 left … 1 right (z-rotation)
  final double headDrop; // 0 up … 1 gentle down (wistful/lonely)
  final double squash; // playful crouch (squash & stretch)
  final double hop; // vertical hop impulse
  final double chestUp; // proud chest
  final double eyeOpen; // 1 wide … 0 closed
  final double smile; // mouth curve 0 flat … 1 big smile
  final double mouthOpen; // 0 closed … 1 open (yawn/laugh)
  final double browSoft; // gentle brows (comfort/lonely) — never angry
  final double blush; // cheek blush opacity
  final bool heartEyes;
  final bool sparkleEyes;
  final bool tongue;
  final bool closedHappyEyes;

  static _Pose idleFor(PetMood mood) => switch (mood) {
    PetMood.joyful => const _Pose(
      breatheAmp: 0.8,
      earLift: 0.9,
      tailLift: 0.9,
      tailWag: 1.0,
      smile: 0.85,
      eyeOpen: 1.0,
    ),
    PetMood.content => const _Pose(
      breatheAmp: 0.55,
      earLift: 0.65,
      tailLift: 0.6,
      tailWag: 0.45,
      smile: 0.6,
      eyeOpen: 0.92,
    ),
    PetMood.wistful => const _Pose(
      breatheAmp: 0.4,
      earLift: 0.4,
      tailLift: 0.35,
      tailWag: 0.2,
      smile: 0.42,
      eyeOpen: 0.85,
      headDrop: 0.25,
      browSoft: 0.4,
    ),
    // "Low" stays warm and safe — a tired-but-loved look, never suffering.
    PetMood.low => const _Pose(
      breatheAmp: 0.32,
      earLift: 0.25,
      tailLift: 0.2,
      tailWag: 0.12,
      smile: 0.32,
      eyeOpen: 0.75,
      headDrop: 0.4,
      browSoft: 0.7,
      blush: 0.2,
    ),
  };

  /// The reaction overlay for [e] at envelope strength [t] (0..1..0). Values
  /// lerp FROM the idle pose, so every reaction decays back to idle — the
  /// contract's "one-shot, returns to idle".
  _Pose react(PetEmotion e, double t) => switch (e) {
    PetEmotion.happy => _lerp(
      t,
      hop: 0.7,
      smile: 0.95,
      earLift: 1.0,
      tailWag: 1.0,
    ),
    PetEmotion.excited => _lerp(
      t,
      hop: 1.0,
      smile: 1.0,
      mouthOpen: 0.35,
      earLift: 1.0,
      tailWag: 1.0,
      sparkle: true,
    ),
    PetEmotion.playful => _lerp(
      t,
      squash: 0.85,
      smile: 0.9,
      mouthOpen: 0.4,
      tailWag: 1.0,
      tongue: true,
    ),
    PetEmotion.affectionate => _lerp(
      t,
      headTilt: 0.6,
      smile: 0.85,
      blush: 0.9,
      hearts: true,
    ),
    PetEmotion.content => _lerp(t, smile: 0.7, eyeOpen: -0.5, chestUp: 0.2),
    PetEmotion.proud => _lerp(
      t,
      chestUp: 0.9,
      smile: 0.8,
      closedHappy: true,
      earLift: 0.9,
    ),
    PetEmotion.calm => _lerp(t, chestUp: 0.35, eyeOpen: -0.35, smile: 0.6),
    PetEmotion.sleepy => _lerp(
      t,
      mouthOpen: 0.8,
      eyeOpen: -0.8,
      headDrop: 0.35,
      earLift: -0.2,
    ),
    PetEmotion.curious => _lerp(
      t,
      headTilt: -0.8,
      earLift: 1.0,
      eyeOpen: 0.15,
      smile: 0.5,
      mouthOpen: 0.12,
    ),
    // Gentle longing — soft gaze, soft ears. NEVER crying or dramatic (§6.2).
    PetEmotion.lonely => _lerp(
      t,
      headDrop: 0.55,
      headTilt: 0.25,
      earLift: -0.3,
      smile: 0.35,
      browSoft: 0.8,
    ),
    // A cute tummy-wiggle "snack please?" — never pain (§6.2).
    PetEmotion.hungry => _lerp(
      t,
      squash: 0.3,
      mouthOpen: 0.3,
      smile: 0.5,
      tongue: true,
      headTilt: 0.3,
    ),
    PetEmotion.comforted => _lerp(
      t,
      chestUp: 0.25,
      smile: 0.65,
      eyeOpen: -0.55,
      blush: 0.8,
      browSoft: 0.5,
    ),
  };

  _Pose _lerp(
    double t, {
    double hop = 0,
    double squash = 0,
    double chestUp = 0,
    double headTilt = 0,
    double headDrop = -9,
    double earLift = -9,
    double tailWag = -9,
    double smile = -9,
    double mouthOpen = 0,
    double eyeOpen = 0,
    double browSoft = -9,
    double blush = -9,
    bool hearts = false,
    bool sparkle = false,
    bool tongue = false,
    bool closedHappy = false,
  }) {
    double at(double base, double target) =>
        target <= -9 ? base : base + (target - base) * t;
    return _Pose(
      breatheAmp: breatheAmp,
      earLift: earLift <= -9
          ? this.earLift
          : (earLift < 0
                ? this.earLift +
                      earLift *
                          t // relative droop
                : at(this.earLift, earLift)),
      tailLift: tailLift,
      tailWag: at(this.tailWag, tailWag <= -9 ? this.tailWag : tailWag),
      headTilt: this.headTilt + headTilt * t,
      headDrop: at(this.headDrop, headDrop <= -9 ? this.headDrop : headDrop),
      squash: this.squash + squash * t,
      hop: this.hop + hop * t,
      chestUp: this.chestUp + chestUp * t,
      eyeOpen: (this.eyeOpen + eyeOpen * t).clamp(0.08, 1.0),
      smile: at(this.smile, smile <= -9 ? this.smile : smile),
      mouthOpen: this.mouthOpen + mouthOpen * t,
      browSoft: at(this.browSoft, browSoft <= -9 ? this.browSoft : browSoft),
      blush: at(this.blush, blush <= -9 ? this.blush : blush),
      heartEyes: hearts && t > 0.15,
      sparkleEyes: sparkle && t > 0.15,
      tongue: tongue && t > 0.2,
      closedHappyEyes: closedHappy && t > 0.2,
    );
  }

  static _Pose blend(_Pose a, _Pose b, double t) => _Pose(
    breatheAmp: _l(a.breatheAmp, b.breatheAmp, t),
    earLift: _l(a.earLift, b.earLift, t),
    tailLift: _l(a.tailLift, b.tailLift, t),
    tailWag: _l(a.tailWag, b.tailWag, t),
    headTilt: _l(a.headTilt, b.headTilt, t),
    headDrop: _l(a.headDrop, b.headDrop, t),
    squash: _l(a.squash, b.squash, t),
    hop: _l(a.hop, b.hop, t),
    chestUp: _l(a.chestUp, b.chestUp, t),
    eyeOpen: _l(a.eyeOpen, b.eyeOpen, t),
    smile: _l(a.smile, b.smile, t),
    mouthOpen: _l(a.mouthOpen, b.mouthOpen, t),
    browSoft: _l(a.browSoft, b.browSoft, t),
    blush: _l(a.blush, b.blush, t),
    heartEyes: t < 0.5 ? a.heartEyes : b.heartEyes,
    sparkleEyes: t < 0.5 ? a.sparkleEyes : b.sparkleEyes,
    tongue: t < 0.5 ? a.tongue : b.tongue,
    closedHappyEyes: t < 0.5 ? a.closedHappyEyes : b.closedHappyEyes,
  );

  static double _l(double a, double b, double t) => a + (b - a) * t;
}

/// Species palettes — canonical: cream/peach base; soft orange (puppy),
/// gray-honey (kitten). Low contrast, warm undertone, storybook-soft.
class _Palette {
  const _Palette({
    required this.body,
    required this.bodyShade,
    required this.accent,
    required this.earInner,
    required this.muzzle,
  });

  final Color body;
  final Color bodyShade;
  final Color accent;
  final Color earInner;
  final Color muzzle;

  static const puppy = _Palette(
    body: Color(0xFFF6E3C8),
    bodyShade: Color(0xFFEDCFA9),
    accent: Color(0xFFE8A46B),
    earInner: Color(0xFFF2BE93),
    muzzle: Color(0xFFFBF2E2),
  );

  static const kitten = _Palette(
    body: Color(0xFFF0E7D4),
    bodyShade: Color(0xFFDECFB2),
    accent: Color(0xFFC9B282),
    earInner: Color(0xFFE8D3B4),
    muzzle: Color(0xFFFAF4E6),
  );
}

class _PetPainter extends CustomPainter {
  _PetPainter({
    required this.mood,
    required this.previousMood,
    required this.moodBlend,
    required this.emotion,
    required this.reactionT,
    required this.reactionActive,
    required this.idlePhase,
    required this.stageT,
    required this.species,
  });

  final PetMood mood;
  final PetMood? previousMood;
  final double moodBlend;
  final PetEmotion emotion;
  final double reactionT;
  final bool reactionActive;
  final double idlePhase;
  final double stageT;
  final Species species;

  static const _outline = Color(0xFF6B5844); // soft warm line, never black
  static const _eyeColor = Color(0xFF4A3F38);

  @override
  void paint(Canvas canvas, Size size) {
    // ---- resolve the pose ------------------------------------------------
    var pose = _Pose.idleFor(mood);
    final prev = previousMood;
    if (prev != null && moodBlend < 1) {
      pose = _Pose.blend(_Pose.idleFor(prev), pose, moodBlend);
    }
    if (reactionActive) {
      // Reaction envelope: quick attack, gentle release → returns to idle.
      final t = reactionT < 0.3
          ? Curves.easeOutBack.transform(reactionT / 0.3)
          : 1 - Curves.easeInOut.transform((reactionT - 0.3) / 0.7);
      pose = pose.react(emotion, t.clamp(0.0, 1.0));
    }

    final phase = idlePhase * 2 * math.pi;
    final breathe = math.sin(phase) * 0.5 + 0.5; // 0..1
    // Deterministic blink: a soft dip late in each idle cycle.
    final blink = _blinkAt(idlePhase);
    final eyeOpen = (pose.eyeOpen * (1 - blink)).clamp(0.06, 1.0);

    final palette = species == Species.kitten
        ? _Palette.kitten
        : _Palette.puppy;

    // ---- layout (200-unit design space, scaled to the box) ----------------
    final s = size.shortestSide / 200.0;
    canvas.save();
    canvas.translate((size.width - 200 * s) / 2, (size.height - 200 * s) / 2);
    canvas.scale(s);

    // Life-stage proportions: pupKit big-headed (≈1:1.6) → grown (≈1:2.2).
    final headR = 46 - 9 * stageT;
    final bodyW = 62 + 14 * stageT;
    final bodyH = 58 + 20 * stageT;
    final hopY = -14.0 * pose.hop * math.sin(math.min(1, reactionT) * math.pi);
    final squashK = 1 - 0.18 * pose.squash;
    final breatheK = 1 + 0.02 * pose.breatheAmp * (breathe - 0.5) * 2;

    const groundY = 178.0;
    const bodyCx = 100.0;
    final bodyCy = groundY - bodyH * 0.52 * squashK + hopY - pose.chestUp * 5;
    final headCy =
        bodyCy - bodyH * 0.52 * squashK - headR * 0.62 + pose.headDrop * 10;

    // ---- ground shadow (soft, follows the hop) ----------------------------
    final shadowPaint = Paint()
      ..color = const Color(0x2A8A6B4F)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final shadowW = bodyW * (1 + 0.1 * pose.squash) * (1 + 0.05 * -hopY / 14);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(bodyCx, groundY + 6),
        width: shadowW * 1.5,
        height: 18,
      ),
      shadowPaint,
    );

    final bodyPaint = Paint()..color = palette.body;
    final linePaint = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    // ---- tail (behind the body) -------------------------------------------
    final wag =
        math.sin(phase * (1 + 2.2 * pose.tailWag)) *
        (0.25 + 0.75 * pose.tailWag);
    _paintTail(canvas, palette, bodyCx, bodyCy, bodyW, pose, wag, linePaint);

    // ---- back paws ---------------------------------------------------------
    final pawPaint = Paint()..color = palette.bodyShade;
    for (final dx in [-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bodyCx + dx * bodyW * 0.34, groundY - 7),
          width: 26,
          height: 16,
        ),
        pawPaint,
      );
    }

    // ---- body (squashy pear) ----------------------------------------------
    final bodyRect = Rect.fromCenter(
      center: Offset(bodyCx, bodyCy),
      width: bodyW * (1 + 0.22 * pose.squash) * breatheK,
      height: bodyH * squashK * breatheK,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(bodyW * 0.42)),
      bodyPaint,
    );
    // tummy patch
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bodyCx, bodyCy + bodyH * 0.12),
        width: bodyW * 0.52,
        height: bodyH * 0.5,
      ),
      Paint()..color = palette.muzzle,
    );

    // ---- front paws ---------------------------------------------------------
    for (final dx in [-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bodyCx + dx * bodyW * 0.18, groundY - 6),
          width: 22,
          height: 15,
        ),
        Paint()..color = palette.body,
      );
      // tiny soft toe line (minimal detail, never claws)
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(bodyCx + dx * bodyW * 0.18, groundY - 7),
          width: 10,
          height: 8,
        ),
        math.pi * 0.15,
        math.pi * 0.7,
        false,
        linePaint..strokeWidth = 1.4,
      );
    }
    linePaint.strokeWidth = 2.6;

    // ---- head ----------------------------------------------------------------
    canvas.save();
    canvas.translate(bodyCx, headCy);
    canvas.rotate(pose.headTilt * 0.16);

    // ears first (behind the head)
    _paintEars(canvas, palette, headR, pose, phase);

    // head base — round, cornerless, full cheeks
    canvas.drawCircle(Offset.zero, headR, bodyPaint);

    // muzzle
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, headR * 0.42),
        width: headR * 1.05,
        height: headR * 0.72,
      ),
      Paint()..color = palette.muzzle,
    );

    _paintFace(canvas, palette, headR, pose, eyeOpen);
    canvas.restore();

    canvas.restore();
  }

  /// A soft deterministic blink late in each idle cycle (no randomness — the
  /// same phase always blinks, so goldens and replays are stable).
  static double _blinkAt(double t) {
    const start = 0.78, width = 0.07;
    if (t < start || t > start + width) return 0;
    final k = (t - start) / width;
    return math.sin(k * math.pi);
  }

  void _paintTail(
    Canvas canvas,
    _Palette p,
    double cx,
    double cy,
    double bodyW,
    _Pose pose,
    double wag,
    Paint line,
  ) {
    final tailPaint = Paint()
      ..color = p.accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final baseX = cx + bodyW * 0.52;
    final baseY = cy + 6;
    if (species == Species.kitten) {
      // Long, fluid S-curve rising from the hip.
      tailPaint.strokeWidth = 11;
      final path = Path()
        ..moveTo(baseX - 6, baseY + 18)
        ..cubicTo(
          baseX + 18,
          baseY + 14 + wag * 5,
          baseX + 24,
          baseY - 18 + wag * 12,
          baseX + 8 + wag * 10,
          baseY - 38 + pose.tailLift * -6 + wag * 8,
        );
      canvas.drawPath(path, tailPaint);
    } else {
      // Short, lively wagger from the hip — up and out, never a stick.
      tailPaint.strokeWidth = 14;
      canvas.drawLine(
        Offset(baseX - 6, baseY + 16),
        Offset(baseX + 10 + wag * 7, baseY - 2 - pose.tailLift * 12 + wag * 10),
        tailPaint,
      );
    }
  }

  void _paintEars(
    Canvas canvas,
    _Palette p,
    double headR,
    _Pose pose,
    double phase,
  ) {
    final earPaint = Paint()..color = p.accent;
    final innerPaint = Paint()..color = p.earInner;
    // Curious one-ear-up micro-gesture rides on the idle phase.
    final twitch = emotion == PetEmotion.curious
        ? math.max(0, math.sin(phase * 2)) * 0.15
        : 0.0;
    for (final side in [-1, 1]) {
      final lift = (pose.earLift + (side == 1 ? twitch : 0)).clamp(0.0, 1.2);
      canvas.save();
      canvas.translate(side * headR * 0.62, -headR * 0.55);
      if (species == Species.kitten) {
        // Rounded, blunt triangle (never sharp).
        canvas.rotate(side * (0.18 - 0.22 * lift));
        final path = Path()
          ..moveTo(-headR * 0.3, headR * 0.18)
          ..quadraticBezierTo(
            -headR * 0.16,
            -headR * (0.42 + 0.2 * lift),
            headR * 0.05,
            -headR * (0.5 + 0.22 * lift),
          )
          ..quadraticBezierTo(
            headR * 0.3,
            -headR * (0.28 + 0.1 * lift),
            headR * 0.3,
            headR * 0.14,
          )
          ..close();
        canvas.drawPath(path, earPaint);
        final inner = Path()
          ..moveTo(-headR * 0.14, headR * 0.1)
          ..quadraticBezierTo(
            -headR * 0.05,
            -headR * (0.3 + 0.16 * lift),
            headR * 0.04,
            -headR * (0.34 + 0.18 * lift),
          )
          ..quadraticBezierTo(
            headR * 0.18,
            -headR * 0.16,
            headR * 0.17,
            headR * 0.08,
          )
          ..close();
        canvas.drawPath(inner, innerPaint);
      } else {
        // Soft floppy flap hanging beside the head — the puppy's main
        // secondary-motion carrier. Perky lifts it up; droopy lets it hang.
        final droop = 1 - lift; // 0 perky … 1 droopy
        final sway = math.sin(phase * 1.5) * 3 * pose.breatheAmp;
        canvas.translate(side * headR * 0.28, 0); // clear the head silhouette
        canvas.rotate(side * (0.28 + 0.55 * droop));
        final flap = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              0,
              headR * (0.05 - 0.3 * lift + 0.3 * droop) + sway * 0.4,
            ),
            width: headR * 0.5,
            height: headR * (1.0 - 0.1 * lift),
          ),
          Radius.circular(headR * 0.25),
        );
        canvas.drawRRect(flap, earPaint);
        canvas.drawRRect(flap.deflate(headR * 0.11), innerPaint);
      }
      canvas.restore();
    }
  }

  void _paintFace(
    Canvas canvas,
    _Palette p,
    double headR,
    _Pose pose,
    double eyeOpen,
  ) {
    // Eyes ~32% of head width (bigger + brighter than the reference genre).
    final eyeR = headR * 0.16;
    final eyeY = -headR * 0.08;
    final eyeDx = headR * 0.34;

    for (final side in [-1, 1]) {
      final c = Offset(side * eyeDx, eyeY);
      if (pose.heartEyes) {
        _paintHeart(canvas, c, eyeR * 1.5, const Color(0xFFE98FA5));
        continue;
      }
      if (pose.closedHappyEyes || eyeOpen <= 0.12) {
        // Happy arc — never a flat "dead" line.
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: eyeR),
          math.pi * 1.15,
          math.pi * 0.7,
          false,
          Paint()
            ..color = _eyeColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }
      // White, iris, catchlight — the "eye light" that carries sincerity.
      final open = eyeOpen.clamp(0.15, 1.0);
      final eyeRect = Rect.fromCenter(
        center: c,
        width: eyeR * 2,
        height: eyeR * 2 * open,
      );
      canvas.drawOval(eyeRect, Paint()..color = Colors.white);
      canvas.drawOval(
        Rect.fromCenter(
          center: c.translate(0, eyeR * 0.06),
          width: eyeR * 1.5,
          height: eyeR * 1.5 * open,
        ),
        Paint()..color = _eyeColor,
      );
      canvas.drawCircle(
        c.translate(eyeR * 0.32, -eyeR * 0.3 * open),
        eyeR * 0.3,
        Paint()..color = Colors.white,
      );
      if (pose.sparkleEyes) {
        _paintSparkle(
          canvas,
          c.translate(-eyeR * 0.45, -eyeR * 0.5),
          eyeR * 0.3,
        );
      }
      // Soft brow (comfort/wistful) — a gentle tilt, never a frown.
      if (pose.browSoft > 0.05) {
        canvas.drawArc(
          Rect.fromCircle(
            center: c.translate(0, -eyeR * 1.5),
            radius: eyeR * 0.9,
          ),
          math.pi * (side == -1 ? 1.15 : 1.35),
          math.pi * 0.5,
          false,
          Paint()
            ..color = _eyeColor.withValues(alpha: 0.45 * pose.browSoft)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Blush
    if (pose.blush > 0.05) {
      final blushPaint = Paint()
        ..color = const Color(0xFFF2A48C).withValues(alpha: 0.5 * pose.blush)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      for (final side in [-1, 1]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(side * headR * 0.58, headR * 0.22),
            width: headR * 0.3,
            height: headR * 0.18,
          ),
          blushPaint,
        );
      }
    }

    // Nose — small, soft, rounded.
    final noseY = headR * 0.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, noseY),
          width: headR * 0.2,
          height: headR * 0.14,
        ),
        Radius.circular(headR * 0.07),
      ),
      Paint()..color = _outline,
    );

    // Kitten whiskers — thin, soft, three per cheek.
    if (species == Species.kitten) {
      final whisker = Paint()
        ..color = _outline.withValues(alpha: 0.4)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;
      for (final side in [-1, 1]) {
        for (var i = 0; i < 3; i++) {
          final y = headR * (0.3 + 0.09 * i);
          canvas.drawLine(
            Offset(side * headR * 0.5, y),
            Offset(
              side * headR * (0.88 + 0.04 * i),
              y + (i - 1) * headR * 0.06,
            ),
            whisker,
          );
        }
      }
    }

    // Mouth — a warm curve; opens for yawns/laughs; optional tongue.
    final mouthPaint = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final mouthY = noseY + headR * 0.13;
    final smileLift = headR * 0.12 * pose.smile;
    if (pose.mouthOpen > 0.15) {
      final open = pose.mouthOpen;
      final mouth = Rect.fromCenter(
        center: Offset(0, mouthY + headR * 0.1),
        width: headR * (0.3 + 0.14 * open),
        height: headR * (0.18 + 0.3 * open),
      );
      canvas.drawOval(mouth, Paint()..color = const Color(0xFF8A5A48));
      if (pose.tongue) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, mouth.bottom - headR * 0.06),
            width: headR * 0.2,
            height: headR * 0.16,
          ),
          Paint()..color = const Color(0xFFF2A48C),
        );
      }
    } else if (pose.smile >= 0.5) {
      // The classic two-lobe muzzle smile (joyful/content).
      for (final side in [-1, 1]) {
        final path = Path()
          ..moveTo(0, mouthY)
          ..quadraticBezierTo(
            side * headR * 0.14,
            mouthY + headR * 0.12,
            side * headR * 0.24,
            mouthY + headR * 0.1 - smileLift,
          );
        canvas.drawPath(path, mouthPaint);
      }
      if (pose.tongue) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, mouthY + headR * 0.14),
            width: headR * 0.16,
            height: headR * 0.13,
          ),
          Paint()..color = const Color(0xFFF2A48C),
        );
      }
    } else {
      // A small, soft resting mouth (wistful/low) — one gentle curve that
      // still turns faintly up at the ends. Warm, never a frown.
      final path = Path()
        ..moveTo(-headR * 0.14, mouthY + headR * 0.08 - smileLift * 0.4)
        ..quadraticBezierTo(
          0,
          mouthY + headR * 0.14,
          headR * 0.14,
          mouthY + headR * 0.08 - smileLift * 0.4,
        );
      canvas.drawPath(path, mouthPaint);
    }
  }

  void _paintHeart(Canvas canvas, Offset c, double r, Color color) {
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

  void _paintSparkle(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..color = const Color(0xFFFFE9A8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), paint);
    canvas.drawLine(c.translate(0, -r), c.translate(0, r), paint);
  }

  @override
  bool shouldRepaint(_PetPainter old) =>
      old.mood != mood ||
      old.emotion != emotion ||
      old.reactionT != reactionT ||
      old.reactionActive != reactionActive ||
      old.idlePhase != idlePhase ||
      old.moodBlend != moodBlend ||
      old.stageT != stageT ||
      old.species != species;
}
