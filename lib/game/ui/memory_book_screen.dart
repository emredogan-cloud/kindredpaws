/// The Memory Book v2 (GAMEPLAY_AND_PROGRESSION_BIBLE.md §7.2, P2-3): the
/// player-visible, tangible record of what the pet remembers — the provable
/// trust signal that the memory is real (Risk R3). Organized into warm
/// categories (Rescue / Favorites / Milestones / Our Bond / Growing Up). All
/// content is closed-set + templated; NO free-text from the player (Risk R1).
library;

import 'package:flutter/material.dart';

import '../../heartmind/memory_book.dart';
import '../../heartmind/memory_category.dart';
import '../controller/game_controller.dart';

class MemoryBookScreen extends StatelessWidget {
  const MemoryBookScreen({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final pet = controller.pet;
    final theme = Theme.of(context);

    if (pet == null) {
      return Scaffold(
        key: const Key('memory-book'),
        appBar: AppBar(title: const Text('The Memory Book')),
        body: const SizedBox.shrink(),
      );
    }

    final book = MemoryBook.build(
      facts: controller.facts,
      petName: pet.name,
      speciesLabel: pet.species.displayName,
      bondStageLabel: pet.bond.stage.displayName,
      lifeStageLabel: pet.lifeStage.displayName,
      createdAtMs: pet.createdAtMs,
    );

    return Scaffold(
      key: const Key('memory-book'),
      appBar: AppBar(title: const Text('The Memory Book')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Our Story', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const ExcludeSemantics(
                child: Text('🐾', style: TextStyle(fontSize: 24)),
              ),
              title: Text(pet.name),
              subtitle: Text(
                'A ${pet.species.displayName.toLowerCase()} I met on Rescue Day. '
                'We are ${pet.bond.stage.displayName}s.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final category in book.populatedCategories)
            _CategorySection(
              category: category,
              entries: book.inCategory(category),
            ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.entries});

  final MemoryCategory category;
  final List<MemoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: Key('memory-category-${category.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            ExcludeSemantics(
              child: Text(category.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 6),
            Text(category.displayName, style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 6),
        for (final e in entries)
          Card(child: ListTile(dense: true, title: Text(e.text))),
      ],
    );
  }
}
