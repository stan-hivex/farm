import '/backend/services/api_service.dart';

class UserApiService {
  static String getSuggestionValue(Map<String, dynamic> user) {
    final username = (user['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;
    final phone = (user['phone'] ?? '').toString().trim();
    return phone;
  }

  static String getSuggestionLabel(Map<String, dynamic> user) {
    final username = (user['username'] ?? '').toString().trim();
    final phone = (user['phone'] ?? '').toString().trim();
    if (username.isNotEmpty && phone.isNotEmpty) return '@$username • $phone';
    if (username.isNotEmpty) return '@$username';
    return phone;
  }

  static bool shouldSearchSuggestions(String value) {
    return value.trim().length >= 3;
  }

  static Future<List<dynamic>> searchUsers({
    required String query,
  }) async {
    final path = '/users/search?q=${Uri.encodeQueryComponent(query)}';
    final resp = await ApiService.request(
      method: 'GET',
      path: path,
      requiresAuth: true,
    );
    return List<dynamic>.from(resp['data'] ?? []);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final resp = await ApiService.request(
      method: 'GET',
      path: '/users/me',
      requiresAuth: true,
    );
    return resp['data'] ?? resp;
  }

  static Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
    String? country,
    String? city,
  }) async {
    await ApiService.request(
      method: 'PUT',
      path: '/users/me',
      body: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (bio != null) 'bio': bio,
        if (country != null) 'country': country,
        if (city != null) 'city': city,
      },
      requiresAuth: true,
    );
  }

  static Future<List<dynamic>> getContacts() async {
    final resp = await ApiService.request(
      method: 'GET',
      path: '/users/contacts',
      requiresAuth: true,
    );
    return resp['data'] ?? [];
  }

  static Future<void> addContact({
    required String identifier,
    String? nickname,
  }) async {
    await ApiService.request(
      method: 'POST',
      path: '/users/contacts',
      body: {'identifier': identifier, if (nickname != null) 'nickname': nickname},
      requiresAuth: true,
    );
  }

  static Future<List<dynamic>> getNotifications() async {
    final resp = await ApiService.request(
      method: 'GET',
      path: '/users/notifications',
      requiresAuth: true,
    );
    return resp['data'] ?? [];
  }
}