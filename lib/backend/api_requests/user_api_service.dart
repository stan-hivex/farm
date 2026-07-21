import 'dart:convert';
import '/core/app_config.dart';
import 'package:http/http.dart' as http;

class UserApiService {
  static String get baseUrl => '${AppConfig.api}/users';

  static String getSuggestionValue(Map<String, dynamic> user) {
    final username = (user['username'] ?? '').toString().trim();
    if (username.isNotEmpty) {
      return username;
    }

    final phone = (user['phone'] ?? '').toString().trim();
    return phone;
  }

  static String getSuggestionLabel(Map<String, dynamic> user) {
    final username = (user['username'] ?? '').toString().trim();
    final phone = (user['phone'] ?? '').toString().trim();

    if (username.isNotEmpty && phone.isNotEmpty) {
      return '@$username • $phone';
    }

    if (username.isNotEmpty) {
      return '@$username';
    }

    return phone;
  }

  static bool shouldSearchSuggestions(String value) {
    return value.trim().length >= 3;
  }

  static Future<List<dynamic>> searchUsers({
    required String token,
    required String query,
  }) async {
    // Backend controller uses ?q= not ?query=
    final uri = Uri.parse('$baseUrl/search')
        .replace(queryParameters: {'q': query});

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) throw Exception('Failed to search users');
    final body = jsonDecode(res.body);
    return List<dynamic>.from(body['data'] ?? []);
  }

  static Future<Map<String, dynamic>> getProfile({
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('Failed to load profile');
    return jsonDecode(res.body)['data'];
  }

  static Future<void> updateProfile({
    required String token,
    String? firstName,
    String? lastName,
    String? bio,
    String? country,
    String? city,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (bio != null) 'bio': bio,
        if (country != null) 'country': country,
        if (city != null) 'city': city,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to update profile');
  }

  static Future<List<dynamic>> getContacts({required String token}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/contacts'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('Failed to load contacts');
    return jsonDecode(res.body)['data'] ?? [];
  }

  static Future<void> addContact({
    required String token,
    required String identifier,
    String? nickname,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/contacts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'identifier': identifier, if (nickname != null) 'nickname': nickname}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(jsonDecode(res.body)['message'] ?? 'Failed to add contact');
    }
  }

  static Future<List<dynamic>> getNotifications({required String token}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return [];
    return jsonDecode(res.body)['data'] ?? [];
  }
}