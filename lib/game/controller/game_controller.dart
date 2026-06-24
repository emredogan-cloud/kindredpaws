/// The app-facing game controller (P1-3b). Owns the runtime save, drives the
/// deterministic [GameSimulation], persists via [SaveRepository], seeds the
/// Memory Book, and schedules warm notifications. A [ChangeNotifier] so the UI
/// rebuilds on change. The clock is injectable so tests stay deterministic.
library;

import 'package:flutter/foundation.dart';

import '../../core/name_input_validator.dart';
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
import '../../services/feedback_service.dart';
import '../../services/home_widget_service.dart';
import '../../services/live_ops.dart';
import '../../services/notification_scheduler.dart';
import '../../services/observability.dart';
import '../../services/share_service.dart';
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
    required this.share,
    FeedbackService? feedback,
    LiveOps? liveOps,
    int Function()? clock,
    String Function()? idGenerator,
  }) : _feedback = feedback ?? const NoopFeedbackService(),
       _liveOps = liveOps,
       _now = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
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
  final ShareService share;
  final FeedbackService _feedback;

  /// LiveOps control plane (P4-3), or null in tests. Notifications respect its
  /// kill-switch so the founder can silence them live (incident mitigation).
  final LiveOps? _liveOps;

  /// Notifications are live unless a LiveOps kill-switch has disabled them.
  bool get _notificationsLive =>
      _liveOps?.isKilled(LiveFeature.notifications) != true;

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

  /// Wall-clock (ms) the current play session began, or null between sessions.
  /// Set when a session starts (adopt / resume / app-foregrounded); cleared by
  /// [_endSession] after the `sessionQuality` beat is emitted.
  int? _sessionStartMs;

  /// Wall-clock (ms) the Rescue Day onboarding began (first beat), for the
  /// activation-funnel timing. Null before onboarding starts.
  int? _onboardingStartMs;

  /// Records a Rescue Day onboarding funnel step (P5-1) — `reach_out` (start) →
  /// `choose_species` → `species_selected`; `adopt` is `rescueDayComplete`. Lets
  /// the activation funnel + per-step drop-off be measured (§13.4 ≥80% complete).
  /// The single emit point keeps the taxonomy enforced + PII-free.
  void recordOnboardingStep(String step) {
    _onboardingStartMs ??= _now();
    observability.event(AnalyticsEvent.onboardingStep, {
      'step': step,
      'ms_since_start': _now() - _onboardingStartMs!,
    });
  }

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

  /// The pet's evolving personality (drifts with care; persisted across restarts
  /// from save v6 — P3-4). Read-only; drift happens via [interact].
  PersonalityProfile get personality => _personality;

  /// Load the local save (migrating forward), resolve offline catch-up, and
  /// surface the pet. If there's no save, [hasPet] stays false → Rescue Day.
  Future<void> load() async {
    final res = await repo.load();
    final state = res.valueOrNull;
    if (state != null) {
      _save = state;
      _personality =
          state.personality; // restore drift (P3-4; was reset before)
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
    // Re-validate at the persistence boundary so the controller — not just the
    // Rescue Day widget — is the chokepoint keeping PII/profanity out of the save
    // (defense in depth, §11.1; P3-8 audit). A rejected name falls back to the
    // species default rather than blocking adoption here.
    final validated = const NameInputValidator().validate(name);
    final pet = PetState.newlyRescued(
      petId: _idGenerator(),
      species: species,
      name: validated.isValid ? validated.sanitized : species.defaultName,
      nowMs: now,
    );
    _save = KindredSaveState(
      pet: pet,
      ledger: BondLedger.empty,
      facts: _seedMemories(pet, now),
      keepsakes: [_keepsakes.rescueDay(pet, now)], // the first card
    );
    _session = SessionInteractions.empty;
    _sessionStartMs = now;
    lastInteraction = null;
    ambientEmotion = null;
    _personality = PersonalityProfile.neutral;
    _mood = sim.moodOf(pet.meters, recentAttentionBonus: 100);
    observability.event(AnalyticsEvent.rescueDayComplete, {
      'species': species.id,
    });
    if (_notificationsLive) {
      await notifications.scheduleDailyPresence(petName: pet.name, fromMs: now);
    }
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
    _save = _save?.copyWith(
      personality: _personality,
    ); // persist the drift (P3-4)
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
    if (outcome.state.bond.stage != preStage) {
      observability.event(AnalyticsEvent.bondStageUp, {
        'stage': outcome.state.bond.stage.name,
      });
      // A warm "come celebrate" nudge for later (never guilt; capped) — P4-4.
      // Respects the LiveOps notifications kill-switch (P4-3 / audit).
      if (_notificationsLive) {
        await notifications.scheduleEvent(
          kind: NotificationKind.celebration,
          petName: outcome.state.name,
          atMs: _now() + 4 * Duration.millisecondsPerHour,
          detail: 'becoming ${outcome.state.bond.stage.name}s',
        );
      }
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
    _sessionStartMs = _now();
    lastInteraction = null;
    ambientEmotion = null;
    _mood = resume.mood;
    observability.event(AnalyticsEvent.sessionStart, {
      'offline_hours': resume.offlineHours.round(),
    });
    // The pet greets you back — a "returning" beat after a real absence,
    // otherwise a normal greeting; a memory callback when one is available.
    // The returning line is warm + longing, NEVER guilt (the comeback model).
    final intent = resume.offlineHours >= config.graceHours
        ? HeartmindIntent.returning
        : HeartmindIntent.greeting;
    _say(intent, tryCallback: true);
    _recordRetentionBeats();
  }

  /// Standard retention-milestone days since adoption (D1/D3/D7/D14/D30) — feeds
  /// the G4 D1≥42% / D7≥20% / D30≥10% gates.
  static const Set<int> _retentionDays = {1, 3, 7, 14, 30};

  /// Soft-launch retention beats (P5-2), on a real session start. NEVER guilt:
  /// the retention-milestone signal, plus the **Gotcha Day** adoption-anniversary
  /// celebration (a milestone beat — pride + joy, never obligation). Seasonal
  /// moments arrive via Remote Config content top-ups (Content OS), not a
  /// hardcoded calendar.
  void _recordRetentionBeats() {
    final pet = _save?.pet;
    if (pet == null) return;
    final daysSinceAdopt =
        (_now() ~/ Duration.millisecondsPerDay) -
        (pet.createdAtMs ~/ Duration.millisecondsPerDay);
    final isAnniversary = daysSinceAdopt > 0 && daysSinceAdopt % 365 == 0;

    // Retention-milestone return (per session on the day; the dashboard counts
    // distinct returning users — see AnalyticsMetrics.retentionMilestonesByDay).
    if (_retentionDays.contains(daysSinceAdopt) || isAnniversary) {
      observability.event(AnalyticsEvent.retentionMilestone, {
        'day': daysSinceAdopt,
      });
    }
    // Gotcha Day — the pet celebrates how far you've come together.
    if (isAnniversary) {
      _say(HeartmindIntent.milestone);
    }
  }

  /// App returned to the foreground (P3-7). Starts a fresh session: re-resolves
  /// offline catch-up, greets, and re-arms the session clock. No-op on Rescue
  /// Day (no pet yet), and — critically — a no-op when a session is still active
  /// (`_sessionStartMs != null`): a transient `resumed` after `inactive` (no real
  /// background) must not re-resolve catch-up or re-greet (P3-8 audit finding).
  void onAppForegrounded() {
    if (!hasPet || _sessionStartMs != null) return;
    _resumeSession();
    notifyListeners();
  }

  /// App went to the background (P3-7). Ends the session — emits the
  /// `sessionQuality` retention beat — and persists. Idempotent: a second
  /// background event before the next foreground is a no-op.
  Future<void> onAppBackgrounded() async {
    _endSession();
    await _persist();
  }

  /// Emits the deferred `sessionQuality` summary (the daily-retention lever):
  /// `empty=false` ⇔ the player did ≥1 care interaction this session. No-op if
  /// no session is active (guards double-emit). See [ObservabilityFacade].
  void _endSession() {
    final start = _sessionStartMs;
    if (start == null) return;
    observability.recordSessionQuality(
      interactions: _session.total,
      durationSeconds: ((_now() - start) / 1000).round(),
    );
    _sessionStartMs = null;
  }

  /// Submits closed-beta feedback (P3-7) via the [FeedbackService] seam.
  /// Best-effort + PII-minimized (rating + capped note only); never throws into
  /// the UI.
  Future<void> submitBetaFeedback({required int rating, String? comment}) =>
      _feedback.submit(BetaFeedback(rating: rating, comment: comment));

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

  /// Shares a Keepsake card via the platform share seam and — only if the user
  /// actually shared — emits the `keepsakeShare` virality event (P3-1 taxonomy;
  /// G4 KPI ≥1 share/DAU-week). `moment_type` is the canonical card kind; never
  /// PII. Returns the outcome so the UI can react. Never throws into the loop.
  Future<ShareOutcome> shareKeepsake(Keepsake k) async {
    final outcome = await share.shareKeepsake(
      title: k.title,
      caption: k.caption,
      imageRef: k.imageRef,
    );
    if (outcome.shared) {
      observability.event(AnalyticsEvent.keepsakeShare, {
        'moment_type': k.kind.name,
        'platform': outcome.platform,
      });
    }
    return outcome;
  }

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
