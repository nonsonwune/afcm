import 'package:flutter/foundation.dart';

@immutable
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.siteUrl,
    required this.releaseStage,
  });

  factory AppConfig.fromEnvironment() {
    final supabaseUrl = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    final supabaseAnonKey = const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    final siteUrl = const String.fromEnvironment(
      'SITE_URL',
      defaultValue: '',
    );
    final releaseStage = const String.fromEnvironment(
      'RELEASE_STAGE',
      defaultValue: 'local',
    );

    return AppConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      siteUrl: siteUrl,
      releaseStage: releaseStage,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String siteUrl;
  final String releaseStage;

  bool get hasValidSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
