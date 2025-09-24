-- Core schema objects shared across modules.

set check_function_bodies = off;
set statement_timeout = 0;
set lock_timeout = 0;

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";
create extension if not exists "citext";

create type public.staff_role as enum ('operator', 'supervisor', 'admin');
create type public.attendee_role as enum ('investor', 'buyer', 'seller', 'attendee');
create type public.order_status as enum ('pending', 'paid', 'cancelled', 'expired');
create type public.attendee_status as enum ('UNPAID', 'PAID', 'CANCELLED');

create table if not exists public.event_settings (
  id smallint primary key default 1,
  event_name text not null,
  timezone text not null default 'Africa/Lagos',
  start_date date not null,
  end_date date not null,
  site_url text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.event_days (
  id bigserial primary key,
  day_number integer not null,
  label text not null,
  event_date date not null unique,
  doors_open timestamptz not null,
  doors_close timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint event_days_doors check (doors_close > doors_open)
);

create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  display_name text,
  slug text unique,
  website text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email citext not null unique,
  full_name text,
  phone text,
  attendee_role public.attendee_role,
  company_id uuid references public.companies (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff_members (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role public.staff_role not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigserial primary key,
  actor_user_id uuid references auth.users (id),
  actor_role public.staff_role,
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_email citext not null,
  subject text not null,
  body_html text,
  body_text text,
  status text not null default 'pending',
  send_after timestamptz,
  sent_at timestamptz,
  error text,
  metadata jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_notifications_status on public.notifications (status, send_after);

enable row level security on public.notifications;
