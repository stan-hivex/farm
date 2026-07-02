class DeviceFingerprintService {
  static Future<String> getDeviceFingerprint() async {
    return 'flutter-device-${DateTime.now().millisecondsSinceEpoch}';
  }
}
