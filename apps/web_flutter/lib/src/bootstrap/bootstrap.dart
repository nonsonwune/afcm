import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';
import '../app_config.dart';
import '../shared/providers/app_providers.dart';

Future<void> bootstrap() async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  final config = AppConfig.fromEnvironment();

  if (!config.hasValidSupabaseConfig) {
    runApp(ConfigurationErrorApp(config: config));
    return;
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  runZonedGuarded(() {
    runApp(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const AfcmApp(),
      ),
    );
  }, (error, stackTrace) {
    log('Uncaught error', error: error, stackTrace: stackTrace);
  });
}

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFCM – Configuration Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Missing Supabase configuration.\n'
              'Ensure SUPABASE_URL and SUPABASE_ANON_KEY are supplied via --dart-define.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

