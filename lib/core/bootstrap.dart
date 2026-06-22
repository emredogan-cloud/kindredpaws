/// Application bootstrap: builds [AppConfig] from the environment and registers
/// the concrete service implementations in the [ServiceLocator]. Defaults to
/// fully-offline mock adapters so the app runs with zero credentials.
///
/// This is Phase-0 provisioning wiring. No gameplay loop is started here.
library;

import 'app_config.dart';
import 'service_locator.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import '../services/firebase_backend.dart';
import '../services/remote_config_service.dart';
import '../heartmind/heartmind_service.dart';

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
  sl.registerSingleton<AnalyticsService>(InMemoryAnalyticsService());
  sl.registerSingleton<HeartmindService>(const StubHeartmind());

  return config;
}
