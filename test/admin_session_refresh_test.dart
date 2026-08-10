import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm/admin/services/admin_api_service.dart';

void main() {
  group('AdminApiService token refresh logic', () {
    test('returns true for tokens that are near expiry', () {
      final exp = DateTime.now().add(const Duration(minutes: 1)).toUtc();
      final token = _buildJwt(exp);

      expect(AdminApiService.tokenNeedsRefresh(token), isTrue);
    });

    test('returns false for tokens with plenty of life left', () {
      final exp = DateTime.now().add(const Duration(hours: 2)).toUtc();
      final token = _buildJwt(exp);

      expect(AdminApiService.tokenNeedsRefresh(token), isFalse);
    });
  });
}

String _buildJwt(DateTime expiry) {
  final payload = {
    'exp': expiry.millisecondsSinceEpoch ~/ 1000,
  };
  final header = {'alg': 'none', 'typ': 'JWT'};
  final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
  final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return '$encodedHeader.$encodedPayload.signature';
}
