truncate table public.event_days restart identity cascade;
truncate table public.event_settings restart identity cascade;

insert into public.event_settings (id, event_name, timezone, start_date, end_date, site_url)
values (
  1,
  'African Film & Content Market 2025',
  'Africa/Lagos',
  date '2025-09-23',
  date '2025-09-26',
  'https://afcm.app'
)
on conflict (id) do update set
  event_name = excluded.event_name,
  timezone = excluded.timezone,
  start_date = excluded.start_date,
  end_date = excluded.end_date,
  site_url = excluded.site_url,
  updated_at = now();

insert into public.event_days (day_number, label, event_date, doors_open, doors_close)
values
  (1, 'Day 1', date '2025-09-23', timestamptz '2025-09-23 08:00:00+01', timestamptz '2025-09-23 19:00:00+01'),
  (2, 'Day 2', date '2025-09-24', timestamptz '2025-09-24 08:00:00+01', timestamptz '2025-09-24 19:00:00+01'),
  (3, 'Day 3', date '2025-09-25', timestamptz '2025-09-25 08:00:00+01', timestamptz '2025-09-25 19:00:00+01'),
  (4, 'Day 4', date '2025-09-26', timestamptz '2025-09-26 08:00:00+01', timestamptz '2025-09-26 18:00:00+01')
on conflict (event_date) do update set
  day_number = excluded.day_number,
  label = excluded.label,
  doors_open = excluded.doors_open,
  doors_close = excluded.doors_close,
  updated_at = now();
