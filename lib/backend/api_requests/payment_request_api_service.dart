import 'dart:convert';
import 'package:http/http.dart' as http;
import '/core/app_config.dart';

class PaymentRequestApiService {
  static String get _base => '${AppConfig.api}/payment-requests';

  static Future<Map<String, dynamic>> requestPayment({
    required String token,
    required String recipientIdentifier,
    required double amount,
    String? description,
  }) async {
    final res = await http.post(Uri.parse('$_base/request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'recipient_identifier': recipientIdentifier,
          'amount': amount,
          'description': description ?? '',
        }));
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(body['message'] ?? 'Failed to create payment request');
    }
    return body;
  }

  static Future<List<dynamic>> getPendingRequests({
    required String token,
  }) async {
    final res = await http.get(Uri.parse('$_base/pending'), headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (res.statusCode != 200) throw Exception('Failed to load payment requests');
    final body = jsonDecode(res.body);
    return List<dynamic>.from(body['data'] ?? []);
  }

  static Future<Map<String, dynamic>> acceptPaymentRequest({
    required String token,
    required String requestId,
    required String pin,
  }) async {
    final res = await http.post(Uri.parse('$_base/accept'), headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }, body: jsonEncode({'request_id': requestId, 'pin': pin}));
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(body['message'] ?? 'Failed to accept payment request');
    }
    return body;
  }

  static Future<Map<String, dynamic>> rejectPaymentRequest({
    required String token,
    required String requestId,
  }) async {
    final res = await http.post(Uri.parse('$_base/$requestId/reject'), headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(body['message'] ?? 'Failed to reject payment request');
    }
    return body;
  }

  static Future<Map<String, dynamic>> cancelPaymentRequest({
    required String token,
    required String requestId,
  }) async {
    final res = await http.post(Uri.parse('$_base/$requestId/cancel'), headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(body['message'] ?? 'Failed to cancel payment request');
    }
    return body;
  }
}
