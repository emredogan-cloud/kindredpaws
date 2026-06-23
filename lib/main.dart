import 'package:flutter/material.dart';

import 'core/app_config.dart';
import 'core/bootstrap.dart';
import 'core/kindred_terms.dart';
import 'core/service_locator.dart';
import 'data/prefs_save_store.dart';
import 'game/controller/game_controller.dart';
import 'game/game_wiring.dart';
import 'game/ui/game_root.dart';
import 'services/firebase_provisioning.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = bootstrap();
  // Best-effort Firebase init (no-op until provisioned; never throws).
  await FirebaseProvisioning.initialize();
  final controller = createGameController(
    sl: ServiceLocator.instance,
    store: PrefsSaveStore(),
  );
  runApp(KindredPawsApp(config: config, controller: controller));
}

/// Root application widget — the Phase-1 playable vertical slice. Routes between
/// Rescue Day (no pet) and the Companion home (pet adopted) via [GameRoot].
class KindredPawsApp extends StatelessWidget {
  const KindredPawsApp({
    required this.config,
    required this.controller,
    super.key,
  });

  final AppConfig config;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: KindredTerms.gameTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C8EAD)),
      ),
      // Key by controller identity so a controller swap (e.g. sign-in / restore)
      // gets a fresh GameRoot State that re-runs load(), instead of Flutter
      // silently reusing the old State and never loading the new save.
      home: GameRoot(key: ValueKey(controller), controller: controller),
    );
  }
}
