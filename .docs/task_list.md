# 0) Foundation (one-time setup before Module 1)

**0.1 Repo & tooling**

* [ ] Create mono-repo: `apps/web_flutter` (Flutter) + `supabase/` (SQL, Edge Functions).
* [ ] Enable Flutter Web: `flutter config --enable-web`.
* [ ] Add Flutter packages: `go_router`, `riverpod` (or `bloc`), `supabase_flutter`, `dio`, `intl`, `qr_flutter`, `flutter_web_plugins`, `url_launcher`.
* [ ] Codegen: `build_runner`, `freezed`, `json_serializable` (models).

**0.2 Hosting & domains**

* [ ] Supabase project (Postgres + storage + Edge Functions).
* [ ] Flutter Web hosting (Vercel/Netlify/Firebase Hosting) + custom domain + SSL.
* [ ] DNS for `api.afcm.app` (optional reverse proxy if you want a vanity hostname for Edge Functions).

**0.3 Secrets & environment**

* [ ] Store **server secrets only** in Supabase: `PAYSTACK_SECRET_KEY`, `RESEND_API_KEY or SMTP`, `QR_SECRET`, `TZ=Africa/Lagos`.
* [ ] Flutter uses only public keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SITE_URL`.

**0.4 Database & security**

* [ ] Apply SQL migrations for **core schema** (users, staff roles, companies, audit logs).
* [ ] Enable **RLS**; write policies (read-only for public lists; write for owners; staff gated by role).
* [ ] Seed `event_settings` (2025-09-23 → 2025-09-26, TZ `Africa/Lagos`) and `event_days` (doors open/close).
* [ ] Set up daily backups; logging; error tracking (Sentry or Supabase logs viewer).

**0.5 Flutter PWA shell**

* [ ] App manifest, icons, service worker; cache: app shell, floor-plan image, `/me/ticket` data.
* [ ] Global theme, typography, light/dark; responsive breakpoints (mobile ↔ desktop).

**Exit criteria (Foundation)**

* App boots at `https://your-domain`; Supabase connected; protected pages redirect to sign-in.

---

# Module 1 — **Registration & Pass Checkout (Paystack)**

**Backend (Supabase Edge Functions + SQL)**

* [ ] Tables: `pass_products`, `attendees`, `orders`, `tickets`, `notifications`.
* [ ] Seed **passes** (1D, 2D, 3D, 4D, 4D-EB) with NGN prices; USD kept as display.
* [ ] Function `create_order`:

  * Validates selected `badge_sku`.
  * Creates `attendees(UNPAID)` and `orders(pending)` with **amount snapshot** (kobo).
  * Calls **Paystack Payment Request** (invoice) → stores `request_code`.
  * Returns `{ order_id, message: 'Invoice sent' }`.
* [ ] Webhook `paystack_webhook` (Edge Function):

  * Verify `X-Paystack-Signature` (HMAC-SHA512).
  * `GET /paymentrequest/verify/:code` to confirm paid.
  * **Idempotent**: set `orders.status='paid'`, `attendees.status='PAID'`.
  * Issue **ticket**: generate signed QR payload; compute `valid_dates` from `pass_products` offsets + `event_days`.
  * Send confirmation email with **QR image** + **ICS attachment**.
* [ ] Cron jobs: abandon `orders(pending)` older than N hours.

**Flutter (screens & flows)**

* [ ] **Passes** page → choose **role** & **pass** (Investor/Buyer/Seller/Attendee).
* [ ] **Register** form (name, email, phone, company optional) → call `create_order`.
* [ ] **Payment instructions** screen: “Invoice sent to your email” + “Resend invoice” button (calls Paystack notify).
* [ ] **My Ticket** page: shows **QR**, pass name, valid dates, **Download ICS**, and offline availability.
* [ ] “My Profile” shows role & attendee status (UNPAID/PAID).

**Ops**

* [ ] DKIM/SPF for sender domain.
* [ ] Email templates: Payment confirmation (QR + ICS).

**Exit criteria (Module 1)**

* A new user can register, receive Paystack invoice, pay, trigger webhook, receive **QR ticket + ICS**, and view ticket offline.

---

# Module 2 — **Meeting Scheduling & Management**

**Backend**

* [ ] Tables: `rooms`, `meetings`.
* [ ] Constraint/logic: prevent **overlap** on **accepted** meetings per user.
* [ ] Edge Function APIs:

  * `directory_list`: search/filter users (role/company/interests).
  * `meeting_request`: create `meetings(pending)`.
  * `meeting_act`: recipient `{accept|decline}`; requester `{schedule}` with `{start_at, end_at, location_type, location_value}` (30-min slot).
  * `meeting_list_me`: returns inbox/sent + calendar feed.
  * All actions write to `audit_logs`.
* [ ] Cron: **reminders** at T-24h & T-2h (email; optional SMS later).
* [ ] ICS: send on accept/schedule/update/cancel.

**Flutter**

* [ ] **Directory** page: filters (role/company), profile cards, “Request meeting”.
* [ ] **Meetings** page: tabs (Inbox/Sent/Calendar).
* [ ] **Slot picker**: fixed 30-min grid within event days (09:00–18:00).
* [ ] Toasts/status badges; guard rails (cannot double-book).

**Exit criteria (Module 2)**

* User A requests B → B accepts → A schedules slot → both get ICS → reminders fire.
* No user can have two **accepted** meetings overlapping.

---

# Module 3 — **Booth Order Management (no pricing online)**

**Backend**

* [ ] Tables: `booths`, `booth_leads` (with `assignee_id`, `status workflow`, `notes`).
* [ ] Seed **43 booths** (A1–A18, B1–B9, C1–C11, D1–D2, E, F1–F2) with 3×3 default and zone.
* [ ] Edge Functions:

  * `booths_list`: filter by zone/status/size.
  * `lead_create`: create lead; email sales; write audit trail.
  * **Staff**: `booth_status_set` (status + hold expiry), `lead_update`, `booths_import_csv`, `leads_export_csv`.
* [ ] Cron: expire holds at `hold_expires_at` → set to `available`.

**Flutter**

* [ ] **Booths** page: top = **floor plan image** (zoom/pan only). Below = tabs per zone; filters; **cards** with status chips + **Call Sales** (`tel:`) + **Request details** form.
* [ ] **Staff console** (RBAC):

  * Booths table with inline status toggle & hold date picker.
  * Leads pipeline view (`new → contacted → qualified → closed`), assignee, notes, export CSV.

**Exit criteria (Module 3)**

* Public page shows 43 items with correct zone counts; leads create records + email.
* Staff can change booth statuses, set holds, and holds auto-expire.

---

# Module 4 — **Pitch Sessions (registered-only)**

**Backend**

* [ ] Tables: `pitch_sessions`, `pitch_applications`.
* [ ] Edge Functions:

  * `pitch_sessions_list` (public).
  * `pitch_apply` (requires `attendees.status='PAID'`).
  * **Staff**: `pitch_review` `{approve|decline|waitlist}`; set `{timeslot_start, timeslot_end}`; email ICS to presenter.
  * Capacity enforcement; FIFO waitlist.

**Flutter**

* [ ] **Pitch** page: list sessions (date, capacity).
* [ ] **Apply** form (title, logline, optional link).
* [ ] **My Applications** page (statuses, timeslot if approved).
* [ ] **Staff** pitch panel: approvals, slot assign, bulk email.

**Exit criteria (Module 4)**

* Only **PAID** users can apply; approvals assign times; ICS sent; waitlist respected.

---

# Cross-cutting hardening (after all modules)

**A) RBAC & RLS checks**

* [ ] Verify every mutating endpoint: public users can’t touch staff routes; staff roles honored.
* [ ] Add rate limits on auth, lead creation, meeting requests.

**B) PWA polish**

* [ ] “Update available” toast on new service worker.
* [ ] Offline fallbacks: ticket, floor plan, agenda.
* [ ] Lighthouse: PWA installable, performance budget green.

**C) Observability & ops**

* [ ] Dashboards: orders/day, webhook success rate, meetings/day, leads pipeline stats.
* [ ] Alerts on webhook failures and cron errors.

**D) QA & E2E**

* [ ] E2E scripts per module (happy paths + edge cases).
* [ ] Load smoke: 300 concurrent directory views, 30 RPS meetings, 20/min webhook bursts.

---

## Flutter app routes (suggested)

```
/passes
/register
/me/ticket
/directory
/meetings
/booths
/pitch
/staff/booths
/staff/pitch
```

Use `go_router` with guards:

* Auth guard on `/me/*`, `/meetings`, `/pitch`.
* Staff guard on `/staff/*`.

---

## Deliverables per module

* **Module 1**: Live pass sales, invoice flow, webhook, tickets (QR), ICS, offline ticket.
* **Module 2**: Directory + scheduling with 30-min slots, ICS + reminders, overlap protection.
* **Module 3**: Floor plan image + booth list, lead funnel, staff console, hold expiry.
* **Module 4**: Pitch sessions, registered-only apply, approvals & slots, ICS to presenters.

---

## Notes on Dart/Flutter specifics

* Turn on `webRenderers` (html/canvaskit) and test both; use **canvaskit** for smoother animations if bundle size is acceptable.
* For PWA icons/manifest: `flutter create .` generates defaults—edit `web/manifest.json` and `web/icons/`.
* Supabase client: `supabase_flutter` handles auth/session persist; use **Edge Functions** for all server secrets.
* Generate QR with `qr_flutter` (renders CanvasKit fast on web).
* File downloads (ICS): provide a signed URL to an Edge Function that streams the file or build ICS string on client and trigger download.

---