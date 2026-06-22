/// Account / identity abstraction (GAME_TECHNICAL_SYSTEMS.md §8.3).
///
/// MVP supports Apple / Google sign-in + guest. PII is minimized (no
/// email/password). The default implementation is an in-memory guest account
/// so the app is usable before Firebase Auth is provisioned.
library;

abstract interface class AuthService {
  /// The current account id (a stable guest id until linked), or null.
  String? get currentUserId;

  bool get isGuest;

  Future<String> signInGuest();

  /// Linking a guest to a real account is a forced-MVP requirement (#25,
  /// "no update may orphan a pet"); the real adapters implement these.
  Future<String> signInWithApple();
  Future<String> signInWithGoogle();
}

/// Offline default: a single stable guest identity. No network, no PII.
class GuestAuthService implements AuthService {
  final String _userId = 'guest-local';

  @override
  String? get currentUserId => _userId;

  @override
  bool get isGuest => true;

  @override
  Future<String> signInGuest() async => _userId;

  @override
  Future<String> signInWithApple() => throw UnimplementedError(
    'Apple Sign-In requires Firebase Auth — see REQUIRED_ENVIRONMENTS.md',
  );

  @override
  Future<String> signInWithGoogle() => throw UnimplementedError(
    'Google Sign-In requires Firebase Auth — see REQUIRED_ENVIRONMENTS.md',
  );
}
