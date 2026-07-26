import 'dart:convert';

class MerchantQrPayload {
  const MerchantQrPayload({
    required this.merchantId,
    required this.businessName,
    this.rawPayload,
  });

  final String merchantId;
  final String businessName;
  final String? rawPayload;
}

MerchantQrPayload? parseMerchantQrPayload(String? qrPayload) {
  if (qrPayload == null || qrPayload.trim().isEmpty) {
    return null;
  }

  final trimmed = qrPayload.trim();

  if (trimmed.startsWith('{')) {
    try {
      final decoded = jsonDecode(trimmed);
      return _parseDecodedPayload(decoded, trimmed);
    } catch (_) {
      return null;
    }
  }

  if (trimmed.startsWith('data:')) {
    final commaIndex = trimmed.indexOf(',');
    if (commaIndex != -1) {
      final encoded = trimmed.substring(commaIndex + 1);
      try {
        final decoded = utf8.decode(base64Decode(encoded));
        return _parseDecodedPayload(jsonDecode(decoded), trimmed);
      } catch (_) {
        return null;
      }
    }
  }

  return null;
}

MerchantQrPayload? _parseDecodedPayload(Object? decoded, String rawPayload) {
  if (decoded is Map) {
    final map = decoded.map((key, value) => MapEntry(key.toString(), value));

    final nested = map['data'];
    if (nested is Map) {
      final nestedMap = nested.map((key, value) => MapEntry(key.toString(), value));
      final merchantId = _readString(nestedMap['merchant_id']) ??
          _readString(nestedMap['merchantId']);
      final businessName = _readString(nestedMap['business_name']) ??
          _readString(nestedMap['businessName']);

      if (merchantId != null && businessName != null) {
        return MerchantQrPayload(
          merchantId: merchantId,
          businessName: businessName,
          rawPayload: rawPayload,
        );
      }
    }

    final merchantId = _readString(map['merchant_id']) ?? _readString(map['merchantId']);
    final businessName = _readString(map['business_name']) ??
        _readString(map['businessName']) ??
        _readString(map['name']);

    if (merchantId != null && businessName != null) {
      return MerchantQrPayload(
        merchantId: merchantId,
        businessName: businessName,
        rawPayload: rawPayload,
      );
    }
  }

  return null;
}

String? _readString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
