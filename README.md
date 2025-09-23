# AFCM Event Platform Monorepo

This repository hosts the AFCM event progressive web application and Supabase backend.

## Structure

- `apps/web_flutter/` – Flutter web application (PWA) for attendees, staff, and public visitors.
- `supabase/` – SQL migrations, seeds, and Edge Function source code.
- `docs/` – Architecture and operational documentation.

## Getting Started

1. Install Flutter (3.19 or later) and enable web support:
   ```bash
   flutter config --enable-web
   ```
2. Install the [Supabase CLI](https://supabase.com/docs/guides/cli).
3. Copy environment examples and configure secrets:
   ```bash
   cp apps/web_flutter/.env.sample apps/web_flutter/.env
   cp supabase/.env.example supabase/.env
   ```
4. Fetch Flutter dependencies:
   ```bash
   flutter pub get
   ```
5. Run the Flutter web dev server:
   ```bash
   flutter run -d chrome --target=lib/main.dart
   ```
6. Start Supabase locally:
   ```bash
   supabase start
   supabase db reset
   ```

See [`docs/foundation.md`](docs/foundation.md) for detailed module planning.
