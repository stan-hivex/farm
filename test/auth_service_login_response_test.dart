import 'package:flutter_test/flutter_test.dart';
import 'package:farm/services/auth/auth_service.dart';

void main() {
  group('AuthService login response normalization', () {
    test('surfaces the backend access tokens for direct password logins', () {
      final response = {
        'data': {
          'access_token': 'access-token',
          'refresh_token': 'refresh-token',
          'phone': '+254700000000',
          'user': {'id': 'user-1', 'role': 'user'},
        },
      };

      final normalized = AuthService.normalizeLoginResponse(response);

      expect(normalized['farmJwt'], 'access-token');
      expect(normalized['refreshToken'], 'refresh-token');
      expect(normalized['data']['phone'], '+254700000000');
      expect(normalized['user']['role'], 'user');
      expect(normalized['loginMethod'], 'backend');
    });

    test('preserves access tokens for admin logins', () {
      final response = {
        'data': {
          'access_token': 'access-token',
          'refresh_token': 'refresh-token',
          'user': {'id': 'admin-1', 'role': 'admin'},
        },
      };

      final normalized = AuthService.normalizeLoginResponse(response);

      expect(normalized['farmJwt'], 'access-token');
      expect(normalized['refreshToken'], 'refresh-token');
      expect(normalized['user']['role'], 'admin');
    });
  });
}
