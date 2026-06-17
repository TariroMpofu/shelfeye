/// Minimal Result type so the repository can return either data or an
/// operator-readable message without throwing across layers.
sealed class Result<T> {
  const Result();
  R when<R>({
    required R Function(T value) ok,
    required R Function(String message) err,
  }) {
    final self = this;
    if (self is Ok<T>) return ok(self.value);
    return err((self as Err<T>).message);
  }
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final String message;
  const Err(this.message);
}
