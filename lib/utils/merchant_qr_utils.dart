import 'dart:convert';

String? extractMerchantQrBase64(dynamic source) {
  if (source == null) return null;

  if (source is String) {
    final value = source.trim();
    return value.isEmpty ? null : value;
  }

  if (source is Map) {
    final map = source.map((key, value) => MapEntry(key.toString(), value));

    for (final key in [
      'qr_image_base64',
      'qrImageBase64',
      'qr_image',
      'qrImage',
      'qr_code',
      'qrCode',
      'qr',
      'image',
      'image_base64',
    ]) {
      final value = map[key];
      if (value is String) {
        final normalized = value.trim();
        if (normalized.isNotEmpty) return normalized;
      }
    }

    if (map.containsKey('data')) {
      final nested = extractMerchantQrBase64(map['data']);
      if (nested != null) return nested;
    }

    if (map.containsKey('merchant')) {
      final nested = extractMerchantQrBase64(map['merchant']);
      if (nested != null) return nested;
    }
  }

  return null;
}

List<int>? resolveMerchantQrBytes(String? qrPayload) {
  if (qrPayload == null || qrPayload.trim().isEmpty) return null;

  final payload = qrPayload.trim();
  final encoded = payload.startsWith('data:')
      ? payload.substring(payload.indexOf(',') + 1)
      : payload;

  final cleaned = encoded.replaceAll(RegExp(r'\s+'), '');
  if (cleaned.isEmpty) return null;

  try {
    return base64Decode(cleaned);
  } on FormatException {
    try {
      return base64Url.decode(cleaned);
    } on FormatException {
      return null;
    }
  }
}
