import 'package:flutter/material.dart';

import 'core/app_config.dart';
import 'core/bootstrap.dart';
import 'core/kindred_terms.dart';
import 'core/service_locator.dart';
import 'data/kindred_save_state.dart';
import 'heartmind/heartmind_service.dart';
import 'render/pet_renderer.dart';
import 'services/analytics_service.dart';
import 'services/backend_service.dart';
import 'tooling/llm_cost_model.dart';

void main() {
  final config = bootstrap();
  runApp(KindredPawsApp(config: config));
}

/// Root application widget.
///
/// NOTE: This is the **Phase-0 pre-production shell**. It renders a provisioning
/// status screen — which services are live vs mocked, the save schema version,
/// the locked LLM models, and the LLM cost-gate result — plus a placeholder pet
/// to validate the render seam. It contains **no gameplay**; Phase 1 replaces
/// the home screen with the core-loop prototype.
class KindredPawsApp extends StatelessWidget {
  const KindredPawsApp({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: KindredTerms.gameTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C8EAD)),
      ),
      home: ProvisioningStatusPage(config: config),
    );
  }
}

class ProvisioningStatusPage extends StatelessWidget {
  const ProvisioningStatusPage({
    required this.config,
    this.renderer = const PlaceholderPetRenderer(),
    super.key,
  });

  final AppConfig config;
  final PetRenderer renderer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backend = ServiceLocator.instance.get<BackendService>();
    final heartmind = ServiceLocator.instance.get<HeartmindService>();
    final analytics = ServiceLocator.instance.get<AnalyticsService>();
    final cost = computeLlmCost(LlmCostScenarios.mvpLaunch);

    final rows = <(String, String)>[
      ('Environment', config.environmentLabel),
      (
        'Backend',
        '${config.backendMode.name} '
            '(${backend.isAuthoritative ? 'authoritative' : 'mock'})',
      ),
      (
        'Heartmind live chat',
        config.heartmindLiveChatEnabled ? 'ON' : 'OFF (deferred)',
      ),
      ('Heartmind backend', heartmind.runtimeType.toString()),
      ('Runtime LLM', HeartmindModels.runtimeModel),
      ('Pre-gen LLM', HeartmindModels.pregenModel),
      ('Save schema', 'v${KindredSaveState.currentSchemaVersion}'),
      (
        'Analytics events',
        '${AnalyticsEvent.values.length} (${analytics.runtimeType})',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: const Text('${KindredTerms.gameTitle} · Pre-production'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: renderer.build(
                  context,
                  mood: PetMood.content,
                  lifeStage: 'Pup/Kit',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Engineering provisioning status',
                key: const Key('provisioning-status'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    for (final r in rows)
                      ListTile(
                        dense: true,
                        title: Text(r.$1),
                        trailing: Text(r.$2),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: cost.passesGuardGate
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'LLM cost gate (G4): ${(cost.ratio * 100).toStringAsFixed(1)}% '
                    'of ARPDAU — ${cost.passesGuardGate ? 'PASS' : 'FAIL'}',
                    key: const Key('cost-gate-banner'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
