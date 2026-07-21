import 'package:flutter_test/flutter_test.dart';
import 'package:farm/utils/send_amount_cooldown.dart';

void main() {
  group('SendAmountCooldown', () {
    test('blocks same amount within one minute', () {
      final now = DateTime.now();
      final blocked = SendAmountCooldown.shouldBlockDuplicateSend(
        amount: 10,
        lastSentAmount: 10,
        lastSentAt: now.subtract(const Duration(seconds: 30)),
      );

      expect(blocked, isTrue);
    });

    test('allows different amount within one minute', () {
      final now = DateTime.now();
      final blocked = SendAmountCooldown.shouldBlockDuplicateSend(
        amount: 80,
        lastSentAmount: 10,
        lastSentAt: now.subtract(const Duration(seconds: 30)),
      );

      expect(blocked, isFalse);
    });

    test('allows same amount after one minute', () {
      final now = DateTime.now();
      final blocked = SendAmountCooldown.shouldBlockDuplicateSend(
        amount: 10,
        lastSentAmount: 10,
        lastSentAt: now.subtract(const Duration(minutes: 2)),
      );

      expect(blocked, isFalse);
    });
  });
}
