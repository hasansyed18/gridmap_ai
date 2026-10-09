import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl {
    final v = dotenv.env['SUPABASE_URL'];
    assert(v != null && v.isNotEmpty, 'SUPABASE_URL missing in .env');
    return v!;
  }

  static String get supabaseAnonKey {
    final v = dotenv.env['SUPABASE_ANON_KEY'];
    assert(v != null && v.isNotEmpty, 'SUPABASE_ANON_KEY missing in .env');
    return v!;
  }
}