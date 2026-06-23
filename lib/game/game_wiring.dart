/// Builds a [GameController] from the registered services + a [LocalSaveStore].
/// Used by `main()` (with the persistent prefs store) and constructible directly
/// in tests (with an in-memory store + an injected clock).
library;

import '../core/service_locator.dart';
import '../data/save_repository.dart';
import '../services/backend_service.dart';
import '../services/notification_scheduler.dart';
import '../services/observability.dart';
import '../services/remote_config_service.dart';
import 'controller/game_controller.dart';
import 'sim/game_simulation.dart';
import 'sim/sim_config.dart';

GameController createGameController({
  required ServiceLocator sl,
  required LocalSaveStore store,
  int Function()? clock,
}) {
  final sim = GameSimulation(
    SimConfig.fromRemoteConfig(sl.get<RemoteConfigService>()),
  );
  final repo = SaveRepository(local: store, backend: sl.get<BackendService>());
  return GameController(
    sim: sim,
    repo: repo,
    observability: sl.get<ObservabilityFacade>(),
    notifications: sl.get<NotificationScheduler>(),
    clock: clock,
  );
}
