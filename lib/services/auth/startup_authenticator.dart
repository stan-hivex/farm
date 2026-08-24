import 'package:flutter/foundation.dart';
import '../../app_state.dart';
import '../../backend/services/api_service.dart';
import 'session_store_service.dart';
import 'refresh_manager.dart';

/// Restores persisted sessions at app startup.
///
/// Behavior:
/// - Reads role-specific persisted session from `AuthSessionStore`.
/// - Restores in-memory `FFAppState()` fields if missing.
/// - Attempts a forced refresh using `RefreshManager().refreshIfNeeded(force: true)`
///   when a persisted session exists.
/// - If refresh is temporarily unavailable, keeps the persisted session intact.
class StartupAuthenticator {
  static final StartupAuthenticator _instance = StartupAuthenticator._internal();
  factory StartupAuthenticator() => _instance;
  StartupAuthenticator._internal();

  /// Restore persisted session and attempt silent token refresh.
  /// Call this before `runApp()` so routing decisions can rely on restored state.
  Future<void> restoreSession() async {
    final state = FFAppState();
    state.setAuthStartupState(AuthStartupState.initializing);
    debugPrint('[AUTH STARTUP] Beginning session restoration');
    try {
      final role = (await AuthSessionStore.readActiveRole() ?? '').toLowerCase();
      if (role.isEmpty) {
        state.setAuthStartupState(AuthStartupState.unauthenticated);
        return;
      }
      final persisted = await AuthSessionStore.readRoleSession(role);
      if (persisted == null) {
        state.setAuthStartupState(AuthStartupState.unauthenticated);
        debugPrint('[AUTH STARTUP] No persisted session found');
        return;
      }

      debugPrint('[AUTH STARTUP] Persisted session found; restoring role=$role');

      // Populate in-memory state conservatively if missing
      if (state.accessToken.isEmpty && (persisted.accessToken).isNotEmpty) {
        state.accessToken = persisted.accessToken;
      }
      if (state.refreshToken.isEmpty && (persisted.refreshToken).isNotEmpty) {
        state.refreshToken = persisted.refreshToken;
      }
      if (state.userId.isEmpty && (persisted.userId).isNotEmpty) {
        state.userId = persisted.userId;
      }
      state.role = persisted.role;
      // A refresh token keeps the session authenticated while access is renewed.
      state.isLoggedIn = state.accessToken.isNotEmpty || state.refreshToken.isNotEmpty;

      // Try a forced refresh to ensure tokens are valid. If refresh succeeds,
      // the RefreshManager will update persisted session tokens as needed.
      bool refreshed = false;
      try {
        refreshed = await RefreshManager().refreshIfNeeded(force: true);
        debugPrint('[AUTH STARTUP] Refresh result=$refreshed');
      } catch (e) {
        debugPrint('[AUTH STARTUP] Refresh temporarily unavailable: $e');
      }

      if (RefreshManager().lastFailureWasRevocation) {
        await state.clearAuthCredentials('startup refresh session revoked');
        return;
      }

      try {
        final profileResponse = await ApiService.getProfile(timeoutSeconds: 5);
        final profile = profileResponse['data'] is Map<String, dynamic>
            ? profileResponse['data'] as Map<String, dynamic>
            : profileResponse;
        final serverUserId = profile['id']?.toString() ?? '';
        final serverRole = profile['role']?.toString().toLowerCase() ?? '';
        if (serverUserId.isEmpty || serverRole.isEmpty ||
            (state.userId.isNotEmpty && serverUserId != state.userId)) {
          await state.clearAuthCredentials('startup identity mismatch');
          return;
        }
        state.userId = serverUserId;
        state.role = serverRole;
        await AuthSessionStore.saveRoleSession(
          role: serverRole,
          accessToken: state.accessToken,
          refreshToken: state.refreshToken,
          userId: serverUserId,
        );
      } catch (e) {
        debugPrint('[AUTH STARTUP] Profile verification unavailable: $e');
      }

      if (!refreshed) {
        debugPrint('[AUTH STARTUP] Preserving persisted session after temporary refresh failure');
      }
      state.setAuthStartupState(AuthStartupState.authenticated);
      debugPrint('[AUTH STARTUP] Authenticated state restored');
    } catch (e) {
      state.setAuthStartupState(AuthStartupState.unauthenticated);
      debugPrint('[StartupAuthenticator] restoreSession error: $e');
    }
  }
}
