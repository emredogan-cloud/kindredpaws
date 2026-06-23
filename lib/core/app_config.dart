/// Central runtime configuration + feature flags for KindredPaws.
///
/// Values are read from `--dart-define` at build time with **safe defaults**:
/// the app runs fully on mock / in-memory adapters until real backends are
/// provisioned (see `REQUIRED_ENVIRONMENTS.md`). This is Phase-0 provisioning
/// scaffolding — it contains **no gameplay**.
library;

/// Which backend implementation is wired (see GAME_TECHNICAL_SYSTEMS.md §2).
enum BackendMode { mock, firebase }

/// Which pet-rendering backend is wired (ADR-001; engine = Flutter + **Rive**,
/// locked at P1-0 after the animation spike — see `docs/ANIMATION_SPIKE_REPORT.md`).
/// `placeholder` is the deterministic Flutter-drawn stand-in used until the
/// commissioned `.riv` rig asset arrives (P2); `rive` activates the real seam.
enum PetRendererBackend { placeholder, rive }

/// Immutable, build-time application configuration.
class AppConfig {
  const AppConfig({
    required this.backendMode,
    required this.petRendererBackend,
    required this.riveAssetPath,
    required this.heartmindLiveChatEnabled,
    required this.anthropicProxyConfigured,
    required this.environmentLabel,
  });

  /// Default config used when nothing is overridden via `--dart-define`.
  /// Mock backend, placeholder renderer, live chat OFF, no proxy — fully
  /// offline-safe and deterministic for dev/CI/golden tests.
  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      backendMode: _backend == 'firebase'
          ? BackendMode.firebase
          : BackendMode.mock,
      petRendererBackend: _renderer == 'rive'
          ? PetRendererBackend.rive
          : PetRendererBackend.placeholder,
      // Empty `--dart-define` ⇒ null ⇒ the Rive seam paints its stand-in.
      riveAssetPath: _riveAsset == '' ? null : _riveAsset,
      heartmindLiveChatEnabled: _liveChat,
      anthropicProxyConfigured: _proxy,
      environmentLabel: _env,
    );
  }

  /// Selected backend (Firebase is the locked choice; mock until provisioned).
  final BackendMode backendMode;

  /// Selected pet-render backend (Rive is the locked rig runtime; placeholder
  /// until the commissioned `.riv` asset arrives at P2).
  final PetRendererBackend petRendererBackend;

  /// Path to the bundled `.riv` rig (from `KP_RIV_ASSET`), or null to run the
  /// Rive seam's native-free stand-in. Only consulted when [petRendererBackend]
  /// is `rive`.
  final String? riveAssetPath;

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
  static const String _renderer = String.fromEnvironment(
    'KP_PET_RENDERER',
    defaultValue: 'placeholder',
  );
  static const String _riveAsset = String.fromEnvironment(
    'KP_RIV_ASSET',
    defaultValue: '',
  );
  static const bool _liveChat = bool.fromEnvironment('KP_HEARTMIND_LIVE_CHAT');
  static const bool _proxy = bool.fromEnvironment('KP_ANTHROPIC_PROXY');
  static const String _env = String.fromEnvironment(
    'KP_ENV',
    defaultValue: 'dev',
  );
}
