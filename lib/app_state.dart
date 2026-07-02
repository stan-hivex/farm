import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_theme.dart';

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
  }

  String get authToken => _accessToken;

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
  }
}
