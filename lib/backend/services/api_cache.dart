class ApiCacheEntry {
  ApiCacheEntry(this.data, this.fetchedAt);

  final Map<String, dynamic> data;
  final DateTime fetchedAt;

  bool isFresh(Duration maxAge) {
    return DateTime.now().difference(fetchedAt) <= maxAge;
  }
}

class ApiCacheStore {
  ApiCacheStore._internal();

  static final ApiCacheStore _instance = ApiCacheStore._internal();

  factory ApiCacheStore() => _instance;

  final Map<String, ApiCacheEntry> _entries = {};

  ApiCacheEntry? read(String key) => _entries[key];

  Map<String, dynamic>? readData(String key) => _entries[key]?.data;

  void write(String key, Map<String, dynamic> value) {
    _entries[key] = ApiCacheEntry(
      Map<String, dynamic>.from(value),
      DateTime.now(),
    );
  }

  bool isFresh(String key, Duration maxAge) {
    final entry = _entries[key];
    if (entry == null) return false;
    return entry.isFresh(maxAge);
  }

  void remove(String key) => _entries.remove(key);

  void clear() => _entries.clear();
}
