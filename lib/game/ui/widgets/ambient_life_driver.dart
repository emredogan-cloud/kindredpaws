/// Autonomous micro-behaviors (GE-2): every so often, an idle pet simply
/// *does something* — a stretch, an ear-flick, a look around — via the
/// existing ambient-emotion path. Renders nothing; it only paces gentle
/// [GameController.nudgeAmbient] beats:
///
///  * only while ambient motion is enabled ([AmbientScene.motionEnabled] —
///    OFF in tests/CI, ON in the app) and reduced-motion is off;
///  * only when the pet is awake and genuinely idle (no fresh reaction);
///  * a few beats per sitting ([maxBeats]) — presence, never a show-off loop.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../controller/game_controller.dart';
import 'ambient_scene.dart';

class AmbientLifeDriver extends StatefulWidget {
  const AmbientLifeDriver({required this.controller, super.key});

  final GameController controller;

  /// Seconds of stillness before the pet acts on its own.
  static const Duration idleBeat = Duration(seconds: 14);

  /// Autonomous beats per mount (per app sitting) — enough to feel alive,
  /// few enough to stay a companion rather than a screensaver.
  static const int maxBeats = 3;

  @override
  State<AmbientLifeDriver> createState() => _AmbientLifeDriverState();
}

class _AmbientLifeDriverState extends State<AmbientLifeDriver> {
  Timer? _timer;
  int _beats = 0;
  int _arms = 0;

  /// Bounded re-arm chain: even when every fire is skipped (interactions,
  /// sleep), the chain ends — no immortal timer.
  static const int _maxArms = 6;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    // Never even create a timer when motion is globally off (tests/CI stay
    // free of pending timers), or when the sitting's beats are spent.
    if (!AmbientScene.motionEnabled) return;
    if (_beats >= AmbientLifeDriver.maxBeats || _arms >= _maxArms) return;
    _arms++;
    _timer = Timer(AmbientLifeDriver.idleBeat, _fire);
  }

  void _fire() {
    if (!mounted) return;
    final c = widget.controller;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final idle = c.hasPet && !c.isSleeping && c.lastInteraction == null;
    if (!reduced && idle) {
      _beats++;
      c.nudgeAmbient(); // the pet stirs: stretch / ear-flick / look-around
    }
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
