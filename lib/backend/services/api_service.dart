import 'dart:convert';
import 'package:flutter/foundation.dart';
import '/backend/services/turnstile_payload.dart';
import 'package:http/http.dart' as http;
import '/core/app_config.dart';
import '/app_state.dart';
import '/services/auth/refresh_manager.dart';

class ApiService {
  static http.Client _client = http.Client();

  static set client(http.Client value) => _client = value;

  static Future<Map<String, dynamic>> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) =>
      _request(
        method: method,
        path: path,
        body: body,
        requiresAuth: requiresAuth,
      );

  // Central method — all requests go through here
  static final Map<String, Map<String, dynamic>> _cache = {};

  static Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    bool isRetry = false,
    int timeoutSeconds = 5,
  }) async {
    final uri = Uri.parse('${AppConfig.api}$path');
    final token = FFAppState().accessToken;

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (requiresAuth && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    http.Response response;
    final start = DateTime.now();
    debugPrint('[ApiService] START $method $path @ $start');

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(
                Duration(seconds: timeoutSeconds),
              );
          break;
        case 'POST':
          response = await _client
              .post(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'PUT':
          response = await _client
              .put(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'PATCH':
          response = await _client
              .patch(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(Duration(seconds: timeoutSeconds));
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(Duration(seconds: timeoutSeconds));
          break;
        default:
          throw Exception('Unknown HTTP method: $method');
      }
    } catch (e) {
      final duration = DateTime.now().difference(start);
      debugPrint(
          '[ApiService] ERROR $method $path after ${duration.inMilliseconds}ms -> $e');
      rethrow;
    }

    final duration = DateTime.now().difference(start);
    debugPrint(
        '[ApiService] END $method $path status=${response.statusCode} duration=${duration.inMilliseconds}ms');
    if (duration.inMilliseconds > 1000) {
      debugPrint('[ApiService] SLOW_ENDPOINT $method $path took ${duration.inMilliseconds}ms');
    }

    if ((response.statusCode == 401 || response.statusCode == 403) &&
        requiresAuth &&
        !isRetry &&
        FFAppState().refreshToken.isNotEmpty) {
      final refreshed = await RefreshManager().refreshIfNeeded(force: true);
      if (refreshed) {
        await Future.delayed(const Duration(milliseconds: 250));
        return _request(
          method: method,
          path: path,
          body: body,
          requiresAuth: requiresAuth,
          isRetry: true,
          timeoutSeconds: timeoutSeconds,
        );
      }
    }

    Map<String, dynamic> decoded = {};
    String responseBody = response.body;

    if (responseBody.isNotEmpty) {
      try {
        decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {
        decoded = {};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // store in simple in-memory cache keyed by path
      try {
        _cache[path] = decoded;
      } catch (_) {}
      return decoded;
    }

    final message = decoded['message'] is String
        ? decoded['message'] as String
        : responseBody;
    throw Exception(message.isNotEmpty
        ? message
        : 'Request failed (${response.statusCode})');
  }


  // ── Auth ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String? turnstileToken,
  }) =>
      _request(
        method: 'POST',
        path: '/auth/login',
        body: attachTurnstileToken(
          {
            'identifier': identifier,
            'password': password,
          },
          turnstileToken: turnstileToken,
        ),
        requiresAuth: false,
      );

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String password,
    String? email,
    String? country,
    String? referralCode,
    String? turnstileToken,
  }) =>
      _request(
        method: 'POST',
        path: '/auth/register',
        body: attachTurnstileToken(
          {
            'first_name': firstName,
            'last_name': lastName,
            'username': username,
            'phone': phone,
            'password': password,
            if (email != null && email.isNotEmpty) 'email': email,
            if (country != null && country.isNotEmpty) 'country': country,
            if (referralCode != null && referralCode.isNotEmpty)
              'referral_code': referralCode,
          },
          turnstileToken: turnstileToken,
        ),
        requiresAuth: false,
      );

  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otpCode,
    String purpose = 'phone_verification',
  }) =>
      _request(
        method: 'POST',
        path: '/auth/verify-otp',
        body: {'phone': phone, 'otp_code': otpCode, 'purpose': purpose},
        requiresAuth: false,
      );

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
    String? turnstileToken,
  }) =>
      _request(
        method: 'POST',
        path: '/auth/forgot-password',
        body: attachTurnstileToken({'email': email},
            turnstileToken: turnstileToken),
        requiresAuth: false,
      );

  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String email,
    required String password,
    required String confirmPassword,
  }) =>
      _request(
        method: 'POST',
        path: '/auth/reset-password',
        body: {
          'token': token,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        },
        requiresAuth: false,
      );

  static Future<Map<String, dynamic>> setPin({
    required String pin,
    required String confirmPin,
  }) =>
      _request(
        method: 'POST',
        path: '/auth/set-pin',
        body: {'pin': pin, 'confirm_pin': confirmPin},
      );

  static Future<Map<String, dynamic>> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) =>
      _request(
        method: 'POST',
        path: '/auth/change-pin',
        body: {
          'current_pin': currentPin,
          'new_pin': newPin,
          'confirm_pin': confirmPin,
        },
      );

  static Future<void> logout() =>
      _request(method: 'POST', path: '/auth/logout');

  static Future<Map<String, dynamic>> getSessions() =>
      _request(method: 'GET', path: '/auth/sessions');

  static Future<Map<String, dynamic>> revokeSession({
    required String sessionId,
  }) =>
      _request(
        method: 'POST',
        path: '/auth/sessions/revoke',
        body: {'session_id': sessionId},
      );

  static Future<Map<String, dynamic>> revokeOtherSessions() =>
      _request(method: 'POST', path: '/auth/sessions/revoke-other');

  static Future<Map<String, dynamic>> revokeAllSessions() =>
      _request(method: 'POST', path: '/auth/sessions/revoke-all');

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _request(
        method: 'POST',
        path: '/auth/change-password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

  static Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) =>
      _request(
        method: 'POST',
        path: '/auth/refresh',
        body: {'refresh_token': refreshToken},
        requiresAuth: false,
      );

  static Future<Map<String, dynamic>> resendOtp() =>
      _request(method: 'POST', path: '/auth/resend-otp');

  static Future<Map<String, dynamic>> verifyEmail({
    required String token,
  }) =>
      _request(
        method: 'GET',
        path: '/auth/verify-email/$token',
        requiresAuth: false,
      );

  static Future<Map<String, dynamic>> resendEmailVerification({
    required String email,
  }) =>
      _request(
        method: 'POST',
        path: '/auth/resend-email-verification',
        body: {'email': email},
        requiresAuth: false,
      );

  static Future<Map<String, dynamic>> deleteAccount() =>
      _request(method: 'DELETE', path: '/auth/delete-account');

  // ── Wallet ────────────────────────────────────────────────────────────────
    static Future<Map<String, dynamic>> getWallet({int timeoutSeconds = 5}) =>
      _request(method: 'GET', path: '/wallet', timeoutSeconds: timeoutSeconds);

    /// Return last cached response for a given path, if any.
    static Map<String, dynamic>? getCached(String path) => _cache[path];

  static Future<Map<String, dynamic>> sendFunds({
    required String recipientIdentifier,
    required double amount,
    required String pin,
    String? description,
  }) =>
      _request(
        method: 'POST',
        path: '/wallet/send',
        body: {
          'recipient_identifier': recipientIdentifier,
          'amount': amount,
          'pin': pin,
          if (description != null) 'description': description,
        },
      );

  static Future<Map<String, dynamic>> getTransactions({
    String? type,
    String? status,
    int page = 1,
    int limit = 20,
    int timeoutSeconds = 5,
  }) =>
      _request(
        method: 'GET',
        path: '/wallet/transactions?page=$page&limit=$limit'
            '${type != null ? "&type=$type" : ""}'
            '${status != null ? "&status=$status" : ""}',
        timeoutSeconds: timeoutSeconds,
      );
  static Future<Map<String, dynamic>> getGrowthHistory({
    required int days,
    int timeoutSeconds = 5,
  }) =>
      _request(
        method: 'GET',
        path: '/analytics/growth-history?days=$days',
        timeoutSeconds: timeoutSeconds,
      );
  // ── Deposit ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> initiateDeposit({
    required double amountFiat,
    required String currency,
  }) =>
      _request(
        method: 'POST',
        path: '/payments/deposit',
        body: {'amount_fiat': amountFiat, 'currency': currency},
      );

  static Future<Map<String, dynamic>> getDepositHistory() =>
      _request(method: 'GET', path: '/payments/deposits');

  static Future<Map<String, dynamic>> getDepositStatus(String reference) =>
      _request(method: 'GET', path: '/payments/deposit/$reference');

  // ── Withdraw ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> requestWithdrawal({
    required double amountFarm,
    required String currencyFiat,
    required String method,
    required String destination,
    required String pin,
  }) =>
      _request(
        method: 'POST',
        path: '/payments/withdraw',
        body: {
          'amount_farm': amountFarm,
          'currency_fiat': currencyFiat,
          'method': method,
          'destination': destination,
          'pin': pin,
        },
      );

  static Future<Map<String, dynamic>> getWithdrawalHistory() =>
      _request(method: 'GET', path: '/payments/withdrawals');

  static Future<Map<String, dynamic>> getWithdrawalStatus(String reference) =>
      _request(method: 'GET', path: '/payments/withdraw/$reference');

  // ── Escrow ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getEscrows({String? status}) => _request(
        method: 'GET',
        path: '/escrow${status != null ? "?status=$status" : ""}',
      );

  static Future<Map<String, dynamic>> createEscrow({
    required String sellerIdentifier,
    required double amount,
    required String title,
    required String pin,
    String? description,
    int autoReleaseDays = 7,
  }) =>
      _request(
        method: 'POST',
        path: '/escrow',
        body: {
          'seller_identifier': sellerIdentifier,
          'amount': amount,
          'title': title,
          'pin': pin,
          if (description != null) 'description': description,
          'auto_release_days': autoReleaseDays,
        },
      );

  static Future<Map<String, dynamic>> releaseEscrow(String escrowId) =>
      _request(method: 'POST', path: '/escrow/$escrowId/release');

  static Future<Map<String, dynamic>> disputeEscrow(
          String escrowId, String reason) =>
      _request(
        method: 'POST',
        path: '/escrow/$escrowId/dispute',
        body: {'reason': reason},
      );

  static Future<Map<String, dynamic>> cancelEscrow(String escrowId) =>
      _request(method: 'POST', path: '/escrow/$escrowId/cancel');

  // ── Investments ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProjects({String? category}) =>
      _request(
        method: 'GET',
        path: '/investments${category != null ? "?category=$category" : ""}',
      );

  static Future<Map<String, dynamic>> getProject(String id) =>
      _request(method: 'GET', path: '/investments/$id');

  static Future<Map<String, dynamic>> invest({
    required String projectId,
    required double amount,
    required String pin,
  }) =>
      _request(
        method: 'POST',
        path: '/investments/$projectId/invest',
        body: {'amount': amount, 'pin': pin},
      );

  static Future<Map<String, dynamic>> getMyInvestments() =>
      _request(method: 'GET', path: '/investments/my');

  // ── Merchants ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMerchantDashboard() =>
      _request(method: 'GET', path: '/merchant/dashboard');

  static Future<Map<String, dynamic>> getMerchantQr() =>
      _request(method: 'GET', path: '/merchant/qr');

  static Future<Map<String, dynamic>> validateQr(String qrPayload) => _request(
        method: 'POST',
        path: '/qr/validate',
        body: {'qr_payload': qrPayload},
      );

  static Future<Map<String, dynamic>> merchantPay({
    required String qrPayload,
    required double amount,
    required String pin,
  }) =>
      _request(
        method: 'POST',
        path: '/qr/merchant-pay',
        body: {'qr_payload': qrPayload, 'amount': amount, 'pin': pin},
      );

  // ── KYC ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> submitKyc({
    required String documentType,
    required String frontImageUrl,
    String? backImageUrl,
    required String selfieImageUrl,
    String? documentNumber,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? phoneNumber,
    String? email,
    String? country,
    String? state,
    String? city,
    String? address,
    String? postalCode,
    String? gender,
    String? nationality,
  }) =>
      _request(
        method: 'POST',
        path: '/kyc/submit',
        body: {
          'document_type': documentType,
          'front_image_url': frontImageUrl,
          if (backImageUrl != null) 'back_image_url': backImageUrl,
          'selfie_image_url': selfieImageUrl,
          if (documentNumber != null && documentNumber.isNotEmpty)
            'document_number': documentNumber,
          if (firstName != null && firstName.isNotEmpty)
            'first_name': firstName,
          if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
          if (dateOfBirth != null && dateOfBirth.isNotEmpty)
            'date_of_birth': dateOfBirth,
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phone_number': phoneNumber,
          if (email != null && email.isNotEmpty) 'email': email,
          if (country != null && country.isNotEmpty) 'country': country,
          if (state != null && state.isNotEmpty) 'state': state,
          if (city != null && city.isNotEmpty) 'city': city,
          if (address != null && address.isNotEmpty) 'address': address,
          if (postalCode != null && postalCode.isNotEmpty)
            'postal_code': postalCode,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
          if (nationality != null && nationality.isNotEmpty)
            'nationality': nationality,
        },
      );

  static Future<Map<String, dynamic>> getMyKyc() =>
      _request(method: 'GET', path: '/kyc/my');

  // ── Profile ───────────────────────────────────────────────────────────────
    static Future<Map<String, dynamic>> getProfile({int timeoutSeconds = 5}) =>
      _request(method: 'GET', path: '/users/me', timeoutSeconds: timeoutSeconds);

  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
    String? country,
    String? city,
    String? username,
  }) =>
      _request(
        method: 'PUT',
        path: '/users/me',
        body: {
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (bio != null) 'bio': bio,
          if (country != null) 'country': country,
          if (city != null) 'city': city,
          if (username != null && username.isNotEmpty) 'username': username,
        },
      );

  static Future<Map<String, dynamic>> updateEmailOrPhone({
    String? email,
    String? phone,
    required String currentPassword,
  }) =>
      _request(
        method: 'PUT',
        path: '/users/me',
        body: {
          if (email != null && email.isNotEmpty) 'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'current_password': currentPassword,
        },
      );

  static Future<Map<String, dynamic>> searchUsers(String query) => _request(
      method: 'GET',
      path: '/users/search?q=${Uri.encodeQueryComponent(query)}');

  static Future<Map<String, dynamic>> getContacts() =>
      _request(method: 'GET', path: '/users/contacts');

  static Future<Map<String, dynamic>> addContact({
    required String identifier,
    String? nickname,
  }) =>
      _request(
        method: 'POST',
        path: '/users/contacts',
        body: {
          'identifier': identifier,
          if (nickname != null) 'nickname': nickname
        },
      );

    static Future<Map<String, dynamic>> getNotifications({int timeoutSeconds = 5}) =>
      _request(method: 'GET', path: '/users/notifications', timeoutSeconds: timeoutSeconds);

  static Future<Map<String, dynamic>> markNotificationRead({
    required String notificationId,
  }) =>
      _request(
        method: 'PUT',
        path: '/users/notifications/$notificationId/read',
      );

  static Future<Map<String, dynamic>> markAllNotificationsRead() =>
      _request(
        method: 'PUT',
        path: '/users/notifications/read-all',
      );

  static Future<Map<String, dynamic>> deleteNotification({
    required String notificationId,
  }) =>
      _request(
        method: 'DELETE',
        path: '/users/notifications/$notificationId',
      );

  // ── Health check ──────────────────────────────────────────────────────────
  static Future<bool> isBackendAlive() async {
    try {
      final res = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/health'),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
