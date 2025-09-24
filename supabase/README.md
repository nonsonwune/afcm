# Supabase Backend

This directory contains migrations, seed data, and Edge Functions backing the AFCM event platform. Module 1 covers attendee registration, Paystack invoice creation, payment webhooks, and ticket issuance.

## Structure

- `migrations/` — SQL schema definitions applied in order.
- `seed/` — Deterministic seed data (event settings, pass catalogue).
- `functions/` — Edge Functions deployed via `supabase functions deploy`.
- `scripts/` — Helper scripts for local development (e.g. cron jobs).

## Local Development

```bash
supabase start
cp .env.example .env
supabase link --project-ref your-project-ref
supabase db reset
supabase functions serve create-order --env-file ../.env
supabase functions serve paystack-webhook --env-file ../.env
```

Deploy functions with:

```bash
supabase functions deploy create-order --project-ref your-project-ref --no-verify-jwt
supabase functions deploy paystack-webhook --project-ref your-project-ref --no-verify-jwt
```

Both functions expect the environment variables defined in `.env.example` to be provided at runtime (preferably stored in Supabase secrets).

