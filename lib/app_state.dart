import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _biometricsEnabled = prefs.getBool('biometricsEnabled') ?? false;
    _role = prefs.getString('role') ?? '';
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

  // Backwards-compatible alias expected elsewhere
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

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  set isLoggedIn(bool value) {
    _isLoggedIn = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('isLoggedIn', value),
    );
  }

  /// BIOMETRICS
  bool _biometricsEnabled = false;
  bool get biometricsEnabled => _biometricsEnabled;

  set biometricsEnabled(bool value) {
    _biometricsEnabled = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('biometricsEnabled', value),
    );
  }

  // Role (persisted)
  String _role = '';
  String get role => _role;
  set role(String value) {
    _role = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('role', value),
    );
  }
} 