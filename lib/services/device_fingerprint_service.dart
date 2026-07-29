import 'dart:math';

import '/services/secure_storage_service.dart';

class DeviceFingerprintService {
  /// Returns the device fingerprint.
  ///
  /// If a fingerprint is already stored in secure storage, it is returned
  /// unchanged. Otherwise a UUIDv4 is generated and returned (the caller
  /// should persist it after successful backend enrollment).
  static Future<String> getDeviceFingerprint() async {
    final existing = await SecureStorageService.readDeviceFingerprint();
    if (existing != null && existing.isNotEmpty) return existing;

    final uuid = _generateUuidV4();
    return uuid;
  }

  static String _generateUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    // set version and variant bits
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
