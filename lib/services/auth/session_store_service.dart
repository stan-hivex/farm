import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.userId,
    required this.expiresAt,
    required this.loggedInAt,
  });

  final String accessToken;
  final String refreshToken;
  final String role;
  final String userId;
  final String expiresAt;
  final String loggedInAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString() ?? '',
      loggedInAt:
          json['loggedInAt']?.toString() ?? json['expiresAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'role': role,
        'userId': userId,
        'expiresAt': expiresAt,
        'loggedInAt': loggedInAt,
      };
}

class AuthSessionStore {
  static const _userSessionKey = 'user_session';
  static const _adminSessionKey = 'admin_session';
  static const _superAdminSessionKey = 'super_admin_session';

  static Future<AuthSession?> readUserSession() async =>
      _readSession(_userSessionKey);

  static Future<AuthSession?> readAdminSession() async =>
      _readSession(_adminSessionKey);

  static Future<AuthSession?> readSuperAdminSession() async =>
      _readSession(_superAdminSessionKey);

  static Future<void> saveUserSession({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String userId,
    String? expiresAt,
    String? loggedInAt,
  }) async {
    await _saveSession(
      _userSessionKey,
      AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: role.toLowerCase(),
        userId: userId,
        expiresAt: expiresAt ?? _defaultExpiry,
        loggedInAt: loggedInAt ?? _defaultTimestamp,
      ),
    );
  }

  static Future<void> saveAdminSession({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String userId,
    String? expiresAt,
    String? loggedInAt,
  }) async {
    await _saveSession(
      _adminSessionKey,
      AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: role.toLowerCase(),
        userId: userId,
        expiresAt: expiresAt ?? _defaultExpiry,
        loggedInAt: loggedInAt ?? _defaultTimestamp,
      ),
    );
  }

  static Future<void> saveSuperAdminSession({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String userId,
    String? expiresAt,
    String? loggedInAt,
  }) async {
    await _saveSession(
      _superAdminSessionKey,
      AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: role.toLowerCase(),
        userId: userId,
        expiresAt: expiresAt ?? _defaultExpiry,
        loggedInAt: loggedInAt ?? _defaultTimestamp,
      ),
    );
  }

  static Future<void> saveRoleSession({
    required String role,
    required String accessToken,
    required String refreshToken,
    required String userId,
    String? expiresAt,
    String? loggedInAt,
  }) async {
    final normalizedRole = role.toLowerCase();
    if (normalizedRole == 'admin') {
      await saveAdminSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: normalizedRole,
        userId: userId,
        expiresAt: expiresAt,
        loggedInAt: loggedInAt,
      );
    } else if (normalizedRole == 'super_admin') {
      await saveSuperAdminSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: normalizedRole,
        userId: userId,
        expiresAt: expiresAt,
        loggedInAt: loggedInAt,
      );
    } else {
      await saveUserSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: normalizedRole.isEmpty ? 'user' : normalizedRole,
        userId: userId,
        expiresAt: expiresAt,
        loggedInAt: loggedInAt,
      );
    }
  }

  static Future<void> clearUserSession() async =>
      _clearSession(_userSessionKey);

  static Future<void> clearAdminSession() async =>
      _clearSession(_adminSessionKey);

  static Future<void> clearSuperAdminSession() async =>
      _clearSession(_superAdminSessionKey);

  static Future<void> clearRoleSession(String role) async {
    final normalizedRole = role.toLowerCase();
    if (normalizedRole == 'admin') {
      await clearAdminSession();
    } else if (normalizedRole == 'super_admin') {
      await clearSuperAdminSession();
    } else {
      await clearUserSession();
    }
  }

  static Future<AuthSession?> readRoleSession(String role) async {
    final normalizedRole = role.toLowerCase();
    if (normalizedRole == 'admin') {
      return readAdminSession();
    }
    if (normalizedRole == 'super_admin') {
      return readSuperAdminSession();
    }
    return readUserSession();
  }

  static Future<String> getTokenForRole(String role) async {
    final session = await readRoleSession(role);
    return session?.accessToken ?? '';
  }

  static Future<void> _saveSession(String key, AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonPayload = jsonEncode(session.toJson());
    debugPrint(
        '[AuthSessionStore] Saving session key=$key accessTokenPresent=${session.accessToken.isNotEmpty} refreshTokenPresent=${session.refreshToken.isNotEmpty} role=${session.role}');
    await prefs.setString(key, jsonPayload);
  }

  static Future<AuthSession?> _readSession(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    debugPrint(
        '[AuthSessionStore] Reading session key=$key present=${raw != null && raw.isNotEmpty}');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AuthSession.fromJson(decoded);
      }
      if (decoded is Map) {
        return AuthSession.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      debugPrint(
          '[AuthSessionStore] Failed to decode session key=$key error=$e');
      return null;
    }
    return null;
  }

  static Future<void> _clearSession(String key) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('[AuthSessionStore] Clearing session key=$key');
    await prefs.remove(key);
  }

  static String get _defaultTimestamp {
    return DateTime.now().toUtc().toIso8601String();
  }

  static String get _defaultExpiry {
    return DateTime.now()
        .toUtc()
        .add(const Duration(days: 365))
        .toIso8601String();
  }
}
