import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/app_state.dart';
import '/core/config/supabase_config.dart';

/// Service to check and enforce route protection based on authentication status.
///
/// Requirements:
/// 1. Valid Supabase session must exist
/// 2. Valid Backend JWT (FARM JWT) must be stored in FFAppState
/// 3. Both must be present for protected routes
class RouteGuardService {
  static final RouteGuardService _instance = RouteGuardService._internal();

  factory RouteGuardService() {
    return _instance;
  }

  RouteGuardService._internal();

  SupabaseClient get _supabase => SupabaseConfig.client;

  /// Check if user has a valid Supabase session.
  ///
  /// Returns true if:
  /// - Supabase has an active session
  /// - Session is not expired
  Future<bool> hasValidSupabaseSession() async {
    try {
      final session = _supabase.auth.currentSession;
      
      if (session == null) {
        return false;
      }

      // Check if access token is still valid
      if (session.isExpired) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking Supabase session: $e');
      return false;
    }
  }

  /// Check if user has a valid Backend JWT (FARM JWT).
  ///
  /// Returns true if FFAppState has a non-empty accessToken and the user is
  /// marked as logged in, or if there is a persisted backend token available.
  bool hasValidBackendJwt() {
    final token = FFAppState().accessToken;
    return token.isNotEmpty && (FFAppState().isLoggedIn || token.isNotEmpty);
  }

  /// Check if user is fully authenticated (both Supabase + Backend).
  ///
  /// This is the primary check for route protection.
  /// 
  /// Returns true only if:
  /// 1. Valid Supabase session exists
  /// 2. Valid Backend JWT exists in FFAppState
  /// 3. User marked as logged in (isLoggedIn flag)
  Future<bool> isUserAuthenticated() async {
    try {
      final hasBackendJwt = hasValidBackendJwt();
      final isLoggedInFlag = FFAppState().isLoggedIn;
      final hasSupabaseSession = await hasValidSupabaseSession();

      return hasBackendJwt && (isLoggedInFlag || hasSupabaseSession);
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  /// Check if a specific route requires authentication.
  ///
  /// Public routes (no auth required):
  /// - /splash
  /// - /
  /// - /onboarding
  /// - /login
  /// - /register
  /// - /forgot-password
  /// - /otp
  bool isPublicRoute(String path) {
    final publicPaths = [
      '/',
      '/splash',
      '/onboarding',
      '/login',
      '/register',
      '/forgot-password',
      '/forgotPasswordPage',
      '/reset-password',
      '/verify-email',
      '/otp',
    ];

    return publicPaths.contains(path) ||
        publicPaths.any((publicPath) => path.startsWith(publicPath));
  }

  /// Verify authentication and handle redirect if needed.
  ///
  /// Used in GoRouter redirect callback.
  /// Returns the redirect path if auth is required and user is not authenticated,
  /// otherwise returns null (no redirect).
  Future<String?> verifyAndRedirect(
    BuildContext context,
    String currentPath,
  ) async {
    // Public routes don't need protection
    if (isPublicRoute(currentPath)) {
      return null;
    }

    // Check if user is authenticated
    final isAuthenticated = await isUserAuthenticated();
    if (!isAuthenticated) {
      // Clear stale auth data before redirecting to login
      await FFAppState().clearAuthCredentials();
      return '/login';
    }

    // User is authenticated, proceed normally
    return null;
  }

  /// Clear all authentication data (logout).
  ///
  /// This ensures both Supabase session and Backend JWT are cleared.
  Future<void> clearAuthentication() async {
    try {
      // Sign out from Supabase
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out from Supabase: $e');
    }

    // Clear Backend JWT and related data from FFAppState
    await FFAppState().clearAuthCredentials();
  }
}
