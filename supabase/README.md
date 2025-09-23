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

## Module 1: Registration Schema

`migrations/00000000000200_module1_registration.sql` expands the database with:

- `pass_products` catalog entries (validity offsets, pricing, active flag).
- `attendees`, `orders`, `tickets`, and `notifications` tables with RLS that limits access to the owning user or staff.
- Helper stored procedures: `create_attendee_order` wraps attendee + order creation, `pass_valid_dates` calculates valid date ranges from seeded event settings, and `tickets_valid_dates_check` enforces range consistency.

Seed data in `seed/00000000000200_seed_passes.sql` loads the five initial pass SKUs (1D/2D/3D/4D and Early-Bird).

## Edge Functions

Two Deno-based Supabase Edge Functions implement the Module 1 flows:

- `create-order` — Authenticated attendees call this to validate a pass SKU, sync their profile, create the attendee/order snapshot, and request a Paystack invoice (`/paymentrequest`). The function stores the generated invoice code/reference for webhook reconciliation and logs an email notification job.
- `paystack-webhook` — Processes Paystack webhook callbacks. It verifies the signature, confirms payment status via Paystack’s verify endpoint, marks the order/attendee as paid, generates a QR-backed ticket (using `QR_SECRET`), and queues a ticket notification.

To run functions locally:

```bash
supabase functions serve create-order
supabase functions serve paystack-webhook
```

Ensure the environment provides `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `PAYSTACK_SECRET_KEY`, and `QR_SECRET`.
