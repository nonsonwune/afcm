-- Module 1 Admin & Observability Enhancements

set check_function_bodies = off;
set statement_timeout = 0;
set lock_timeout = 0;

-- Rename staff_members to staff_roles for clarity with Product scope.
alter table if exists public.staff_members rename to staff_roles;

-- Ensure expected columns exist on renamed table.
alter table if exists public.staff_roles
  alter column user_id type uuid using user_id::uuid,
  alter column role type public.staff_role;

create index if not exists idx_staff_roles_role on public.staff_roles (role);

-- Helper to fetch staff role quickly.
create or replace function public.is_staff(p_uid uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.staff_roles sr
    where sr.user_id = p_uid
  );
$$;

-- Convenience function returning actor role (may be null).
create or replace function public.current_staff_role()
returns public.staff_role
language sql
stable
as $$
  select role from public.staff_roles where user_id = auth.uid();
$$;

-- Generic audit helper to keep logic consistent.
create or replace function public.log_audit(
  p_action text,
  p_entity text,
  p_entity_id uuid,
  p_metadata jsonb default '{}'::jsonb
) returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  insert into public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    entity_type,
    entity_id,
    metadata
  ) values (
    auth.uid(),
    public.current_staff_role(),
    p_action,
    p_entity,
    p_entity_id,
    coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;

-- Transactional helper for attendee + order creation used by register flow.
create or replace function public.create_pending_registration(
  p_pass_product_id uuid,
  p_attendee_role public.attendee_role,
  p_full_name text,
  p_email citext,
  p_phone text default null,
  p_company text default null,
  p_currency text,
  p_amount_kobo integer,
  p_metadata jsonb default '{}'::jsonb
)
returns table(attendee_id uuid, order_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_attendee_id uuid;
  v_order_id uuid := gen_random_uuid();
begin
  select id
    into v_attendee_id
    from public.attendees
   where email = p_email
     and status = 'UNPAID'
   for update;

  if not found then
    v_attendee_id := gen_random_uuid();
    insert into public.attendees (
      id,
      pass_product_id,
      attendee_role,
      full_name,
      email,
      phone,
      company,
      status,
      metadata
    ) values (
      v_attendee_id,
      p_pass_product_id,
      p_attendee_role,
      p_full_name,
      p_email,
      nullif(p_phone, ''),
      nullif(p_company, ''),
      'UNPAID',
      jsonb_set(coalesce(p_metadata, '{}'::jsonb), '{source}', to_jsonb('web'))
    );
  else
    update public.attendees
       set pass_product_id = p_pass_product_id,
           attendee_role = p_attendee_role,
           full_name = p_full_name,
           phone = nullif(p_phone, ''),
           company = nullif(p_company, ''),
           metadata = jsonb_set(
             coalesce(metadata, '{}'::jsonb),
             '{refreshed_at}',
             to_jsonb(now())
           ),
           updated_at = now()
     where id = v_attendee_id;
  end if;

  insert into public.orders (
    id,
    attendee_id,
    pass_product_id,
    status,
    amount_kobo,
    currency,
    metadata
  ) values (
    v_order_id,
    v_attendee_id,
    p_pass_product_id,
    'pending',
    p_amount_kobo,
    p_currency,
    coalesce(p_metadata, '{}'::jsonb)
  );

  attendee_id := v_attendee_id;
  order_id := v_order_id;
  return next;
end;
$$;

-- Manual overrides for orders.
create or replace function public.mark_order_paid(
  p_order_id uuid,
  p_note text default null
) returns public.orders
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_order public.orders;
  v_attendee public.attendees;
begin
  if not public.is_staff(auth.uid()) then
    raise exception 'permission denied' using errcode = '42501';
  end if;

  update public.orders
  set
    status = 'paid',
    paid_at = coalesce(paid_at, now()),
    updated_at = now()
  where id = p_order_id
  returning * into v_order;

  if not found then
    raise exception 'order not found' using errcode = 'P0002';
  end if;

  update public.attendees
  set status = 'PAID', updated_at = now()
  where id = v_order.attendee_id
  returning * into v_attendee;

  perform public.log_audit(
    'order_marked_paid',
    'order',
    v_order.id,
    jsonb_build_object(
      'note', p_note,
      'attendee_id', v_order.attendee_id,
      'actor', auth.uid()
    )
  );

  return v_order;
end;
$$;

create or replace function public.mark_order_failed(
  p_order_id uuid,
  p_reason text default null
) returns public.orders
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_order public.orders;
begin
  if not public.is_staff(auth.uid()) then
    raise exception 'permission denied' using errcode = '42501';
  end if;

  update public.orders
  set
    status = 'cancelled',
    updated_at = now(),
    metadata = jsonb_set(metadata, '{manual_reason}', to_jsonb(coalesce(p_reason, 'manual_override')))
  where id = p_order_id
  returning * into v_order;

  if not found then
    raise exception 'order not found' using errcode = 'P0002';
  end if;

  update public.attendees
    set status = 'CANCELLED', updated_at = now()
    where id = v_order.attendee_id;

  perform public.log_audit(
    'order_marked_failed',
    'order',
    v_order.id,
    jsonb_build_object('reason', p_reason)
  );

  return v_order;
end;
$$;

-- Allow staff dashboards to query necessary tables.
create policy "attendees viewable by staff" on public.attendees
  for select using (public.is_staff(auth.uid()));

create policy "orders viewable by staff" on public.orders
  for select using (public.is_staff(auth.uid()));

create policy "tickets viewable by staff" on public.tickets
  for select using (public.is_staff(auth.uid()));

create policy "audit logs viewable by staff" on public.audit_logs
  for select using (public.is_staff(auth.uid()));

-- Staff mutations happen through security definer functions, so no direct update policy needed.

-- Storage buckets for tickets and ICS assets.
insert into storage.buckets (id, name, public)
values ('tickets', 'tickets', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('ics', 'ics', false)
on conflict (id) do nothing;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'tickets objects service access'
  ) then
    execute $$
      create policy "tickets objects service access" on storage.objects
        for insert to authenticated
        with check (
          bucket_id = 'tickets' and public.is_staff(auth.uid())
        );
    $$;
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'tickets objects staff read'
  ) then
    execute $$
      create policy "tickets objects staff read" on storage.objects
        for select to authenticated
        using (
          bucket_id = 'tickets' and public.is_staff(auth.uid())
        );
    $$;
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'ics objects service access'
  ) then
    execute $$
      create policy "ics objects service access" on storage.objects
        for insert to authenticated
        with check (
          bucket_id = 'ics' and public.is_staff(auth.uid())
        );
    $$;
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'ics objects staff read'
  ) then
    execute $$
      create policy "ics objects staff read" on storage.objects
        for select to authenticated
        using (
          bucket_id = 'ics' and public.is_staff(auth.uid())
        );
    $$;
  end if;
end;
$$;
