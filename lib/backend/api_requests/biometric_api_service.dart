import '/backend/services/api_service.dart';

class BiometricApiService {
  /// Verify the current device fingerprint with the backend.
  static Future<Map<String, dynamic>> verifyDevice({
    required String deviceFingerprint,
  }) {
    return ApiService.request(
      method: 'POST',
      path: '/security/verify-device',
      body: {'deviceFingerprint': deviceFingerprint},
    );
  }

  /// Enable biometrics for the current user.
  static Future<Map<String, dynamic>> enableBiometrics({
    required String deviceFingerprint,
    required String biometricType,
  }) async {
    return ApiService.request(
      method: 'PUT',
      path: '/security/biometrics',
      body: {
        'enabled': true,
        'deviceFingerprint': deviceFingerprint,
        'biometricType': biometricType,
      },
    );
  }
}
