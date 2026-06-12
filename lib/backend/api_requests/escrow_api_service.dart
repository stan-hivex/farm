import 'dart:convert';
import '/core/app_config.dart';
import 'package:http/http.dart' as http;
import '../models/escrow_model.dart';

class EscrowApiService {
  static String get baseUrl => '${AppConfig.api}/escrow';

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ── List my escrows ─────────────────────────────────────────────────────
  static Future<List<EscrowModel>> getEscrows({
    required String token,
    String? status,
  }) async {
    if (token.isEmpty) throw Exception('User token missing. Please login again.');

    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        if (status != null) 'status': status,
      },
    );

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception('Failed to load escrows: ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    final list = body['data'] as List? ?? [];
    return list.map((e) => EscrowModel.fromJson(e)).toList();
  }

  // ── Create escrow (PIN required) ────────────────────────────────────────
  static Future<Map<String, dynamic>> createEscrow({
    required String token,
    required String sellerIdentifier,
    required double amount,
    required String title,
    required String pin,
    String? description,
    int autoReleaseDays = 7,
  }) async {
    if (token.isEmpty) throw Exception('User token missing. Please login again.');

    final res = await http.post(
      Uri.parse(baseUrl),
      headers: _headers(token),
      body: jsonEncode({
        'seller_identifier': sellerIdentifier,
        'amount': amount,
        'title': title,
        'pin': pin,
        if (description != null) 'description': description,
        'auto_release_days': autoReleaseDays,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(body['message'] ?? 'Failed to create escrow');
    }
    return body;
  }

  // ── Release escrow funds to seller ─────────────────────────────────────
  static Future<void> releaseEscrow({
    required String token,
    required String escrowId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$escrowId/release'),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to release escrow');
    }
  }

  // ── Raise a dispute ─────────────────────────────────────────────────────
  static Future<void> disputeEscrow({
    required String token,
    required String escrowId,
    required String reason,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$escrowId/dispute'),
      headers: _headers(token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to raise dispute');
    }
  }

  // ── Cancel escrow ───────────────────────────────────────────────────────
  static Future<void> cancelEscrow({
    required String token,
    required String escrowId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$escrowId/cancel'),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to cancel escrow');
    }
  }

  // ── Send message inside escrow ──────────────────────────────────────────
  static Future<void> sendMessage({
    required String token,
    required String escrowId,
    required String message,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$escrowId/message'),
      headers: _headers(token),
      body: jsonEncode({'message': message}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to send message');
    }
  }
}