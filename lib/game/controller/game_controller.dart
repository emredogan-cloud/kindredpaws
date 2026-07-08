/// The app-facing game controller (P1-3b). Owns the runtime save, drives the
/// deterministic [GameSimulation], persists via [SaveRepository], seeds the
/// Memory Book, and schedules warm notifications. A [ChangeNotifier] so the UI
/// rebuilds on change. The clock is injectable so tests stay deterministic.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/local_day.dart';
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
import '../../services/beta_feedback_pipeline.dart';
import '../../services/feedback_service.dart';
import '../../services/feel_service.dart';
import '../../services/home_widget_service.dart';
import '../../services/live_ops.dart';
import '../../services/notification_scheduler.dart';
import '../../services/observability.dart';
import '../../services/share_service.dart';
import '../../services/status_snapshot_service.dart';
import '../minigames/mini_games.dart' show miniGameKibble;
import '../model/bond.dart';
import '../model/decor.dart';
import '../model/inventory.dart';
import '../model/items.dart';
import '../model/kindness.dart';
import '../model/mood.dart';
import '../model/pet_state.dart';
import '../model/pet_status_snapshot.dart';
import '../model/species.dart';
import '../sim/bond_engine.dart';
import '../sim/game_simulation.dart';
import '../model/season_progress.dart';
import '../sim/interaction.dart';
import '../sim/kindness_engine.dart';
import '../sim/season_engine.dart';
import '../sim/shopping.dart';
import '../sim/sim_config.dart';

/// Why the app is showing the save-recovery screen instead of a pet or Rescue
/// Day (KP-010). Null on [GameController.recovery] means "no recovery needed".
enum RecoveryKind {
  /// The local save exists but cannot be read (truncated write, corrupt or
  /// unmigratable data). The blob is quarantined; nothing may overwrite it
  /// without an explicit, confirmed fresh start.
  corruptSave,

  /// The local save was written by a NEWER app version (a downgrade). The
  /// save is healthy — the fix is updating the app, never data loss.
  appTooOld,
}

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
    BetaFeedbackPipeline? betaFeedback,
    LiveOps? liveOps,
    FeelService? feel,
    bool Function()? notificationsAllowed,
    bool Function()? southernHemisphere,
    UtcOffsetAt utcOffsetAt = utcOffsetNone,
    void Function(int hour)? recordOpenHour,
    List<int> Function()? openHourHistogram,
    Set<String> Function()? seenHints,
    void Function(String id)? markHintSeen,
    int Function()? clock,
    String Function()? idGenerator,
  }) : _feedback = feedback ?? const NoopFeedbackService(),
       _betaFeedback = betaFeedback,
       _liveOps = liveOps,
       _feel = feel,
       _notificationsAllowed = notificationsAllowed,
       _southern = southernHemisphere,
       _recordOpenHour = recordOpenHour,
       _utcOffsetAt = utcOffsetAt,
       _openHourHistogram = openHourHistogram,
       _seenHints = seenHints,
       _markHintSeen = markHintSeen,
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

  /// The P5-5 beta-ops pipeline (ingest → sentiment → crash/diagnostic
  /// correlation → triage → telemetry), or null in tests that don't wire it.
  final BetaFeedbackPipeline? _betaFeedback;

  /// LiveOps control plane (P4-3), or null in tests. Notifications respect its
  /// kill-switch so the founder can silence them live (incident mitigation).
  final LiveOps? _liveOps;

  /// The Feel layer (E1): one warm cue (sound + soft haptic, both gated by
  /// player toggles) per meaningful moment. Null-safe — pure-logic tests that
  /// construct the controller directly simply feel nothing.
  final FeelService? _feel;

  void _cue(SfxCue sfx, [HapticKind kind = HapticKind.tap]) {
    final feel = _feel;
    if (feel != null) unawaited(feel.cue(sfx, kind));
  }

  /// Player-side notification preference (Settings toggle), or null in tests.
  final bool Function()? _notificationsAllowed;

  /// Southern-hemisphere seasons (Settings toggle, GE-5), or null (northern).
  final bool Function()? _southern;

  /// Rhythm-aware notifications (GE-6): records the local open-hour and reads
  /// the on-device open-hour histogram. Null in pure-logic tests.
  final void Function(int hour)? _recordOpenHour;

  /// Local calendar frame (KP-016/KP-018) — shared with the sim + scheduler
  /// so kindness rollovers, seasons, Gotcha Day, and the rhythm histogram all
  /// live on the player's clock.
  final UtcOffsetAt _utcOffsetAt;

  /// [_now] shifted into the local frame, for pure date math (months/days).
  int _localNow() => toLocalFrame(_now(), _utcOffsetAt);
  final List<int> Function()? _openHourHistogram;

  /// First-visit verb hints (GE-6): the device-local seen-set + recorder.
  /// Null in pure-logic tests (hints simply never show).
  final Set<String> Function()? _seenHints;
  final void Function(String id)? _markHintSeen;

  /// True if [hintId]'s one-time pulse hasn't been shown yet (GE-6).
  bool shouldShowHint(String hintId) =>
      !(_seenHints?.call().contains(hintId) ?? true);

  /// The one-time notification priming moment (KP-023). Stored in the same
  /// device-local seen-set as the first-visit hints (not the pet save).
  static const String kNotificationPrimingId = 'notification_priming';

  /// Offer the warm notification-permission card only AFTER the player is
  /// invested: a pet exists and at least one care action landed this
  /// session. The OS prompt used to fire at cold boot, over the rainy
  /// cold-open's first beat — spending the one prompt before the player
  /// cared (KP-023).
  bool get shouldOfferNotificationPriming =>
      hasPet && _session.total >= 1 && shouldShowHint(kNotificationPrimingId);

  /// The player accepted the priming card → NOW ask the OS.
  Future<void> acceptNotificationPriming() async {
    markHintSeen(kNotificationPrimingId);
    final granted = await notifications.requestPermission();
    final name = pet?.name ?? 'Your friend';
    lastMessage = granted
        ? '$name will send a gentle hello now and then 💛'
        : 'No worries — you can change this in Settings any time.';
    notifyListeners();
  }

  /// "Maybe later" — never ask again unprompted; Settings remains the path.
  void declineNotificationPriming() {
    markHintSeen(kNotificationPrimingId);
  }

  /// Marks [hintId] shown so its pulse never repeats (once per install).
  void markHintSeen(String hintId) {
    _markHintSeen?.call(hintId);
    notifyListeners();
  }

  /// Notifications are live unless the founder's LiveOps kill-switch OR the
  /// player's own Settings toggle has disabled them.
  bool get _notificationsLive =>
      _liveOps?.isKilled(LiveFeature.notifications) != true &&
      (_notificationsAllowed?.call() ?? true);

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

  /// Non-null while the save is unreadable → the UI shows the recovery screen
  /// (never Rescue Day: adopting would persist a fresh pet over a recoverable
  /// one — the KP-010 data-loss path this state exists to close).
  RecoveryKind? recovery;

  /// Pet id salvaged from the unreadable blob, for keying a cloud restore.
  String? _recoveryPetId;

  /// Wall-clock (ms) the current play session began, or null between sessions.
  /// Set when a session starts (adopt / resume / app-foregrounded); cleared by
  /// [_endSession] after the `sessionQuality` beat is emitted.
  int? _sessionStartMs;

  /// Last instant the session was provably alive (session start + every
  /// persist-worthy action). Lets [onAppForegrounded] detect a session that
  /// was REALLY backgrounded even though the embedder only delivered
  /// `hidden` (KP-021): a stale "active" session is closed and re-resolved
  /// instead of silently skipping catch-up + greeting.
  int _lastAliveMs = 0;

  /// Foregrounding an "active" session after a gap this large means the
  /// lifecycle stream lied (hidden-only background) — resolve for real.
  /// Generous: a notification-shade peek or app-switcher glance is seconds.
  static const int kStaleSessionGapMs = 5 * 60 * 1000;

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

  /// A pending one-time Streak Repair offer (the count that just broke), or
  /// null. Welcome-back framing only — ignoring it costs nothing (§11.2).
  int? streakRepairOffer;

  bool get loading => _loading;
  bool get hasPet => _save != null;

  /// This session's interaction tallies (read-only — e.g. the garden
  /// songbird visits after play; GE-2 ambient presence).
  SessionInteractions get session => _session;
  PetState? get pet => _save?.pet;
  Mood get mood => _mood;
  List<MemoryFact> get facts => _save?.facts ?? const [];

  /// The household inventory (pantry, toys, supplies, closet) — empty until a
  /// pet is adopted.
  Inventory get inventory => _save?.inventory ?? const Inventory();

  /// True while the pet naps in the Bedroom (shared across every room).
  bool get isSleeping => _save?.pet.isSleeping ?? false;

  /// The pet's evolving personality (drifts with care; persisted across restarts
  /// from save v6 — P3-4). Read-only; drift happens via [interact].
  PersonalityProfile get personality => _personality;

  /// Load the local save (migrating forward), resolve offline catch-up, and
  /// surface the pet. If there's no save, [hasPet] stays false → Rescue Day.
  ///
  /// KP-010: a save that EXISTS but cannot be read is never treated as "no
  /// pet". The blob is quarantined by the repository, a cloud restore is
  /// attempted, and failing that the controller enters [recovery] — from which
  /// adoption is blocked until the player explicitly confirms a fresh start.
  Future<void> load() async {
    final outcome = await repo.loadOutcome();
    switch (outcome) {
      case SaveLoaded(:final state):
        _adoptLoadedState(state);
        await _persist();
      case SaveAbsent():
        break; // genuinely fresh install → Rescue Day
      case SaveUnreadable(
        :final error,
        :final stackTrace,
        :final isNewerSchema,
        :final salvagedPetId,
      ):
        observability.recordError(
          error,
          stackTrace,
          context: 'save_unreadable',
          keys: {
            'newer_schema': isNewerSchema,
            'pet_id_salvaged': salvagedPetId != null,
          },
        );
        _recoveryPetId = salvagedPetId;
        if (isNewerSchema) {
          recovery = RecoveryKind.appTooOld;
        } else {
          final restored = await _tryCloudRestore();
          if (!restored) recovery = RecoveryKind.corruptSave;
        }
    }
    _loading = false;
    notifyListeners();
  }

  /// Re-run the whole load path from the recovery screen ("Try again").
  Future<void> retryLoad() async {
    _loading = true;
    recovery = null;
    notifyListeners();
    await load();
  }

  /// Attempt to pull the authoritative cloud snapshot for the quarantined
  /// save. True when a pet was restored. No-op (false) while the backend is
  /// unprovisioned or the blob yielded no pet id.
  Future<bool> _tryCloudRestore() async {
    final petId = _recoveryPetId;
    if (petId == null) return false;
    final res = await repo.restoreFromCloud(petId);
    final state = res.valueOrNull;
    if (state == null) {
      if (res.isErr) {
        observability.recordError(
          res.errorOrNull ?? 'cloud restore failed',
          null,
          context: 'save_recovery_cloud_restore',
        );
      }
      return false;
    }
    _adoptLoadedState(state);
    recovery = null;
    lastMessage = '${state.pet.name} is safe and sound — welcome back! 💛';
    return true;
  }

  /// The player explicitly chose "start fresh" from the recovery screen after
  /// the confirm dialog. The quarantined blob stays preserved in the backup
  /// slot; only now may Rescue Day (and its persist) run again.
  void beginFreshStart() {
    if (recovery != RecoveryKind.corruptSave) return;
    recovery = null;
    notifyListeners();
  }

  /// Shared "a save is now live in memory" wiring for load + cloud restore.
  void _adoptLoadedState(KindredSaveState state) {
    _save = state;
    _personality = state.personality; // restore drift (P3-4; was reset before)
    _resumeSession();
  }

  /// Rescue Day adoption: create the pet, seed the first memories, schedule
  /// warm notifications, persist. The emotional core of onboarding (§13).
  Future<void> adopt({required Species species, required String name}) async {
    // KP-010 invariant: while a quarantined save awaits recovery, adopting
    // (which persists a fresh pet) is refused — beginFreshStart() is the only
    // explicit, player-confirmed way past this guard.
    if (recovery != null) return;
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
      utcOffsetAt: _utcOffsetAt,
    );
    _save = KindredSaveState(
      pet: pet,
      ledger: BondLedger.empty,
      facts: _seedMemories(pet, now),
      keepsakes: [_keepsakes.rescueDay(pet, now)], // the first card
      inventory: Inventory.starter(), // the rescue kit — no room starts empty
    );
    _session = SessionInteractions.empty;
    _sessionStartMs = now;
    _lastAliveMs = now;
    lastInteraction = null;
    ambientEmotion = null;
    _personality = PersonalityProfile.neutral;
    _mood = sim.moodOf(pet.meters, recentAttentionBonus: 100);
    observability.event(AnalyticsEvent.rescueDayComplete, {
      'species': species.id,
    });
    if (_notificationsLive) {
      await notifications.scheduleDailyPresence(
        petName: pet.name,
        fromMs: now,
        preferredHours: _preferredHours(),
      );
    }
    _syncKindness(); // Rescue Day ends with today's first two kindnesses
    await _persist();
    lastMessage = 'Welcome home, ${pet.name}! 💛';
    _say(HeartmindIntent.greeting); // the pet's first words
    notifyListeners();
  }

  /// Perform a care interaction (feed/clean/play) and surface warm feedback.
  Future<void> interact(CareInteraction interaction) =>
      _applyInteraction(interaction);

  /// Feeds a specific pantry food (Kitchen). Consumes one from the pantry;
  /// when the pantry is out, surfaces a warm nudge toward the Grocery Store
  /// instead (never an error, never guilt).
  Future<void> feedWith(ItemDef food) async {
    final save = _save;
    if (save == null || food.kind != ItemKind.food) return;
    if (_guardSleeping()) return;
    final remaining = save.inventory.consume(food);
    if (remaining == null) {
      lastMessage =
          'The ${food.displayName} shelf is empty — '
          'the Grocery Store has more! 🧺';
      notifyListeners();
      return;
    }
    _save = save.copyWith(inventory: remaining);
    await _applyInteraction(
      CareInteraction.feed,
      item: food,
      warmLine: (name) =>
          '$name munched the ${food.displayName} right up! ${food.emoji}',
    );
  }

  /// Plays with a specific owned toy (Play Garden) and deepens that toy's
  /// affection (pure delight progression — never Bond).
  Future<void> playWith(ItemDef toy) async {
    final save = _save;
    if (save == null || toy.kind != ItemKind.toy) return;
    if (_guardSleeping()) return;
    if (!save.inventory.ownsToy(toy.id)) return;
    _save = save.copyWith(inventory: save.inventory.bumpAffinity(toy.id));
    await _applyInteraction(
      CareInteraction.play,
      item: toy,
      toyAffinity: save.inventory.affinity(toy.id),
      warmLine: (name) =>
          '$name and the ${toy.displayName} had the best time! ${toy.emoji}',
    );
  }

  Future<void> _applyInteraction(
    CareInteraction interaction, {
    ItemDef? item,
    int toyAffinity = 0,
    String Function(String petName)? warmLine,
  }) async {
    final save = _save;
    if (save == null) return;
    if (_guardSleeping()) return;
    final preStage = save.pet.bond.stage;
    final outcome = sim.interact(
      state: save.pet,
      interaction: interaction,
      session: _session,
      ledger: save.ledger,
      nowMs: _now(),
      item: item,
      toyAffinity: toyAffinity,
    );
    _save = save.copyWith(
      pet: outcome.state,
      ledger: outcome.ledger,
      facts: outcome.grew
          ? _withGrowthMemory(save.facts, outcome.state, _now())
          : save.facts,
    );
    _captureKeepsakes(outcome, preStage);
    if (outcome.streakBrokeFromCount > 0) {
      streakRepairOffer = outcome.streakBrokeFromCount;
    } else if (outcome.streakIncremented) {
      streakRepairOffer = null; // a fresh day of care moves us forward
    }
    if (outcome.grew || outcome.state.bond.stage != preStage) {
      _cue(SfxCue.tada, HapticKind.celebrate);
    } else if (outcome.comfortBeat) {
      _cue(SfxCue.heartGlow, HapticKind.success);
    } else {
      _cue(switch (interaction) {
        CareInteraction.feed => SfxCue.feedChime,
        CareInteraction.clean => SfxCue.splash,
        CareInteraction.play => SfxCue.boing,
      });
    }
    _session = outcome.session;
    _mood = outcome.mood;
    lastOutcome = outcome;
    lastInteraction = interaction;
    ambientEmotion = null; // a reaction takes over from any ambient idle
    lastMessage = outcome.comfortBeat || warmLine == null
        ? _warmLine(interaction, outcome)
        : warmLine(outcome.state.name);
    _driftPersonality(interaction);
    _save = _save?.copyWith(
      personality: _personality,
    ); // persist the drift (P3-4)
    // The pet speaks: a milestone celebration if it grew, else a care ack.
    _say(outcome.grew ? HeartmindIntent.milestone : HeartmindIntent.careAck);
    _recordKindness(switch (interaction) {
      CareInteraction.feed => KindnessTrigger.feed,
      CareInteraction.clean => KindnessTrigger.clean,
      CareInteraction.play => KindnessTrigger.play,
    }, itemId: item?.id);

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

  /// True (and surfaces a warm hush) when the pet is asleep — care actions
  /// wait until the player wakes them gently in the Bedroom.
  bool _guardSleeping() {
    if (!isSleeping) return false;
    final name = _save?.pet.name ?? 'Your friend';
    lastMessage = '$name is fast asleep 💤 — wake them gently first';
    notifyListeners();
    return true;
  }

  // ---- Grocery Store & inventory (Immersive Pet Experience) ----

  /// Buys [item] with Kibble (soft currency only — no real money in rooms).
  /// Every outcome is warm: success celebrates, "not enough Kibble" invites
  /// more care moments (never pressure).
  Future<bool> purchase(ItemDef item) async {
    final save = _save;
    if (save == null) return false;
    final outcome = tryPurchase(
      state: save.pet,
      inventory: save.inventory,
      item: item,
    );
    if (!outcome.success) {
      lastMessage = switch (outcome.block!) {
        PurchaseBlock.kibble =>
          'A few more care moments and the ${item.displayName} is yours! 💛',
        PurchaseBlock.alreadyOwned =>
          'You already have the ${item.displayName} — it\'s yours forever!',
        PurchaseBlock.notSoldHere =>
          'The ${item.displayName} isn\'t on these shelves.',
      };
      notifyListeners();
      return false;
    }
    var inventory = outcome.inventory!;
    // A wished-for item coming home empties the jar (quietly, proudly).
    if (inventory.wishlistId == item.id) {
      inventory = inventory.copyWith(clearWishlist: true);
    }
    _save = save.copyWith(pet: outcome.state, inventory: inventory);
    _cue(SfxCue.basket, HapticKind.success);
    lastMessage = '${item.emoji} ${item.displayName} — into the basket!';
    // Décor set completion (GE-3): exactly once per set (stable keepsake id).
    if (item.kind == ItemKind.decor) {
      for (final set in DecorSets.containing(item.id)) {
        if (set.completedBy(inventory.decor)) {
          _collect(
            _keepsakes.decorSet(outcome.state!, set.id, set.title, _now()),
          );
          _cue(SfxCue.tada, HapticKind.celebrate);
          lastMessage =
              '${set.emoji} The ${set.title} set is complete — '
              'a keepsake for the book!';
          _say(HeartmindIntent.milestone);
        }
      }
    }
    _recordKindness(KindnessTrigger.grocery, itemId: item.id);
    observability.event(AnalyticsEvent.careAction, {
      'verb': 'purchase',
      'bond_awarded': 0,
      'needed': false,
    });
    await _persist();
    notifyListeners();
    return true;
  }

  // ---- Cozy Corners décor (GE-3 — pure expression, never power) ----

  /// Places an owned décor piece in [slot] (two taps: spot → piece).
  Future<void> placeDecor(DecorSlot slot, ItemDef item) async {
    final save = _save;
    if (save == null || item.kind != ItemKind.decor) return;
    if (!save.inventory.ownsDecor(item.id)) return;
    _save = save.copyWith(inventory: save.inventory.place(slot.id, item.id));
    _cue(SfxCue.softPop);
    lastMessage =
        '${item.emoji} The ${item.displayName} looks lovely on '
        '${slot.label}!';
    await _persist();
    notifyListeners();
  }

  /// Empties a décor slot (the piece stays owned — back to the box).
  Future<void> clearDecor(DecorSlot slot) async {
    final save = _save;
    if (save == null || save.inventory.placedIn(slot.id) == null) return;
    _save = save.copyWith(inventory: save.inventory.clearSlot(slot.id));
    _cue(SfxCue.softPop);
    await _persist();
    notifyListeners();
  }

  /// Sets (or clears, with null) the one wished-for shop item — the saving
  /// jar. Pure intent: no notifications, no badges, no nagging, ever.
  Future<void> setWishlist(ItemDef? item) async {
    final save = _save;
    if (save == null) return;
    final inv = item == null
        ? save.inventory.copyWith(clearWishlist: true)
        : save.inventory.copyWith(wishlistId: item.id);
    _save = save.copyWith(inventory: inv);
    if (item != null) {
      _cue(SfxCue.sparkle);
      lastMessage =
          '${item.emoji} Wished for the ${item.displayName} — '
          'the jar is on the shelf!';
    }
    await _persist();
    notifyListeners();
  }

  // ---- Care Corner (gentle wellness — never frightening) ----

  /// Offers a care supply (vitamin chew, soothing balm, warm broth…): consumes
  /// one and applies its comfort. Out-of-stock nudges the Grocery Store warmly.
  Future<void> useSupply(ItemDef supply) async {
    final save = _save;
    if (save == null || supply.kind != ItemKind.careSupply) return;
    if (_guardSleeping()) return;
    final remaining = save.inventory.consume(supply);
    if (remaining == null) {
      lastMessage =
          'No ${supply.displayName} left — '
          'the Grocery Store keeps them in stock 🧺';
      notifyListeners();
      return;
    }
    final outcome = sim.applySupply(
      state: save.pet,
      item: supply,
      ledger: save.ledger,
      nowMs: _now(),
    );
    _save = save.copyWith(
      pet: outcome.state,
      ledger: outcome.ledger,
      inventory: remaining,
    );
    _mood = outcome.mood;
    lastInteraction = null;
    ambientEmotion = null;
    _cue(
      outcome.comfortBeat ? SfxCue.heartGlow : SfxCue.sparkle,
      outcome.comfortBeat ? HapticKind.success : HapticKind.tap,
    );
    lastMessage = outcome.comfortBeat
        ? '${outcome.state.name} feels so much better with you here 💛'
        : '${supply.emoji} ${outcome.state.name} feels cozier already';
    if (outcome.comfortBeat) {
      _collect(_keepsakes.comfort(outcome.state, _now()));
    }
    _say(
      outcome.comfortBeat ? HeartmindIntent.comfort : HeartmindIntent.careAck,
    );
    _recordKindness(KindnessTrigger.supply, itemId: supply.id);
    observability.event(AnalyticsEvent.careAction, {
      'verb': 'supply',
      'bond_awarded': outcome.bondAwarded,
      'needed': outcome.comfortBeat,
    });
    await _persist();
    notifyListeners();
  }

  /// A gentle comfort touch (Care Corner & Bedroom): tiny capped Bond, a
  /// little joy, and the signature Comfort beat when it lifts a Low pet.
  Future<void> comfortPet() async {
    final save = _save;
    if (save == null) return;
    if (_guardSleeping()) return;
    final outcome = sim.comfort(
      state: save.pet,
      session: _session,
      ledger: save.ledger,
      nowMs: _now(),
    );
    _save = save.copyWith(pet: outcome.state, ledger: outcome.ledger);
    _session = outcome.session;
    _mood = outcome.mood;
    lastInteraction = null;
    ambientEmotion = null;
    _cue(SfxCue.heartGlow, HapticKind.success);
    lastMessage = outcome.comfortBeat
        ? '${outcome.state.name} feels so much better with you here 💛'
        : '${outcome.state.name} leans into your hand 💛';
    if (outcome.comfortBeat) {
      _collect(_keepsakes.comfort(outcome.state, _now()));
    }
    _say(HeartmindIntent.comfort);
    _recordKindness(KindnessTrigger.comfort);
    observability.event(AnalyticsEvent.careAction, {
      'verb': 'comfort',
      'bond_awarded': outcome.bondAwarded,
      'needed': outcome.comfortBeat,
    });
    await _persist();
    notifyListeners();
  }

  /// The Care Corner temperature check — always reassuring, by design: the
  /// pet can never be sick (no-death floor, Health/Illness removed from canon).
  /// It's a warm ritual that reflects the pet's coziness back to the player.
  void wellnessCheck() {
    final save = _save;
    if (save == null) return;
    final name = save.pet.name;
    final lowest = save.pet.meters.lowest;
    _cue(SfxCue.sparkle);
    lastMessage = lowest >= config.needsCareThreshold
        ? '🌡️ Snug as a sunbeam — $name is doing wonderfully!'
        : '🌡️ All safe and sound — a little extra love and '
              '$name will be beaming';
    lastInteraction = null;
    ambientEmotion = null;
    _say(HeartmindIntent.careAck);
    if (_recordKindness(KindnessTrigger.wellness)) {
      unawaited(_persist()); // the only sync caller — completion must stick
    }
    notifyListeners();
  }

  // ---- Wardrobe (cosmetic delight — zero gameplay power) ----

  /// Wears an owned cosmetic (or, for a Forever Friends premium keepsake the
  /// player is entitled to, grants + wears it). Never sold for money in-room.
  Future<void> equipCosmetic(ItemDef item, {bool entitled = false}) async {
    final save = _save;
    if (save == null || item.kind != ItemKind.cosmetic) return;
    var inv = save.inventory;
    if (!inv.ownsCosmetic(item.id)) {
      if (!item.premium || !entitled) return; // UI gates; defense in depth
      inv = inv.add(item); // the Forever Friends keepsake joins the closet
    }
    _save = save.copyWith(inventory: inv.equip(item));
    _cue(SfxCue.softPop);
    lastMessage =
        '${item.emoji} ${save.pet.name} is wearing the '
        '${item.displayName}!';
    _recordKindness(KindnessTrigger.dressUp, itemId: item.id);
    await _persist();
    notifyListeners();
  }

  /// Takes a cosmetic off (back to the closet — it stays owned forever).
  Future<void> unequipCosmetic(ItemDef item) async {
    final save = _save;
    if (save == null) return;
    _save = save.copyWith(inventory: save.inventory.unequip(item.id));
    await _persist();
    notifyListeners();
  }

  // ---- Bedroom (sleep, dreams, mornings) ----

  /// Tucks the pet in. Sleep persists across app restarts; energy regenerates
  /// for the whole nap when the pet wakes (§5.1 rest +20/h).
  Future<void> tuckIn() async {
    final save = _save;
    if (save == null || save.pet.isSleeping) return;
    _save = save.copyWith(pet: save.pet.tuckedIn(_now()));
    lastInteraction = null;
    ambientEmotion = null;
    _cue(SfxCue.lullabyDip);
    lastMessage = 'Sweet dreams, ${save.pet.name} 🌙';
    _say(HeartmindIntent.goodbye);
    _recordKindness(KindnessTrigger.tuckIn);
    await _persist();
    notifyListeners();
  }

  /// Gently wakes the pet: credits the nap's energy and greets the morning.
  Future<void> wakeUp() async {
    final save = _save;
    if (save == null || !save.pet.isSleeping) return;
    final outcome = sim.wake(state: save.pet, nowMs: _now());
    _save = save.copyWith(pet: outcome.state);
    _mood = outcome.mood;
    lastInteraction = null;
    ambientEmotion = null;
    _cue(SfxCue.morningChirp, HapticKind.success);
    lastMessage = outcome.sleptHours >= 1
        ? '☀️ ${outcome.state.name} stretches — what a lovely nap!'
        : '☀️ ${outcome.state.name} blinks awake, happy to see you';
    _say(HeartmindIntent.greeting);
    observability.event(AnalyticsEvent.careAction, {
      'verb': 'wake',
      'bond_awarded': 0,
      'needed': false,
    });
    await _persist();
    notifyListeners();
  }

  /// Right-to-be-forgotten (§8.3, Settings): erases the save everywhere
  /// (local + backend + analytics identifiers via the repo), cancels every
  /// pending notification, clears the runtime, and returns to Rescue Day.
  /// Returns false (with a calm message) if the erase failed — never silent.
  Future<bool> deleteAccountAndStartOver() async {
    final result = await repo.deleteAccount(petId: _save?.pet.petId);
    if (result.isErr) {
      lastMessage =
          'Something went wrong and nothing was deleted — please try again.';
      notifyListeners();
      return false;
    }
    await notifications.cancelAll();
    _save = null;
    _session = SessionInteractions.empty;
    _mood = Mood.content;
    _personality = PersonalityProfile.neutral;
    petLine = null;
    lastMessage = null;
    lastOutcome = null;
    lastInteraction = null;
    ambientEmotion = null;
    _sessionStartMs = null;
    _onboardingStartMs = null;
    notifyListeners();
    return true;
  }

  /// Wraps up a Play Garden mini-game session: one canonical play verb (the
  /// game IS play — bond/energy/happiness semantics identical) plus a small
  /// capped Kibble thank-you for the joy scored. No-fail by design upstream;
  /// a zero score still ends warmly (the verb alone).
  Future<void> finishMiniGame({
    required String gameId,
    required int score,
  }) async {
    if (_save == null) return;
    if (_guardSleeping()) return;
    await _applyInteraction(
      CareInteraction.play,
      warmLine: (name) => '$name had the best time playing! \u{1F389}',
    );
    final bonus = miniGameKibble(score);
    final save = _save;
    if (save == null) return;
    if (bonus > 0) {
      _save = save.copyWith(
        pet: save.pet.copyWith(wallet: save.pet.wallet.addKibble(bonus)),
      );
      lastMessage = '+$bonus Kibble \u2014 what a game! \u{1F9B4}';
      _cue(SfxCue.tada, HapticKind.success);
    }
    _recordKindness(KindnessTrigger.miniGame);
    observability.event(AnalyticsEvent.careAction, {
      'verb': 'minigame_$gameId',
      'bond_awarded': lastOutcome?.bondAwarded ?? 0,
      'needed': false,
    });
    await _persist();
    notifyListeners();
  }

  /// The one-time Streak Repair (§11.2): spends Kibble to rekindle the streak
  /// that just broke. Only available while [streakRepairOffer] stands; always
  /// optional, never nagged. Returns false when Kibble is short (warm copy).
  Future<bool> repairStreak() async {
    final save = _save;
    final offer = streakRepairOffer;
    if (save == null || offer == null) return false;
    final debited = save.pet.wallet.spendKibble(config.streakRepairKibbleCost);
    if (debited == null) {
      lastMessage =
          'A few more care moments and the streak can be rekindled 💛';
      notifyListeners();
      return false;
    }
    final rekindled = sim.repairStreak(save.pet.careStreak, offer + 1);
    _save = save.copyWith(
      pet: save.pet.copyWith(wallet: debited, careStreak: rekindled),
    );
    streakRepairOffer = null;
    _cue(SfxCue.tada, HapticKind.success);
    lastMessage = 'Your streak is glowing again — day ${offer + 1} 🔥';
    observability.event(AnalyticsEvent.streakEvent, {'count': rekindled.count});
    await _persist();
    notifyListeners();
    return true;
  }

  // ---- Seasons of Us (GE-5, Genre Evolution) ----

  bool get _seasonsLive => _liveOps?.isKilled(LiveFeature.seasons) != true;

  /// The current nature season (hemisphere-aware; pure date math).
  NatureSeason get season =>
      seasonFor(_localNow(), southern: _southern?.call() ?? false);

  /// The season the rooms should dress for, or null while the founder's
  /// kill-switch holds the world neutral (instant revert, no restart).
  NatureSeason? get seasonAccent => _seasonsLive ? season : null;

  /// Counts one active day toward the season keepsake (called only on a
  /// real new-day session start). Five gentle days → the keepsake, once
  /// per season-window; every season is earnable again next year.
  void _countSeasonDay() {
    final save = _save;
    if (save == null) return;
    final key = seasonWindowKey(
      _localNow(),
      southern: _southern?.call() ?? false,
    );
    final prior = save.seasonProgress;
    final days = prior != null && prior.windowKey == key ? prior.days + 1 : 1;
    _save = save.copyWith(
      seasonProgress: SeasonProgress(windowKey: key, days: days),
    );
    if (days == seasonKeepsakeDays) {
      final s = season;
      _collect(
        _keepsakes.season(save.pet, key, s.displayName.toLowerCase(), _now()),
      );
      _cue(SfxCue.tada, HapticKind.celebrate);
      lastMessage =
          '${s.emoji} Five ${s.displayName.toLowerCase()} days together — '
          'a keepsake for the book!';
      _say(HeartmindIntent.milestone);
    }
  }

  // ---- Daily Kindnesses (GE-1, Genre Evolution) ----

  static const KindnessEngine _kindnessEngine = KindnessEngine();

  /// Today's kindness slate (offered pair + completion) — null before the
  /// first session of the day resolves it.
  KindnessState? get kindnessToday => _save?.kindness;

  /// Today's offered kindnesses resolved to their defs (retired ids skip).
  List<KindnessDef> get todaysKindnesses => [
    for (final id in _save?.kindness?.offered ?? const <String>[])
      ?KindnessCatalog.byId(id),
  ];

  /// Ensures the slate belongs to today (a new day quietly brings a fresh
  /// pair; yesterday's simply fades — nothing lost, nothing mentioned).
  void _syncKindness() {
    final save = _save;
    if (save == null) return;
    final synced = _kindnessEngine.today(
      utcOffsetAt: _utcOffsetAt,
      nowMs: _now(),
      petId: save.pet.petId,
      prior: save.kindness,
      season: _seasonsLive ? season : null,
    );
    if (!identical(synced, save.kindness)) {
      _save = save.copyWith(kindness: synced);
    }
  }

  /// A real care moment happened — detect completions, thank with Kibble, and
  /// celebrate. The moment already carried its own bond/meters through the
  /// sim; the kindness adds delight, never a second scoop of power. Returns
  /// true when something completed (sync callers persist on that signal).
  bool _recordKindness(KindnessTrigger trigger, {String? itemId}) {
    final save = _save;
    if (save == null) return false;
    final slate = _kindnessEngine.today(
      utcOffsetAt: _utcOffsetAt,
      nowMs: _now(),
      petId: save.pet.petId,
      prior: save.kindness,
      season: _seasonsLive ? season : null,
    );
    final res = _kindnessEngine.record(slate, trigger, itemId: itemId);
    if (res.completed.isEmpty) {
      if (!identical(res.state, save.kindness)) {
        _save = save.copyWith(kindness: res.state);
      }
      return false;
    }
    var wallet = save.pet.wallet;
    var thanks = 0;
    for (final def in res.completed) {
      wallet = wallet.addKibble(def.kibble);
      thanks += def.kibble;
    }
    _save = save.copyWith(
      pet: save.pet.copyWith(wallet: wallet),
      kindness: res.state,
    );
    _cue(SfxCue.tada, HapticKind.celebrate);
    lastMessage = res.state.allDone
        ? 'Every kindness done today — +$thanks Kibble! 💛'
        : '${res.completed.first.emoji} A kindness complete — '
              '+$thanks Kibble!';
    _say(
      res.state.allDone ? HeartmindIntent.milestone : HeartmindIntent.careAck,
    );
    // Its own event kind — kindnesses must never skew the careAction funnel.
    for (final def in res.completed) {
      observability.event(AnalyticsEvent.kindnessComplete, {
        'kindness': def.id,
        'kibble': def.kibble,
        'all_done': res.state.allDone,
      });
    }
    return true;
  }

  /// The household's preferred notification hours from the on-device rhythm
  /// histogram (GE-6), or null in tests without the seam (defaults stand).
  List<int>? _preferredHours() {
    final hist = _openHourHistogram?.call();
    if (hist == null) return null;
    return preferredNotificationHours(hist, 1);
  }

  void _resumeSession() {
    final save = _save!;
    // Rhythm-aware notifications (GE-6): note the session-open hour, on-device
    // only (privacy-first — never a pet-save field). It's the clock's hour,
    // consistent with how the scheduler places its anchor hours, so the
    // hellos land at the household's habitual time.
    final openHour = (_localNow() ~/ Duration.millisecondsPerHour) % 24;
    _recordOpenHour?.call(openHour);
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
    _lastAliveMs = _now();
    lastInteraction = null;
    ambientEmotion = null;
    _mood = resume.mood;
    observability.event(AnalyticsEvent.sessionStart, {
      'offline_hours': resume.offlineHours.round(),
    });
    if (resume.dailyKibble > 0) {
      lastMessage =
          '+${resume.dailyKibble} Kibble — happy new day together! 🦴';
      _cue(SfxCue.sparkle);
    }
    // The pet greets you back — a "returning" beat after a real absence,
    // otherwise a normal greeting; a memory callback when one is available.
    // The returning line is warm + longing, NEVER guilt (the comeback model).
    final intent = resume.offlineHours >= config.graceHours
        ? HeartmindIntent.returning
        : HeartmindIntent.greeting;
    _say(intent, tryCallback: true);
    _syncKindness(); // today's pair greets the day (deterministic, quiet)
    // A real new day (the daily Kibble marks it) counts toward the season
    // keepsake — five gentle days, never a streak (GE-5).
    if (resume.dailyKibble > 0 && _seasonsLive) _countSeasonDay();
    // Re-arm presence notifications on the freshly-updated rhythm (GE-6):
    // as the open-hour histogram grows, the hellos drift toward when this
    // household actually plays.
    if (_notificationsLive) {
      unawaited(
        notifications.scheduleDailyPresence(
          petName: resume.state.name,
          fromMs: _now(),
          preferredHours: _preferredHours(),
        ),
      );
    }
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
        localDayOf(_now(), _utcOffsetAt) -
        localDayOf(pet.createdAtMs, _utcOffsetAt);
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
    if (!hasPet) return;
    if (_sessionStartMs != null) {
      // A session is nominally still active. If it went quiet only moments
      // ago this is a transient blip (inactive → resumed) — keep it. If it
      // has been silent for a real gap, the platform backgrounded us with
      // only `hidden` (no `paused`) — close the stale session at its last
      // provably-alive instant and fall through to a fresh resolve (KP-021).
      if (_now() - _lastAliveMs < kStaleSessionGapMs) return;
      _endSession(endMs: _lastAliveMs);
    }
    _resumeSession();
    // The fresh kindness slate + season-day count must stick even if the
    // session ends abruptly (they're not derivable after the fact).
    unawaited(_persist());
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
  void _endSession({int? endMs}) {
    final start = _sessionStartMs;
    if (start == null) return;
    final end = endMs ?? _now();
    observability.recordSessionQuality(
      interactions: _session.total,
      durationSeconds: ((end - start) / 1000).clamp(0, 1 << 32).round(),
    );
    _sessionStartMs = null;
  }

  /// Submits closed-beta feedback. When the P5-5 [BetaFeedbackPipeline] is wired
  /// it runs the full beta-ops pass (sentiment + crash/diagnostic correlation +
  /// triage + telemetry); otherwise it falls back to the raw [FeedbackService]
  /// seam. Best-effort + PII-minimized (rating + capped note only); never throws.
  Future<void> submitBetaFeedback({
    required int rating,
    String? comment,
  }) async {
    final pipeline = _betaFeedback;
    if (pipeline != null) {
      await pipeline.ingest(rating: rating, comment: comment);
      return;
    }
    await _feedback.submit(BetaFeedback(rating: rating, comment: comment));
  }

  Future<void> _persist() async {
    final save = _save;
    if (save == null) return;
    // Every persist-worthy action proves the session alive (KP-021).
    _lastAliveMs = _now();
    // Belt-and-braces for KP-010: never write while a quarantined save is
    // pending recovery (there is no in-memory save then, but keep the guard).
    if (recovery != null) return;
    final res = await repo.save(save);
    if (res.isErr) {
      observability.recordError(
        res.errorOrNull ?? 'save failed',
        null,
        context: 'persist',
      );
    }
    // Best-effort by contract: a snapshot/home-widget platform failure must
    // never escape into the fire-and-forget gameplay callers (KP-020).
    try {
      await _publishSnapshot(save);
    } catch (e, st) {
      observability.recordError(e, st, context: 'publish_snapshot');
    }
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
      CareInteraction.clean => '$name feels fresh and happy 💦',
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
  /// A sleeping pet just snoozes on (soft dream murmur, never startled awake).
  void nudgeAmbient() {
    if (_save == null) return;
    if (isSleeping) {
      ambientEmotion = PetEmotion.sleepy;
      petLine = '💤 …';
      notifyListeners();
      return;
    }
    _ambientTick++;
    _cue(SfxCue.softPop);
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
