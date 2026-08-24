import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:farm/admin/core/admin_guard.dart';
import 'package:farm/app_state.dart';
import 'package:farm/services/auth/route_guard_service.dart';
import 'package:farm/services/auth/session_store_service.dart';

String _makeJwt({required int expiresInSeconds}) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final payload = base64Url.encode(
    utf8.encode('{"exp":${DateTime.now().toUtc().add(Duration(seconds: expiresInSeconds)).millisecondsSinceEpoch ~/ 1000}}'),
  );
  return '$header.$payload.signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    FFAppState.reset();
  });

  test('initializePersistedState restores the admin session from the role-specific store', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', 'user');
    await prefs.setString('authInstallId', 'install-123');
    await prefs.setBool('hasCompletedLogin', true);
    await prefs.setString('accessToken', 'legacy-user-token');
    await prefs.setString('refreshToken', 'legacy-refresh-token');
    await prefs.setString('userId', 'legacy-user');
    await prefs.setBool('isLoggedIn', true);

    final adminToken = _makeJwt(expiresInSeconds: 3600);
    await AuthSessionStore.saveAdminSession(
      accessToken: adminToken,
      refreshToken: 'admin-refresh-token',
      role: 'admin',
      userId: 'admin-id',
    );

    final state = FFAppState();
    await state.initializePersistedState();

    expect(state.role, 'admin');
    expect(state.accessToken, adminToken);
    expect(state.refreshToken, 'admin-refresh-token');
    expect(state.userId, 'admin-id');
    expect(state.isLoggedIn, isTrue);
  });

  test('initializePersistedState preserves a persisted user session when the token is expired', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', 'user');
    await prefs.setString('authInstallId', 'install-456');
    await prefs.setBool('hasCompletedLogin', true);
    await prefs.setString('accessToken', 'expired-token');
    await prefs.setString('refreshToken', 'refresh-token');
    await prefs.setString('userId', 'user-id');
    await prefs.setBool('isLoggedIn', false);

    final userToken = _makeJwt(expiresInSeconds: 3600);
    await AuthSessionStore.saveUserSession(
      accessToken: userToken,
      refreshToken: 'refresh-token',
      role: 'user',
      userId: 'user-id',
    );

    final state = FFAppState();
    await state.initializePersistedState();

    expect(state.role, 'user');
    expect(state.accessToken, userToken);
    expect(state.refreshToken, 'refresh-token');
    expect(state.userId, 'user-id');
    expect(state.isLoggedIn, isTrue);
  });

  test('initializePersistedState keeps a persisted session when the access token is expired but refresh token exists', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authInstallId', 'install-123');
    await prefs.setString('role', 'user');
    await prefs.setString('accessToken', 'expired-token');
    await prefs.setString('refreshToken', 'refresh-token');
    await prefs.setString('userId', 'user-id');
    await prefs.setBool('isLoggedIn', false);

    await AuthSessionStore.saveUserSession(
      accessToken: _makeJwt(expiresInSeconds: -60),
      refreshToken: 'refresh-token',
      role: 'user',
      userId: 'user-id',
    );

    final state = FFAppState();
    await state.initializePersistedState();

    expect(state.role, 'user');
    expect(state.isLoggedIn, isTrue);
    expect(state.refreshToken, 'refresh-token');
  });

  test('initializePersistedState does not restore auth without an active session marker', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authInstallId');
    await prefs.setString('role', 'admin');
    await prefs.setString('accessToken', 'legacy-token');
    await prefs.setString('refreshToken', 'legacy-refresh');
    await prefs.setString('userId', 'legacy-user');
    await prefs.setBool('isLoggedIn', true);

    await AuthSessionStore.saveAdminSession(
      accessToken: _makeJwt(expiresInSeconds: 3600),
      refreshToken: 'legacy-refresh',
      role: 'admin',
      userId: 'legacy-user',
    );
    await prefs.remove('active_auth_role');

    final state = FFAppState();
    await state.initializePersistedState();

    expect(state.isLoggedIn, isFalse);
    expect(state.role, isEmpty);
    expect(state.accessToken, isEmpty);
  });

  test('RouteGuardService treats admin sessions as authenticated', () async {
    final state = FFAppState();
    state.role = 'admin';
    state.accessToken = _makeJwt(expiresInSeconds: 3600);
    state.refreshToken = 'admin-refresh-token';
    state.isLoggedIn = false;

    final guard = RouteGuardService();
    final authenticated = await guard.isUserAuthenticated();

    expect(authenticated, isTrue);
  });

  test('RouteGuardService recognizes persisted admin sessions without app-state token', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('adminToken');
    await prefs.remove('adminRole');

    final persistedAdminToken = _makeJwt(expiresInSeconds: 3600);
    await AuthSessionStore.saveAdminSession(
      accessToken: persistedAdminToken,
      refreshToken: 'persisted-admin-refresh-token',
      role: 'admin',
      userId: 'admin-id',
    );

    await FFAppState().initializePersistedState();

    final guard = RouteGuardService();
    final hasBackendJwt = await guard.hasValidBackendJwt();
    final authenticated = await guard.isUserAuthenticated();
    final adminAuthenticated = await AdminGuard.isAuthenticated();

    expect(FFAppState().role, 'admin');
    expect(FFAppState().accessToken, persistedAdminToken);
    expect(hasBackendJwt, isTrue);
    expect(authenticated, isTrue);
    expect(adminAuthenticated, isTrue);
  });

  test('FFAppState resolves a super-admin token from the persisted session store', () async {
    final state = FFAppState();
    state.role = 'super_admin';
    state.accessToken = '';

    final superAdminToken = _makeJwt(expiresInSeconds: 3600);
    await AuthSessionStore.saveSuperAdminSession(
      accessToken: superAdminToken,
      refreshToken: 'super-admin-refresh-token',
      role: 'super_admin',
      userId: 'super-admin-id',
    );

    final resolvedToken = await state.getActiveAccessToken();

    expect(resolvedToken, superAdminToken);
  });

  test('RouteGuardService rejects a persisted super-admin session when the role is still empty', () async {
    final state = FFAppState();
    state.role = '';
    state.accessToken = '';
    state.refreshToken = '';
    state.isLoggedIn = false;

    final persistedSuperAdminToken = _makeJwt(expiresInSeconds: 3600);
    await AuthSessionStore.saveSuperAdminSession(
      accessToken: persistedSuperAdminToken,
      refreshToken: 'persisted-super-admin-refresh-token',
      role: 'super_admin',
      userId: 'super-admin-id',
    );

    final guard = RouteGuardService();
    final authenticated = await guard.isUserAuthenticated();

    expect(authenticated, isFalse);
  });
}
