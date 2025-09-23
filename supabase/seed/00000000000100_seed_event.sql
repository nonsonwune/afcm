insert into public.event_settings (id, name, start_date, end_date, timezone)
values (
  gen_random_uuid(),
  'afcm-2025',
  date '2025-09-23',
  date '2025-09-26',
  'Africa/Lagos'
)
on conflict (id) do nothing;

insert into public.event_days (event_date, open_time, close_time)
values
  (date '2025-09-23', time '09:00', time '18:00'),
  (date '2025-09-24', time '09:00', time '18:00'),
  (date '2025-09-25', time '09:00', time '18:00'),
  (date '2025-09-26', time '09:00', time '18:00')
on conflict (event_date) do update
set open_time = excluded.open_time,
    close_time = excluded.close_time;
