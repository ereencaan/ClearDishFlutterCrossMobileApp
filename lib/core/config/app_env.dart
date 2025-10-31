/// Application environment configuration
/// 
/// This class manages environment variables for Supabase connection.
/// In production, use actual environment variables or a secrets manager.
class AppEnv {
  /// Supabase project URL
  /// 
  /// Get this from your Supabase project settings.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );

  /// Supabase anonymous key
  /// 
  /// Get this from your Supabase project settings (API > Project API keys).
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  /// Validates that environment variables are set
  static bool get isConfigured =>
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';

  /// Throws if environment is not configured
  static void ensureConfigured() {
    if (!isConfigured) {
      throw Exception(
        'Supabase environment variables not configured. '
        'Please set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
  }
}

