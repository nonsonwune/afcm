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
   - Supabase project URL: `https://fbhpejawdjokhpaewxoo.supabase.co`
   - Supabase anon key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZiaHBlamF3ZGpva2hwYWV3eG9vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3MDc3NDIsImV4cCI6MjA3NDI4Mzc0Mn0.VHZJYNqthg108Gl9FUtk4fKYyk8RcqRktoWWVZHPOuI`

## Database connection strings (Supabase project)

- Direct connection: `postgresql://postgres:i02T8wfTKreuGxS5@db.fbhpejawdjokhpaewxoo.supabase.co:5432/postgres`
- Transaction pooler: `postgresql://postgres.fbhpejawdjokhpaewxoo:i02T8wfTKreuGxS5@aws-1-eu-north-1.pooler.supabase.com:6543/postgres`
- Session pooler: `postgresql://postgres.fbhpejawdjokhpaewxoo:i02T8wfTKreuGxS5@aws-1-eu-north-1.pooler.supabase.com:5432/postgres`
