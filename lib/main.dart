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
import 'services/firebase/firebase_services.dart';
import 'services/home_widget_service.dart';
import 'services/remote_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = bootstrap();
  final sl = ServiceLocator.instance;
  // Production native bridges (the prefs-backed home-widget writer feeds the
  // OS widget; bootstrap's defaults are the test-safe in-memory versions).
  sl.registerSingleton<HomeWidgetService>(PrefsHomeWidgetService());

  // Real Firebase stack (P3-0): activates ONLY when provisioned
  // (KP_FIREBASE_PROVISIONED + flutterfire configure). Otherwise the mock/
  // in-memory adapters from bootstrap() stand — the app runs with zero creds.
  if (FirebaseProvisioning.isProvisioned && await initFirebase()) {
    registerFirebaseServices(sl);
    await (sl.get<RemoteConfigService>() as FirebaseRemoteConfigAdapter)
        .initialise();
  } else {
    await FirebaseProvisioning.initialize(); // records the unprovisioned status
  }

  final controller = createGameController(sl: sl, store: PrefsSaveStore());
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
