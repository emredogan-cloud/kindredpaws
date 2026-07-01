import 'dart:async';

import 'package:flutter/material.dart';

import 'core/app_config.dart';
import 'core/app_instrumentation.dart';
import 'core/bootstrap.dart';
import 'core/kindred_terms.dart';
import 'core/performance_budgets.dart';
import 'core/service_locator.dart';
import 'data/prefs_save_store.dart';
import 'game/controller/game_controller.dart';
import 'game/game_wiring.dart';
import 'game/model/species.dart';
import 'game/ui/cozy_theme.dart';
import 'game/ui/game_root.dart';
import 'render/pet_renderer.dart';
import 'render/pet_renderer_factory.dart';
import 'services/analytics_service.dart';
import 'services/crash_reporter.dart';
import 'services/firebase_provisioning.dart';
import 'services/firebase/firebase_services.dart';
import 'services/home_widget_service.dart';
import 'services/live_ops.dart';
import 'services/local_notification_scheduler.dart';
import 'services/logger.dart';
import 'services/notification_scheduler.dart';
import 'services/notifications/flutter_local_notifications_sink.dart';
import 'services/observability.dart';
import 'services/performance_monitor.dart';
import 'services/remote_config_service.dart';

Future<void> main() async {
  final startMs = DateTime.now().millisecondsSinceEpoch;
  WidgetsFlutterBinding.ensureInitialized();
  // Players meet the animated vector pet (the temporary renderer honouring
  // the Rive contract); tests/CI keep the deterministic placeholder default.
  // An explicit KP_PET_RENDERER (e.g. `rive` once the .riv lands) always wins.
  final config = bootstrap(fallbackRenderer: PetRendererBackend.vector);
  final sl = ServiceLocator.instance;
  // Activate crash capture as early as possible (P3-7): route uncaught Flutter +
  // platform errors to the CrashReporter so the closed beta gets crash-free-rate
  // data (G3 ≥99%). Wired before the Firebase swap so even a provisioning error
  // is captured (by the in-memory reporter until Crashlytics takes over).
  installCrashHandlers(sl.get<CrashReporter>());
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

  // Production OS notifications (Task 1): the warm, capped, never-guilt scheduler
  // over flutter_local_notifications. bootstrap()'s in-memory scheduler stands in
  // for dev/CI/tests; this is the real device binding (a production swap like the
  // home-widget writer), wired after the Firebase swap so the tap handler emits
  // through the authoritative observability facade. Never blocks the first frame.
  final observability = sl.get<ObservabilityFacade>();
  final notifications = LocalNotificationScheduler(
    sink: FlutterLocalNotificationsSink(),
    liveOps: sl.get<LiveOps>(),
  );
  await notifications.initialize(
    onTap: (payload) => observability.event(AnalyticsEvent.notificationOpened, {
      'kind': payload ?? NotificationKind.reEngagement.name,
    }),
  );
  sl.registerSingleton<NotificationScheduler>(notifications);
  // Ask for notification permission in-context, fire-and-forget (Android 13+/
  // iOS) — never awaited, so a user-interactive dialog can't block boot.
  unawaited(notifications.requestPermission());

  final controller = createGameController(sl: sl, store: PrefsSaveStore());
  // The vector rig follows the adopted species (puppy ↔ kitten) — a
  // production re-bind in the same idiom as the home-widget/notification
  // swaps above. The Rive/placeholder backends ignore the resolver.
  sl.registerSingleton<PetRenderer>(
    createPetRenderer(
      config.petRendererBackend,
      riveAsset: config.riveAssetPath,
      onDiagnostic: riveDiagnosticSink(
        sl.get<Logger>(),
        sl.get<CrashReporter>(),
      ),
      speciesOf: () => controller.pet?.species ?? Species.puppy,
    ),
  );
  // Cold-start metric (P3-7): boot duration → first runApp. Feeds the startup
  // perf budget alongside the host-side performance tests.
  final coldStartMs = DateTime.now().millisecondsSinceEpoch - startMs;
  recordColdStart(sl.get<PerformanceMonitor>(), elapsedMs: coldStartMs);
  // Gate it against the budget (P5-6): a > 2.5s boot warns + breadcrumbs so a
  // soft-launch startup regression is visible in beta triage (never throws).
  sl.get<PerformanceBudgetMonitor>().check(PerfBudget.coldStart, coldStartMs);
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
      theme: cozyTheme(),
      // Key by controller identity so a controller swap (e.g. sign-in / restore)
      // gets a fresh GameRoot State that re-runs load(), instead of Flutter
      // silently reusing the old State and never loading the new save.
      home: GameRoot(key: ValueKey(controller), controller: controller),
    );
  }
}
