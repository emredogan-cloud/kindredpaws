/// Central runtime configuration + feature flags for KindredPaws.
///
/// Values are read from `--dart-define` at build time with **safe defaults**:
/// the app runs fully on mock / in-memory adapters until real backends are
/// provisioned (see `REQUIRED_ENVIRONMENTS.md`). This is Phase-0 provisioning
/// scaffolding — it contains **no gameplay**.
library;

/// Which backend implementation is wired (see GAME_TECHNICAL_SYSTEMS.md §2).
enum BackendMode { mock, firebase }

/// Immutable, build-time application configuration.
class AppConfig {
  const AppConfig({
    required this.backendMode,
    required this.heartmindLiveChatEnabled,
    required this.anthropicProxyConfigured,
    required this.environmentLabel,
  });

  /// Default config used when nothing is overridden via `--dart-define`.
  /// Mock backend, live chat OFF, no proxy — fully offline-safe for dev/CI.
  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      backendMode: _backend == 'firebase'
          ? BackendMode.firebase
          : BackendMode.mock,
      heartmindLiveChatEnabled: _liveChat,
      anthropicProxyConfigured: _proxy,
      environmentLabel: _env,
    );
  }

  /// Selected backend (Firebase is the locked choice; mock until provisioned).
  final BackendMode backendMode;

  /// Deferred feature #6b: live free-form LLM chat. MUST stay OFF for MVP
  /// (age-gated + subscriber-only, post-soft-launch). See the decision log.
  final bool heartmindLiveChatEnabled;

  /// Whether the server-side Heartmind proxy (the only holder of the Anthropic
  /// API key) is configured. The client NEVER calls Anthropic directly.
  final bool anthropicProxyConfigured;

  /// Free-form environment label (dev / staging / soft-launch / prod).
  final String environmentLabel;

  bool get usingMockBackend => backendMode == BackendMode.mock;

  static const String _backend = String.fromEnvironment(
    'KP_BACKEND',
    defaultValue: 'mock',
  );
  static const bool _liveChat = bool.fromEnvironment('KP_HEARTMIND_LIVE_CHAT');
  static const bool _proxy = bool.fromEnvironment('KP_ANTHROPIC_PROXY');
  static const String _env = String.fromEnvironment(
    'KP_ENV',
    defaultValue: 'dev',
  );
}
