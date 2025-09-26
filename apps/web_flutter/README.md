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
  --dart-define=SITE_URL=https://afcm.app
```

## Deploying to Vercel (prebuilt)

When the Flutter bundle is ready, ship it to Vercel as a static site:

```bash
export SUPABASE_URL=https://fbhpejawdjokhpaewxoo.supabase.co
export SUPABASE_ANON_KEY=anon-key
export SITE_URL=https://afcm.app # or your custom domain

scripts/build-web.sh
vercel deploy --prebuilt --prod
```

The repo includes `vercel.json`, which points the deployment at `apps/web_flutter/build/web` and rewrites deep links back to `index.html`. Configure the same env vars inside the Vercel dashboard for Preview/Production.
