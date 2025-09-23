class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.siteUrl,
    required this.floorPlanAsset,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String siteUrl;
  final String floorPlanAsset;

  static const _defaultFloorPlan = 'assets/images/floor_plan.svg';

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      siteUrl: String.fromEnvironment('SITE_URL', defaultValue: 'https://afcm.app'),
      floorPlanAsset: String.fromEnvironment(
        'FLOOR_PLAN_ASSET',
        defaultValue: _defaultFloorPlan,
      ),
    );
  }
}
