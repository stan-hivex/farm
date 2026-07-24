import 'package:flutter_test/flutter_test.dart';
import 'package:farm/backend/services/turnstile_payload.dart';

void main() {
  test('turnstile helper remains a no-op for the restored auth flow', () {
    final body = {'email': 'user@example.com'};

    final payload = attachTurnstileToken(body, turnstileToken: 'token-123');

    expect(payload, body);
  });
}
