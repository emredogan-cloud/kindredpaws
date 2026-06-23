/// Application bootstrap: builds [AppConfig] from the environment and registers
/// the concrete service implementations in the [ServiceLocator]. Defaults to
/// fully-offline mock adapters so the app runs with zero credentials.
///
/// This is Phase-0 provisioning wiring. No gameplay loop is started here.
library;

import 'app_config.dart';
import 'service_locator.dart';
import '../render/pet_renderer.dart';
import '../render/pet_renderer_factory.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import '../services/crash_reporter.dart';
import '../services/firebase_backend.dart';
import '../services/logger.dart';
import '../services/notification_scheduler.dart';
import '../services/observability.dart';
import '../services/performance_monitor.dart';
import '../services/remote_config_service.dart';
import '../services/home_widget_service.dart';
import '../services/status_snapshot_service.dart';
import '../heartmind/heartmind_service.dart';
import '../heartmind/local_heartmind.dart';

AppConfig bootstrap({ServiceLocator? locator}) {
  final sl = locator ?? ServiceLocator.instance;
  final config = AppConfig.fromEnvironment();

  sl.registerSingleton<AppConfig>(config);
  sl.registerSingleton<AuthService>(GuestAuthService());
  sl.registerSingleton<BackendService>(
    config.backendMode == BackendMode.firebase
        ? FirebaseBackendService()
        : InMemoryBackendService(),
  );
  sl.registerSingleton<RemoteConfigService>(const DefaultRemoteConfig());
  // The on-device hybrid Heartmind (P2-2): reviewed bank + closed-set memory
  // injection + safety. $0 runtime tokens, no network. Replaces the P0 stub.
  final heartmind = LocalHeartmind();
  sl.registerSingleton<HeartmindService>(heartmind);
  sl.registerSingleton<Heartmind>(heartmind);
  sl.registerSingleton<NotificationScheduler>(InMemoryNotificationScheduler());
  sl.registerSingleton<StatusSnapshotService>(InMemoryStatusSnapshotService());
  sl.registerSingleton<HomeWidgetService>(NoopHomeWidgetService());
  sl.registerSingleton<PetRenderer>(
    createPetRenderer(config.petRendererBackend),
  );

  // Observability (P1-2). In-memory/console impls are fully functional for
  // dev/CI; the Firebase-backed bodies drop in once provisioned (see
  // firebase_provisioning.dart). Analytics is shared with the facade.
  final analytics = InMemoryAnalyticsService();
  final logger = InMemoryLogger();
  final crash = InMemoryCrashReporter();
  final performance = InMemoryPerformanceMonitor();
  sl.registerSingleton<AnalyticsService>(analytics);
  sl.registerSingleton<Logger>(logger);
  sl.registerSingleton<CrashReporter>(crash);
  sl.registerSingleton<PerformanceMonitor>(performance);
  sl.registerSingleton<ObservabilityFacade>(
    ObservabilityFacade(
      logger: logger,
      crash: crash,
      performance: performance,
      analytics: analytics,
    ),
  );

  return config;
}
