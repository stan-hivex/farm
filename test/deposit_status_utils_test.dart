import 'package:flutter_test/flutter_test.dart';
import 'package:farm/pages/depositpage/deposit_status_utils.dart';

void main() {
  group('deposit status helpers', () {
    test('treats success-like values as completed', () {
      expect(parseDepositLifecycleStatus('SUCCESS'), DepositLifecycleStatus.completed);
      expect(parseDepositLifecycleStatus('completed'), DepositLifecycleStatus.completed);
      expect(parseDepositLifecycleStatus('paid'), DepositLifecycleStatus.completed);
    });

    test('treats failure-like values as failed', () {
      expect(parseDepositLifecycleStatus('failed'), DepositLifecycleStatus.failed);
      expect(parseDepositLifecycleStatus('cancelled'), DepositLifecycleStatus.failed);
      expect(parseDepositLifecycleStatus('error'), DepositLifecycleStatus.failed);
    });

    test('keeps pending values pending', () {
      expect(parseDepositLifecycleStatus('pending'), DepositLifecycleStatus.pending);
      expect(parseDepositLifecycleStatus('processing'), DepositLifecycleStatus.pending);
    });
  });
}
