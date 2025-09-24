-- Module 1: Pass catalogue, attendees, orders, tickets, and supporting logic.

set check_function_bodies = off;
set statement_timeout = 0;
set lock_timeout = 0;

create table if not exists public.pass_products (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  name text not null,
  description text,
  amount_kobo integer not null,
  currency text not null default 'NGN',
  display_amount_usd numeric(10, 2),
  valid_start_day integer not null,
  valid_end_day integer not null,
  is_early_bird boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pass_products_valid_range check (valid_end_day >= valid_start_day)
);

create table if not exists public.attendees (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  profile_id uuid references public.profiles (id) on delete set null,
  pass_product_id uuid references public.pass_products (id),
  attendee_role public.attendee_role not null,
  full_name text not null,
  email citext not null,
  phone text,
  company text,
  status public.attendee_status not null default 'UNPAID',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_attendees_email on public.attendees (email);
create index if not exists idx_attendees_user_id on public.attendees (user_id);
create unique index if not exists idx_attendees_email_unpaid on public.attendees (email)
  where status = 'UNPAID';

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  attendee_id uuid not null references public.attendees (id) on delete cascade,
  pass_product_id uuid not null references public.pass_products (id),
  status public.order_status not null default 'pending',
  amount_kobo integer not null,
  currency text not null default 'NGN',
  paystack_request_code text unique,
  paystack_invoice_url text,
  paystack_pdf_url text,
  paystack_meta jsonb,
  paid_at timestamptz,
  expires_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_orders_attendee on public.orders (attendee_id);
create index if not exists idx_orders_status on public.orders (status);
create index if not exists idx_orders_paystack_code on public.orders (paystack_request_code);
create unique index if not exists idx_orders_pending_unique on public.orders (attendee_id)
  where status = 'pending';

create table if not exists public.tickets (
  id uuid primary key default gen_random_uuid(),
  attendee_id uuid not null references public.attendees (id) on delete cascade,
  order_id uuid not null references public.orders (id) on delete cascade,
  pass_product_id uuid not null references public.pass_products (id),
  serial_number text not null unique,
  qr_payload jsonb not null,
  qr_checksum text not null,
  valid_from timestamptz not null,
  valid_to timestamptz not null,
  ics_base64 text,
  issued_at timestamptz not null default now(),
  revoked_at timestamptz,
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists idx_tickets_attendee on public.tickets (attendee_id);
create index if not exists idx_tickets_order on public.tickets (order_id);

create sequence if not exists public.ticket_serial_seq start with 100001;

create or replace function public.generate_ticket_serial() returns text as $$
declare
  seq bigint;
begin
  select nextval('public.ticket_serial_seq') into seq;
  return lpad(seq::text, 8, '0');
end;
$$ language plpgsql;

create or replace function public.abandon_stale_orders(max_age interval default interval '24 hours')
returns integer as $$
declare
  updated_count integer;
begin
  update public.orders
  set status = 'expired', updated_at = now()
  where status = 'pending' and created_at < now() - max_age;

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$ language plpgsql;

create or replace function public.claim_attendee_records(claim_email text)
returns setof public.attendees
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  return query
    update public.attendees
    set user_id = auth.uid(), updated_at = now()
    where email = claim_email
      and (user_id is null or user_id = auth.uid())
    returning *;
end;
$$;

create or replace function public.touch_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_pass_products_updated
before update on public.pass_products
for each row execute procedure public.touch_updated_at();

create trigger trg_attendees_updated
before update on public.attendees
for each row execute procedure public.touch_updated_at();

create trigger trg_orders_updated
before update on public.orders
for each row execute procedure public.touch_updated_at();

create policy "pass_products are viewable by anyone" on public.pass_products
  for select
  using (is_active = true);

alter table public.pass_products enable row level security;

alter table public.attendees enable row level security;

alter table public.orders enable row level security;

alter table public.tickets enable row level security;

create policy "attendees visible to owner" on public.attendees
  for select
  using (
    auth.uid() is not null and (
      user_id = auth.uid() or profile_id = auth.uid()
    )
  );

create policy "orders visible to owner" on public.orders
  for select
  using (
    auth.uid() is not null and attendee_id in (
      select id from public.attendees where user_id = auth.uid()
    )
  );

create policy "tickets visible to owner" on public.tickets
  for select
  using (
    auth.uid() is not null and attendee_id in (
      select id from public.attendees where user_id = auth.uid()
    )
  );
