/// The app-facing game controller (P1-3b). Owns the runtime save, drives the
/// deterministic [GameSimulation], persists via [SaveRepository], seeds the
/// Memory Book, and schedules warm notifications. A [ChangeNotifier] so the UI
/// rebuilds on change. The clock is injectable so tests stay deterministic.
library;

import 'package:flutter/foundation.dart';

import '../../data/kindred_save_state.dart';
import '../../data/save_repository.dart';
import '../../heartmind/dialogue_selector.dart';
import '../../heartmind/heartmind_intent.dart';
import '../../heartmind/local_heartmind.dart';
import '../../heartmind/memory_fact.dart';
import '../../heartmind/personality.dart';
import '../../heartmind/presence.dart';
import '../../keepsake/keepsake.dart';
import '../../keepsake/keepsake_factory.dart';
import '../../render/pet_renderer.dart';
import '../../services/analytics_service.dart';
import '../../services/home_widget_service.dart';
import '../../services/notification_scheduler.dart';
import '../../services/observability.dart';
import '../../services/status_snapshot_service.dart';
import '../model/bond.dart';
import '../model/mood.dart';
import '../model/pet_state.dart';
import '../model/pet_status_snapshot.dart';
import '../model/species.dart';
import '../sim/bond_engine.dart';
import '../sim/game_simulation.dart';
import '../sim/interaction.dart';
import '../sim/sim_config.dart';

class GameController extends ChangeNotifier {
  GameController({
    required this.sim,
    required this.config,
    required this.repo,
    required this.observability,
    required this.notifications,
    required this.snapshots,
    required this.homeWidget,
    required this.heartmind,
    int Function()? clock,
    String Function()? idGenerator,
  }) : _now = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _idGenerator =
           idGenerator ??
           (() => 'pet-${DateTime.now().microsecondsSinceEpoch}');

  final GameSimulation sim;
  final SimConfig config;
  final SaveRepository repo;
  final ObservabilityFacade observability;
  final NotificationScheduler notifications;
  final StatusSnapshotService snapshots;
  final HomeWidgetService homeWidget;
  final Heartmind heartmind;
  final int Function() _now;
  final String Function() _idGenerator;

  static const AmbientScheduler _ambient = AmbientScheduler();
  static const KeepsakeFactory _keepsakes = KeepsakeFactory();
  PersonalityProfile _personality = PersonalityProfile.neutral;
  int _ambientTick = 0;

  /// The collected Keepsake cards (the emotional scrapbook), newest first.
  List<Keepsake> get keepsakes =>
      _save == null ? const [] : _save!.keepsakes.reversed.toList();

  /// The pet's current spoken line (from Heartmind — greeting/return/care/
  /// callback/idle). Warm, never guilt. Null before the pet first speaks.
  String? petLine;

  /// A transient ambient idle expression (set by [nudgeAmbient]); cleared by a
  /// care interaction.
  PetEmotion? ambientEmotion;

  KindredSaveState? _save;
  SessionInteractions _session = SessionInteractions.empty;
  Mood _mood = Mood.content;
  bool _loading = true;

  /// Transient warm line for the UI to surface (never guilt). Null after read.
  String? lastMessage;

  /// The most recent interaction's outcome (for transient UI flourishes).
  InteractionOutcome? lastOutcome;

  /// The most recent care verb (drives the pet's reaction expression). Null
  /// after adopt/resume (the pet shows its resting expression for the mood).
  CareInteraction? lastInteraction;

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
      keepsakes: [_keepsakes.rescueDay(pet, now)], // the first card
    );
    _session = SessionInteractions.empty;
    lastInteraction = null;
    ambientEmotion = null;
    _personality = PersonalityProfile.neutral;
    _mood = sim.moodOf(pet.meters, recentAttentionBonus: 100);
    observability.event(AnalyticsEvent.rescueDayComplete, {
      'species': species.id,
    });
    await notifications.scheduleDailyPresence(petName: pet.name, fromMs: now);
    await _persist();
    lastMessage = 'Welcome home, ${pet.name}! 💛';
    _say(HeartmindIntent.greeting); // the pet's first words
    notifyListeners();
  }

  /// Perform a care interaction (feed/clean/play) and surface warm feedback.
  Future<void> interact(CareInteraction interaction) async {
    final save = _save;
    if (save == null) return;
    final preStage = save.pet.bond.stage;
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
    _captureKeepsakes(outcome, preStage);
    _session = outcome.session;
    _mood = outcome.mood;
    lastOutcome = outcome;
    lastInteraction = interaction;
    ambientEmotion = null; // a reaction takes over from any ambient idle
    lastMessage = _warmLine(interaction, outcome);
    _driftPersonality(interaction);
    // The pet speaks: a milestone celebration if it grew, else a care ack.
    _say(outcome.grew ? HeartmindIntent.milestone : HeartmindIntent.careAck);

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
    lastInteraction = null;
    ambientEmotion = null;
    _mood = resume.mood;
    observability.event(AnalyticsEvent.sessionStart, {
      'offline_hours': resume.offlineHours.round(),
    });
    // The pet greets you back — a "returning" beat after a real absence,
    // otherwise a normal greeting; a memory callback when one is available.
    final intent = resume.offlineHours >= config.graceHours
        ? HeartmindIntent.returning
        : HeartmindIntent.greeting;
    _say(intent, tryCallback: true);
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
    await _publishSnapshot(save);
  }

  /// Writes the single shared status snapshot (§6.1) that feeds the notification
  /// scheduler and the home widget. Best-effort; never blocks the game.
  Future<void> _publishSnapshot(KindredSaveState save) async {
    final snapshot = PetStatusSnapshot.fromPet(
      pet: save.pet,
      mood: _mood,
      config: config,
      nowMs: _now(),
    );
    await snapshots.write(snapshot);
    await homeWidget.update(snapshot); // push to the native home widget
  }

  /// The latest published status snapshot (for the in-app status surfaces).
  PetStatusSnapshot? get statusSnapshot => snapshots.latest;

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

  // ---- Companion Presence (P2-4) ----

  /// The current coarse mood mapped to the render layer.
  PetMood get petMood => switch (_mood) {
    Mood.joyful => PetMood.joyful,
    Mood.content => PetMood.content,
    Mood.wistful => PetMood.wistful,
    Mood.low => PetMood.low,
  };

  DayPart get dayPart =>
      DayPart.fromHour((_now() ~/ Duration.millisecondsPerHour) % 24);

  HeartmindContext _contextFor(HeartmindIntent intent) {
    final pet = _save!.pet;
    return HeartmindContext(
      intent: intent,
      lifeStage: pet.lifeStage.id,
      mood: _mood.name,
      bondStage: pet.bond.stage.displayName,
      personalityKey: _personality.bankKey,
      facts: _save!.facts,
    );
  }

  /// The pet says something for [intent]. With [tryCallback], it first attempts
  /// the "it remembered me" beat (a real memory callback) when a fact exists,
  /// falling back to the requested intent. Sets [petLine].
  void _say(HeartmindIntent intent, {bool tryCallback = false}) {
    if (_save == null) return;
    if (tryCallback && _save!.facts.isNotEmpty) {
      final callback = heartmind.speak(
        _contextFor(HeartmindIntent.memoryCallback),
      );
      if (callback.isCallback && !callback.isFallback) {
        petLine = callback.text;
        if (callback.surfacedFacts.isNotEmpty) {
          observability.event(AnalyticsEvent.memoryCallback, {
            'facts': callback.surfacedFacts.length,
          });
          // The "it remembered me" beat earns a Keepsake (Virality #2).
          _collect(
            _keepsakes.memoryCallback(_save!.pet, callback.text, _now()),
          );
        }
        return;
      }
    }
    petLine = heartmind.speak(_contextFor(intent)).text;
  }

  /// Tap-the-pet ambient life: a fresh idle expression (weighted by mood +
  /// daypart) + an idle line. Makes the pet feel alive between care actions.
  void nudgeAmbient() {
    if (_save == null) return;
    _ambientTick++;
    lastInteraction = null; // ambient idle takes over from a stale reaction
    ambientEmotion = _ambient.idleEmotion(
      mood: petMood,
      dayPart: dayPart,
      tick: _ambientTick,
    );
    _say(HeartmindIntent.idle);
    notifyListeners();
  }

  /// Personality drifts slowly with how you play (deterministic, bounded).
  void _driftPersonality(CareInteraction interaction) {
    final dial = switch (interaction) {
      CareInteraction.play => PersonalityDial.playfulness,
      CareInteraction.feed => PersonalityDial.cuddliness,
      CareInteraction.clean => PersonalityDial.bravery,
    };
    // Slow drift: nudge only occasionally (every few like-actions).
    _personality = _personality.nudge(dial);
  }

  // ---- Keepsakes (P2-5) ----

  static const Set<int> _streakMilestones = {3, 7, 30, 100};

  /// Adds [k] to the scrapbook if a card with that id isn't already collected.
  void _collect(Keepsake k) {
    final save = _save;
    if (save == null) return;
    if (save.keepsakes.any((e) => e.id == k.id)) return;
    _save = save.copyWith(keepsakes: [...save.keepsakes, k]);
  }

  /// Captures the milestone cards an interaction may have earned.
  void _captureKeepsakes(InteractionOutcome o, BondStage preStage) {
    final now = _now();
    final pet = o.state;
    if (o.grew) _collect(_keepsakes.growth(pet, now));
    if (pet.bond.stage != preStage) {
      _collect(_keepsakes.bondMilestone(pet, pet.bond.stage, now));
    }
    if (o.streakIncremented &&
        _streakMilestones.contains(pet.careStreak.count)) {
      _collect(_keepsakes.streakMilestone(pet, pet.careStreak.count, now));
    }
    if (o.comfortBeat) _collect(_keepsakes.comfort(pet, now));
  }
}
