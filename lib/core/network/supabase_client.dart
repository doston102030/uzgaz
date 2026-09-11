import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the Supabase SDK. Call [SupabaseService.init] once
/// in `main()` before `runApp`, then reach the client anywhere via
/// [SupabaseService.client].
class SupabaseService {
  SupabaseService._();

  static Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL'];
    final publishableKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || publishableKey == null || publishableKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL / SUPABASE_ANON_KEY topilmadi. Loyiha ildizidagi '
        '.env faylini tekshiring (.env.example asosida yarating).',
      );
    }

    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  /// The initialized Supabase client. Available after [init] has run.
  static SupabaseClient get client => Supabase.instance.client;

  /// Convenience accessor for the current signed-in user, if any.
  static User? get currentUser => client.auth.currentUser;
}
