#!/usr/bin/env bash

# Builds the Flutter web bundle with the env-specific Supabase configuration.
# If Flutter isn't on PATH (e.g. on Vercel build machines), we download a
# pinned SDK into the build cache so subsequent runs reuse it.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/apps/web_flutter"

for var in SUPABASE_URL SUPABASE_ANON_KEY SITE_URL; do
  if [[ -z "${!var:-}" ]]; then
    echo "\033[31mMissing required environment variable: $var\033[0m" >&2
    exit 1
  fi
done

# Trim any accidental newlines from environment values (e.g. CLI piping).
SUPABASE_URL="$(printf '%s' "$SUPABASE_URL" | tr -d '\r\n')"
SUPABASE_ANON_KEY="$(printf '%s' "$SUPABASE_ANON_KEY" | tr -d '\r\n')"
SITE_URL="$(printf '%s' "$SITE_URL" | tr -d '\r\n')"

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.3}"
  FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
  CACHE_ROOT="${VERCEL_CACHE_DIR:-$REPO_ROOT/.flutter-cache}"
  SDK_DIR="$CACHE_ROOT/flutter"

  mkdir -p "$CACHE_ROOT"
  if [[ ! -x "$SDK_DIR/bin/flutter" ]]; then
    echo "Flutter SDK not found. Downloading $FLUTTER_VERSION ($FLUTTER_CHANNEL)..."
    rm -rf "$SDK_DIR"
    curl -sSL "https://storage.googleapis.com/flutter_infra_release/releases/$FLUTTER_CHANNEL/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" \
      | tar -xJ -C "$CACHE_ROOT"
  fi

  export PATH="$SDK_DIR/bin:$PATH"
  git config --global --add safe.directory "$SDK_DIR" >/dev/null 2>&1 || true
  flutter config --enable-web >/dev/null
fi

echo "Building Flutter web bundle with assets at $APP_DIR/build/web"

cd "$APP_DIR"

flutter pub get

defines_file="$(mktemp)"
cat >"$defines_file" <<JSON
{
  "SUPABASE_URL": "$SUPABASE_URL",
  "SUPABASE_ANON_KEY": "$SUPABASE_ANON_KEY",
  "SITE_URL": "$SITE_URL"
}
JSON

flutter build web --release --dart-define-from-file="$defines_file"

rm -f "$defines_file"

echo "Done. Deployable assets available in $APP_DIR/build/web"
