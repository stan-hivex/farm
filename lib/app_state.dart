import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_theme.dart';
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

    _accessToken = prefs.getString('accessToken') ?? '';
    _refreshToken = prefs.getString('refreshToken') ?? '';
    _userId = prefs.getString('userId') ?? '';
    _firstName = prefs.getString('firstName') ?? '';
    _userName = prefs.getString('userName') ?? '';
    _phone = prefs.getString('phone') ?? '';
    _kycStatus = prefs.getString('kycStatus') ?? '';
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _biometricsEnabled = prefs.getBool('biometricsEnabled') ?? false;
    _pushNotifications = prefs.getBool('pushNotifications') ?? true;
    _emailNotifications = prefs.getBool('emailNotifications') ?? false;
    _inAppNotifications = prefs.getBool('inAppNotifications') ?? true;
    _smsNotifications = prefs.getBool('smsNotifications') ?? false;
    _notificationSoundEnabled =
        prefs.getBool('notificationSoundEnabled') ?? true;
    _notificationVibrationEnabled =
        prefs.getBool('notificationVibrationEnabled') ?? true;
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
    notifyListeners();
  }

  String _accessToken = '';
  String get accessToken => _accessToken;
  set accessToken(String value) {
    _accessToken = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('accessToken', value),
    );
    SecureStorageService.writeAccessToken(value);
  }

  String get authToken => _accessToken;

  String _refreshToken = '';
  String get refreshToken => _refreshToken;
  set refreshToken(String value) {
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

  bool _notificationSoundEnabled = true;
  bool get notificationSoundEnabled => _notificationSoundEnabled;
  set notificationSoundEnabled(bool value) {
    _notificationSoundEnabled = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('notificationSoundEnabled', value),
    );
  }

  bool _notificationVibrationEnabled = true;
  bool get notificationVibrationEnabled => _notificationVibrationEnabled;
  set notificationVibrationEnabled(bool value) {
    _notificationVibrationEnabled = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('notificationVibrationEnabled', value),
    );
  }

  bool _pushNotifications = true;
  bool get pushNotifications => _pushNotifications;
  set pushNotifications(bool value) {
    _pushNotifications = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('pushNotifications', value),
    );
  }

  bool _emailNotifications = false;
  bool get emailNotifications => _emailNotifications;
  set emailNotifications(bool value) {
    _emailNotifications = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('emailNotifications', value),
    );
  }

  bool _inAppNotifications = true;
  bool get inAppNotifications => _inAppNotifications;
  set inAppNotifications(bool value) {
    _inAppNotifications = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('inAppNotifications', value),
    );
  }

  bool _smsNotifications = false;
  bool get smsNotifications => _smsNotifications;
  set smsNotifications(bool value) {
    _smsNotifications = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('smsNotifications', value),
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

  String _role = '';
  String get role => _role;
  set role(String value) {
    _role = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('role', value),
    );
  }

  ThemeMode _themeMode = ThemeMode.system;
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

  Future<void> clearAuthCredentials() async {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('firstName');
    await prefs.remove('userName');
    await prefs.remove('phone');
    await prefs.remove('kycStatus');
    await prefs.remove('isLoggedIn');
    await prefs.remove('biometricsEnabled');
    await prefs.remove('role');
    await SecureStorageService.clearAuthData();
  }
}
