class SendAmountCooldown {
  static bool shouldBlockDuplicateSend({
    required double amount,
    required double? lastSentAmount,
    required DateTime? lastSentAt,
    Duration cooldown = const Duration(minutes: 1),
  }) {
    if (lastSentAmount == null || lastSentAt == null) {
      return false;
    }

    final normalizedAmount = _normalizeAmount(amount);
    final normalizedLastAmount = _normalizeAmount(lastSentAmount);
    if (normalizedAmount != normalizedLastAmount) {
      return false;
    }

    return DateTime.now().difference(lastSentAt) < cooldown;
  }

  static double _normalizeAmount(double amount) {
    return double.parse(amount.toStringAsFixed(2));
  }
}
