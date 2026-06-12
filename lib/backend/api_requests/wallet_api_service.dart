import 'dart:convert';
import 'package:http/http.dart' as http;
import '/core/app_config.dart';

class WalletApiService {
  static String get _base => '${AppConfig.api}/wallet';

  // ── Get wallet balance ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getWallet({
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse(_base),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode != 200) throw Exception('Failed to load wallet');
    final body = jsonDecode(res.body);
    return body['data'];
  }

  // ── Send FARM to another user (PIN required) ────────────────────────────
  static Future<Map<String, dynamic>> sendFunds({
    required String token,
    required String recipient,
    required double amount,
    required String pin,
    String? description,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/send'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'recipient_identifier': recipient,
        'amount': amount,
        'pin': pin,
        'description': description ?? '',
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(body['message'] ?? 'Transfer failed');
    }
    return body;
  }

  // ── Get transaction history ─────────────────────────────────────────────
  static Future<List<dynamic>> getTransactions({
    required String token,
    String? type,
    String? status,
    int page = 1,
  }) async {
    final uri = Uri.parse('$_base/transactions').replace(
      queryParameters: {
        'page': page.toString(),
        if (type != null) 'type': type,
        if (status != null) 'status': status,
      },
    );
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('Failed to fetch transactions');
    final body = jsonDecode(res.body);
    return body['data'] ?? [];
  }

  // ── Get single transaction ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getTransaction({
    required String token,
    required String txId,
  }) async {
    final res = await http.get(
      Uri.parse('$_base/transactions/$txId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('Transaction not found');
    return jsonDecode(res.body)['data'];
  }
}