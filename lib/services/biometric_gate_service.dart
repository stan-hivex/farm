class BiometricGateService {
  static bool shouldRequireBiometricCheck(DateTime? lastVerified) {
    if (lastVerified == null) return true;
    return DateTime.now().difference(lastVerified).inMinutes > 10;
  }
}
