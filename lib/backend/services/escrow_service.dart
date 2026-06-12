import 'dart:convert';
import '/core/app_config.dart';
import 'package:http/http.dart' as http;
import '../models/escrow_model.dart';

class EscrowService {
  static String get baseUrl => '${AppConfig.api}/escrow';

  static Future<List<EscrowModel>> fetchEscrows(String token, {String? status}) async {
    final uri = Uri.parse('$baseUrl/escrow').replace(
      queryParameters: status != null ? {'status': status} : null,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List escrows = body['data'];
      return escrows.map((e) => EscrowModel.fromJson(e)).toList();
    }

    throw Exception('Failed to load escrows: ${response.body}');
  }
}