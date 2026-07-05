import 'package:flutter_test/flutter_test.dart';
import 'package:farm/backend/services/turnstile_payload.dart';

void main() {
  group('ApiService turnstile payload helpers', () {
    test('adds turnstile fields when a token is provided', () {
      final body = {'email': 'user@example.com'};

      final payload = attachTurnstileToken(body, turnstileToken: 'token-123');

      expect(payload['email'], 'user@example.com');
      expect(payload['cf_turnstile_response'], 'token-123');
      expect(payload['turnstile_token'], 'token-123');
    });

    test('leaves the payload unchanged when no token is provided', () {
      final body = {'email': 'user@example.com'};

      final payload = attachTurnstileToken(body, turnstileToken: null);

      expect(payload, body);
    });
  });
}
