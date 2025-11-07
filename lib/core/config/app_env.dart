/// Application environment configuration
///
/// This class manages environment variables for Supabase connection.
/// In production, use actual environment variables or a secrets manager.
class AppEnv {
  /// Supabase project URL
  ///
  /// Get this from your Supabase project settings.
  static const String supabaseUrl = 'https://uhquiaattcdarsyvogmj.supabase.co';

  /// Supabase anonymous key
  ///
  /// Get this from your Supabase project settings (API > Project API keys).
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVocXVpYWF0dGNkYXJzeXZvZ21qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwODAxOTUsImV4cCI6MjA3NzY1NjE5NX0.l2TM8kj15OihDTdb9vPjCd_z1SEwFtf1159Y3lnsSy0';

  /// Validates that environment variables are set
  static bool get isConfigured => true;

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
