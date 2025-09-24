# Foundation Setup

1. Install Flutter 3.22+, Supabase CLI, and Node 18+.
2. Create a Supabase project and store the secrets listed in `supabase/.env.example` as project secrets.
3. Link the local project with `supabase link` and run migrations/seeds:
   ```bash
   supabase db reset
   ```
4. Deploy the Edge Functions for Module 1:
   ```bash
   supabase functions deploy create-order --no-verify-jwt
   supabase functions deploy paystack-webhook --no-verify-jwt
   ```
5. For Flutter, copy `.env.sample` to `.env` (optional) or pass `--dart-define` values when running/building.

