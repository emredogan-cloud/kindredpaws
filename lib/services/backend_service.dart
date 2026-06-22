/// Backend (BaaS) abstraction — the authoritative store for cloud save and the
/// trust-critical objects (GAME_TECHNICAL_SYSTEMS.md §1.2). Locked choice is
/// Firebase; the in-memory default keeps the app fully functional until the
/// real project is provisioned (see REQUIRED_ENVIRONMENTS.md).
library;

abstract interface class BackendService {
  /// True once a real, authoritative backend is wired (not the mock).
  bool get isAuthoritative;

  /// Read a cloud document (e.g. the save snapshot) by collection + key.
  Future<Map<String, dynamic>?> readDocument(String collection, String key);

  /// Write a cloud document.
  Future<void> writeDocument(
    String collection,
    String key,
    Map<String, dynamic> value,
  );

  /// Append-only write (Impact-Pool ledger, Coin-mint requests). The mock
  /// keeps an in-memory list; the real backend enforces append-only server-side.
  Future<void> append(String stream, Map<String, dynamic> entry);
}

/// Offline default. Authoritative=false so callers know value/trust objects are
/// NOT yet server-gated. Suitable for dev, tests, and pre-provisioning runs.
class InMemoryBackendService implements BackendService {
  final Map<String, Map<String, Map<String, dynamic>>> _docs = {};
  final Map<String, List<Map<String, dynamic>>> _streams = {};

  @override
  bool get isAuthoritative => false;

  @override
  Future<Map<String, dynamic>?> readDocument(
    String collection,
    String key,
  ) async => _docs[collection]?[key];

  @override
  Future<void> writeDocument(
    String collection,
    String key,
    Map<String, dynamic> value,
  ) async {
    (_docs[collection] ??= {})[key] = Map<String, dynamic>.from(value);
  }

  @override
  Future<void> append(String stream, Map<String, dynamic> entry) async {
    (_streams[stream] ??= []).add(Map<String, dynamic>.from(entry));
  }

  /// Test/inspection helper.
  List<Map<String, dynamic>> entriesOf(String stream) =>
      List.unmodifiable(_streams[stream] ?? const []);
}
