import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static Future<DateTime?> readBiometricLastVerified() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('biometric_last_verified');
    return stored == null ? null : DateTime.tryParse(stored);
  }

  static Future<void> writeBiometricLastVerified(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biometric_last_verified', value);
  }

  static Future<void> writeDeviceFingerprint(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_fingerprint', value);
  }

  static Future<void> writeDeviceId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', value);
  }

  static Future<void> clearBiometricData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometric_last_verified');
    await prefs.remove('device_fingerprint');
    await prefs.remove('device_id');
  }

  static Future<void> writeAccessToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', value);
  }

  static Future<void> writeRefreshToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refreshToken', value);
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await clearBiometricData();
  }
}
