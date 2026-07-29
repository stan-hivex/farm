import 'package:flutter/foundation.dart';
import '/services/biometric_lock_service.dart';
import '/services/device_fingerprint_service.dart';
import '/services/secure_storage_service.dart';

enum TransactionAuthenticationOutcome {
  biometricAuthorized,
  pinRequired,
}

class TransactionAuthenticationResult {
  const TransactionAuthenticationResult({
    required this.outcome,
    this.deviceFingerprint,
  });

  final TransactionAuthenticationOutcome outcome;
  final String? deviceFingerprint;

  bool get biometricUsed =>
      outcome == TransactionAuthenticationOutcome.biometricAuthorized;
}

class TransactionAuthenticationService {
  static final TransactionAuthenticationService _instance =
      TransactionAuthenticationService._internal();
  factory TransactionAuthenticationService() => _instance;
  TransactionAuthenticationService._internal();

  int _biometricAttemptsMade = 0;

  int get biometricAttemptsMade => _biometricAttemptsMade;

  void resetBiometricAttemptState() {
    _biometricAttemptsMade = 0;
  }

  void recordBiometricAttemptFailure() {
    _biometricAttemptsMade += 1;
  }

  static bool canUseBiometricFlow({
    required bool biometricsEnabled,
    required bool biometricsAvailable,
    required bool hasStoredFingerprint,
  }) {
    return biometricsAvailable &&
        hasStoredFingerprint &&
        (biometricsEnabled || hasStoredFingerprint);
  }

  static TransactionAuthenticationOutcome resolveOutcome({
    required bool biometricsEnabled,
    required bool biometricsAvailable,
    required bool biometricAuthenticated,
    required bool hasDeviceFingerprint,
    required int attemptsMade,
    required int maxBiometricAttempts,
  }) {
    if (!canUseBiometricFlow(
      biometricsEnabled: biometricsEnabled,
      biometricsAvailable: biometricsAvailable,
      hasStoredFingerprint: hasDeviceFingerprint,
    )) {
      return TransactionAuthenticationOutcome.pinRequired;
    }

    if (biometricAuthenticated && hasDeviceFingerprint) {
      return TransactionAuthenticationOutcome.biometricAuthorized;
    }

    if (attemptsMade >= maxBiometricAttempts) {
      return TransactionAuthenticationOutcome.pinRequired;
    }

    return TransactionAuthenticationOutcome.pinRequired;
  }

  Future<bool> canUseBiometricAuth() async {
    try {
      if (!await BiometricLockService().isBiometricEnabled()) {
        return false;
      }
      return await BiometricLockService().canUseBiometrics();
    } catch (_) {
      return false;
    }
  }

  Future<String?> _ensureStoredFingerprint() async {
    final existing = await SecureStorageService.readDeviceFingerprint();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = await DeviceFingerprintService.getDeviceFingerprint();
    if (generated.isNotEmpty) {
      await SecureStorageService.writeDeviceFingerprint(generated);
    }
    return generated;
  }

  Future<TransactionAuthenticationResult> authenticateTransaction({
    String localizedReason = 'Confirm transaction',
    int maxBiometricAttempts = 3,
  }) async {
    try {
      final biometricsEnabled =
          await BiometricLockService().isBiometricEnabled();
      final biometricsAvailable =
          await BiometricLockService().canUseBiometrics();
      final storedFingerprint = await _ensureStoredFingerprint();
      final hasStoredFingerprint =
          (storedFingerprint != null && storedFingerprint.isNotEmpty);

      if (!canUseBiometricFlow(
        biometricsEnabled: biometricsEnabled,
        biometricsAvailable: biometricsAvailable,
        hasStoredFingerprint: hasStoredFingerprint,
      )) {
        resetBiometricAttemptState();
        return const TransactionAuthenticationResult(
          outcome: TransactionAuthenticationOutcome.pinRequired,
        );
      }

      if (_biometricAttemptsMade >= maxBiometricAttempts) {
        resetBiometricAttemptState();
        return const TransactionAuthenticationResult(
          outcome: TransactionAuthenticationOutcome.pinRequired,
        );
      }

      final authenticated = await BiometricLockService().authenticate(
        localizedReason: localizedReason,
      );

      if (authenticated) {
        resetBiometricAttemptState();
        await BiometricLockService().markVerified();
        final deviceFingerprint = await _ensureStoredFingerprint();
        debugPrint(
            'TransactionAuthentication: biometric succeeded, stored fingerprint present=${deviceFingerprint != null && deviceFingerprint.isNotEmpty}');
        if (deviceFingerprint != null && deviceFingerprint.isNotEmpty) {
          return TransactionAuthenticationResult(
            outcome: TransactionAuthenticationOutcome.biometricAuthorized,
            deviceFingerprint: deviceFingerprint,
          );
        }
      }

      recordBiometricAttemptFailure();
      return const TransactionAuthenticationResult(
        outcome: TransactionAuthenticationOutcome.pinRequired,
      );
    } catch (_) {
      return const TransactionAuthenticationResult(
        outcome: TransactionAuthenticationOutcome.pinRequired,
      );
    }
  }
}
