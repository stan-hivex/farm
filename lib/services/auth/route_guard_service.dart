import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/app_state.dart';
import '/core/config/supabase_config.dart';
import 'session_store_service.dart';

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
      final message = e.toString();
      if (message.contains('LateInitializationError') ||
          message.contains('must initialize the supabase instance') ||
          message.contains('Not initialized')) {
        return false;
      }
      debugPrint('Error checking Supabase session: $e');
      return false;
    }
  }

  /// Check if user has a valid Backend JWT (FARM JWT).
  ///
  /// Returns true if FFAppState has a non-empty accessToken and the user is
  /// marked as logged in, or if there is a persisted backend token available.
  Future<bool> hasValidBackendJwt() async {
    final state = FFAppState();
    final token = state.accessToken;
    final role = state.role.toLowerCase();
    debugPrint('[RouteGuardService] hasValidBackendJwt role=$role accessTokenPresent=${token.isNotEmpty} accessTokenLength=${token.length}');

    if (token.isNotEmpty) {
      return true;
    }

    final persistedSession = await AuthSessionStore.readRoleSession(role);
    final persistedToken = persistedSession?.accessToken ?? '';
    debugPrint('[RouteGuardService] persistedSession role=$role tokenPresent=${persistedToken.isNotEmpty}');
    if (persistedToken.isNotEmpty) {
      return true;
    }

    final adminSession = await AuthSessionStore.readAdminSession();
    final superAdminSession = await AuthSessionStore.readSuperAdminSession();
    final userSession = await AuthSessionStore.readUserSession();
    debugPrint('[RouteGuardService] fallbackSessions admin=${(adminSession?.accessToken ?? '').isNotEmpty} superAdmin=${(superAdminSession?.accessToken ?? '').isNotEmpty} user=${(userSession?.accessToken ?? '').isNotEmpty}');

    return (adminSession?.accessToken ?? '').isNotEmpty ||
        (superAdminSession?.accessToken ?? '').isNotEmpty ||
        (userSession?.accessToken ?? '').isNotEmpty;
  }

  /// Check if the current session is authenticated for the active role.
  ///
  /// This is the primary check for route protection and startup auth checks.
  ///
  /// Returns true when:
  /// 1. A backend JWT exists in state
  /// 2. The active role is a user and the user is marked logged-in or has a
  ///    valid Supabase session
  /// 3. The active role is admin/super_admin and the backend JWT is present
  Future<bool> isUserAuthenticated() async {
    try {
      final state = FFAppState();
      final hasBackendJwt = await hasValidBackendJwt();
      final isLoggedInFlag = state.isLoggedIn;
      final hasSupabaseSession = await hasValidSupabaseSession();
      final role = state.role.toLowerCase();
      final isAdminRole = role == 'admin' || role == 'super_admin';

      if (!hasBackendJwt) {
        return false;
      }

      if (isAdminRole) {
        return true;
      }

      if (role.isEmpty) {
        final adminSession = await AuthSessionStore.readAdminSession();
        final superAdminSession = await AuthSessionStore.readSuperAdminSession();
        final hasPrivilegedPersistedSession =
            (adminSession?.accessToken ?? '').isNotEmpty ||
            (superAdminSession?.accessToken ?? '').isNotEmpty;
        if (hasPrivilegedPersistedSession) {
          return true;
        }
      }

      return isLoggedInFlag || hasSupabaseSession;
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
    final role = FFAppState().role.toLowerCase();
    final loggedIn = FFAppState().isLoggedIn;
    final accessTokenLength = FFAppState().accessToken.length;
    final refreshTokenLength = FFAppState().refreshToken.length;
    final persistedSession = await AuthSessionStore.readRoleSession(role);
    final sessionExists = persistedSession?.accessToken.isNotEmpty ?? false;

    print('AUTH GUARD CHECK');
    print('Current route: $currentPath');
    print('Current role: $role');
    print('Access token length: $accessTokenLength');
    print('Refresh token length: $refreshTokenLength');
    print('Session exists: $sessionExists');

    // Public routes don't need protection
    if (isPublicRoute(currentPath)) {
      print('Reason for redirect: none (public route)');
      return null;
    }

    // Check if user is authenticated
    final isAuthenticated = await isUserAuthenticated();
    if (!isAuthenticated) {
      final reason = accessTokenLength == 0
          ? 'accessToken.isEmpty'
          : role.isEmpty
              ? 'role.isEmpty'
              : 'no valid auth session';
      debugPrint('[RouteGuardService] verifyAndRedirect NOT authenticated');
      debugPrint('[RouteGuardService] role=$role loggedIn=$loggedIn currentPath=$currentPath');
      debugPrint('[RouteGuardService] redirect reason=$reason');
      if (role == 'super_admin') {
        debugPrint('SUPER_ADMIN REDIRECTED TO LOGIN');
        debugPrint(StackTrace.current.toString());
      }
      // Clear stale auth data before redirecting to login
      await FFAppState().clearAuthCredentials();
      return '/login';
    }

    debugPrint('[RouteGuardService] verifyAndRedirect authenticated role=$role currentPath=$currentPath');
    debugPrint('[RouteGuardService] verifyAndRedirect state accessTokenLength=$accessTokenLength refreshTokenLength=$refreshTokenLength sessionExists=$sessionExists');
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
