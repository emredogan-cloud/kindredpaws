/// The Memory Book (GAMEPLAY_AND_PROGRESSION_BIBLE.md §7.2): the player-visible,
/// tangible record of what the pet remembers — the provable trust signal that
/// the memory is real (Risk R3). P1 surfaces the closed-set, templated facts the
/// game seeds from gameplay events; NO free-text from the player (Risk R1).
library;

import 'package:flutter/material.dart';

import '../../heartmind/memory_fact.dart';
import '../controller/game_controller.dart';

class MemoryBookScreen extends StatelessWidget {
  const MemoryBookScreen({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final pet = controller.pet;
    final facts = controller.facts;
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('memory-book'),
      appBar: AppBar(title: const Text('The Memory Book')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pet != null) ...[
            Text('Our Story', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Text('🐾', style: TextStyle(fontSize: 24)),
                title: Text(pet.name),
                subtitle: Text(
                  'A ${pet.species.displayName.toLowerCase()} I met on Rescue Day. '
                  'We are ${pet.bond.stage.displayName}s.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What ${pet.name} remembers',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
          ],
          if (facts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'As you feed, clean, and play with ${pet?.name ?? 'your pet'}, '
                'the moments you share will appear here.',
              ),
            )
          else
            ...facts.map(
              (f) => Card(
                key: Key('memory-${f.key.name}-${f.createdAtMs}'),
                child: ListTile(
                  leading: ExcludeSemantics(
                    child: Text(
                      _emojiFor(f.key),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  title: Text(_lineFor(pet?.name ?? 'Your pet', f)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _emojiFor(FactKey key) => switch (key) {
    FactKey.importantDate => '📅',
    FactKey.likesActivity => '🎾',
    FactKey.favoriteThing => '⭐',
    FactKey.favoriteColor => '🎨',
    FactKey.namedPetAfter => '💭',
    FactKey.hadAHardDayOn => '🤍',
  };

  String _lineFor(String name, MemoryFact f) => switch (f.key) {
    FactKey.importantDate => f.value,
    FactKey.likesActivity => '$name loves ${f.value}',
    FactKey.favoriteThing => "$name's favorite is ${f.value}",
    FactKey.favoriteColor => 'Favorite color: ${f.value}',
    FactKey.namedPetAfter => 'Named after ${f.value}',
    FactKey.hadAHardDayOn => 'Was there for you on ${f.value}',
  };
}
