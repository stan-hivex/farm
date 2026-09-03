import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_theme.dart';
import '/services/auth/session_store_service.dart';
import '/services/secure_storage_service.dart';

enum AuthStartupState { initializing, authenticated, unauthenticated }

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  AuthStartupState _authStartupState = AuthStartupState.initializing;
  AuthStartupState get authStartupState => _authStartupState;
  bool get isAuthInitializing =>
      _authStartupState == AuthStartupState.initializing;

  void setAuthStartupState(AuthStartupState value) {
    if (_authStartupState == value) return;
    _authStartupState = value;
    notifyListeners();
  }

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future<void> initializePersistedState() async {
    final prefs = await SharedPreferences.getInstance();

    _accessToken = prefs.getString('accessToken') ?? '';
    _refreshToken = prefs.getString('refreshToken') ?? '';
    _userId = prefs.getString('userId') ?? '';
    _firstName = prefs.getString('firstName') ?? '';
    _userName = prefs.getString('userName') ?? '';
    _phone = prefs.getString('phone') ?? '';
    _email = prefs.getString('email') ?? '';
    _kycStatus = prefs.getString('kycStatus') ?? '';
    _emailVerified = prefs.getBool('emailVerified') ?? false;
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _biometricsEnabled = prefs.getBool('biometricsEnabled') ?? false;
    _hasPin = prefs.getBool('hasPin') ?? false;
    _isBiometricAllowed = prefs.getBool('isBiometricAllowed') ?? true;
    _pushNotifications = prefs.getBool('pushNotifications') ?? true;
    _emailNotifications = prefs.getBool('emailNotifications') ?? false;
    _inAppNotifications = prefs.getBool('inAppNotifications') ?? true;
    _smsNotifications = prefs.getBool('smsNotifications') ?? false;
    _notificationSoundEnabled =
      prefs.getBool('notificationSoundEnabled') ?? true;
    _notificationVibrationEnabled =
      prefs.getBool('notificationVibrationEnabled') ?? true;
    _walletBalance = prefs.getDouble('walletBalance') ?? 0.0;
    _kesEquivalent = prefs.getDouble('kesEquivalent') ?? 0.0;
    _profileImageUrl = prefs.getString('profileImageUrl') ?? '';
    _unreadNotificationCount = prefs.getInt('unreadNotificationCount') ?? 0;
    _biometricLockTimeoutSeconds =
      prefs.getInt('biometricLockTimeoutSeconds') ?? 600;
    final biometricVerified = prefs.getString('biometricLastVerified');
    _biometricLastVerified = biometricVerified == null
      ? null
      : DateTime.tryParse(biometricVerified);
    _role = prefs.getString('role') ?? '';
    
    // Load theme mode
    final themeModeString = prefs.getString('themeMode');
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }
  }

  void update(VoidCallback callback) {
    callback();
    _notifyListeners();
  }

  bool _suspendNotifications = false;

  void batchUpdate(VoidCallback callback) {
    _suspendNotifications = true;
    callback();
    _suspendNotifications = false;
    notifyListeners();
  }

  void _notifyListeners() {
    if (!_suspendNotifications) notifyListeners();
  }

  String _accessToken = '';
  String get accessToken => _accessToken;
  set accessToken(String value) {
    _accessToken = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('accessToken', value),
    );
  }

  String get authToken => _accessToken;

  Future<String> getActiveAccessToken() async {
    if (_accessToken.isNotEmpty) return _accessToken;
    final session = await AuthSessionStore.readRoleSession(_role);
    if (session == null || session.accessToken.isEmpty) return _accessToken;
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _userId = session.userId;
    _role = session.role;
    _isLoggedIn = true;
    notifyListeners();
    return _accessToken;
  }

  String _refreshToken = '';
  String get refreshToken => _refreshToken;
  set refreshToken(String value) {
    _refreshToken = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('refreshToken', value),
    );
  }

  String _userId = '';
  String get userId => _userId;
  set userId(String value) {
    _userId = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('userId', value),
    );
  }

  String _firstName = '';
  String get firstName => _firstName;
  set firstName(String value) {
    _firstName = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('firstName', value),
    );
  }

  String _userName = '';
  String get userName => _userName;
  set userName(String value) {
    _userName = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('userName', value),
    );
  }

  String _phone = '';
  String get phone => _phone;
  set phone(String value) {
    _phone = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('phone', value),
    );
  }

  String _kycStatus = '';
  String get kycStatus => _kycStatus;
  set kycStatus(String value) {
    _kycStatus = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('kycStatus', value),
    );
  }

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  set isLoggedIn(bool value) {
    _isLoggedIn = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('isLoggedIn', value),
    );
  }

  bool _biometricsEnabled = false;
  bool get biometricsEnabled => _biometricsEnabled;
  set biometricsEnabled(bool value) {
    _biometricsEnabled = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('biometricsEnabled', value),
    );
  }

  String _role = '';
  String get role => _role;
  set role(String value) {
    _role = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('role', value),
    );
  }

  bool _emailVerified = false;
  bool get emailVerified => _emailVerified;
  set emailVerified(bool value) {
    _emailVerified = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('emailVerified', value),
    );
  }

  double _walletBalance = 0.0;
  double get walletBalance => _walletBalance;
  set walletBalance(double value) {
    _walletBalance = value;
    SharedPreferences.getInstance().then((prefs) =>
        prefs.setDouble('walletBalance', value));
    notifyListeners();
  }

  double _kesEquivalent = 0.0;
  double get kesEquivalent => _kesEquivalent;
  set kesEquivalent(double value) {
    _kesEquivalent = value;
    SharedPreferences.getInstance().then((prefs) =>
        prefs.setDouble('kesEquivalent', value));
    notifyListeners();
  }

  String _email = '';
  String get email => _email;
  set email(String value) {
    _email = value;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('email', value));
    notifyListeners();
  }

  String _profileImageUrl = '';
  String get profileImageUrl => _profileImageUrl;
  set profileImageUrl(String value) {
    _profileImageUrl = value;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('profileImageUrl', value));
    notifyListeners();
  }

  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;
  set recentTransactions(List<Map<String, dynamic>> value) {
    _recentTransactions = value;
    notifyListeners();
  }

  int _unreadNotificationCount = 0;
  int get unreadNotificationCount => _unreadNotificationCount;
  set unreadNotificationCount(int value) {
    _unreadNotificationCount = value;
    SharedPreferences.getInstance().then((prefs) => prefs.setInt('unreadNotificationCount', value));
    notifyListeners();
  }

  bool _hasPin = false;
  bool get hasPin => _hasPin;
  set hasPin(bool value) {
    _hasPin = value;
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('hasPin', value));
    notifyListeners();
  }

  bool _isBiometricAllowed = true;
  bool get isBiometricAllowed => _isBiometricAllowed;
  set isBiometricAllowed(bool value) {
    _isBiometricAllowed = value;
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('isBiometricAllowed', value));
    notifyListeners();
  }

  int _biometricLockTimeoutSeconds = 600;
  int get biometricLockTimeoutSeconds => _biometricLockTimeoutSeconds;
  set biometricLockTimeoutSeconds(int value) {
    _biometricLockTimeoutSeconds = value;
    SharedPreferences.getInstance().then((prefs) => prefs.setInt('biometricLockTimeoutSeconds', value));
    notifyListeners();
  }

  DateTime? _biometricLastVerified;
  DateTime? get biometricLastVerified => _biometricLastVerified;
  set biometricLastVerified(DateTime? value) {
    _biometricLastVerified = value;
    SharedPreferences.getInstance().then((prefs) {
      if (value == null) return prefs.remove('biometricLastVerified');
      return prefs.setString('biometricLastVerified', value.toIso8601String());
    });
    notifyListeners();
  }

  bool _pushNotifications = true;
  bool get pushNotifications => _pushNotifications;
  set pushNotifications(bool value) { _pushNotifications = value; _persistBool('pushNotifications', value); notifyListeners(); }
  bool _emailNotifications = false;
  bool get emailNotifications => _emailNotifications;
  set emailNotifications(bool value) { _emailNotifications = value; _persistBool('emailNotifications', value); notifyListeners(); }
  bool _inAppNotifications = true;
  bool get inAppNotifications => _inAppNotifications;
  set inAppNotifications(bool value) { _inAppNotifications = value; _persistBool('inAppNotifications', value); notifyListeners(); }
  bool _smsNotifications = false;
  bool get smsNotifications => _smsNotifications;
  set smsNotifications(bool value) { _smsNotifications = value; _persistBool('smsNotifications', value); notifyListeners(); }
  bool _notificationSoundEnabled = true;
  bool get notificationSoundEnabled => _notificationSoundEnabled;
  set notificationSoundEnabled(bool value) { _notificationSoundEnabled = value; _persistBool('notificationSoundEnabled', value); notifyListeners(); }
  bool _notificationVibrationEnabled = true;
  bool get notificationVibrationEnabled => _notificationVibrationEnabled;
  set notificationVibrationEnabled(bool value) { _notificationVibrationEnabled = value; _persistBool('notificationVibrationEnabled', value); notifyListeners(); }

  void _persistBool(String key, bool value) {
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(key, value));
  }

  bool get isAdmin => _role == 'admin' || _role == 'super_admin';

  Future<void> clearRoleSession(String role) =>
      AuthSessionStore.clearRoleSession(role);

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
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

  Future<void> clearAuthCredentials([String? reason]) async {
    accessToken = '';
    refreshToken = '';
    userId = '';
    firstName = '';
    userName = '';
    phone = '';
    kycStatus = '';
    isLoggedIn = false;
    biometricsEnabled = false;
    role = '';
    themeMode = ThemeMode.light;
    await SecureStorageService.clearAuthData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('firstName');
    await prefs.remove('userName');
    await prefs.remove('phone');
    await prefs.remove('kycStatus');
    await prefs.remove('emailVerified');
    await prefs.remove('isLoggedIn');
    await prefs.remove('biometricsEnabled');
    await prefs.remove('role');
  }
}
