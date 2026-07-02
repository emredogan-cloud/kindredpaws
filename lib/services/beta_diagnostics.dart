/// Closed-beta diagnostics + support export (P4-7). A **PII-free** snapshot of
/// the app's configuration + live-flag state that a beta tester can attach to a
/// bug report, and that the founder reads to triage an incident. It carries NO
/// player data — no pet name, no account id, no save contents — only build
/// config, the compliance posture, the subscription flag, the live kill-switch
/// state, and schema/content versions. Authority: GAME_MASTER_EXECUTION_ROADMAP
/// G3 (closed beta), GAME_TECHNICAL_SYSTEMS §10.
library;

import '../core/app_config.dart';
import '../core/compliance_config.dart';
import '../data/kindred_save_state.dart';
import '../monetization/monetization_controller.dart';
import 'live_ops.dart';

/// A PII-free diagnostic snapshot for support / incident triage.
class DiagnosticReport {
  const DiagnosticReport({
    required this.env,
    required this.backend,
    required this.billing,
    required this.renderer,
    required this.liveChatFlag,
    required this.ageBand,
    required this.childSafe,
    required this.subscriber,
    required this.contentVersion,
    required this.saveSchemaVersion,
    required this.killedFeatures,
  });

  final String env;
  final String backend;
  final String billing;
  final String renderer;
  final bool liveChatFlag;
  final String ageBand;
  final bool childSafe;
  final bool subscriber;
  final int contentVersion;
  final int saveSchemaVersion;

  /// The features currently disabled by a live kill-switch (incident state).
  final List<String> killedFeatures;

  Map<String, Object?> toJson() => {
    'env': env,
    'backend': backend,
    'billing': billing,
    'renderer': renderer,
    'liveChat': liveChatFlag,
    'ageBand': ageBand,
    'childSafe': childSafe,
    'subscriber': subscriber,
    'contentVersion': contentVersion,
    'saveSchemaVersion': saveSchemaVersion,
    'killedFeatures': killedFeatures,
  };

  /// A compact copy-paste block for a beta bug report (PII-free).
  String exportText() =>
      'KindredPaws diagnostics (no personal data)\n'
      '  env=$env · backend=$backend · billing=$billing · renderer=$renderer\n'
      '  compliance: ageBand=$ageBand childSafe=$childSafe liveChatFlag=$liveChatFlag\n'
      '  subscriber=$subscriber · saveSchema=v$saveSchemaVersion · content=v$contentVersion\n'
      '  killed=${killedFeatures.isEmpty ? "(none)" : killedFeatures.join(",")}';
}

/// Builds a [DiagnosticReport] from the registered services. PII-free by
/// construction — it only reads config + flags + versions, never player data.
class BetaDiagnostics {
  const BetaDiagnostics({
    required this.appConfig,
    required this.compliance,
    required this.monetization,
    required this.liveOps,
  });

  final AppConfig appConfig;
  final ComplianceConfig compliance;
  final MonetizationController monetization;
  final LiveOps liveOps;

  DiagnosticReport snapshot() => DiagnosticReport(
    env: appConfig.environmentLabel,
    backend: appConfig.backendMode.name,
    billing: appConfig.billingMode.name,
    renderer: appConfig.petRendererBackend.name,
    liveChatFlag: appConfig.heartmindLiveChatEnabled,
    ageBand: compliance.ageBand.name,
    childSafe: compliance.isChildSafe,
    subscriber: monetization.entitlements.foreverFriends,
    contentVersion: liveOps.contentVersion,
    saveSchemaVersion: KindredSaveState.currentSchemaVersion,
    killedFeatures: [
      for (final f in LiveFeature.values)
        if (liveOps.isKilled(f)) f.key,
    ],
  );
}
