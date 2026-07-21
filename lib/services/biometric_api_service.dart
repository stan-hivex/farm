import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '/core/app_config.dart';
import '/app_state.dart';

class BiometricApiService {
  static final http.Client _client = http.Client();

  /// Register a device for biometrics. Returns backend device id on success.
  static Future<String> enableBiometrics({
    required String deviceFingerprint,
    String biometricType = 'fingerprint',
  }) async {
    final uri = Uri.parse('${AppConfig.api}/security/biometrics');
    final token = FFAppState().accessToken;

    debugPrint('===== BIOMETRIC API REQUEST: enableBiometrics =====');
    debugPrint('POST $uri');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    // Logging per requirements
    debugPrint('deviceFingerprint: $deviceFingerprint');
    debugPrint('deviceFingerprint.runtimeType: ${deviceFingerprint.runtimeType}');

    final bodyMap = {
      'deviceFingerprint': deviceFingerprint,
      'biometricType': biometricType,
    };

    debugPrint('request body: $bodyMap');

    final body = jsonEncode(bodyMap);

    final res = await _client.post(uri, headers: headers, body: body);

    debugPrint('statusCode: ${res.statusCode}');
    debugPrint('response: ${res.body}');
    debugPrint('headers: ${res.headers}');

    if (res.statusCode != 200 && res.statusCode != 201) {
      String message = res.body;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['message'] is String) {
          message = decoded['message'];
        }
      } catch (_) {}
      throw Exception('HTTP ${res.statusCode}: $message\n${res.body}');
    }

    try {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      // Accept either device_id or deviceId in responses
      if (decoded.containsKey('device_id')) {
        return decoded['device_id'].toString();
      }
      if (decoded.containsKey('deviceId')) {
        return decoded['deviceId'].toString();
      }
      throw Exception('enableBiometrics: missing device_id in response');
    } catch (e) {
      rethrow;
    }
  }

  /// Disable biometrics for the current device id.
  static Future<void> disableBiometrics({required String deviceId}) async {
    final uri = Uri.parse('${AppConfig.api}/security/biometrics');
    final token = FFAppState().accessToken;

    debugPrint('===== BIOMETRIC API REQUEST: disableBiometrics =====');
    debugPrint('DELETE $uri');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    // Backend DELETE ignores body and uses authenticated user; send no body to avoid validation issues
    final res = await _client.delete(
      uri,
      headers: headers,
    );

    debugPrint('statusCode: ${res.statusCode}');
    debugPrint('response: ${res.body}');
    debugPrint('headers: ${res.headers}');

    if (res.statusCode != 200 && res.statusCode != 204) {
      String message = res.body;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['message'] is String) {
          message = decoded['message'];
        }
      } catch (_) {}
      throw Exception('HTTP ${res.statusCode}: $message\n${res.body}');
    }
  }

  /// Verify a fingerprint against backend (optional flow).
  static Future<bool> verifyBiometrics({
    required String deviceFingerprint,
  }) async {
    final uri = Uri.parse('${AppConfig.api}/security/verify-device');
    final token = FFAppState().accessToken;

    debugPrint('===== BIOMETRIC API REQUEST: verifyBiometrics =====');
    debugPrint('POST $uri');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    debugPrint('deviceFingerprint: $deviceFingerprint');
    debugPrint('deviceFingerprint.runtimeType: ${deviceFingerprint.runtimeType}');
    final bodyMap = {'deviceFingerprint': deviceFingerprint};
    debugPrint('request body: $bodyMap');

    final body = jsonEncode(bodyMap);

    final res = await _client.post(uri, headers: headers, body: body);

    debugPrint('statusCode: ${res.statusCode}');
    debugPrint('response: ${res.body}');
    debugPrint('headers: ${res.headers}');

    if (res.statusCode != 200 && res.statusCode != 201) {
      String message = res.body;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['message'] is String) {
          message = decoded['message'];
        }
      } catch (_) {}
      throw Exception('HTTP ${res.statusCode}: $message\n${res.body}');
    }

    try {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return decoded['verified'] == true || decoded['success'] == true;
    } catch (e) {
      rethrow;
    }
  }
}
