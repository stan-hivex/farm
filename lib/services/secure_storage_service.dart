import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static Future<String?> _readValue(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }

    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('SecureStorage read error: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  static Future<void> _writeValue(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }

    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStorage write error: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  static Future<void> _deleteValue(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }

    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint('SecureStorage delete error: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }

  static Future<DateTime?> readBiometricLastVerified() async {
    final stored = await _readValue('biometric_last_verified');
    return stored == null ? null : DateTime.tryParse(stored);
  }

  static Future<void> writeBiometricLastVerified(String value) async {
    await _writeValue('biometric_last_verified', value);
  }

  static Future<void> deleteBiometricLastVerified() async {
    await _deleteValue('biometric_last_verified');
  }

  static Future<void> writeDeviceFingerprint(String value) async {
    await _writeValue('device_fingerprint', value);
  }

  static Future<void> writeDeviceId(String value) async {
    await _writeValue('device_id', value);
  }

  static Future<String?> readDeviceId() async {
    return _readValue('device_id');
  }

  static Future<String?> readDeviceFingerprint() async {
    return _readValue('device_fingerprint');
  }

  static Future<void> clearBiometricData() async {
    await _deleteValue('biometric_last_verified');
    await _deleteValue('device_fingerprint');
    await _deleteValue('device_id');
  }

  static Future<String?> readAccessToken() async {
    return _readValue('accessToken');
  }

  static Future<String?> readRefreshToken() async {
    return _readValue('refreshToken');
  }

  static Future<void> writeAccessToken(String token) async {
    await _writeValue('accessToken', token);
  }

  static Future<void> writeRefreshToken(String token) async {
    await _writeValue('refreshToken', token);
  }

  static Future<void> clearAuthData() async {
    await _deleteValue('accessToken');
    await _deleteValue('refreshToken');
  }
}
