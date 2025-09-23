# Supabase Backend

This directory contains database migrations, seed data, and configuration guidance for the AFCM event platform.

## Structure

- `migrations/` – SQL migrations executed in chronological order.
- `seed/` – Seed scripts applied after migrations.
- `.env.example` – Sample environment values for local development.

## Applying Migrations Locally

```bash
supabase start
supabase db reset
```

The reset command runs all migrations and seeds. Connect to the generated Postgres instance with any SQL client to inspect the schema.

## Core Schema

The foundation migration introduces:

- `companies` and `users` tables for public profiles and attendee records.
- `staff_roles` to manage RBAC tiers (`operator`, `supervisor`, `admin`).
- `audit_logs` for tracked staff actions.
- `event_settings` and `event_days` to anchor scheduling and ticket validity windows.

All tables have Row Level Security enabled with baseline policies. See `migrations/00000000000100_core_schema.sql` for details.
