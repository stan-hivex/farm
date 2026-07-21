import 'package:flutter_test/flutter_test.dart';
import 'package:farm/backend/api_requests/user_api_service.dart';

void main() {
  group('UserApiService suggestions', () {
    test('prefers username as the selected value and shows both username and phone', () {
      final user = {
        'username': 'maria',
        'phone': '+254712345678',
      };

      expect(UserApiService.getSuggestionValue(user), 'maria');
      expect(UserApiService.getSuggestionLabel(user), '@maria • +254712345678');
    });

    test('falls back to phone when username is missing', () {
      final user = {
        'phone': '+254712345678',
      };

      expect(UserApiService.getSuggestionValue(user), '+254712345678');
      expect(UserApiService.getSuggestionLabel(user), '+254712345678');
    });

    test('only starts searching once the input has at least three characters', () {
      expect(UserApiService.shouldSearchSuggestions('ab'), isFalse);
      expect(UserApiService.shouldSearchSuggestions('abc'), isTrue);
      expect(UserApiService.shouldSearchSuggestions('  abc  '), isTrue);
    });
  });
}
