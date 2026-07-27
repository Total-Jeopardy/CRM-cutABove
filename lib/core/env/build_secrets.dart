/// Compile-time values from `flutter build ... --dart-define=KEY=value`.
/// Use for CI/Netlify without committing secrets; empty means “not set”.
abstract final class BuildSecrets {
  BuildSecrets._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
}
