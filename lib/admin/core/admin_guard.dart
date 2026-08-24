import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/auth/session_store_service.dart';
import '/admin/services/admin_api_service.dart';

class AdminGuard {
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final activeRole = (await AuthSessionStore.readActiveRole() ?? '').toLowerCase();
    if (activeRole != 'admin' && activeRole != 'super_admin') {
      return false;
    }
    final token = prefs.getString('adminToken') ?? '';
    final role = prefs.getString('adminRole') ?? '';
    debugPrint('[AdminGuard] isAuthenticated prefTokenPresent=${token.isNotEmpty} prefRole=$role');
    if (token.isNotEmpty && (role == 'admin' || role == 'super_admin') && _isJwtValid(token)) {
      return true;
    }

    final session = await AuthSessionStore.readRoleSession(activeRole);
    final adminToken = session?.accessToken ?? '';
    final adminRole = session?.role ?? '';
    debugPrint('[AdminGuard] isAuthenticated persistedTokenPresent=${adminToken.isNotEmpty} persistedRole=$adminRole');

    // If a persisted token exists but is expired, attempt a forced refresh
    final hasPersisted = adminToken.isNotEmpty &&
        (adminRole == 'admin' || adminRole == 'super_admin');
    if (hasPersisted && _isJwtValid(adminToken)) {
      return true;
    }

    if (hasPersisted) {
      try {
        final refreshed = await AdminApiService.ensureValidSession(force: true);
        debugPrint('[AdminGuard] forced refresh attempted result=$refreshed');
        if (refreshed) return true;
      } catch (e) {
        debugPrint('[AdminGuard] forced refresh error: $e');
      }
    }

    return false;
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

    final activeRole = await AuthSessionStore.readActiveRole();
    if (activeRole != 'admin' && activeRole != 'super_admin') return '';
    final session = await AuthSessionStore.readRoleSession(activeRole!);
    return session?.role ?? '';
  }
}