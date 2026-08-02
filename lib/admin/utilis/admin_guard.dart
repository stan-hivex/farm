class AdminGuard {
  static bool isAdmin(String role) {
    final normalized = role.toLowerCase();
    return normalized == 'admin' || normalized == 'super_admin';
  }
}
