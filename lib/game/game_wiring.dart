/// Builds a [GameController] from the registered services + a [LocalSaveStore].
/// Used by `main()` (with the persistent prefs store) and constructible directly
/// in tests (with an in-memory store + an injected clock).
library;

import '../core/service_locator.dart';
import '../data/save_repository.dart';
import '../services/analytics_service.dart';
import '../services/backend_service.dart';
import '../services/beta_feedback_pipeline.dart';
import '../services/feedback_service.dart';
import '../services/live_ops.dart';
import '../services/home_widget_service.dart';
import '../services/notification_scheduler.dart';
import '../services/observability.dart';
import '../services/remote_config_service.dart';
import '../services/share_service.dart';
import '../services/status_snapshot_service.dart';
import '../heartmind/local_heartmind.dart';
import 'controller/game_controller.dart';
import 'sim/game_simulation.dart';
import 'sim/sim_config.dart';

GameController createGameController({
  required ServiceLocator sl,
  required LocalSaveStore store,
  int Function()? clock,
}) {
  final config = SimConfig.fromRemoteConfig(sl.get<RemoteConfigService>());
  final repo = SaveRepository(
    local: store,
    backend: sl.get<BackendService>(),
    // Right-to-be-forgotten: deleteAccount resets the analytics identifiers so
    // post-deletion telemetry can't link back to the wiped account (§11.2).
    onIdentityReset: () async => sl.get<AnalyticsService>().resetIdentifiers(),
  );
  return GameController(
    sim: GameSimulation(config),
    config: config,
    repo: repo,
    observability: sl.get<ObservabilityFacade>(),
    notifications: sl.get<NotificationScheduler>(),
    snapshots: sl.get<StatusSnapshotService>(),
    homeWidget: sl.get<HomeWidgetService>(),
    heartmind: sl.get<Heartmind>(),
    share: sl.get<ShareService>(),
    feedback: sl.get<FeedbackService>(),
    betaFeedback: sl.get<BetaFeedbackPipeline>(),
    liveOps: sl.get<LiveOps>(),
    clock: clock,
  );
}
