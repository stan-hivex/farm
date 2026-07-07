import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '/core/config/supabase_config.dart';
import '/core/config/env.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/services/api_service.dart';
import '/backend/services/turnstile_payload.dart';
import '/services/secure_storage_service.dart';

/// Centralized authentication service for the FARM app.
///
/// This service handles:
/// 1. Supabase authentication (signUp, login, logout, etc.)
/// 2. FARM backend JWT exchange and management
/// 3. Session refresh and verification
///
/// Registration Flow:
/// Flutter → Supabase → Verification Email → User verifies
/// → Flutter receives session → Backend creates user/wallet
/// → Backend issues FARM JWT
///
/// Login Flow:
/// Flutter → Supabase Login → Access Token
/// → POST /auth/supabase → Backend verifies → Issues FARM JWT
/// → Flutter stores FARM JWT → Dashboard
class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  SupabaseClient get _supabase => SupabaseConfig.client;

  /// Sign up a new user with email and password.
  ///
  /// Flow:
  /// 1. Create account in Supabase
  /// 2. Supabase sends verification email
  /// 3. User clicks link in email
  /// 4. Session is established
  /// 5. Backend creates FARM user, wallet, and issues JWT
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    String? country,
    String? referralCode,
    String? turnstileToken,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign up failed: User is null');
      }

      await ApiService.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        phone: phone,
        password: password,
        email: email,
        country: country,
        referralCode: referralCode,
        turnstileToken: turnstileToken,
      );

      return response;
    } on AuthException catch (e) {
      throw Exception('Sign up error: ${e.message}');
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  /// Log in with email or phone and password.
  ///
  /// Email-based login continues to use Supabase + backend token exchange.
  /// Phone/username login uses the backend login route directly.
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String? turnstileToken,
  }) async {
    try {
      final isEmail = identifier.contains('@');

      if (isEmail) {
        final authResponse = await _supabase.auth.signInWithPassword(
          email: identifier,
          password: password,
        );

        if (authResponse.session == null) {
          throw Exception('Login failed: No session returned');
        }

        final supabaseToken = authResponse.session!.accessToken;
        final backendData = await exchangeSupabaseToken(
          supabaseToken,
          turnstileToken: turnstileToken,
        );
        final farmJwt = backendData['access_token'] as String? ?? '';
        final refreshToken = backendData['refresh_token'] as String? ?? '';
        final backendUser = backendData['user'];

        if (farmJwt.isNotEmpty) {
          FFAppState().accessToken = farmJwt;
        }
        if (refreshToken.isNotEmpty) {
          FFAppState().refreshToken = refreshToken;
        }

        return {
          'success': true,
          'farmJwt': farmJwt,
          'refreshToken': refreshToken,
          'supabaseToken': supabaseToken,
          'user': backendUser ?? authResponse.user,
        };
      }

      final response = await ApiService.login(
        identifier: identifier,
        password: password,
        turnstileToken: turnstileToken,
      );

      final responseData = response['data'] as Map<String, dynamic>? ?? {};
      final farmJwt = responseData['access_token'] as String? ?? '';
      final refreshToken = responseData['refresh_token'] as String? ?? '';
      final backendUser = responseData['user'] as Map<String, dynamic>?;

      if (farmJwt.isNotEmpty) {
        FFAppState().accessToken = farmJwt;
      }
      if (refreshToken.isNotEmpty) {
        FFAppState().refreshToken = refreshToken;
      }

      return {
        'success': true,
        'farmJwt': farmJwt,
        'refreshToken': refreshToken,
        'user': backendUser,
      };
    } on AuthException catch (e) {
      throw Exception('Login error: ${e.message}');
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Exchange Supabase token for FARM backend JWT.
  ///
  /// This calls the backend /auth/supabase endpoint which:
  /// 1. Verifies the Supabase token
  /// 2. Creates or updates the FARM user
  /// 3. Creates a wallet if needed
  /// 4. Issues a FARM JWT for API authentication
  ///
  /// Public method used by AuthService.login() and BiometricLoginService.
  Future<Map<String, dynamic>> exchangeSupabaseToken(
    String supabaseToken, {
    String? turnstileToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.api}/auth/supabase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseToken',
        },
        body: jsonEncode(
          attachTurnstileToken(
            {'supabase_token': supabaseToken},
            turnstileToken: turnstileToken,
          ),
        ),
      );

      final bodyData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        final message = bodyData['message'] ?? response.body;
        throw Exception(
            'Token exchange failed: ${response.statusCode} - $message');
      }

      final payload = bodyData['data'] is Map<String, dynamic>
          ? bodyData['data'] as Map<String, dynamic>
          : bodyData;

      return payload;
    } catch (e) {
      throw Exception('Failed to exchange token: $e');
    }
  }

  /// Log out the user from Supabase and FARM backend, and clear all local auth data.
  Future<void> logout() async {
    Exception? logoutError;

    try {
      await ApiService.revokeAllSessions();
    } catch (e) {
      debugPrint('Backend revoke-all error: $e');
      try {
        await ApiService.logout();
      } catch (e2) {
        debugPrint('Backend logout fallback error: $e2');
        logoutError = Exception('Backend logout failed: $e2');
      }
    }

    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut error: $e');
      logoutError = Exception('Supabase logout failed: $e');
    }

    try {
      await SecureStorageService.clearAuthData();
      await FFAppState().clearAuthCredentials();
    } catch (e) {
      debugPrint('Local clear auth data error: $e');
      logoutError = Exception('Local logout cleanup failed: $e');
    }

    if (logoutError != null) {
      debugPrint('Logout completed with errors: ${logoutError.toString()}');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await ApiService.deleteAccount();
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }

    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut error during account deletion: $e');
    }

    try {
      await SecureStorageService.clearAuthData();
      await FFAppState().clearAuthCredentials();
    } catch (e) {
      debugPrint('Local cleanup error during account deletion: $e');
    }
  }

  /// Send a password reset email with a secure reset link.
  Future<void> sendPasswordReset({
    required String email,
    String? turnstileToken,
  }) async {
    try {
      await ApiService.forgotPassword(
        email: email,
        turnstileToken: turnstileToken,
      );
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Confirm a password reset using a secure token sent by email.
  Future<void> confirmPasswordReset({
    required String token,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await ApiService.resetPassword(
        token: token,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
    } catch (e) {
      throw Exception('Password reset confirmation failed: $e');
    }
  }

  /// Refresh the current session.
  ///
  /// This is called when the access token is about to expire.
  /// Returns the new FARM JWT if successful.
  Future<String?> refreshSession() async {
    try {
      final backendRefreshToken = FFAppState().refreshToken.trim();
      if (backendRefreshToken.isNotEmpty) {
        final response =
            await ApiService.refreshToken(refreshToken: backendRefreshToken);
        final payload = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final newFarmJwt = payload['access_token'] as String? ?? '';
        final newRefreshToken = payload['refresh_token'] as String? ?? '';

        if (newFarmJwt.isEmpty) {
          throw Exception('Backend refresh did not return an access token');
        }

        FFAppState().accessToken = newFarmJwt;
        if (newRefreshToken.isNotEmpty) {
          FFAppState().refreshToken = newRefreshToken;
          await SecureStorageService.writeRefreshToken(newRefreshToken);
        }

        try {
          if (_supabase.auth.currentSession != null) {
            await _supabase.auth.refreshSession();
          }
        } catch (e) {
          debugPrint('Supabase refresh best-effort failed: $e');
        }

        return newFarmJwt;
      }

      final currentSession = _supabase.auth.currentSession;
      if (currentSession == null) {
        throw Exception('No active session to refresh');
      }

      final response = await _supabase.auth.refreshSession();
      if (response.session == null) {
        throw Exception('Session refresh failed');
      }

      final newSupabaseToken = response.session!.accessToken;
      final backendData = await exchangeSupabaseToken(newSupabaseToken);
      final newFarmJwt = backendData['access_token'] as String? ?? '';
      final refreshToken = backendData['refresh_token'] as String? ?? '';

      if (newFarmJwt.isNotEmpty) {
        FFAppState().accessToken = newFarmJwt;
      }
      if (refreshToken.isNotEmpty) {
        FFAppState().refreshToken = refreshToken;
      }

      return newFarmJwt;
    } catch (e) {
      await FFAppState().clearAuthCredentials();
      throw Exception('Session refresh failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final response = await ApiService.getSessions();
    final sessions = response['sessions'];
    if (sessions is List) {
      return sessions.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<void> revokeSession({required String sessionId}) async {
    await ApiService.revokeSession(sessionId: sessionId);
  }

  Future<void> revokeOtherSessions() async {
    await ApiService.revokeOtherSessions();
  }

  Future<void> revokeAllSessions() async {
    await ApiService.revokeAllSessions();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await ApiService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  /// Verify email with a token from the verification link.
  ///
  /// Called after user clicks the verification link in their email.
  Future<void> verifyEmail({required String token}) async {
    try {
      final response = await ApiService.verifyEmail(token: token);
      if (response['message'] == null) {
        throw Exception('Email verification failed: Invalid response');
      }
    } catch (e) {
      throw Exception('Email verification failed: $e');
    }
  }

  Future<void> resendEmailVerification({required String email}) async {
    try {
      final response = await ApiService.resendEmailVerification(email: email);
      if (response['message'] == null) {
        throw Exception('Resend verification failed: Invalid response');
      }
    } catch (e) {
      throw Exception('Resend verification failed: $e');
    }
  }

  /// Get the current authenticated user.
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Get the current session.
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  /// Check if user is authenticated.
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null &&
        _supabase.auth.currentSession != null;
  }

  /// Listen to auth state changes.
  /// Returns a stream that emits AuthState when authentication changes.
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
