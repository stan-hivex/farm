import 'package:flutter_test/flutter_test.dart';
import 'package:farm/services/auth/delete_account_validator.dart';

void main() {
  group('DeleteAccountValidator', () {
    test('returns an error when password is empty', () {
      final result = DeleteAccountValidator.validate(
        password: '   ',
        acknowledged: true,
        confirmDelete: true,
      );

      expect(result.isValid, isFalse);
      expect(result.error, 'Please enter your password to continue.');
    });

    test('returns an error when acknowledgement is missing', () {
      final result = DeleteAccountValidator.validate(
        password: 'secret123',
        acknowledged: false,
        confirmDelete: true,
      );

      expect(result.isValid, isFalse);
      expect(result.error, 'Please confirm that you understand this action is permanent.');
    });

    test('returns an error when final confirmation is missing', () {
      final result = DeleteAccountValidator.validate(
        password: 'secret123',
        acknowledged: true,
        confirmDelete: false,
      );

      expect(result.isValid, isFalse);
      expect(result.error, 'Please confirm that you want to delete your account permanently.');
    });

    test('passes when all required confirmations are provided', () {
      final result = DeleteAccountValidator.validate(
        password: 'secret123',
        acknowledged: true,
        confirmDelete: true,
      );

      expect(result.isValid, isTrue);
      expect(result.error, isNull);
    });
  });
}
