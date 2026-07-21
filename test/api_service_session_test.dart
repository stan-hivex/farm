import 'dart:convert';

import 'package:farm/app_state.dart';
import 'package:farm/backend/services/api_service.dart';
import 'package:farm/services/auth/refresh_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: '.env');
    FFAppState.reset();
    await FFAppState().initializePersistedState();
    RefreshManager().reset();
  });

  test('preserves existing auth state when refresh is rejected', () async {
    const existingToken = 'still-valid-token';

    FFAppState().accessToken = existingToken;
    FFAppState().refreshToken = 'expired-token';
    FFAppState().isLoggedIn = true;

    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        return http.Response(
          jsonEncode({'message': 'Unauthorized'}),
          401,
        );
      }

      return http.Response('not found', 404);
    });

    ApiService.client = mockClient;
    RefreshManager.client = mockClient;

    final refreshed = await RefreshManager().refreshIfNeeded(force: true);

    expect(refreshed, isFalse);
    expect(FFAppState().accessToken, existingToken);
    expect(FFAppState().refreshToken, 'expired-token');
    expect(FFAppState().isLoggedIn, isTrue);
  });

  test('retries a protected request after a successful refresh', () async {
    const oldToken = 'old-token';
    const refreshedToken = 'new-token';

    FFAppState().accessToken = oldToken;
    FFAppState().refreshToken = 'refresh-token';

    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        expect(request.body, contains('refresh-token'));
        return http.Response(
          jsonEncode({
            'data': {
              'access_token': refreshedToken,
              'refresh_token': 'rotated-refresh-token',
            },
          }),
          200,
        );
      }

      if (request.url.path.endsWith('/me')) {
        final authHeader = request.headers['Authorization'];
        if (authHeader == 'Bearer $oldToken') {
          return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
        }
        if (authHeader == 'Bearer $refreshedToken') {
          return http.Response(jsonEncode({'ok': true}), 200);
        }
      }

      return http.Response('not found', 404);
    });

    ApiService.client = mockClient;
    RefreshManager.client = mockClient;

    final result = await ApiService.request(method: 'GET', path: '/me');

    expect(result['ok'], isTrue);
    expect(FFAppState().accessToken, refreshedToken);
    expect(FFAppState().refreshToken, 'rotated-refresh-token');
  });
}
