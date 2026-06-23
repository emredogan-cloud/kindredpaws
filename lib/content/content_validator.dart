/// Content Operating System — validation gate (P3-3).
///
/// The hybrid MVP ships an offline-pre-generated, **100% human-reviewed**
/// dialogue bank (CONTENT_FACTORY §7.2/§10.2). This validator is the automated
/// half of that gate: it proves a bank is **safe + well-formed by construction**
/// before it can ship (bundled OR pushed via Remote Config), so a malformed or
/// off-tone line can never reach a child (Risk R1/R6/R10). It is the enforcement
/// behind `just content-validate` and `mergeRemoteContent`.
///
/// Rules enforced (see `docs/CONTENT_OPERATING_SYSTEM.md`):
///  - **Vocabulary** — intent/mood/bondStage/lifeStage are from the SSOT enums
///    (`*` wildcard allowed); a typo'd tag is dead content → error.
///  - **Slots** — every `{fact:slot}` resolves to a closed-set [FactKey]
///    ([kSlotToFactKey]); an unknown slot is unfillable → error.
///  - **Safety by construction** — every line (slots filled with a neutral
///    placeholder) passes the fail-closed [SafetyFilter] (no banned topics, not
///    empty) AND the never-guilt tone scan (Risk R6 / D-047).
///  - **Shape** — every entry has ≥1 non-empty line.
library;

import '../game/model/bond.dart';
import '../game/model/mood.dart';
import '../heartmind/dialogue_bank.dart';
import '../heartmind/heartmind_intent.dart';
import '../heartmind/memory_injection.dart';
import '../heartmind/safety_filter.dart';

/// Severity of a content issue. [error] blocks shipping; [warning] is advisory.
enum ContentSeverity { error, warning }

/// One problem found in a content entry/line.
class ContentIssue {
  const ContentIssue(this.severity, this.entryKey, this.message, {this.line});

  final ContentSeverity severity;
  final String entryKey;
  final String message;

  /// The offending line text, when the issue is line-scoped.
  final String? line;

  @override
  String toString() {
    final tag = severity == ContentSeverity.error ? 'ERROR' : 'warn ';
    final where = line == null ? '' : ' · "$line"';
    return '[$tag] $entryKey: $message$where';
  }
}

/// The outcome of validating a bank: the issues + convenience rollups.
class ContentReport {
  ContentReport(this.issues);

  final List<ContentIssue> issues;

  Iterable<ContentIssue> get errors =>
      issues.where((i) => i.severity == ContentSeverity.error);
  Iterable<ContentIssue> get warnings =>
      issues.where((i) => i.severity == ContentSeverity.warning);

  int get errorCount => errors.length;
  int get warningCount => warnings.length;

  /// A bank ships only when there are no errors.
  bool get ok => errorCount == 0;

  String summary(int entryCount, int lineCount) =>
      'content: $entryCount entries / $lineCount lines · '
      '$errorCount error(s), $warningCount warning(s)'
      '${ok ? " · OK" : ""}';
}

/// Validates dialogue content against the Content OS rules.
class ContentValidator {
  const ContentValidator();

  /// Never-guilt tone words (Risk R6 / D-047) — a cozy companion must never
  /// frame care as obligation. Authoring-time content policy (stricter than the
  /// runtime fail-closed [SafetyFilter]).
  static const List<String> forbiddenGuiltLanguage = [
    'starving',
    'dying',
    'sick',
    'abandon',
    'guilt',
    'miss you',
    'forgot',
    'neglect',
    'punish',
    'lonely without',
  ];

  // SSOT vocabularies (derived from the canonical enums; `*` is a wildcard).
  static final Set<String> _intents = HeartmindIntent.values
      .map((i) => i.id)
      .toSet();
  static final Set<String> _moods = Mood.values.map((m) => m.name).toSet();
  static final Set<String> _bondStages = BondStage.values
      .map((b) => b.displayName)
      .toSet();
  static const Set<String> _lifeStages = {'Pup/Kit', 'Young One', 'Grown'};
  static const Set<String> _knownDials = {
    'playful',
    'calm',
    'cuddly',
    'brave',
    'chatty',
  };

  static final RegExp _slot = RegExp(r'\{fact:([a-z_]+)\}');

  /// Validates every entry + line in [bank].
  ContentReport validateBank(DialogueBank bank) {
    final issues = <ContentIssue>[];
    for (final e in bank.entries) {
      _validateEntry(e, issues);
    }
    return ContentReport(issues);
  }

  void _validateEntry(DialogueBankEntry e, List<ContentIssue> out) {
    final key = e.key;
    void err(String m, {String? line}) =>
        out.add(ContentIssue(ContentSeverity.error, key, m, line: line));
    void warn(String m, {String? line}) =>
        out.add(ContentIssue(ContentSeverity.warning, key, m, line: line));

    // Vocabulary (wildcard `*` always allowed).
    if (!_intents.contains(e.intent)) err('unknown intent "${e.intent}"');
    if (e.mood != '*' && !_moods.contains(e.mood)) {
      err('unknown mood "${e.mood}"');
    }
    if (e.bondStage != '*' && !_bondStages.contains(e.bondStage)) {
      err('unknown bondStage "${e.bondStage}"');
    }
    if (e.lifeStage != '*' && !_lifeStages.contains(e.lifeStage)) {
      err('unknown lifeStage "${e.lifeStage}"');
    }
    if (e.personalityDial != '*' &&
        !_knownDials.contains(e.personalityDial.toLowerCase())) {
      warn('unrecognized personalityDial "${e.personalityDial}"');
    }

    // Shape.
    if (e.lines.isEmpty) {
      err('entry has no lines');
      return;
    }

    // Per-line: slots resolve to the closed set + safety-by-construction.
    for (final line in e.lines) {
      if (line.trim().isEmpty) {
        err('empty line', line: line);
        continue;
      }
      for (final m in _slot.allMatches(line)) {
        final slot = m.group(1)!;
        if (!kSlotToFactKey.containsKey(slot)) {
          err('unknown memory slot "{fact:$slot}"', line: line);
        }
      }
      final rendered = _renderForScan(line);
      final verdict = const SafetyFilter().validateOutput(rendered);
      if (!verdict.safe) {
        err('fails safety filter (${verdict.reason})', line: line);
      }
      final lower = rendered.toLowerCase();
      for (final w in forbiddenGuiltLanguage) {
        if (lower.contains(w)) {
          err('never-guilt violation ("$w")', line: line);
        }
      }
    }
  }

  /// Replaces `{fact:slot}` tokens with a neutral placeholder so the safety/tone
  /// scan runs on realistic text (and so the fail-closed unfilled-slot check in
  /// [SafetyFilter] doesn't mask the real content).
  String _renderForScan(String line) =>
      line.replaceAll(_slot, 'something nice');
}
