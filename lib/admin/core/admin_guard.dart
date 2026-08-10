import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/auth/session_store_service.dart';

class AdminGuard {
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('adminToken') ?? '';
    final role = prefs.getString('adminRole') ?? '';
    final refreshToken = prefs.getString('adminRefreshToken') ?? '';
    debugPrint('[AdminGuard] isAuthenticated prefTokenPresent=${token.isNotEmpty} prefRole=$role');
    if (token.isNotEmpty && (role == 'admin' || role == 'super_admin') && (_isJwtValid(token) || refreshToken.isNotEmpty)) {
      return true;
    }

    final adminSession = await AuthSessionStore.readAdminSession();
    final superAdminSession = await AuthSessionStore.readSuperAdminSession();
    final adminToken = adminSession?.accessToken ?? superAdminSession?.accessToken ?? '';
    final adminRole = adminSession?.role ?? superAdminSession?.role ?? '';
    final adminRefresh = adminSession?.refreshToken ?? superAdminSession?.refreshToken ?? '';
    debugPrint('[AdminGuard] isAuthenticated persistedTokenPresent=${adminToken.isNotEmpty} persistedRole=$adminRole');

    return adminToken.isNotEmpty &&
        (adminRole == 'admin' || adminRole == 'super_admin') &&
        (_isJwtValid(adminToken) || adminRefresh.isNotEmpty || refreshToken.isNotEmpty);
  }

  static bool _isJwtValid(String token) {
    final expiry = _getJwtExpiry(token);
    if (expiry == null) return false;
    return expiry.isAfter(DateTime.now().toUtc());
  }

  static DateTime? _getJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = payloadMap['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }
      if (exp is String) {
        final value = int.tryParse(exp);
        if (value != null) {
          return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
        }
      }
    } catch (e) {
      debugPrint('[AdminGuard] Failed to parse JWT expiry: $e');
    }
    return null;
  }

  static Future<String> getAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('adminName') ?? 'Admin';
  }

  static Future<String> getAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('adminRole') ?? '';
    if (role.isNotEmpty) {
      return role;
    }

    final adminSession = await AuthSessionStore.readAdminSession();
    final superAdminSession = await AuthSessionStore.readSuperAdminSession();
    return adminSession?.role ?? superAdminSession?.role ?? '';
  }
}