import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/auth/session_store_service.dart';

class AdminGuard {
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('adminToken') ?? '';
    final role = prefs.getString('adminRole') ?? '';
    debugPrint('[AdminGuard] isAuthenticated prefTokenPresent=${token.isNotEmpty} prefRole=$role');
    if (token.isNotEmpty && (role == 'admin' || role == 'super_admin')) {
      return true;
    }

    final adminSession = await AuthSessionStore.readAdminSession();
    final superAdminSession = await AuthSessionStore.readSuperAdminSession();
    final adminToken = adminSession?.accessToken ?? superAdminSession?.accessToken ?? '';
    final adminRole = adminSession?.role ?? superAdminSession?.role ?? '';
    debugPrint('[AdminGuard] isAuthenticated persistedTokenPresent=${adminToken.isNotEmpty} persistedRole=$adminRole');

    return adminToken.isNotEmpty &&
        (adminRole == 'admin' || adminRole == 'super_admin');
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