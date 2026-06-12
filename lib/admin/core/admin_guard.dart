import 'package:shared_preferences/shared_preferences.dart';

class AdminGuard {
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('adminToken') ?? '';
    final role = prefs.getString('adminRole') ?? '';
    return token.isNotEmpty &&
        (role == 'admin' || role == 'super_admin');
  }

  static Future<String> getAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('adminName') ?? 'Admin';
  }

  static Future<String> getAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('adminRole') ?? '';
  }
}