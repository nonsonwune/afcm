# Module 1 — Registration & Tickets

## Backend setup

1. Export the secrets defined in `supabase/.env.example` to your Supabase project secrets (`supabase secrets set ...`). For the test environment use:
   ```bash
   supabase secrets set \
     PAYSTACK_SECRET_KEY=sk_test_4bd2a491d6f8049ef0223188bf66ecd87e6c39a9 \
     PAYSTACK_PUBLIC_KEY=pk_test_2e3086f562f602b292b5b27ea534a2ddd04c91df \
     RESEND_API_KEY=... \
     QR_SECRET=choose-a-secret \
     SITE_URL=https://your-preview-domain \
     TZ=Africa/Lagos \
     EMAIL_FROM="AFCM Tickets <tickets@afcm.market>"
   ```
2. Apply migrations and seed data:
   ```bash
   supabase db reset
   ```
3. Deploy the Edge Functions:
   ```bash
   supabase functions deploy create-order --no-verify-jwt
   supabase functions deploy paystack-webhook --no-verify-jwt
   ```
4. Configure a Paystack webhook pointing to `https://<project-ref>.functions.supabase.co/paystack-webhook`.
5. Schedule the stale-order cleanup (optional but recommended):
   ```bash
   supabase db query < supabase/scripts/run_abandon_orders.sql
   ```

## Frontend

Run the Flutter web app (Chrome):
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=anon-key \
  --dart-define=SITE_URL=http://localhost:3000
```

## Smoke test

1. Browse to `/passes`, select a role, and start registration.
2. Complete the form → confirm a Paystack invoice email is generated.
3. Trigger Paystack payment (or simulate via `paystack-cli`) → confirm webhook issues a ticket and sends confirmation email/ICS.
4. Sign in with the registered email (OTP) → `/me/ticket` should show the cached QR and allow ICS download even offline.
5. Validate shared preferences were populated by reloading in offline mode.

## Follow-up

- Add automated email delivery worker to consume `notifications` table (currently send-mail is inline).
- Harden service worker caching to pin the floor plan image and ticket assets.
- Create E2E test harness to simulate Paystack webhook callbacks.
