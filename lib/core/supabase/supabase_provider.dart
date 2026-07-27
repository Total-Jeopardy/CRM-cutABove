import 'package:supabase_flutter/supabase_flutter.dart';

/// Throws with a clear message if accessed before [Supabase.initialize] completes.
SupabaseClient get supabaseClient {
  if (!Supabase.instance.isInitialized) {
    throw StateError(
      'Supabase is not initialized. '
      'Ensure Supabase.initialize() has completed before '
      'accessing supabaseClient.',
    );
  }
  return Supabase.instance.client;
}

bool get isSupabaseInitialized => Supabase.instance.isInitialized;
