/// Application bootstrap: builds [AppConfig] from the environment and registers
/// the concrete service implementations in the [ServiceLocator]. Defaults to
/// fully-offline mock adapters so the app runs with zero credentials.
///
/// This is Phase-0 provisioning wiring. No gameplay loop is started here.
library;

import 'app_config.dart';
import 'compliance_config.dart';
import 'performance_budgets.dart';
import 'service_locator.dart';
import '../monetization/ad_config.dart';
import '../monetization/ad_service.dart';
import '../monetization/ads_controller.dart';
import '../monetization/monetization_controller.dart';
import '../monetization/paywall_controller.dart';
import '../render/pet_renderer.dart';
import '../render/pet_renderer_factory.dart';
import '../render/rive_pet_renderer.dart' show RiveDiagnostic;
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import '../services/beta_diagnostics.dart';
import '../services/beta_feedback_pipeline.dart';
import '../services/experiments.dart';
import '../services/crash_reporter.dart';
import '../services/feedback_service.dart';
import '../services/feel_service.dart';
import '../services/firebase_backend.dart';
import '../services/logger.dart';
import '../services/notification_scheduler.dart';
import '../services/observability.dart';
import '../services/performance_monitor.dart';
import '../services/prefs_service.dart';
import '../services/live_ops.dart';
import '../services/remote_config_service.dart';
import '../services/home_widget_service.dart';
import '../services/share_service.dart';
import '../monetization/billing_service.dart';
import '../services/status_snapshot_service.dart';
import '../heartmind/heartmind_service.dart';
import '../heartmind/local_heartmind.dart';

AppConfig bootstrap({
  ServiceLocator? locator,
  PetRendererBackend fallbackRenderer = PetRendererBackend.placeholder,
}) {
  final sl = locator ?? ServiceLocator.instance;
  final config = AppConfig.fromEnvironment(fallbackRenderer: fallbackRenderer);

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
  // Feel layer (Product Evolution E1): player prefs + gated sound/haptics.
  // In-memory prefs + a silent audio sink keep dev/CI deterministic; main()
  // swaps the SharedPreferences + audioplayers implementations in production.
  final prefsService = InMemoryPrefsService();
  sl.registerSingleton<PrefsService>(prefsService);
  sl.registerSingleton<FeelService>(
    FeelService(prefs: prefsService, audio: NoopAudioSink()),
  );
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

  // Observability sinks (P1-2 leaves). In-memory/console impls are fully
  // functional for dev/CI; the Firebase-backed bodies drop in once provisioned
  // (see firebase_provisioning.dart). The ObservabilityFacade + every service
  // that reads it are built in [rewireDerivedServices] below, so the SAME wiring
  // re-runs after the Firebase swap (no derived service left on a dead sink).
  final logger = InMemoryLogger();
  final crash = InMemoryCrashReporter();
  sl.registerSingleton<AnalyticsService>(InMemoryAnalyticsService());
  sl.registerSingleton<Logger>(logger);
  sl.registerSingleton<CrashReporter>(crash);
  sl.registerSingleton<PerformanceMonitor>(InMemoryPerformanceMonitor());
  // Ad seam leaf (P4-6); the ethical AdsController is built in the derived layer.
  sl.registerSingleton<AdService>(const NoopAdService());

  // Build the derived layer (the ObservabilityFacade + everything reading it)
  // from the leaves just registered. registerFirebaseServices() calls this exact
  // function again after swapping the leaves to Firebase adapters, so telemetry,
  // the impact ledger, diagnostics, and the live kill-switches can never be left
  // pointing at the boot-time in-memory sinks (P5 audit fix).
  rewireDerivedServices(sl);

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

/// (Re)builds the **derived service layer** — the [ObservabilityFacade] and
/// everything that depends on it — from the leaf singletons currently registered
/// in [sl]. Called once by [bootstrap] over the in-memory leaves, and again by
/// `registerFirebaseServices` after the leaves are swapped to the Firebase
/// adapters. Routing all of this through one function is the fix for the
/// stale-dependency bug class (P5 audit): because these services capture their
/// dependencies at construction, anything that reads a leaf MUST be rebuilt when
/// the leaf is swapped — otherwise it keeps writing to the dead in-memory sink.
/// The [SessionHealthMonitor] is preserved across a re-wire so a boot-time crash
/// signal isn't lost.
void rewireDerivedServices(ServiceLocator sl) {
  final sessionHealth = sl.isRegistered<ObservabilityFacade>()
      ? sl.get<ObservabilityFacade>().sessionHealth
      : null;

  // The single fan-out point for all telemetry/crash/perf. Rebuilt over the
  // currently-registered sinks (in-memory at boot, Firebase after the swap).
  final observability = ObservabilityFacade(
    logger: sl.get<Logger>(),
    crash: sl.get<CrashReporter>(),
    performance: sl.get<PerformanceMonitor>(),
    analytics: sl.get<AnalyticsService>(),
    sessionHealth: sessionHealth,
  );
  sl.registerSingleton<ObservabilityFacade>(observability);

  // Performance budgets (P5-6): the runtime gate over the canonical ceilings.
  sl.registerSingleton<PerformanceBudgetMonitor>(
    PerformanceBudgetMonitor(observability: observability),
  );

  // Monetization (P4-5): owns Entitlements + the impact ledger; the single
  // PII-free emit point for monetizationEvent / compassionCoinMint. Reads the
  // (now-authoritative) BackendService so the ledger persists in production.
  sl.registerSingleton<MonetizationController>(
    MonetizationController(
      billing: sl.get<BillingService>(),
      observability: observability,
      backend: sl.get<BackendService>(),
    ),
  );

  // Ads (P4-6): the ethical coordinator. Reads the live LiveOps/RemoteConfig so
  // the founder's ad kill-switch + caps take effect after provisioning.
  sl.registerSingleton<AdsController>(
    AdsController(
      ads: sl.get<AdService>(),
      adConfig: sl.get<AdConfig>(),
      liveOps: sl.get<LiveOps>(),
      remoteConfig: sl.get<RemoteConfigService>(),
      observability: observability,
    ),
  );

  // Closed-beta diagnostics (P4-7): reads the live LiveOps so the support/
  // incident snapshot reflects the real kill-switch state, not the offline one.
  sl.registerSingleton<BetaDiagnostics>(
    BetaDiagnostics(
      appConfig: sl.get<AppConfig>(),
      compliance: sl.get<ComplianceConfig>(),
      monetization: sl.get<MonetizationController>(),
      liveOps: sl.get<LiveOps>(),
    ),
  );

  // Beta feedback loop (P5-5): ingest → sentiment → crash/diagnostic correlation
  // → triage → PII-free telemetry, over the authoritative feedback stream.
  sl.registerSingleton<BetaFeedbackPipeline>(
    BetaFeedbackPipeline(
      feedback: sl.get<FeedbackService>(),
      diagnostics: sl.get<BetaDiagnostics>(),
      observability: observability,
    ),
  );

  // A/B experiments (P5-3): variant assignment + exposure telemetry.
  sl.registerSingleton<Experiments>(
    Experiments(liveOps: sl.get<LiveOps>(), observability: observability),
  );

  // Paywall coordinator (P5-4): the purchase-funnel diagnostics + the pricing-
  // framing experiment over the (cosmetic/QoL-only) catalogue.
  sl.registerSingleton<PaywallController>(
    PaywallController(
      monetization: sl.get<MonetizationController>(),
      experiments: sl.get<Experiments>(),
      observability: observability,
      auth: sl.get<AuthService>(),
    ),
  );
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
