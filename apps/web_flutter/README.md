# AFCM Flutter Web App

This Flutter project powers the AFCM event progressive web application.

## Configuration

Provide runtime configuration via `--dart-define` when running locally or building:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=public-anon-key \
  --dart-define=SITE_URL=https://afcm.app \
  --dart-define=FLOOR_PLAN_ASSET=assets/images/floor_plan.svg
```

## Development

```bash
flutter pub get
flutter run -d chrome --web-renderer=auto
```

Code generation commands will be added in Module 1 once models are introduced.

## PWA Features

- Web manifest and icons located under `web/`.
- Custom service worker caches the app shell, floor plan illustration, and `/me/ticket` responses for offline ticket access.
- Floor plan placeholder asset (`floor_plan.svg`) lives under `assets/images/`.
