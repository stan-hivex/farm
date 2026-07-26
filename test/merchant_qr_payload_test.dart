import 'package:flutter_test/flutter_test.dart';
import 'package:farm/utils/merchant_qr_parser.dart';

void main() {
  group('merchant QR payload parsing', () {
    test('parses signed merchant QR payloads without relying on backend validation', () {
      const payload = '{"merchant_id":"m_123","business_name":"Farm Market","v":1,"sig":"abc123"}';

      final parsed = parseMerchantQrPayload(payload);

      expect(parsed, isNotNull);
      expect(parsed!.merchantId, 'm_123');
      expect(parsed.businessName, 'Farm Market');
    });

    test('returns null for non-merchant QR payloads', () {
      const payload = '{"wallet_address":"abc123","amount":10,"v":1}';

      expect(parseMerchantQrPayload(payload), isNull);
    });
  });
}
