import 'dart:convert';

String? extractMerchantQrBase64(dynamic source) {
  if (source == null) return null;

  if (source is String) {
    final value = source.trim();
    if (value.isEmpty) return null;
    return _looksLikeQrImage(value) ? value : null;
  }

  if (source is Map) {
    final map = source.map((key, value) => MapEntry(key.toString(), value));

    for (final key in [
      'qr_image_base64',
      'qr_image_data_url',
      'qrImageBase64',
      'qrImageDataUrl',
      'qr_image',
      'qrImage',
      'image',
      'image_base64',
      'imageDataUrl',
    ]) {
      final value = map[key];
      if (value is String) {
        final normalized = value.trim();
        if (normalized.isEmpty) continue;
        if (_looksLikeQrImage(normalized)) return normalized;
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

    for (final value in map.values) {
      if (value is String) {
        final normalized = value.trim();
        if (normalized.isEmpty) continue;
        if (_looksLikeQrImage(normalized)) return normalized;
      }
      if (value is Map) {
        final nested = extractMerchantQrBase64(value);
        if (nested != null) return nested;
      }
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

bool _looksLikeQrImage(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return false;

  return normalized.startsWith('data:image/') ||
      normalized.startsWith('iVBORw0K') ||
      normalized.startsWith('/9j/') ||
      normalized.startsWith('R0lGOD');
}
