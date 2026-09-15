/// Whether the user is entitled to Pro features, and why.
///
/// There are three states rather than a boolean because a temporary pass — the
/// reward for watching an ad — expires, and code that has only a boolean tends
/// to forget to check when.
final class ProStatus {
  const ProStatus._({required this.isLifetime, this.passExpiry});

  /// A one-off, permanent purchase. DoctorFilter has no subscriptions.
  final bool isLifetime;

  /// When a temporary pass runs out, or null if there is none.
  final DateTime? passExpiry;

  factory ProStatus.free() => const ProStatus._(isLifetime: false);

  factory ProStatus.lifetime() => const ProStatus._(isLifetime: true);

  factory ProStatus.pass(DateTime expiry) =>
      ProStatus._(isLifetime: false, passExpiry: expiry);

  /// Whether Pro features should be available right now.
  bool get isActive {
    if (isLifetime) return true;
    final expiry = passExpiry;
    return expiry != null && expiry.isAfter(DateTime.now());
  }

  /// Time left on a temporary pass, or null when there is no live pass.
  Duration? get passRemaining {
    if (isLifetime) return null;
    final expiry = passExpiry;
    if (expiry == null) return null;
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProStatus &&
          runtimeType == other.runtimeType &&
          isLifetime == other.isLifetime &&
          passExpiry == other.passExpiry;

  @override
  int get hashCode => Object.hash(isLifetime, passExpiry);

  @override
  String toString() => isLifetime
      ? 'ProStatus(lifetime)'
      : passExpiry != null
          ? 'ProStatus(pass until $passExpiry)'
          : 'ProStatus(free)';
}
