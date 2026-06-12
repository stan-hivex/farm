class AppConfig {
  // Your deployed Render backend URL
  static const String baseUrl = 'https://farm-backend-9b8u.onrender.com';

  static const String apiVersion = '/api/v1';
  static String get api => '$baseUrl$apiVersion';
}