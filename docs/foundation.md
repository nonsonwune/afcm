# Foundation Implementation Notes

This document tracks the one-time foundation setup before Module 1 and captures operational details for the AFCM event platform.

## Repository & Tooling

- Monorepo layout with `apps/web_flutter` for the Flutter PWA and `supabase/` for database migrations and Edge Functions.
- Flutter web must be enabled locally with `flutter config --enable-web`.
- Required Flutter packages are declared in `pubspec.yaml`. Run `flutter pub get` after cloning.
- Code generation relies on `build_runner`, `freezed`, and `json_serializable`.

## Hosting & Domains

- Provision a Supabase project that provides Postgres, authentication, storage, and Edge Functions.
- Deploy the Flutter web build to a static host such as Vercel, Netlify, or Firebase Hosting.
- Configure DNS for the primary web app and (optionally) `api.afcm.app` as a reverse-proxy hostname for Supabase Edge Functions.

## Secrets & Environment Management

- Server-only secrets live in Supabase configuration (`PAYSTACK_SECRET_KEY`, `RESEND_API_KEY` or SMTP credentials, `QR_SECRET`, `TZ=Africa/Lagos`).
- The Flutter web client stores only public keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SITE_URL`.
- Environment samples are provided at `apps/web_flutter/.env.sample` and `supabase/.env.example`.

## Database & Security

- Core schema migrations for users, staff roles, companies, audit logs, event settings, and event days are located in `supabase/migrations`.
- Row Level Security (RLS) is enabled for all tables with baseline policies:
  - Public read access for published directory data.
  - Authenticated users can update their own records.
  - Staff operations are gated by `staff_roles`.
- Seed data establishes event dates (2025-09-23 → 2025-09-26 in `Africa/Lagos`) and door open/close windows.
- Supabase backups should run daily during the event, and logging/error tracking should be enabled (e.g., Sentry integration).


### Module 1 Registration Schema (In Progress)

- `migrations/00000000000200_module1_registration.sql` introduces `pass_products`, `attendees`, `orders`, `tickets`, and `notifications` along with supporting stored procedures (`create_attendee_order`, `pass_valid_dates`) and range consistency triggers.
- Seeds (`seed/00000000000200_seed_passes.sql`) load the five initial passes with pricing snapshots and validity offsets relative to the seeded event dates.
- Edge Functions:
  - `create-order` validates a selected pass SKU, synchronises the caller’s profile, creates the attendee/order, and issues a Paystack Payment Request invoice.
  - `paystack-webhook` validates HMAC signatures, verifies invoices with Paystack, marks orders as paid, generates QR tickets (using the documented payload structure), and queues ticket notification jobs.
- Environment expectations for Module 1 server flows now include `SUPABASE_SERVICE_ROLE_KEY`, `PAYSTACK_SECRET_KEY`, and `QR_SECRET` (see `supabase/.env.example`).


## Flutter PWA Shell

- The Flutter application defines a global light/dark theme and responsive layout breakpoints.
- PWA assets are stored under `apps/web_flutter/web`, including the web manifest, icons, and a custom service worker that caches the app shell, floor plan image, and `/me/ticket` API response for offline availability.
- The floor plan placeholder asset (`floor_plan.svg`) lives in `apps/web_flutter/assets/images/`.
- Service worker registration occurs automatically via `web/index.html` and precaches core routes.

## Exit Criteria

- The app serves a placeholder UI at build time and redirects unauthenticated users away from protected routes.
- Supabase connectivity is handled by `lib/src/bootstrap.dart` and will surface configuration issues early during runtime.
