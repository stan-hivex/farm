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
    _walletBalance = prefs.getDouble('walletBalance') ?? 0.0;
    _kesEquivalent = prefs.getDouble('kesEquivalent') ?? 0.0;
    _profileImageUrl = prefs.getString('profileImageUrl') ?? '';
    _unreadNotificationCount = prefs.getInt('unreadNotificationCount') ?? 0;

    // Load theme mode
    final themeModeString = prefs.getString('themeMode');
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }
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
