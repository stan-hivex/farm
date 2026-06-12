import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../core/admin_config.dart';

class AdminApiService {
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('adminToken') ?? '';
    debugPrint('AdminApiService._getToken: token length=${token.length}');
    return token;
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<Map<String, dynamic>> _req({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final token = await _getToken();
    if (token.isEmpty) throw Exception('Not authenticated');
    final uri = Uri.parse('${AdminConfig.api}$path');
    late http.Response res;
    switch (method) {
      case 'GET':
        res = await http.get(uri, headers: _headers(token));
        break;
      case 'POST':
        res = await http.post(uri,
            headers: _headers(token),
            body: body != null ? jsonEncode(body) : null);
        break;
      case 'PUT':
        res = await http.put(uri,
            headers: _headers(token),
            body: body != null ? jsonEncode(body) : null);
        break;
      case 'PATCH':
        res = await http.patch(uri,
            headers: _headers(token),
            body: body != null ? jsonEncode(body) : null);
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: _headers(token));
        break;
      default:
        throw Exception('Unknown method');
    }
    // Handle explicit 401: clear stored admin credentials and surface error
    if (res.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('adminToken');
      await prefs.remove('adminRefreshToken');
      await prefs.remove('adminRole');
      await prefs.remove('adminName');
      final decoded = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>
          : <String, dynamic>{};
      throw Exception(decoded['message'] ?? 'Unauthorized');
    }

    final decoded = res.body.isNotEmpty
        ? jsonDecode(res.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    throw Exception(decoded['message'] ?? 'Request failed (${res.statusCode})');
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String identifier, String password) async {
    final res = await http.post(
      Uri.parse('${AdminConfig.api}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      final role = decoded['data']?['user']?['role'];
      if (role != 'admin' && role != 'super_admin') {
        throw Exception('Access denied. Admin account required.');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'adminToken', decoded['data']['access_token'] ?? '');
      await prefs.setString(
          'adminRefreshToken', decoded['data']['refresh_token'] ?? '');
      await prefs.setString(
          'adminRole', decoded['data']['user']['role'] ?? '');
      await prefs.setString(
          'adminName', decoded['data']['user']['first_name'] ?? 'Admin');
      return decoded;
    }
    throw Exception(decoded['message'] ?? 'Login failed');
  }

  static Future<void> logout() async {
    try {
      await _req(method: 'POST', path: '/auth/logout');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('adminToken');
      await prefs.remove('adminRefreshToken');
      await prefs.remove('adminRole');
      await prefs.remove('adminName');
    }
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardStats() =>
      _req(method: 'GET', path: '/admin/dashboard');

  // ── Users ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getUsers({
    int page = 1,
    String? search,
    String? role,
    String? kycStatus,
  }) =>
      _req(
        method: 'GET',
        path: '/admin/users?page=$page'
            '${search != null ? "&search=${Uri.encodeQueryComponent(search)}" : ""}'
            '${role != null ? "&role=$role" : ""}'
            '${kycStatus != null ? "&kyc_status=$kycStatus" : ""}',
      );

  static Future<Map<String, dynamic>> getUserDetail(String userId) =>
      _req(method: 'GET', path: '/admin/users/$userId');

  static Future<Map<String, dynamic>> updateUserStatus(
          String userId, Map<String, dynamic> data) =>
      _req(method: 'PATCH', path: '/admin/users/$userId/status', body: data);

  // ── KYC ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getKycQueue({int page = 1}) =>
      _req(method: 'GET', path: '/kyc/queue?page=$page');

  static Future<Map<String, dynamic>> reviewKyc(
          String docId, String status, {String? rejectionReason}) =>
      _req(
        method: 'POST',
        path: '/kyc/$docId/review',
        body: {
          'status': status,
          if (rejectionReason != null) 'rejection_reason': rejectionReason,
        },
      );

  // ── Transactions ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getTransactions({
    int page = 1,
    String? type,
    String? status,
    String? search,
  }) =>
      _req(
        method: 'GET',
        path: '/admin/transactions?page=$page'
            '${type != null ? "&type=$type" : ""}'
            '${status != null ? "&status=$status" : ""}'
            '${search != null ? "&search=${Uri.encodeQueryComponent(search)}" : ""}',
      );

  // ── Escrow ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getEscrows(
          {int page = 1, String? status}) =>
      _req(
        method: 'GET',
        path: '/admin/escrow?page=$page'
            '${status != null ? "&status=$status" : ""}',
      );

  static Future<Map<String, dynamic>> resolveDispute(
          String escrowId, String winner, String note) =>
      _req(
        method: 'POST',
        path: '/admin/escrow/$escrowId/resolve',
        body: {'winner': winner, 'note': note},
      );

  // ── Deposits ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDeposits(
          {int page = 1, String? status}) =>
      _req(
        method: 'GET',
        path: '/admin/transactions?page=$page&type=deposit'
            '${status != null ? "&status=$status" : ""}',
      );

  // ── Withdrawals ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getWithdrawals(
          {int page = 1, String? status}) =>
      _req(
        method: 'GET',
        path: '/admin/transactions?page=$page&type=withdrawal'
            '${status != null ? "&status=$status" : ""}',
      );

  static Future<Map<String, dynamic>> processWithdrawal(
          String txId, String action) =>
      _req(
        method: 'POST',
        path: '/admin/withdrawals/$txId/process',
        body: {'status': action},
      );

  // ── Merchants ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMerchants(
          {int page = 1, String? status}) =>
      _req(
        method: 'GET',
        path: '/admin/merchants?page=$page'
            '${status != null ? "&status=$status" : ""}',
      );

  static Future<Map<String, dynamic>> decideMerchant(
          String merchantId, String status) =>
      _req(
        method: 'POST',
        path: '/admin/merchants/$merchantId/decision',
        body: {'status': status},
      );

  // ── Notifications ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendNotification(
          Map<String, dynamic> data) =>
      _req(method: 'POST', path: '/admin/notifications/broadcast', body: data);

  // ── Settings ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getSettings() =>
      _req(method: 'GET', path: '/admin/settings');

  static Future<Map<String, dynamic>> updateSetting(
          String key, String value) =>
      _req(method: 'PUT', path: '/admin/settings/$key', body: {'value': value});

  // ── Fees ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getFees() =>
      _req(method: 'GET', path: '/admin/fees');

  static Future<Map<String, dynamic>> updateFee(
          String feeId, String value) =>
      _req(method: 'PUT', path: '/admin/fees/$feeId', body: {'value': value});

  // ── Audit logs ────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAuditLogs({int page = 1}) =>
      _req(method: 'GET', path: '/admin/audit-logs?page=$page');

  // ── Analytics ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAnalytics(
          {String period = 'month'}) =>
      _req(method: 'GET', path: '/admin/system/stats?period=$period');
}