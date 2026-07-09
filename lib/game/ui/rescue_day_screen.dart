/// Rescue Day — the 60–90s cold-open (GAMEPLAY_AND_PROGRESSION_BIBLE.md §13.1).
/// Emotionally front-loaded: empathy → care → attachment → ADOPT → naming +
/// memory seed. No tutorial wall, no account wall, no monetization (§13.3). On
/// adopt, the controller creates the pet and the app routes to the Nest.
library;

import 'package:flutter/material.dart';

import '../../core/name_input_validator.dart';
import '../../render/pet_renderer.dart';
import '../../render/vector_pet_renderer.dart';
import '../model/life_stage.dart';
import '../controller/game_controller.dart';
import '../model/species.dart';
import 'widgets/cozy.dart';
import 'kp_tokens.dart';

class RescueDayScreen extends StatefulWidget {
  const RescueDayScreen({required this.controller, super.key});

  final GameController controller;

  @override
  State<RescueDayScreen> createState() => _RescueDayScreenState();
}

class _RescueDayScreenState extends State<RescueDayScreen> {
  int _beat = 0;
  Species? _species;
  final TextEditingController _name = TextEditingController();
  // The single free-text surface in the app is filtered for PII + profanity so
  // it is child-safe for ALL users (§11.1, no free-text from minors).
  final NameInputValidator _validator = const NameInputValidator();
  String? _nameError;
  bool _adopting = false;

  static const _beats = [
    _Beat(
      '🌧️',
      'A cold, rainy evening.',
      'Somewhere out in the dark, a tiny shape is curled up, all alone.',
    ),
    _Beat(
      '🐾',
      'You kneel down and reach out.',
      'It flinches — then peeks up at you with big, hopeful eyes.',
    ),
    _Beat(
      '💗',
      'A tiny tail gives a hopeful wag.',
      'It leans into your hand. Warmth. Trust, beginning.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Onboarding funnel start (P5-1): the cold-open's first beat.
    widget.controller.recordOnboardingStep('reach_out');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('rescue-day'),
      body: CozyBackground(
        asset: KpAssets.onboardingDark,
        // A soft scrim lifts the cream panel + text off the dim rainy scene.
        scrim: Colors.black.withValues(alpha: 0.26),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                decoration: BoxDecoration(
                  color: KpColors.card.withValues(alpha: 0.93),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _body(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _beatIllos = [
    KpAssets.onboardingBeat1,
    KpAssets.onboardingBeat2,
    KpAssets.onboardingBeat3,
  ];

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    if (_beat < _beats.length) {
      final b = _beats[_beat];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Skip + per-beat back (KP-025): repeat/reinstalling players can
          // jump straight to the choice; the beats stay the default path so
          // first-timers keep the emotional hook.
          Row(
            children: [
              if (_beat > 0)
                IconButton(
                  key: const Key('rescue-back'),
                  tooltip: 'Back',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  onPressed: () => setState(() => _beat--),
                )
              else
                const SizedBox(width: 40),
              const Spacer(),
              TextButton(
                key: const Key('rescue-skip'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.55,
                  ),
                ),
                onPressed: () {
                  setState(() => _beat = _beats.length);
                  widget.controller.recordOnboardingStep('choose_species');
                },
                child: const Text('Skip'),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CozyImage(
              _beatIllos[_beat],
              width: 280,
              height: 188,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            b.title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            b.body,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            key: const Key('rescue-next'),
            onPressed: () {
              setState(() => _beat++);
              if (_beat >= _beats.length) {
                widget.controller.recordOnboardingStep('choose_species');
              }
            },
            child: Text(
              _beat == _beats.length - 1 ? 'Will you help?' : 'Reach out',
            ),
          ),
        ],
      );
    }
    if (_species == null) return _chooseSpecies(context);
    return _nameAndAdopt(context);
  }

  Widget _chooseSpecies(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const CozyImage(
            KpAssets.adoptionChoice,
            width: 280,
            height: 176,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Will you give it a forever home?',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _speciesCard('choose-puppy', Species.puppy),
            _speciesCard('choose-kitten', Species.kitten),
          ],
        ),
      ],
    );
  }

  Widget _speciesCard(String key, Species species) {
    // The REAL character greets the player at the emotional peak (KP-029) —
    // an OS emoji here read as a prototype right above the premium rug art.
    // Deterministic (no idle loop), so tests and goldens stay stable.
    final preview = VectorPetRenderer(
      speciesOf: () => species,
      size: 88,
      continuousMotion: false,
    );
    return Card(
      child: InkWell(
        key: Key(key),
        onTap: () {
          // Pre-fill the name with the species default → one-tap adopt is a
          // valid, friction-free path (recovery + progressive disclosure, P5-1).
          setState(() {
            _species = species;
            _name.text = species.defaultName;
          });
          widget.controller.recordOnboardingStep('species_selected');
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: preview.build(
                    context,
                    mood: PetMood.joyful,
                    lifeStage: LifeStage.pupKit.id,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(species.displayName),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nameAndAdopt(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'What will you name your new friend?',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          // Responsive: caps at 240 but shrinks on very narrow screens.
          constraints: const BoxConstraints(maxWidth: 240),
          child: TextField(
            key: const Key('name-field'),
            controller: _name,
            textAlign: TextAlign.center,
            maxLength: NameInputValidator.maxLength,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: _nameError,
            ),
            // Clear the gentle nudge as soon as they start fixing the name.
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('confirm-adopt'),
          onPressed: _adopting ? null : _adopt,
          icon: const Icon(Icons.favorite),
          label: const Text('Welcome home'),
        ),
      ],
    );
  }

  Future<void> _adopt() async {
    // Filter the one free-text field before it is ever stored (child-safe for
    // ALL, §11.1). A rejected name shows a gentle, in-character nudge — never a
    // scolding (cozy-game tone, no guilt §18) — and blocks the adopt.
    final result = _validator.validate(_name.text);
    if (!result.isValid) {
      setState(() {
        _nameError = _nudgeFor(result.rejection!);
        _adopting = false;
      });
      return;
    }
    setState(() {
      _adopting = true;
      _nameError = null;
    });
    await widget.controller.adopt(species: _species!, name: result.sanitized);
    // The app routes to the Nest automatically when the controller gains a pet.
  }

  /// Warm, in-character copy for a rejected name (never harsh).
  String _nudgeFor(NameRejection reason) {
    switch (reason) {
      case NameRejection.empty:
        return 'Your new friend needs a name 💛';
      case NameRejection.tooLong:
        return 'That name is a little long — try a shorter one.';
      case NameRejection.containsPii:
        return "Let's keep personal details out — pick a fun name!";
      case NameRejection.containsProfanity:
      case NameRejection.invalidChars:
        return "Let's pick a kinder name for your new friend 💛";
    }
  }
}

class _Beat {
  const _Beat(this.emoji, this.title, this.body);
  final String emoji;
  final String title;
  final String body;
}
