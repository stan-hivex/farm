import '/backend/services/api_service.dart';

class PaymentRequestApiService {
  static Future<Map<String, dynamic>> requestPayment({
    required String recipientIdentifier,
    required double amount,
    String? description,
  }) async {
    final resp = await ApiService.request(
      method: 'POST',
      path: '/payment-requests/request',
      body: {
        'recipient_identifier': recipientIdentifier,
        'amount': amount,
        'description': description ?? '',
      },
      requiresAuth: true,
    );
    return resp;
  }

  static Future<List<dynamic>> getPendingRequests() async {
    final resp = await ApiService.request(
      method: 'GET',
      path: '/payment-requests/pending',
      requiresAuth: true,
    );
    return List<dynamic>.from(resp['data'] ?? []);
  }

  static Future<Map<String, dynamic>> acceptPaymentRequest({
    required String requestId,
    String? pin,
    bool? biometricAuth,
    String? deviceFingerprint,
  }) async {
    final resp = await ApiService.request(
      method: 'POST',
      path: '/payment-requests/accept',
      body: {
        'request_id': requestId,
        if (pin != null) 'pin': pin,
        if (biometricAuth == true) 'biometric_auth': true,
        if (deviceFingerprint != null) 'device_fingerprint': deviceFingerprint,
      },
      requiresAuth: true,
    );
    return resp;
  }

  static Future<Map<String, dynamic>> acceptPaymentRequestsBatch({
    required List<String> requestIds,
    String? pin,
    bool? biometricAuth,
    String? deviceFingerprint,
  }) async {
    return ApiService.request(
      method: 'POST',
      path: '/payment-requests/accept-batch',
      body: {
        'request_ids': requestIds,
        if (pin != null) 'pin': pin,
        if (biometricAuth == true) 'biometric_auth': true,
        if (deviceFingerprint != null) 'device_fingerprint': deviceFingerprint,
      },
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> rejectPaymentRequest({
    required String requestId,
  }) async {
    final resp = await ApiService.request(
      method: 'POST',
      path: '/payment-requests/$requestId/reject',
      requiresAuth: true,
    );
    return resp;
  }

  static Future<Map<String, dynamic>> cancelPaymentRequest({
    required String requestId,
  }) async {
    final resp = await ApiService.request(
      method: 'POST',
      path: '/payment-requests/$requestId/cancel',
      requiresAuth: true,
    );
    return resp;
  }
}
