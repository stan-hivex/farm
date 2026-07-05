import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/app_state.dart';
import '/core/config/supabase_config.dart';
import '/services/secure_storage_service.dart';
import '/services/auth/auth_service.dart';

/// Service for biometric-based login (fingerprint/face ID).
///
/// Flow:
/// 1. User taps fingerprint button
/// 2. Local authentication challenge (fingerprint/face)
/// 3. On success: Retrieve stored Supabase session
/// 4. Refresh Supabase session
/// 5. Exchange new Supabase token for FARM JWT via backend
/// 6. Store new tokens and route to Dashboard
class BiometricLoginService {
  static final BiometricLoginService _instance =
      BiometricLoginService._internal();

  factory BiometricLoginService() {
    return _instance;
  }

  BiometricLoginService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Check if device supports biometric authentication.
  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types on this device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if user has already authenticated with biometrics before.
  ///
  /// This checks if:
  /// 1. Biometrics are enabled in settings (FFAppState.biometricsEnabled)
  /// 2. A stored Supabase session exists
  Future<bool> hasBiometricSession() async {
    try {
      if (!FFAppState().biometricsEnabled) {
        return false;
      }

      // Check if Supabase has a stored session
      final session = _supabase.auth.currentSession;
      return session != null;
    } catch (e) {
      debugPrint('Error checking biometric session: $e');
      return false;
    }
  }

  /// Perform biometric authentication and unlock stored Supabase session.
  ///
  /// Returns:
  /// - Success map with tokens and user data if successful
  /// - Throws Exception with error message if fails
  ///
  /// Steps:
  /// 1. Verify fingerprint/face locally
  /// 2. Retrieve stored Supabase session
  /// 3. Refresh Supabase session (get new tokens)
  /// 4. Exchange Supabase token for FARM JWT
  /// 5. Store tokens and return user data
  Future<Map<String, dynamic>> authenticateWithBiometric() async {
    try {
      // Step 1: Authenticate locally with fingerprint/face
      debugPrint('[Biometric] Starting local authentication...');
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock your FARM account with your fingerprint',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!isAuthenticated) {
        throw Exception('Biometric authentication was cancelled or failed.');
      }

      debugPrint('[Biometric] Local auth succeeded');

      // Step 2: Verify Supabase session exists
      final currentSession = _supabase.auth.currentSession;
      if (currentSession == null) {
        throw Exception(
          'No stored session found. Please log in with email/password first.',
        );
      }

      debugPrint('[Biometric] Found stored Supabase session');

      // Step 3: Refresh Supabase session
      debugPrint('[Biometric] Refreshing Supabase session...');
      final refreshedSession = await _supabase.auth.refreshSession();
      if (refreshedSession.session == null) {
        throw Exception('Failed to refresh Supabase session.');
      }

      debugPrint('[Biometric] Supabase session refreshed');

      // Step 4: Exchange new Supabase token for FARM JWT
      debugPrint('[Biometric] Exchanging Supabase token for FARM JWT...');
      final newSupabaseToken = refreshedSession.session!.accessToken;
      final farmTokenResponse =
          await AuthService().exchangeSupabaseToken(newSupabaseToken);

      final farmJwt = farmTokenResponse['access_token'] as String? ?? '';
      final refreshToken = farmTokenResponse['refresh_token'] as String? ?? '';
      final userData =
          farmTokenResponse['user'] as Map<String, dynamic>? ?? {};

      if (farmJwt.isEmpty) {
        throw Exception('Failed to obtain FARM JWT from backend.');
      }

      debugPrint('[Biometric] FARM JWT obtained');

      // Step 5: Store tokens in app state and secure storage
      FFAppState().accessToken = farmJwt;
      FFAppState().refreshToken = refreshToken;
      FFAppState().userId = userData['id'] ?? '';
      FFAppState().firstName = userData['first_name'] ?? '';
      FFAppState().userName = userData['username'] ?? '';
      FFAppState().phone = userData['phone'] ?? '';
      FFAppState().kycStatus = userData['kyc_status'] ?? '';
      FFAppState().role = (userData['role'] ?? 'user').toString();
      FFAppState().isLoggedIn = true;

      // Persist to secure storage
      await SecureStorageService.writeAccessToken(farmJwt);
      await SecureStorageService.writeRefreshToken(refreshToken);

      // Update biometric verification timestamp
      await SecureStorageService.writeBiometricLastVerified(
        DateTime.now().toIso8601String(),
      );

      debugPrint('[Biometric] Tokens stored successfully');

      return {
        'success': true,
        'farmJwt': farmJwt,
        'refreshToken': refreshToken,
        'user': userData,
        'message': 'Biometric login successful',
      };
    } catch (e) {
      debugPrint('[Biometric] Error: $e');
      throw Exception('Biometric login failed: $e');
    }
  }

  /// Get a user-friendly message based on biometric status.
  Future<String> getBiometricButtonLabel() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.contains(BiometricType.face)) {
        return 'Login with Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Login with Fingerprint';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Login with Iris';
      }
      return 'Login with Biometric';
    } catch (_) {
      return 'Login with Biometric';
    }
  }

  /// Disable biometric login (usually called on logout).
  Future<void> disableBiometricLogin() async {
    try {
      FFAppState().biometricsEnabled = false;
      await SecureStorageService.clearBiometricData();
      debugPrint('[Biometric] Login disabled');
    } catch (e) {
      debugPrint('[Biometric] Error disabling: $e');
    }
  }
}
