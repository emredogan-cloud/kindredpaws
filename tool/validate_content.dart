/// Content OS validation gate (P3-3) — `just content-validate`.
///
/// Validates a dialogue bank against the Content OS rules (see
/// `lib/content/content_validator.dart`, `docs/CONTENT_OPERATING_SYSTEM.md`) and
/// exits non-zero on any error, so CI and the offline pre-gen workflow can gate
/// on it. With no argument it validates the bundled launch bank; pass a path to
/// validate an offline-generated JSON bank before it's shipped/reviewed.
///
///   dart run tool/validate_content.dart [path/to/bank.json]
library;

import 'dart:io';

import 'package:kindredpaws/content/content_validator.dart';
import 'package:kindredpaws/heartmind/dialogue_bank.dart';
import 'package:kindredpaws/heartmind/local_heartmind.dart';

void main(List<String> args) {
  const validator = ContentValidator();

  final DialogueBank bank;
  final String source;
  if (args.isNotEmpty) {
    final file = File(args.first);
    if (!file.existsSync()) {
      stderr.writeln('content: file not found: ${args.first}');
      exit(2);
    }
    try {
      bank = DialogueBank.fromJsonString(file.readAsStringSync());
    } catch (e) {
      stderr.writeln('content: could not parse ${args.first}: $e');
      exit(2);
    }
    source = args.first;
  } else {
    bank = defaultDialogueBank();
    source = 'bundled launch bank (defaultDialogueBank)';
  }

  final report = validator.validateBank(bank);
  final lineCount = bank.entries.fold<int>(0, (n, e) => n + e.lines.length);

  stdout.writeln('content: validating $source');
  for (final issue in report.issues) {
    stdout.writeln('  $issue');
  }
  stdout.writeln(report.summary(bank.entries.length, lineCount));
  exit(report.ok ? 0 : 1);
}
