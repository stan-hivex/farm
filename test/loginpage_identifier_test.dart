import 'package:flutter_test/flutter_test.dart';
import 'package:farm/pages/loginpage/login_identifier.dart';

void main() {
  group('login identifier helpers', () {
    test('normalizes email and phone input for backend login', () {
      expect(
          normalizeLoginIdentifier('  user@example.com  '), 'user@example.com');
      expect(normalizeLoginIdentifier(' +254 700 123 456 '), '+254700123456');
    });

    test('detects email-like input without blocking phone input', () {
      expect(looksLikeEmail('user@example.com'), isTrue);
      expect(looksLikeEmail('+254700123456'), isFalse);
      expect(looksLikeEmail('   '), isFalse);
    });
  });
}
