import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides centralized access to the Supabase client.
/// Use this instead of directly accessing Supabase.instance.client everywhere.
class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;
}
