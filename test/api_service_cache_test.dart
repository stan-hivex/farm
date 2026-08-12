import 'package:flutter_test/flutter_test.dart';
import 'package:farm/backend/services/api_cache.dart';

void main() {
  group('ApiCacheEntry', () {
    test('marks recent entries as fresh', () {
      final entry = ApiCacheEntry(
        {'ok': true},
        DateTime.now().subtract(const Duration(seconds: 10)),
      );

      expect(entry.isFresh(const Duration(seconds: 30)), isTrue);
    });

    test('marks older entries as stale', () {
      final entry = ApiCacheEntry(
        {'ok': true},
        DateTime.now().subtract(const Duration(seconds: 120)),
      );

      expect(entry.isFresh(const Duration(seconds: 30)), isFalse);
    });
  });
}
