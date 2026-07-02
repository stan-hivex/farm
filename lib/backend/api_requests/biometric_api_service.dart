class BiometricApiService {
  static Future<Map<String, dynamic>> verifyDevice({
    required String token,
    required String deviceFingerprint,
  }) async {
    return {
      'trusted': true,
      'requiresReauth': false,
      'message': 'Device verified',
    };
  }

  static Future<Map<String, dynamic>> enableBiometrics({
    required String token,
    required String deviceFingerprint,
    required String biometricType,
  }) async {
    return {
      'success': true,
      'deviceId': 'local-device-${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Biometrics enabled locally',
    };
  }
}
