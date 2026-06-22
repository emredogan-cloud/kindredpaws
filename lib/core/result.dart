/// A tiny `Result` type so service/repository calls can return success or a
/// typed failure without throwing across layer boundaries. Foundation only.
library;

sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  /// Returns the value if [Ok], otherwise [fallback].
  T orElse(T fallback) => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => fallback,
  };
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}
