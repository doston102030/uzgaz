/// Base failure type returned by repositories instead of throwing raw
/// exceptions, so the presentation layer can render proper error states.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Internet aloqasini tekshiring']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server xatoligi yuz berdi']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Lokal maʼlumotni oʻqib boʻlmadi']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Avtorizatsiya xatoligi']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Simple Either-style result wrapper (avoids pulling in dartz).
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}
