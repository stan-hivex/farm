import '/services/transaction_authentication_service.dart';

enum AuthorizationOutcome { success, requirePin }

class AuthorizationResult {
  const AuthorizationResult({required this.outcome, this.deviceFingerprint});

  final AuthorizationOutcome outcome;
  final String? deviceFingerprint;

  bool get biometricUsed => outcome == AuthorizationOutcome.success;

  TransactionAuthenticationResult toTransactionAuthenticationResult() {
    return biometricUsed
        ? TransactionAuthenticationResult(
            outcome: TransactionAuthenticationOutcome.biometricAuthorized,
            deviceFingerprint: deviceFingerprint,
          )
        : const TransactionAuthenticationResult(
            outcome: TransactionAuthenticationOutcome.pinRequired,
          );
  }
}

class TransactionAuthorizationService {
  static final TransactionAuthorizationService _instance = TransactionAuthorizationService._internal();
  factory TransactionAuthorizationService() => _instance;
  TransactionAuthorizationService._internal();

  /// Attempts biometric-first authorization for a transaction.
  /// Returns [AuthorizationResult] indicating whether biometric succeeded
  /// or a PIN is required.
  Future<AuthorizationResult> authorizeTransaction({String localizedReason = 'Confirm transaction'}) async {
    try {
      final auth = await TransactionAuthenticationService().authenticateTransaction(localizedReason: localizedReason);
      if (auth.biometricUsed) {
        return AuthorizationResult(outcome: AuthorizationOutcome.success, deviceFingerprint: auth.deviceFingerprint);
      }
      return const AuthorizationResult(outcome: AuthorizationOutcome.requirePin);
    } catch (_) {
      return const AuthorizationResult(outcome: AuthorizationOutcome.requirePin);
    }
  }
}
