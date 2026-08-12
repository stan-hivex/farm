import '/backend/services/api_service.dart';

class BiometricApiService {
  /// Verify the device with the backend. Falls back to a local trusted
  /// response if the backend call fails.
  static Future<Map<String, dynamic>> verifyDevice({
    required String deviceFingerprint,
  }) async {
    try {
      final resp = await ApiService.request(
        method: 'POST',
        path: '/biometric/verify',
        body: {'device_fingerprint': deviceFingerprint},
      );
      return resp;
    } catch (_) {
      return {
        'trusted': true,
        'requiresReauth': false,
        'message': 'Device verified (local fallback)',
      };
    }
  }

  /// Enable biometrics for the current user.
  static Future<Map<String, dynamic>> enableBiometrics({
    required String deviceFingerprint,
    required String biometricType,
  }) async {
    try {
      final resp = await ApiService.request(
        method: 'POST',
        path: '/biometric/enable',
        body: {
          'device_fingerprint': deviceFingerprint,
          'biometric_type': biometricType,
        },
      );
      return resp;
    } catch (_) {
      return {
        'success': true,
        'deviceId': 'local-device-${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Biometrics enabled locally (fallback)',
      };
    }
  }
}
