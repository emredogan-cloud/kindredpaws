import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pins the store-listing fields to the strictest App Store / Play limits (P4-8),
/// so a submission can never carry an over-length title or "What's New". Mirrors
/// `tool/validate_store_metadata.dart`.
const Map<String, int> _limits = {
  'title': 30,
  'subtitle': 30,
  'short_description': 80,
  'keywords': 100,
  'promotional_text': 170,
  'description': 4000,
  'release_notes': 500,
};

void main() {
  group('store metadata (en-US) is submission-ready', () {
    _limits.forEach((field, limit) {
      test('$field exists, is non-empty, and ≤ $limit chars', () {
        final file = File('store/metadata/en-US/$field.txt');
        expect(file.existsSync(), isTrue, reason: 'missing $field.txt');
        final text = file.readAsStringSync().trim();
        expect(text, isNotEmpty);
        expect(
          text.runes.length,
          lessThanOrEqualTo(limit),
          reason: '$field is over the $limit-char store limit',
        );
      });
    });

    test('the privacy/data-safety + checklist sources are present', () {
      expect(File('store/privacy/data_safety.md').existsSync(), isTrue);
      expect(File('store/checklist.md').existsSync(), isTrue);
    });

    test('the description stays on-message (rescue + memory + child-safe)', () {
      final d = File(
        'store/metadata/en-US/description.txt',
      ).readAsStringSync().toLowerCase();
      expect(d, contains('rescue'));
      expect(d, contains('remember'));
      expect(d, contains('child-safe'));
      // Never overclaim donations (Risk R5 / Priya): no tax-deductible language.
      expect(d, isNot(contains('tax-deductible')));
    });
  });
}
