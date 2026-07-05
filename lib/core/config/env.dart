import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to all environment variables.
/// This ensures a single source of truth for configuration across the app.
class Env {
  static final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';

  static final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static final apiBaseUrl =
      dotenv.env['API_URL'] ?? 'https://farm-backend-9b8u.onrender.com';

  static final frontendUrl =
      dotenv.env['FRONTEND_URL'] ?? 'http://localhost:4200';

  static final appScheme = dotenv.env['APP_SCHEME'] ?? 'farm';

  static final appHost = dotenv.env['APP_HOST'] ?? 'farm.com';

  static final turnstileSiteKey = dotenv.env['TURNSTILE_SITE_KEY'] ?? '';

  static final apiVersion = '/api/v1';

  static String get api => '$apiBaseUrl$apiVersion';
}
