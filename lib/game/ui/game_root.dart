/// Routes the player between Rescue Day (no pet yet) and the Companion home
/// (pet adopted), driven entirely by the [GameController]. Kicks off the load
/// (which resolves offline catch-up) once on mount.
library;

import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import 'recovery_screen.dart';
import 'rescue_day_screen.dart';
import 'rooms/room_host.dart';
import 'widgets/cozy.dart';

class GameRoot extends StatefulWidget {
  const GameRoot({required this.controller, this.autoLoad = true, super.key});

  final GameController controller;

  /// Whether to call `controller.load()` on mount (tests may pre-seed instead).
  final bool autoLoad;

  @override
  State<GameRoot> createState() => _GameRootState();
}

class _GameRootState extends State<GameRoot> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Observe app lifecycle so the controller can end/begin play sessions
    // (P3-7: emits the sessionQuality retention beat on background).
    WidgetsBinding.instance.addObserver(this);
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.load();
      });
    }
  }

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm the first-seen cozy scenes so the home/onboarding paints without a
    // cream flash (perf polish; decoded once, cached). Best-effort + guarded.
    if (_precached) return;
    _precached = true;
    for (final bg in KpAssets.backgrounds) {
      precacheImage(AssetImage(bg), context, onError: (_, _) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // Only a real background ends the session. `inactive`/`hidden` fire on
      // transient interruptions (notification shade, app-switcher peek, a
      // permission dialog) and must NOT end it — otherwise the sessionQuality
      // retention signal + offline-catch-up greeting churn on every blip.
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        widget.controller.onAppBackgrounded();
      case AppLifecycleState.resumed:
        widget.controller.onAppForegrounded();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break; // transient — neither ends nor starts a session
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
        // KP-010: an unreadable-but-present save routes to recovery, never to
        // Rescue Day — adopting there would overwrite a recoverable pet.
        if (widget.controller.recovery != null) {
          return RecoveryScreen(controller: widget.controller);
        }
        return widget.controller.hasPet
            ? RoomHost(controller: widget.controller)
            : RescueDayScreen(controller: widget.controller);
      },
    );
  }
}
