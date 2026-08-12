import '/backend/services/api_service.dart';
import '../models/escrow_model.dart';

class EscrowApiService {
  // ── List my escrows ─────────────────────────────────────────────────────
  static Future<List<EscrowModel>> getEscrows({
    String? status,
  }) async {
    final path = status != null
        ? '/escrow?status=${Uri.encodeQueryComponent(status)}'
        : '/escrow';
    final resp = await ApiService.request(
      method: 'GET',
      path: path,
      requiresAuth: true,
    );
    final list = resp['data'] as List? ?? [];
    return list.map((e) => EscrowModel.fromJson(e)).toList();
  }

  // ── Create escrow (PIN required) ────────────────────────────────────────
  static Future<Map<String, dynamic>> createEscrow({
    required String sellerIdentifier,
    required double amount,
    required String title,
    String? pin,
    bool? biometricAuth,
    String? deviceFingerprint,
    String? description,
    int autoReleaseDays = 7,
  }) async {
    final resp = await ApiService.request(
      method: 'POST',
      path: '/escrow',
      body: {
        'seller_identifier': sellerIdentifier,
        'amount': amount,
        'title': title,
        if (pin != null) 'pin': pin,
        if (biometricAuth == true) 'biometric_auth': true,
        if (deviceFingerprint != null) 'device_fingerprint': deviceFingerprint,
        if (description != null) 'description': description,
        'auto_release_days': autoReleaseDays,
      },
      requiresAuth: true,
    );
    return resp;
  }

  // ── Release escrow funds to seller ─────────────────────────────────────
  static Future<void> releaseEscrow({
    required String escrowId,
    String? pin,
    bool? biometricAuth,
    String? deviceFingerprint,
  }) async {
    await ApiService.request(
      method: 'POST',
      path: '/escrow/$escrowId/release',
      body: {
        if (pin != null) 'pin': pin,
        if (biometricAuth == true) 'biometric_auth': true,
        if (deviceFingerprint != null) 'device_fingerprint': deviceFingerprint,
      },
      requiresAuth: true,
    );
  }

  // ── Raise a dispute ─────────────────────────────────────────────────────
  static Future<void> disputeEscrow({
    required String escrowId,
    required String reason,
  }) async {
    await ApiService.request(
      method: 'POST',
      path: '/escrow/$escrowId/dispute',
      body: {'reason': reason},
      requiresAuth: true,
    );
  }

  // ── Cancel escrow ───────────────────────────────────────────────────────
  static Future<void> cancelEscrow({
    required String escrowId,
  }) async {
    await ApiService.request(
      method: 'POST',
      path: '/escrow/$escrowId/cancel',
      requiresAuth: true,
    );
  }

  // ── Send message inside escrow ──────────────────────────────────────────
  static Future<void> sendMessage({
    required String escrowId,
    required String message,
  }) async {
    await ApiService.request(
      method: 'POST',
      path: '/escrow/$escrowId/message',
      body: {'message': message},
      requiresAuth: true,
    );
  }
}