import 'package:flutter_test/flutter_test.dart';
import 'package:farm/utils/merchant_qr_utils.dart';

void main() {
  group('merchant QR utilities', () {
    test('extracts a QR payload from a nested merchant response', () {
      final payload = {
        'data': {
          'merchant': {
            'qr_image_base64': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQABAA0AAwP4QwAAAAABJRU5ErkJggg=='
          }
        }
      };

      expect(extractMerchantQrBase64(payload), isNotNull);
      expect(extractMerchantQrBase64(payload), contains('iVBORw0KGgo'));
    });

    test('extracts a QR payload from a data URL field', () {
      final payload = {
        'data': {
          'qr_image_data_url': 'data:image/png;base64,aGVsbG8=',
        }
      };

      expect(extractMerchantQrBase64(payload), 'data:image/png;base64,aGVsbG8=');
    });

    test('prefers the real QR image payload over a signed qr_payload string', () {
      final payload = {
        'data': {
          'qr_payload': '{"merchant_id":"merchant-1","business_name":"Farm Shop","v":1,"sig":"abc"}',
          'qr_image_base64': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQABAA0AAwP4QwAAAAABJRU5ErkJggg=='
        }
      };

      expect(extractMerchantQrBase64(payload), contains('iVBORw0KGgo'));
      expect(extractMerchantQrBase64(payload), isNot(contains('"merchant_id"')));
    });

    test('decodes a data URI QR payload into bytes', () {
      final bytes = resolveMerchantQrBytes(
        'data:image/png;base64,aGVsbG8=',
      );

      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
    });
  });
}
