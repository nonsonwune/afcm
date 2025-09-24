# AFCM Event Platform

This monorepo hosts the Flutter web app and Supabase backend for the African Film & Content Market (AFCM) event platform. Module 1 implements attendee registration, pass checkout via Paystack invoices, and QR ticket issuance.

## Structure

- `apps/web_flutter` — Flutter PWA for attendees and staff.
- `supabase` — SQL migrations, seed data, and Edge Functions for server logic.
- `.docs` — Project documentation, technical requirements, and task lists.

## Getting Started

1. Ensure Flutter and Supabase CLI are installed locally.
2. Copy the provided environment samples and fill in secrets.
3. Run database migrations and seeds via Supabase CLI.
4. Launch the Flutter web app with `flutter run -d chrome` or build for release.

See `docs/module1_registration.md` for module-specific setup and smoke test steps.

See `docs/foundation.md` (to be expanded) for detailed environment setup instructions.
