import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

Future<void> bootstrap() async {
  final config = AppConfig.fromEnvironment();

  if (config.supabaseUrl.isEmpty || config.supabaseAnonKey.isEmpty) {
    throw StateError(
      'Supabase configuration is missing. Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
    );
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
    debug: !kReleaseMode,
  );
}
