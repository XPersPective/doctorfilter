/// Sealed class hierarchy representing domain failures across the application.
sealed class Failure {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.cause});
}

final class PlatformFailure extends Failure {
  const PlatformFailure(super.message, {super.cause});
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause});
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause});
}
