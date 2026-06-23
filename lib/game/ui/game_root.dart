/// Routes the player between Rescue Day (no pet yet) and the Companion home
/// (pet adopted), driven entirely by the [GameController]. Kicks off the load
/// (which resolves offline catch-up) once on mount.
library;

import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import 'companion_home_screen.dart';
import 'rescue_day_screen.dart';

class GameRoot extends StatefulWidget {
  const GameRoot({required this.controller, this.autoLoad = true, super.key});

  final GameController controller;

  /// Whether to call `controller.load()` on mount (tests may pre-seed instead).
  final bool autoLoad;

  @override
  State<GameRoot> createState() => _GameRootState();
}

class _GameRootState extends State<GameRoot> {
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.loading) {
          return const Scaffold(
            key: Key('game-loading'),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.controller.hasPet
            ? CompanionHomeScreen(controller: widget.controller)
            : RescueDayScreen(controller: widget.controller);
      },
    );
  }
}
