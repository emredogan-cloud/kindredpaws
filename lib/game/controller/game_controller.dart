/// The app-facing game controller (P1-3b). Owns the runtime save, drives the
/// deterministic [GameSimulation], persists via [SaveRepository], seeds the
/// Memory Book, and schedules warm notifications. A [ChangeNotifier] so the UI
/// rebuilds on change. The clock is injectable so tests stay deterministic.
library;

import 'package:flutter/foundation.dart';

import '../../data/kindred_save_state.dart';
import '../../data/save_repository.dart';
import '../../heartmind/memory_fact.dart';
import '../../services/analytics_service.dart';
import '../../services/notification_scheduler.dart';
import '../../services/observability.dart';
import '../model/mood.dart';
import '../model/pet_state.dart';
import '../model/species.dart';
import '../sim/bond_engine.dart';
import '../sim/game_simulation.dart';
import '../sim/interaction.dart';

class GameController extends ChangeNotifier {
  GameController({
    required this.sim,
    required this.repo,
    required this.observability,
    required this.notifications,
    int Function()? clock,
    String Function()? idGenerator,
  }) : _now = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _idGenerator =
           idGenerator ??
           (() => 'pet-${DateTime.now().microsecondsSinceEpoch}');

  final GameSimulation sim;
  final SaveRepository repo;
  final ObservabilityFacade observability;
  final NotificationScheduler notifications;
  final int Function() _now;
  final String Function() _idGenerator;

  KindredSaveState? _save;
  SessionInteractions _session = SessionInteractions.empty;
  Mood _mood = Mood.content;
  bool _loading = true;

  /// Transient warm line for the UI to surface (never guilt). Null after read.
  String? lastMessage;

  /// The most recent interaction's outcome (for transient UI flourishes).
  InteractionOutcome? lastOutcome;

  bool get loading => _loading;
  bool get hasPet => _save != null;
  PetState? get pet => _save?.pet;
  Mood get mood => _mood;
  List<MemoryFact> get facts => _save?.facts ?? const [];

  /// Load the local save (migrating forward), resolve offline catch-up, and
  /// surface the pet. If there's no save, [hasPet] stays false → Rescue Day.
  Future<void> load() async {
    final res = await repo.load();
    final state = res.valueOrNull;
    if (state != null) {
      _save = state;
      _resumeSession();
      await _persist();
    }
    _loading = false;
    notifyListeners();
  }

  /// Rescue Day adoption: create the pet, seed the first memories, schedule
  /// warm notifications, persist. The emotional core of onboarding (§13).
  Future<void> adopt({required Species species, required String name}) async {
    final now = _now();
    final cleaned = name.trim();
    final pet = PetState.newlyRescued(
      petId: _idGenerator(),
      species: species,
      name: cleaned.isEmpty ? species.defaultName : cleaned,
      nowMs: now,
    );
    _save = KindredSaveState(
      pet: pet,
      ledger: BondLedger.empty,
      facts: _seedMemories(pet, now),
    );
    _session = SessionInteractions.empty;
    _mood = sim.moodOf(pet.meters, recentAttentionBonus: 100);
    observability.event(AnalyticsEvent.rescueDayComplete, {
      'species': species.id,
    });
    await notifications.scheduleDailyPresence(petName: pet.name, fromMs: now);
    await _persist();
    lastMessage = 'Welcome home, ${pet.name}! 💛';
    notifyListeners();
  }

  /// Perform a care interaction (feed/clean/play) and surface warm feedback.
  Future<void> interact(CareInteraction interaction) async {
    final save = _save;
    if (save == null) return;
    final outcome = sim.interact(
      state: save.pet,
      interaction: interaction,
      session: _session,
      ledger: save.ledger,
      nowMs: _now(),
    );
    _save = save.copyWith(
      pet: outcome.state,
      ledger: outcome.ledger,
      facts: outcome.grew
          ? _withGrowthMemory(save.facts, outcome.state, _now())
          : save.facts,
    );
    _session = outcome.session;
    _mood = outcome.mood;
    lastOutcome = outcome;
    lastMessage = _warmLine(interaction, outcome);

    observability.event(AnalyticsEvent.careAction, {
      'verb': interaction.id,
      'bond_awarded': outcome.bondAwarded,
      'needed': outcome.wasNeeded,
    });
    if (outcome.bondAwarded > 0) {
      observability.event(AnalyticsEvent.bondChange, {
        'value': outcome.state.bond.value,
      });
    }
    if (outcome.streakIncremented) {
      observability.event(AnalyticsEvent.streakEvent, {
        'count': outcome.state.careStreak.count,
      });
    }
    if (outcome.grew) {
      observability.event(AnalyticsEvent.lifeStageUp, {
        'stage': outcome.state.lifeStage.id,
      });
    }
    await _persist();
    notifyListeners();
  }

  /// Clears [lastMessage] after the UI shows it.
  void consumeMessage() => lastMessage = null;

  void _resumeSession() {
    final save = _save!;
    final resume = sim.resolveOnResume(
      state: save.pet,
      ledger: save.ledger,
      nowMs: _now(),
    );
    _save = save.copyWith(
      pet: resume.state,
      ledger: resume.ledger,
      facts: resume.grewWhileAway
          ? _withGrowthMemory(save.facts, resume.state, _now())
          : save.facts,
    );
    _session = SessionInteractions.empty;
    _mood = resume.mood;
    observability.event(AnalyticsEvent.sessionStart, {
      'offline_hours': resume.offlineHours.round(),
    });
  }

  Future<void> _persist() async {
    final save = _save;
    if (save == null) return;
    final res = await repo.save(save);
    if (res.isErr) {
      observability.recordError(
        res.errorOrNull ?? 'save failed',
        null,
        context: 'persist',
      );
    }
  }

  /// Seeds the first Memory Book entries (templated, closed-set, child-safe —
  /// never free-text from the player). This is the "it remembers" seed (§13.2).
  List<MemoryFact> _seedMemories(PetState pet, int nowMs) {
    final likes = pet.species == Species.puppy
        ? 'chasing the ball'
        : 'pouncing on the feather toy';
    return [
      MemoryFact(
        key: FactKey.importantDate,
        value: 'Rescue Day — the day we met',
        source: FactSource.onboarding,
        confidence: 1,
        createdAtMs: nowMs,
      ),
      MemoryFact(
        key: FactKey.likesActivity,
        value: likes,
        source: FactSource.onboarding,
        confidence: 1,
        createdAtMs: nowMs,
      ),
    ];
  }

  List<MemoryFact> _withGrowthMemory(
    List<MemoryFact> existing,
    PetState pet,
    int nowMs,
  ) => [
    ...existing,
    MemoryFact(
      key: FactKey.importantDate,
      value: 'Grew into a ${pet.lifeStage.displayName}',
      source: FactSource.onboarding,
      confidence: 1,
      createdAtMs: nowMs,
    ),
  ];

  String _warmLine(CareInteraction interaction, InteractionOutcome o) {
    final name = o.state.name;
    if (o.comfortBeat) return '$name feels so much better with you here 💛';
    return switch (interaction) {
      CareInteraction.feed => '$name gobbled it right up! 🍖',
      CareInteraction.clean => '$name feels fresh and happy 🫧',
      CareInteraction.play => '$name had the best time playing! 🎾',
    };
  }
}
