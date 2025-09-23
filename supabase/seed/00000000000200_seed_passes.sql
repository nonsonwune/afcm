insert into public.pass_products (
  sku,
  name,
  description,
  valid_from_offset_days,
  valid_day_count,
  price_kobo,
  price_usd_cents,
  is_early_bird
) values
  (
    'PASS-1D',
    '1-Day Pass',
    'Single-day access to all general programming.',
    0,
    1,
    7500000,
    5000,
    false
  ),
  (
    'PASS-2D',
    '2-Day Pass',
    'Attend any two consecutive event days.',
    0,
    2,
    13500000,
    9000,
    false
  ),
  (
    'PASS-3D',
    '3-Day Pass',
    'Extended access for deeper networking.',
    0,
    3,
    20250000,
    13500,
    false
  ),
  (
    'PASS-4D',
    '4-Day All-Access',
    'Full access to the conference experience.',
    0,
    4,
    27000000,
    18000,
    false
  ),
  (
    'PASS-4D-EB',
    'Early-Bird 4-Day',
    'Discounted full event access for early supporters.',
    0,
    4,
    24000000,
    16000,
    true
  )
on conflict (sku) do update
set
  name = excluded.name,
  description = excluded.description,
  valid_from_offset_days = excluded.valid_from_offset_days,
  valid_day_count = excluded.valid_day_count,
  price_kobo = excluded.price_kobo,
  price_usd_cents = excluded.price_usd_cents,
  is_early_bird = excluded.is_early_bird,
  updated_at = timezone('utc'::text, now());
