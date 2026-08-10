import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_theme.dart';
import 'services/auth/session_store_service.dart';
import 'services/secure_storage_service.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future<void> initializePersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final storedRole = (prefs.getString('role')?.toLowerCase() ?? '').trim();
    final installMarker = (prefs.getString('authInstallId') ?? '').trim();

    final adminSession = await AuthSessionStore.readAdminSession();
    final superAdminSession = await AuthSessionStore.readSuperAdminSession();
    final userSession = await AuthSessionStore.readUserSession();

    final shouldRestoreSession = installMarker.isNotEmpty || (prefs.getBool('hasCompletedLogin') ?? false);

    _accessToken = '';
    _refreshToken = '';
    _userId = '';
    _role = '';
    _isLoggedIn = false;

    AuthSession? restoredSession;
    String restoredRole = '';
    if (shouldRestoreSession) {
      final roleCandidates = <String>[];
      if (storedRole.isNotEmpty) {
        roleCandidates.add(storedRole);
      }
      if (storedRole != 'admin') {
        roleCandidates.add('admin');
      }
      if (storedRole != 'super_admin') {
        roleCandidates.add('super_admin');
      }
      if (storedRole != 'user') {
        roleCandidates.add('user');
      }

      for (final candidate in roleCandidates) {
        final candidateSession = candidate == 'admin'
            ? adminSession
            : candidate == 'super_admin'
                ? superAdminSession
                : candidate == 'user'
                    ? userSession
                    : null;
        if (candidateSession != null && (_isJwtValid(candidateSession.accessToken) || candidateSession.refreshToken.isNotEmpty)) {
          restoredSession = candidateSession;
          restoredRole = candidateSession.role.isNotEmpty ? candidateSession.role : candidate;
          break;
        }
      }

      if (restoredSession == null) {
        if (adminSession != null && (_isJwtValid(adminSession.accessToken) || adminSession.refreshToken.isNotEmpty)) {
          restoredSession = adminSession;
          restoredRole = adminSession.role.isNotEmpty ? adminSession.role : 'admin';
        } else if (superAdminSession != null && (_isJwtValid(superAdminSession.accessToken) || superAdminSession.refreshToken.isNotEmpty)) {
          restoredSession = superAdminSession;
          restoredRole = superAdminSession.role.isNotEmpty ? superAdminSession.role : 'super_admin';
        } else if (userSession != null && (_isJwtValid(userSession.accessToken) || userSession.refreshToken.isNotEmpty)) {
          restoredSession = userSession;
          restoredRole = userSession.role.isNotEmpty ? userSession.role : 'user';
        }
      }
    }

    if (restoredSession != null && shouldRestoreSession) {
      _accessToken = restoredSession.accessToken;
      _refreshToken = restoredSession.refreshToken;
      _userId = restoredSession.userId;
      _role = restoredRole;
      _isLoggedIn = true;
    } else if (shouldRestoreSession) {
      _accessToken = prefs.getString('accessToken') ?? '';
      if (_accessToken.isEmpty) {
        _accessToken = await SecureStorageService.readAccessToken() ?? '';
      }
      _refreshToken = prefs.getString('refreshToken') ?? '';
      if (_refreshToken.isEmpty) {
        _refreshToken = await SecureStorageService.readRefreshToken() ?? '';
      }
      _userId = prefs.getString('userId') ?? '';
      _role = storedRole.isNotEmpty ? storedRole : '';
      if (_role.isEmpty && _accessToken.isNotEmpty) {
        _role = 'user';
      }
      if ((_role.isNotEmpty && (_accessToken.isNotEmpty || _refreshToken.isNotEmpty)) || prefs.getBool('isLoggedIn') == true) {
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
      }
    }

    _firstName = _role == 'user' ? prefs.getString('firstName') ?? '' : '';
    _userName = _role == 'user' ? prefs.getString('userName') ?? '' : '';
    _phone = _role == 'user' ? prefs.getString('phone') ?? '' : '';
    _email = _role == 'user' ? prefs.getString('email') ?? '' : '';
    _kycStatus = _role == 'user' ? prefs.getString('kycStatus') ?? '' : '';
    _biometricsEnabled = _role == 'user' ? prefs.getBool('biometricsEnabled') ?? false : false;
    _hasPin = prefs.getBool('hasPin') ?? false;
    _pushNotifications = prefs.getBool('pushNotifications') ?? true;
    _emailNotifications = prefs.getBool('emailNotifications') ?? false;
    _inAppNotifications = prefs.getBool('inAppNotifications') ?? true;
    _smsNotifications = prefs.getBool('smsNotifications') ?? false;
    _notificationSoundEnabled = prefs.getBool('notificationSoundEnabled') ?? true;
    _notificationVibrationEnabled = prefs.getBool('notificationVibrationEnabled') ?? true;
    _walletBalance = prefs.getDouble('walletBalance') ?? 0.0;
    _kesEquivalent = prefs.getDouble('kesEquivalent') ?? 0.0;
    _profileImageUrl = prefs.getString('profileImageUrl') ?? '';
    _unreadNotificationCount = prefs.getInt('unreadNotificationCount') ?? 0;
    if (prefs.containsKey('biometricLockTimeoutSeconds')) {
      _biometricLockTimeoutSeconds = prefs.getInt('biometricLockTimeoutSeconds') ?? 600;
    } else if (prefs.containsKey('biometricLockTimeoutMinutes')) {
      _biometricLockTimeoutSeconds = (prefs.getInt('biometricLockTimeoutMinutes') ?? 10) * 60;
    } else {
      _biometricLockTimeoutSeconds = 600;
    }
    final storedBiometricVerified = prefs.getString('biometric_last_verified');
    if (storedBiometricVerified != null) {
      _biometricLastVerified = DateTime.tryParse(storedBiometricVerified);
    } else {
      _biometricLastVerified = await SecureStorageService.readBiometricLastVerified();
    }

    final themeModeString = prefs.getString('themeMode');
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }
  }

  static bool _isJwtValid(String token) {
    final expiry = _getJwtExpiry(token);
    if (expiry == null) return false;
    return expiry.isAfter(DateTime.now().toUtc());
  }

  static DateTime? _getJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = payloadMap['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }
      if (exp is String) {
        final value = int.tryParse(exp);
        if (value != null) {
          return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
        }
      }
    } catch (e) {
      debugPrint('[FFAppState] Failed to parse JWT expiry: $e');
    }
    return null;
  }

  bool _suspendNotifications = false;

  void _notifyListeners() {
    if (!_suspendNotifications) {
      notifyListeners();
    }
  }

  void update(VoidCallback callback) {
    callback();
    _notifyListeners();
  }

  void batchUpdate(VoidCallback callback) {
    _suspendNotifications = true;
    callback();
    _suspendNotifications = false;
    notifyListeners();
  }

  String _accessToken = '';
  String get accessToken => _accessToken;
  set accessToken(String value) {
    if (_accessToken == value) return;
    _accessToken = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('accessToken', value),
    );
    SecureStorageService.writeAccessToken(value);
  }

  String get authToken => _accessToken;

  Future<String> getActiveAccessToken() async {
    if (_accessToken.isNotEmpty && _isJwtValid(_accessToken)) {
      debugPrint('[FFAppState] getActiveAccessToken using valid in-memory token length=${_accessToken.length}');
      return _accessToken;
    }

    final normalizedRole = _role.toLowerCase();
    AuthSession? persistedSession;
    if (normalizedRole.isNotEmpty) {
      persistedSession = await AuthSessionStore.readRoleSession(normalizedRole);
    }
    persistedSession ??= await AuthSessionStore.readAdminSession();
    persistedSession ??= await AuthSessionStore.readSuperAdminSession();
    persistedSession ??= await AuthSessionStore.readUserSession();

    final persistedToken = persistedSession?.accessToken ?? '';
    final resolvedRole = persistedSession?.role.toLowerCase() ?? normalizedRole;
    debugPrint('[FFAppState] getActiveAccessToken role=$resolvedRole persistedTokenPresent=${persistedToken.isNotEmpty}');
    if (persistedToken.isNotEmpty && _isJwtValid(persistedToken)) {
      _accessToken = persistedToken;
      _refreshToken = persistedSession?.refreshToken ?? _refreshToken;
      if (resolvedRole.isNotEmpty) {
        _role = resolvedRole;
      }
      _isLoggedIn = true;
      notifyListeners();
      return _accessToken;
    }

    if (_accessToken.isNotEmpty) {
      debugPrint('[FFAppState] getActiveAccessToken in-memory token invalid or expired');
      _accessToken = '';
      notifyListeners();
    }

    return '';
  }

  String _refreshToken = '';
  String get refreshToken => _refreshToken;
  set refreshToken(String value) {
    if (_refreshToken == value) return;
    _refreshToken = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('refreshToken', value),
    );
    SecureStorageService.writeRefreshToken(value);
  }

  String _userId = '';
  String get userId => _userId;
  set userId(String value) {
    if (_userId == value) return;
    _userId = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('userId', value),
    );
  }

  String _firstName = '';
  String get firstName => _firstName;
  set firstName(String value) {
    if (_firstName == value) return;
    _firstName = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('firstName', value),
    );
  }

  String _userName = '';
  String get userName => _userName;
  set userName(String value) {
    if (_userName == value) return;
    _userName = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('userName', value),
    );
  }

  String _phone = '';
  String get phone => _phone;
  set phone(String value) {
    if (_phone == value) return;
    _phone = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('phone', value),
    );
  }

  String _email = '';
  String get email => _email;
  set email(String value) {
    if (_email == value) return;
    _email = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('email', value),
    );
  }

  String _kycStatus = '';
  String get kycStatus => _kycStatus;
  set kycStatus(String value) {
    if (_kycStatus == value) return;
    _kycStatus = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('kycStatus', value),
    );
  }

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  set isLoggedIn(bool value) {
    if (_isLoggedIn == value) return;
    _isLoggedIn = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('isLoggedIn', value),
    );
  }

  bool _biometricsEnabled = false;
  bool get biometricsEnabled => _biometricsEnabled;
  set biometricsEnabled(bool value) {
    if (_biometricsEnabled == value) return;
    _biometricsEnabled = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('biometricsEnabled', value),
    );
  }

  bool _hasPin = false;
  bool get hasPin => _hasPin;
  set hasPin(bool value) {
    if (_hasPin == value) return;
    _hasPin = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('hasPin', value),
    );
  }

  DateTime? _biometricLastVerified;
  DateTime? get biometricLastVerified => _biometricLastVerified;
  set biometricLastVerified(DateTime? value) {
    if (_biometricLastVerified == value) return;
    _biometricLastVerified = value;
    notifyListeners();
    if (value == null) {
      SecureStorageService.deleteBiometricLastVerified();
      SharedPreferences.getInstance().then(
        (prefs) => prefs.remove('biometric_last_verified'),
      );
    } else {
      SecureStorageService.writeBiometricLastVerified(value.toIso8601String());
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setString('biometric_last_verified', value.toIso8601String()),
      );
    }
  }

  int _biometricLockTimeoutSeconds = 600;
  int get biometricLockTimeoutSeconds => _biometricLockTimeoutSeconds;
  set biometricLockTimeoutSeconds(int value) {
    if (_biometricLockTimeoutSeconds == value) return;
    _biometricLockTimeoutSeconds = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt('biometricLockTimeoutSeconds', value),
    );
  }

  bool _notificationSoundEnabled = true;
  bool get notificationSoundEnabled => _notificationSoundEnabled;
  set notificationSoundEnabled(bool value) {
    if (_notificationSoundEnabled == value) return;
    _notificationSoundEnabled = value;
    _notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('notificationSoundEnabled', value),
    );
  }

  bool _notificationVibrationEnabled = true;
  bool get notificationVibrationEnabled => _notificationVibrationEnabled;
  set notificationVibrationEnabled(bool value) {
    if (_notificationVibrationEnabled == value) return;
    _notificationVibrationEnabled = value;
    _notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('notificationVibrationEnabled', value),
    );
  }

  bool _pushNotifications = true;
  bool get pushNotifications => _pushNotifications;
  set pushNotifications(bool value) {
    if (_pushNotifications == value) return;
    _pushNotifications = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('pushNotifications', value),
    );
  }

  bool _emailNotifications = false;
  bool get emailNotifications => _emailNotifications;
  set emailNotifications(bool value) {
    if (_emailNotifications == value) return;
    _emailNotifications = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('emailNotifications', value),
    );
  }

  bool _inAppNotifications = true;
  bool get inAppNotifications => _inAppNotifications;
  set inAppNotifications(bool value) {
    if (_inAppNotifications == value) return;
    _inAppNotifications = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('inAppNotifications', value),
    );
  }

  bool _smsNotifications = false;
  bool get smsNotifications => _smsNotifications;
  set smsNotifications(bool value) {
    if (_smsNotifications == value) return;
    _smsNotifications = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('smsNotifications', value),
    );
  }

  bool _emailVerified = false;
  bool get emailVerified => _emailVerified;
  set emailVerified(bool value) {
    if (_emailVerified == value) return;
    _emailVerified = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('emailVerified', value),
    );
  }

  String _role = '';
  String get role => _role;
  set role(String value) {
    if (_role == value) return;
    _role = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('role', value),
    );
  }

  bool get isUser => _role.toLowerCase() == 'user';
  bool get isAdmin =>
      _role.toLowerCase() == 'admin' || _role.toLowerCase() == 'super_admin';
  bool get isBiometricAllowed => isUser && _biometricsEnabled;

  double _walletBalance = 0.0;
  double get walletBalance => _walletBalance;
  set walletBalance(double value) {
    if (_walletBalance == value) return;
    _walletBalance = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setDouble('walletBalance', value),
    );
  }

  double _kesEquivalent = 0.0;
  double get kesEquivalent => _kesEquivalent;
  set kesEquivalent(double value) {
    if (_kesEquivalent == value) return;
    _kesEquivalent = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setDouble('kesEquivalent', value),
    );
  }

  String _profileImageUrl = '';
  String get profileImageUrl => _profileImageUrl;
  set profileImageUrl(String value) {
    if (_profileImageUrl == value) return;
    _profileImageUrl = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('profileImageUrl', value),
    );
  }

  int _unreadNotificationCount = 0;
  int get unreadNotificationCount => _unreadNotificationCount;
  set unreadNotificationCount(int value) {
    if (_unreadNotificationCount == value) return;
    _unreadNotificationCount = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt('unreadNotificationCount', value),
    );
  }

  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;
  set recentTransactions(List<Map<String, dynamic>> value) {
    if (_recentTransactions == value) return;
    _recentTransactions = value;
    notifyListeners();
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('themeMode', value.name),
    );
    FlutterFlowTheme.saveThemeMode(value);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
  }

  Future<void> markAuthInstall() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getString('authInstallId') ?? '').trim().isEmpty) {
      await prefs.setString('authInstallId', _generateInstallId());
    }
  }

  Future<void> clearAuthInstallMarker() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authInstallId');
  }

  Future<void> clearAuthCredentials() async {
    final currentRole = _role.toLowerCase();
    debugPrint('[FFAppState] clearAuthCredentials called role=$_role currentRole=$currentRole accessTokenLength=${_accessToken.length} refreshTokenLength=${_refreshToken.length}');
    debugPrint(StackTrace.current.toString());

    await AuthSessionStore.clearAdminSession();
    await AuthSessionStore.clearSuperAdminSession();
    await AuthSessionStore.clearUserSession();

    accessToken = '';
    refreshToken = '';
    userId = '';
    firstName = '';
    userName = '';
    phone = '';
    kycStatus = '';
    isLoggedIn = false;
    biometricsEnabled = false;
    hasPin = false;
    role = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('firstName');
    await prefs.remove('userName');
    await prefs.remove('phone');
    await prefs.remove('kycStatus');
    await prefs.remove('isLoggedIn');
    await prefs.remove('hasCompletedLogin');
    await prefs.remove('biometricsEnabled');
    await prefs.remove('role');
    await prefs.remove('adminToken');
    await prefs.remove('adminRefreshToken');
    await prefs.remove('adminRole');
    await prefs.remove('adminName');
    await prefs.remove('authInstallId');
    await prefs.remove('biometric_last_verified');
    await SecureStorageService.clearAuthData();
    await SecureStorageService.deleteBiometricLastVerified();
  }

  String _generateInstallId() {
    return 'install-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  Future<void> clearRoleSession(String role) async {
    debugPrint('[FFAppState] clearRoleSession called role=$role');
    debugPrint(StackTrace.current.toString());
    final normalizedRole = role.toLowerCase();
    if (normalizedRole == 'admin') {
      await AuthSessionStore.clearAdminSession();
    } else if (normalizedRole == 'super_admin') {
      await AuthSessionStore.clearSuperAdminSession();
    } else {
      await AuthSessionStore.clearUserSession();
    }
  }
}
