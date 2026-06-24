/// Structured, privacy-by-design logging (P1-2 observability).
///
/// Logs are **structured** (a message + a string→value field map) and severity-
/// tagged so they can be shipped to Crashlytics/Cloud Logging later without a
/// rewrite. Privacy is a hard rule (Risk R1): [LogRecord.sanitizedFields] drops
/// any key flagged as PII-bearing, and free-text from minors is never logged.
library;

/// Severity levels (ascending). `wtf` = "should never happen" / assertion-grade.
enum LogLevel { debug, info, warn, error, wtf }

/// One structured log line. Immutable.
class LogRecord {
  LogRecord({
    required this.level,
    required this.message,
    Map<String, Object?> fields = const {},
  }) : fields = Map.unmodifiable(fields);

  final LogLevel level;
  final String message;
  final Map<String, Object?> fields;

  /// Field keys that must never be emitted (PII / free-text). Conservative by
  /// design — observability data is coarse and non-identifying (brief §10).
  static const Set<String> blockedKeys = {
    'name',
    'petName',
    'email',
    'userText',
    'message',
    'freeText',
    'dialogue',
    'fact',
    'factText',
    'comment', // beta feedback note — only its sentiment LABEL may ship (P5-5)
    'note',
  };

  /// [fields] with PII-bearing keys removed. Used by every sink before emit.
  Map<String, Object?> get sanitizedFields => {
    for (final e in fields.entries)
      if (!blockedKeys.contains(e.key)) e.key: e.value,
  };
}

abstract interface class Logger {
  void log(
    LogLevel level,
    String message, {
    Map<String, Object?> fields = const {},
  });

  void debug(String m, {Map<String, Object?> fields = const {}});
  void info(String m, {Map<String, Object?> fields = const {}});
  void warn(String m, {Map<String, Object?> fields = const {}});
  void error(String m, {Map<String, Object?> fields = const {}});
}

/// Base that implements the convenience methods on top of [log].
abstract class BaseLogger implements Logger {
  const BaseLogger();

  @override
  void debug(String m, {Map<String, Object?> fields = const {}}) =>
      log(LogLevel.debug, m, fields: fields);
  @override
  void info(String m, {Map<String, Object?> fields = const {}}) =>
      log(LogLevel.info, m, fields: fields);
  @override
  void warn(String m, {Map<String, Object?> fields = const {}}) =>
      log(LogLevel.warn, m, fields: fields);
  @override
  void error(String m, {Map<String, Object?> fields = const {}}) =>
      log(LogLevel.error, m, fields: fields);
}

/// Captures records in memory (tests, and the breadcrumb buffer a crash report
/// attaches). Applies the PII filter on write. Optional [minLevel] gate.
class InMemoryLogger extends BaseLogger {
  InMemoryLogger({this.minLevel = LogLevel.debug});

  final LogLevel minLevel;
  final List<LogRecord> records = [];

  @override
  void log(
    LogLevel level,
    String message, {
    Map<String, Object?> fields = const {},
  }) {
    if (level.index < minLevel.index) return;
    final record = LogRecord(level: level, message: message, fields: fields);
    // Store already-sanitized so no PII ever rests in the buffer.
    records.add(
      LogRecord(
        level: record.level,
        message: record.message,
        fields: record.sanitizedFields,
      ),
    );
  }

  int countAtLeast(LogLevel level) =>
      records.where((r) => r.level.index >= level.index).length;

  void clear() => records.clear();
}
