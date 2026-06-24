/// Application bootstrap: builds [AppConfig] from the environment and registers
/// the concrete service implementations in the [ServiceLocator]. Defaults to
/// fully-offline mock adapters so the app runs with zero credentials.
///
/// This is Phase-0 provisioning wiring. No gameplay loop is started here.
library;

import 'app_config.dart';
import 'compliance_config.dart';
import 'service_locator.dart';
import '../monetization/ad_config.dart';
import '../monetization/ad_service.dart';
import '../monetization/ads_controller.dart';
import '../monetization/monetization_controller.dart';
import '../render/pet_renderer.dart';
import '../render/pet_renderer_factory.dart';
import '../render/rive_pet_renderer.dart' show RiveDiagnostic;
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import '../services/crash_reporter.dart';
import '../services/feedback_service.dart';
import '../services/firebase_backend.dart';
import '../services/logger.dart';
import '../services/notification_scheduler.dart';
import '../services/observability.dart';
import '../services/performance_monitor.dart';
import '../services/live_ops.dart';
import '../services/remote_config_service.dart';
import '../services/home_widget_service.dart';
import '../services/share_service.dart';
import '../monetization/billing_service.dart';
import '../services/status_snapshot_service.dart';
import '../heartmind/heartmind_service.dart';
import '../heartmind/local_heartmind.dart';

AppConfig bootstrap({ServiceLocator? locator}) {
  final sl = locator ?? ServiceLocator.instance;
  final config = AppConfig.fromEnvironment();

  sl.registerSingleton<AppConfig>(config);

  // Compliance policy (P3-6a). Ships as the fully-protective child-safe default
  // (unknown band ⇒ treated as under-13, D-007): no free-text, templated-only
  // dialogue, COPPA/GDPR-K ad flags on. The flow that establishes a real age
  // band is the G3 legal-gated deliverable (Open Decision #9) — until then every
  // user is treated as a child. The ad-network kids-config is derived from it so
  // the COPPA posture is decided in exactly one place.
  const compliance = ComplianceConfig();
  sl.registerSingleton<ComplianceConfig>(compliance);
  sl.registerSingleton<AdConfig>(AdConfig.fromCompliance(compliance));

  sl.registerSingleton<AuthService>(GuestAuthService());
  sl.registerSingleton<BackendService>(
    config.backendMode == BackendMode.firebase
        ? FirebaseBackendService()
        : InMemoryBackendService(),
  );
  sl.registerSingleton<RemoteConfigService>(const DefaultRemoteConfig());
  // LiveOps control plane (P4-3): kill-switches + %-rollout over Remote Config.
  sl.registerSingleton<LiveOps>(LiveOps(sl.get<RemoteConfigService>()));
  // The on-device hybrid Heartmind (P2-2): reviewed bank + closed-set memory
  // injection + safety. $0 runtime tokens, no network. Replaces the P0 stub.
  final heartmind = LocalHeartmind();
  sl.registerSingleton<HeartmindService>(heartmind);
  sl.registerSingleton<Heartmind>(heartmind);
  sl.registerSingleton<NotificationScheduler>(InMemoryNotificationScheduler());
  sl.registerSingleton<StatusSnapshotService>(InMemoryStatusSnapshotService());
  sl.registerSingleton<HomeWidgetService>(NoopHomeWidgetService());
  sl.registerSingleton<ShareService>(const NoopShareService());
  // Closed-beta feedback hook (P3-7). Noop default keeps dev/CI offline; the
  // backend-backed impl is swapped in once a real backend is wired (below).
  sl.registerSingleton<FeedbackService>(const NoopFeedbackService());
  // Billing seam (P3-5). Noop default = offline/deterministic; the real
  // RevenueCat impl is a post-provisioning swap (no SDK dependency yet).
  // Billing seam (P3-5 / P4-5): RevenueCat when KP_BILLING=revenuecat (a gated
  // seam until the SDK + store products are provisioned), else the offline Noop.
  sl.registerSingleton<BillingService>(
    config.billingMode == BillingMode.revenuecat
        ? const RevenueCatBillingService()
        : NoopBillingService(),
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
  final observability = ObservabilityFacade(
    logger: logger,
    crash: crash,
    performance: performance,
    analytics: analytics,
  );
  sl.registerSingleton<ObservabilityFacade>(observability);

  // Monetization (P4-5): orchestrates the billing seam + the impact ledger, owns
  // the current Entitlements (premium gating), and is the single PII-free emit
  // point for monetizationEvent / compassionCoinMint. The UI listens to it.
  sl.registerSingleton<MonetizationController>(
    MonetizationController(
      billing: sl.get<BillingService>(),
      observability: observability,
      backend: sl.get<BackendService>(),
    ),
  );

  // Ads (P4-6): the child-safe ad seam + the ethical coordinator (rewarded-first,
  // capped, never mid-emotion, kid-flags from AdConfig, killable via LiveOps).
  sl.registerSingleton<AdService>(const NoopAdService());
  sl.registerSingleton<AdsController>(
    AdsController(
      ads: sl.get<AdService>(),
      adConfig: sl.get<AdConfig>(),
      liveOps: sl.get<LiveOps>(),
      remoteConfig: sl.get<RemoteConfigService>(),
      observability: observability,
    ),
  );

  // Pet renderer (P3-2). Registered after observability so the Rive seam's
  // load-timing + failure diagnostics route to the structured log + a crash
  // breadcrumb (an `error`-class code surfaces a malformed rig loudly in dev;
  // it never crashes play — the seam falls back to the stand-in).
  sl.registerSingleton<PetRenderer>(
    createPetRenderer(
      config.petRendererBackend,
      riveAsset: config.riveAssetPath,
      onDiagnostic: riveDiagnosticSink(logger, crash),
    ),
  );

  return config;
}

/// Routes [RivePetRenderer] rig diagnostics to the observability stack: every
/// code drops a crash breadcrumb; `*_failed` / `*_missing` codes (a malformed
/// or absent rig) log at `error` so they surface loudly in dev, everything else
/// (e.g. `rive_loaded` timing) at `info`. Extracted + named so it is unit-tested
/// even though CI runs the placeholder backend (the rive seam never activates).
RiveDiagnostic riveDiagnosticSink(Logger logger, CrashReporter crash) {
  return (String code, {Map<String, Object?> fields = const {}}) {
    crash.addBreadcrumb('rive:$code');
    if (code.endsWith('_failed') || code.endsWith('_missing')) {
      logger.error('rive: $code', fields: fields);
    } else {
      logger.info('rive: $code', fields: fields);
    }
  };
}
