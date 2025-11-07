import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:cleardish/core/config/app_env.dart';

/// Supabase client singleton
///
/// Initializes and provides access to the Supabase client instance.
class SupabaseClient {
  static SupabaseClient? _instance;
  static SupabaseClient get instance {
    _instance ??= SupabaseClient._();
    return _instance!;
  }

  SupabaseClient._();

  /// Initializes Supabase with environment variables
  static Future<void> initialize() async {
    AppEnv.ensureConfigured();
    await supabase.Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }

  /// Gets the Supabase client for authentication
  supabase.GoTrueClient get auth => supabase.Supabase.instance.client.auth;

  /// Gets the Supabase client instance for database operations
  supabase.Supabase get supabaseClient => supabase.Supabase.instance;
}
