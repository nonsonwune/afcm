# AFCM Flutter Web App

Flutter progressive web app for the AFCM event platform. Module 1 delivers pass browsing, attendee registration, and ticket retrieval.

## Prerequisites

- Flutter 3.22+
- Supabase project with Edge Functions deployed from `../../supabase`

## Running locally

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=anon-key \
  --dart-define=SITE_URL=http://localhost:3000
```

## Build for web

```bash
flutter build web \
  --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=anon-key \
  --dart-define=SITE_URL=https://app.afcm.market
```

