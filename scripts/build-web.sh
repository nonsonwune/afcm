#!/usr/bin/env bash

# Builds the Flutter web bundle with the env-specific Supabase configuration.
# Requires Flutter 3.22+ to be available on PATH.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/apps/web_flutter"

for var in SUPABASE_URL SUPABASE_ANON_KEY SITE_URL; do
  if [[ -z "${!var:-}" ]]; then
    echo "\033[31mMissing required environment variable: $var\033[0m" >&2
    exit 1
  fi
done

echo "Building Flutter web bundle with assets at $APP_DIR/build/web"

cd "$APP_DIR"

flutter pub get
flutter build web \
  --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=SITE_URL="$SITE_URL"

echo "Done. Deployable assets available in $APP_DIR/build/web"
