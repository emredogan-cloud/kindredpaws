/// Rescue Day — the 60–90s cold-open (GAMEPLAY_AND_PROGRESSION_BIBLE.md §13.1).
/// Emotionally front-loaded: empathy → care → attachment → ADOPT → naming +
/// memory seed. No tutorial wall, no account wall, no monetization (§13.3). On
/// adopt, the controller creates the pet and the app routes to the Nest.
library;

import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import '../model/species.dart';

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
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: const Key('rescue-day'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.surfaceContainerHighest, scheme.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: _body(context)),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    if (_beat < _beats.length) {
      final b = _beats[_beat];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(b.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
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
            onPressed: () => setState(() => _beat++),
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
        Text(
          'Will you give it a forever home?',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _speciesCard('choose-puppy', '🐶', Species.puppy),
            _speciesCard('choose-kitten', '🐱', Species.kitten),
          ],
        ),
      ],
    );
  }

  Widget _speciesCard(String key, String emoji, Species species) {
    return Card(
      child: InkWell(
        key: Key(key),
        onTap: () => setState(() {
          _species = species;
          _name.text = species.defaultName;
        }),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
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
        SizedBox(
          width: 240,
          child: TextField(
            key: const Key('name-field'),
            controller: _name,
            textAlign: TextAlign.center,
            maxLength: 16,
            decoration: const InputDecoration(border: OutlineInputBorder()),
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
    setState(() => _adopting = true);
    await widget.controller.adopt(species: _species!, name: _name.text);
    // The app routes to the Nest automatically when the controller gains a pet.
  }
}

class _Beat {
  const _Beat(this.emoji, this.title, this.body);
  final String emoji;
  final String title;
  final String body;
}
