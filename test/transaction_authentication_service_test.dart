import 'package:flutter_test/flutter_test.dart';
import 'package:farm/services/transaction_authentication_service.dart';

void main() {
  group('TransactionAuthenticationService outcome resolution', () {
    test('returns pinRequired when biometrics are not available', () {
      final outcome = TransactionAuthenticationService.resolveOutcome(
        biometricsEnabled: false,
        biometricsAvailable: false,
        biometricAuthenticated: false,
        hasDeviceFingerprint: false,
        attemptsMade: 1,
        maxBiometricAttempts: 3,
      );

      expect(outcome, TransactionAuthenticationOutcome.pinRequired);
    });

    test(
        'returns biometricAuthorized when biometric auth succeeds with a device fingerprint',
        () {
      final outcome = TransactionAuthenticationService.resolveOutcome(
        biometricsEnabled: true,
        biometricsAvailable: true,
        biometricAuthenticated: true,
        hasDeviceFingerprint: true,
        attemptsMade: 1,
        maxBiometricAttempts: 3,
      );

      expect(outcome, TransactionAuthenticationOutcome.biometricAuthorized);
    });

    test('falls back to pinRequired after all biometric attempts fail', () {
      final outcome = TransactionAuthenticationService.resolveOutcome(
        biometricsEnabled: true,
        biometricsAvailable: true,
        biometricAuthenticated: false,
        hasDeviceFingerprint: true,
        attemptsMade: 3,
        maxBiometricAttempts: 3,
      );

      expect(outcome, TransactionAuthenticationOutcome.pinRequired);
    });

    test(
        'offers the biometric flow when biometrics are enabled and a device fingerprint is stored',
        () {
      final canUse = TransactionAuthenticationService.canUseBiometricFlow(
        biometricsEnabled: true,
        biometricsAvailable: true,
        hasStoredFingerprint: true,
      );

      expect(canUse, isTrue);
    });

    test(
        'keeps the biometric flow available when a fingerprint is stored even if the app flag is stale',
        () {
      final canUse = TransactionAuthenticationService.canUseBiometricFlow(
        biometricsEnabled: false,
        biometricsAvailable: true,
        hasStoredFingerprint: true,
      );

      expect(canUse, isTrue);
    });

    test('reset clears biometric attempt tracking', () {
      final service = TransactionAuthenticationService();
      service.resetBiometricAttemptState();

      expect(service.biometricAttemptsMade, 0);
    });
  });
}
