/// Minimal service locator (dependency injection) with no external package.
///
/// At startup `bootstrap()` registers concrete service implementations chosen
/// from [AppConfig]; the rest of the app resolves them by type. Keeping this
/// in-house avoids a DI dependency for a solo+AI codebase.
library;

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  final Map<Type, Object> _singletons = {};

  void registerSingleton<T extends Object>(T impl) => _singletons[T] = impl;

  T get<T extends Object>() {
    final s = _singletons[T];
    if (s == null) {
      throw StateError('No service registered for $T. Did bootstrap() run?');
    }
    return s as T;
  }

  bool isRegistered<T extends Object>() => _singletons.containsKey(T);

  /// Clears all registrations (used by tests).
  void reset() => _singletons.clear();
}
