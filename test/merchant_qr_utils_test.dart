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

    test('decodes a data URI QR payload into bytes', () async {
      final bytes = resolveMerchantQrBytes(
        'data:image/png;base64,aGVsbG8=',
      );

      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
    });
  });
}
