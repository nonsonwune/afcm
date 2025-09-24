truncate table public.pass_products restart identity cascade;

insert into public.pass_products (
  sku,
  name,
  description,
  amount_kobo,
  currency,
  display_amount_usd,
  valid_start_day,
  valid_end_day,
  is_early_bird,
  is_active
)
values
  (
    'PASS-1D',
    '1-Day Pass',
    'Access to AFCM Day 1 programming (Investor briefings, keynotes, mixer).',
    7500000,
    'NGN',
    50,
    1,
    1,
    false,
    true
  ),
  (
    'PASS-2D',
    '2-Day Pass',
    'Access to AFCM Days 1 & 2 including deal rooms and roundtables.',
    13500000,
    'NGN',
    90,
    1,
    2,
    false,
    true
  ),
  (
    'PASS-3D',
    '3-Day Pass',
    'Access to AFCM Days 1–3 including expo hall and showcases.',
    20250000,
    'NGN',
    135,
    1,
    3,
    false,
    true
  ),
  (
    'PASS-4D',
    '4-Day All-Access',
    'All programming across the four-day AFCM schedule.',
    27000000,
    'NGN',
    180,
    1,
    4,
    false,
    true
  ),
  (
    'PASS-4D-EB',
    'Early-Bird All-Access',
    'Discounted all-access pass for early commitments.',
    24000000,
    'NGN',
    160,
    1,
    4,
    true,
    true
  )
;

