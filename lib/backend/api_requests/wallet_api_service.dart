import '/backend/services/api_service.dart';

class WalletApiService {
  static Future<Map<String, dynamic>> getWallet() async {
    final resp = await ApiService.getWallet();
    return resp['data'] ?? resp;
  }

  static Future<Map<String, dynamic>> sendFunds({
    required String recipient,
    required double amount,
    String? pin,
    String? description,
    bool? biometricAuth,
    String? deviceFingerprint,
  }) async {
    final resp = await ApiService.request(
      method: 'POST',
      path: '/wallet/send',
      body: {
        'recipient_identifier': recipient,
        'amount': amount,
        if (pin != null) 'pin': pin,
        if (biometricAuth == true) 'biometric_auth': true,
        if (deviceFingerprint != null) 'device_fingerprint': deviceFingerprint,
        'description': description ?? '',
      },
      requiresAuth: true,
    );
    return resp;
  }

  static Future<List<dynamic>> getTransactions({
    String? type,
    String? status,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;
    final query = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
    final path = '/transactions${query.isNotEmpty ? '?$query' : ''}';
    final resp = await ApiService.request(
      method: 'GET',
      path: path,
      requiresAuth: true,
    );
    return resp['data'] ?? [];
  }

  static Future<Map<String, dynamic>> getTransaction({
    required String txId,
  }) async {
    final resp = await ApiService.request(
      method: 'GET',
      path: '/wallet/transactions/$txId',
      requiresAuth: true,
    );
    return resp['data'] ?? resp;
  }

  static Future<List<dynamic>> getPendingRequests() async {
    final resp = await ApiService.request(
      method: 'GET',
      path: '/transfer-requests/pending',
      requiresAuth: true,
    );
    return List<dynamic>.from(resp['data'] ?? []);
  }

  static Future<List<dynamic>> getTransferRequestHistory({
    int page = 1,
    int limit = 10,
  }) async {
    final path = '/transfer-requests?page=${Uri.encodeQueryComponent(page.toString())}&limit=${Uri.encodeQueryComponent(limit.toString())}';
    final resp = await ApiService.request(
      method: 'GET',
      path: path,
      requiresAuth: true,
    );
    return List<dynamic>.from(resp['data'] ?? []);
  }

  static Future<Map<String, dynamic>> requestFunds({
    required String senderIdentifier,
    required double amount,
    String? description,
  }) async {
    final resp = await ApiService.request(
      method: 'POST',
      path: '/transfer-requests/request',
      body: {
        'sender_identifier': senderIdentifier,
        'amount': amount,
        'description': description ?? '',
      },
      requiresAuth: true,
    );
    return resp;
  }

  static Future<Map<String, dynamic>> acceptTransferRequest({
    required String requestId,
    String? pin,
    bool? biometricAuth,
    String? deviceFingerprint,
  }) async {
    final resp = await ApiService.request(
      method: 'POST',
      path: '/transfer-requests/accept',
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

  static Future<Map<String, dynamic>> rejectTransferRequest({
    required String requestId,
  }) async {
    final resp = await ApiService.request(
      method: 'POST',
      path: '/transfer-requests/$requestId/reject',
      requiresAuth: true,
    );
    return resp;
  }

  static Future<Map<String, dynamic>> cancelTransferRequest({
    required String requestId,
  }) async {
    final resp = await ApiService.request(
      method: 'POST',
      path: '/transfer-requests/$requestId/cancel',
      requiresAuth: true,
    );
    return resp;
  }
}
