import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:farm/admin/core/admin_guard.dart';
import 'package:farm/app_state.dart';
import 'package:farm/services/auth/route_guard_service.dart';
import 'package:farm/services/auth/session_store_service.dart';

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
    await prefs.setString('accessToken', 'legacy-user-token');
    await prefs.setString('refreshToken', 'legacy-refresh-token');
    await prefs.setString('userId', 'legacy-user');
    await prefs.setBool('isLoggedIn', true);

    await AuthSessionStore.saveAdminSession(
      accessToken: 'admin-token',
      refreshToken: 'admin-refresh-token',
      role: 'admin',
      userId: 'admin-id',
    );

    final state = FFAppState();
    await state.initializePersistedState();

    expect(state.role, 'admin');
    expect(state.accessToken, 'admin-token');
    expect(state.refreshToken, 'admin-refresh-token');
    expect(state.userId, 'admin-id');
    expect(state.isLoggedIn, false);
  });

  test('RouteGuardService treats admin sessions as authenticated', () async {
    final state = FFAppState();
    state.role = 'admin';
    state.accessToken = 'admin-token';
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

    await AuthSessionStore.saveAdminSession(
      accessToken: 'persisted-admin-token',
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
    expect(hasBackendJwt, isTrue);
    expect(authenticated, isTrue);
    expect(adminAuthenticated, isTrue);
  });

  test('FFAppState resolves a super-admin token from the persisted session store', () async {
    final state = FFAppState();
    state.role = 'super_admin';
    state.accessToken = '';

    await AuthSessionStore.saveSuperAdminSession(
      accessToken: 'super-admin-token',
      refreshToken: 'super-admin-refresh-token',
      role: 'super_admin',
      userId: 'super-admin-id',
    );

    final resolvedToken = await state.getActiveAccessToken();

    expect(resolvedToken, 'super-admin-token');
  });

  test('RouteGuardService keeps a persisted super-admin session authenticated when the role is still empty', () async {
    final state = FFAppState();
    state.role = '';
    state.accessToken = '';
    state.refreshToken = '';
    state.isLoggedIn = false;

    await AuthSessionStore.saveSuperAdminSession(
      accessToken: 'persisted-super-admin-token',
      refreshToken: 'persisted-super-admin-refresh-token',
      role: 'super_admin',
      userId: 'super-admin-id',
    );

    final guard = RouteGuardService();
    final authenticated = await guard.isUserAuthenticated();

    expect(authenticated, isTrue);
  });
}
