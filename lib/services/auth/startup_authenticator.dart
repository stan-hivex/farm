import 'package:flutter/foundation.dart';
import '../../app_state.dart';
import 'session_store_service.dart';
import 'refresh_manager.dart';

/// Restores persisted sessions at app startup.
///
/// Behavior:
/// - Reads role-specific persisted session from `AuthSessionStore`.
/// - Restores in-memory `FFAppState()` fields if missing.
/// - Attempts a forced refresh using `RefreshManager().refreshIfNeeded(force: true)`
///   when a persisted session exists.
/// - If refresh fails, clears local persisted auth to avoid inconsistent state.
class StartupAuthenticator {
  static final StartupAuthenticator _instance = StartupAuthenticator._internal();
  factory StartupAuthenticator() => _instance;
  StartupAuthenticator._internal();

  /// Restore persisted session and attempt silent token refresh.
  /// Call this before `runApp()` so routing decisions can rely on restored state.
  Future<void> restoreSession() async {
    try {
      final state = FFAppState();
      final role = state.role.toLowerCase();
      final persisted = await AuthSessionStore.readRoleSession(role);
      if (persisted == null) {
        debugPrint('[StartupAuthenticator] no persisted session for role=$role');
        return;
      }

      debugPrint('[StartupAuthenticator] restoring persisted session for role=$role');

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
      if (state.role.isEmpty && (persisted.role).isNotEmpty) {
        state.role = persisted.role;
      }
      // Consider the user logged in when an access token exists
      state.isLoggedIn = (state.accessToken.isNotEmpty);

      // Try a forced refresh to ensure tokens are valid. If refresh succeeds,
      // the RefreshManager will update persisted session tokens as needed.
      bool refreshed = false;
      try {
        refreshed = await RefreshManager().refreshIfNeeded(force: true);
        debugPrint('[StartupAuthenticator] forced refresh result=$refreshed');
      } catch (e) {
        debugPrint('[StartupAuthenticator] refresh attempt failed: $e');
      }

      if (!refreshed) {
        // Refresh failed at startup — do NOT clear persisted session here.
        // Keep persisted tokens and allow runtime flow (RouteGuard/RefreshManager)
        // to attempt refresh again and only clear on explicit backend revocation.
        debugPrint('[StartupAuthenticator] forced refresh failed at startup — preserving persisted session for role=$role');
      }
    } catch (e) {
      debugPrint('[StartupAuthenticator] restoreSession error: $e');
    }
  }
}
