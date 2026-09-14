import 'failure.dart';

/// Type-safe functional error handling Result type for pure Dart domain operations.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        FailureResult() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success() => null,
        FailureResult(:final failure) => failure,
      };

  R fold<R>(R Function(Failure failure) onFailure, R Function(T data) onSuccess) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      FailureResult(:final failure) => onFailure(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}
