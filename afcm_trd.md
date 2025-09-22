# AFCM Website (Event PWA) — Technical Requirements Document (TRD) — Simplified MVP

**Purpose.** Define a buildable, testable scope for the AFCM event website/PWA that delivers:

1. Attendee registration & pass checkout, 2) Meeting scheduling, 3) Booth order management (no public pricing), 4) Pitch-session registration (registered-only), with role-based access control (RBAC) and a simple floor plan **image** (no hotspots).

**Event facts reflected in UI/content**

* **Booths:** 43 total → **A=18**, **B=9**, **C=11**, **D=2**, **E=1 (feature area)**, **F=2**.
* **Floor plan usage:** Display as a static image (zoomable). Management occurs via lists/forms, not on the image.

---

## 1) Scope & Non-Goals

### In Scope (MVP)

* **Passes & Registration:** 1-Day, 2-Day, 3-Day, 4-Day (All-Access) + **Early-Bird (4-Day)**; payment; ticket QR; confirmation email with ICS.
* **Meetings:** User directory; request/accept; 30-min slots; conflict prevention; reminders; ICS.
* **Booth Management:** Public page shows floor plan **image** + booth directory/cards; status badges; “Call Sales” + lead form; staff pipeline & status toggles.
* **Pitch Sessions:** Registered-only applications; staff approve/slot; ICS to presenters.
* **PWA:** Installable; offline for **My Ticket (QR)**, **Agenda**, **Floor Plan image**.

### Non-Goals (MVP)

* No guarded streaming/DRM/catalog/rights.
* No two-way calendar sync (ICS only).
* No interactive image hotspots.
* No public booth pricing or online checkout for booths.

---

## 2) Stakeholders & Roles

### Public roles

* **Investor, Buyer, Seller, Attendee** — register/buy passes; directory; meetings; pitch apply (if registered).

### Staff sub-roles (RBAC)

* **Operator** — triage leads, update booth status, manage meeting/pitch queues.
* **Supervisor** — Operator permissions + manage slot grids/capacity; put holds on booths.
* **Admin** — All permissions + user role assignment, pass products/pricing, refunds, site settings.

**RBAC enforcement:** Server-side middleware + UI guards. All staff mutations are **audited**.

---

## 3) User Journeys (Happy Paths)

### A) Registration & Checkout

1. User selects pass → fills form (name, email, phone) → record stored as **UNPAID**.
2. System creates **Order (pending)** with price snapshot (kobo).
3. **Payment link** generated (prefer **Paystack Payment Request**; alternative: `transaction/initialize`).
4. On successful webhook verification, mark **PAID**, issue **Ticket & QR**, email confirmation + ICS.

**Initial pass products (seed):**

* 1-Day NGN **75,000** / USD **50**
* 2-Day NGN **135,000** / USD **90**
* 3-Day NGN **202,500** / USD **135**
* 4-Day NGN **270,000** / USD **180**
* **Early-Bird 4-Day** NGN **240,000** / USD **160**

> Charge currency = **NGN** (kobo). USD shown for display; Admin may set reference FX.

### Event schedule & doors (TZ = Africa/Lagos)

| Day | Date (2025) | Doors open | Doors close | Primary programming |
| --- | --- | --- | --- | --- |
| Day 1 | Tue **Sept 23** | 08:00 | 19:00 | Investor briefings, opening keynotes, evening welcome mixer |
| Day 2 | Wed **Sept 24** | 08:00 | 19:00 | Deal rooms, curated buyer-seller meetings, private roundtables |
| Day 3 | Thu **Sept 25** | 08:00 | 19:00 | Expo hall + booths showcase, ecosystem panels, product launches |
| Day 4 | Fri **Sept 26** | 08:00 | 18:00 | Pitch finals, awards, closing reception |

Event runtime is therefore **23–26 September 2025** (inclusive). All scheduling, ticket validity and ICS generation must use the `Africa/Lagos` timezone.

### B) Meetings

1. Directory filter (role/company/interests/availability).
2. Requester sends meeting request (optionally with proposed windows).
3. Recipient Accepts/Declines; acceptance locks the meeting as **accepted** but unscheduled.
4. After acceptance, the **requester** selects the confirmed **30-min** slot & location (room/meetpoint/virtual).
5. ICS goes out when the slot is set; reminders at **T-24h** & **T-2h**; strict no overlap for **accepted** meetings.

### C) Booths (no price online)

1. Page top: **Floor Plan image** (zoomable).
2. Below: tabs by zone (A/B/C/D/F; E is info-only) + filter by status/size.
3. Each booth card: **code**, **size** (default 3×3 m unless specified), **status** (`available/hold/allocated/hidden`), CTAs: **Call Sales** (tel:) and **Request Details** (lead form).
4. Staff console: update statuses, set **hold expiry**, manage leads pipeline (`new → contacted → qualified → closed`), add internal notes surfaced on the lead detail pane and CSV export.

### D) Pitch Sessions (registered-only)

1. Must hold a valid **PAID** ticket.
2. Apply (title, logline, link optional).
3. Staff approve/decline; assign time; ICS to presenter; capacity with simple waitlist.

---

## 4) Information Architecture

**Public:** Home, Passes, Register, My Ticket, Directory, Meetings, Booths, Pitch, Agenda, Floor Plan, Venue/FAQ/Contact.
**Authenticated:** Dashboard (ticket/meetings), My Meetings, My Pitch Applications.
**Staff Console:** Booths & Leads, Meetings & Rooms, Pitch Sessions, Orders & Refunds, Users & Roles, Settings, Exports, Audit.

---

## 5) Data Model (Relational)

### Core tables

* **users**: `id, email (unique), name, phone, role (investor|buyer|seller|attendee|staff), company_id?, verified_at, created_at`
* **staff\_roles**: `user_id (PK→users.id), staff_role (operator|supervisor|admin)`
* **companies**: `id, name, kind, bio, website`

### Passes & orders

* **event\_settings** (singleton row): `id=1, event_start_date date, event_end_date date, timezone text`
* **event\_days**: `id, day_offset smallint (0-based), event_date date, label, doors_open_at time, doors_close_at time`
* **pass\_products**: `id, sku (unique), name, days (1|2|3|4), price_kobo, price_usd_cents, is_early_bird bool, active bool, valid_from_offset smallint, valid_through_offset smallint`
  * Seed mapping (relative to **Day 1 = 23 Sept 2025**):
    * `PASS-1D` → offsets `0…0` (Tue 23 Sept only).
    * `PASS-2D` → offsets `0…1` (Tue 23 – Wed 24 Sept).
    * `PASS-3D` → offsets `0…2` (Tue 23 – Thu 25 Sept).
    * `PASS-4D` and `PASS-4D-EB` → offsets `0…3` (Tue 23 – Fri 26 Sept).
* **attendees**: `id, user_id, badge_sku, status (UNPAID|PAID|REFUNDED), created_at`
* **orders**: `id, attendee_id, badge_sku, currency (NGN|USD), amount bigint, paystack_reference?, paystack_invoice_code?, status (pending|paid|failed|refunded), created_at`
* **tickets**: `id, attendee_id (unique), valid_dates daterange, qr_payload text, issued_at`

`event_days` is seeded from the schedule in §3. Each pass SKU stores its deterministic inclusive range through the offset fields; there is no implicit “any day” logic. During ticket issuance, the system resolves the offsets into calendar dates using the singleton event setting (`event_start_date = 2025-09-23`, `event_end_date = 2025-09-26`, `timezone = 'Africa/Lagos'`) and stores the resulting contiguous `valid_dates` range on the ticket. ICS attachments for orders and passes must read `tickets.valid_dates` so regenerated ICS files always match the same date span irrespective of when or where they are produced.

### Meetings

* **rooms**: `id, name, capacity, active`
* **meetings**: `id, requester_id, recipient_id, status (pending|accepted|declined|cancelled), start_at, end_at, location_type (room|meetpoint|virtual), location_value, notes, created_at`

  * **Indexes:** `(recipient_id, start_at)`, `(requester_id, start_at)`

### Booths & leads

* **booths**: `booth_code (PK), zone, width_m, depth_m, area_m2, status (available|hold|allocated|hidden) default 'available', hold_expires_at?, features jsonb, allocated_to_company_id?, notes`
* **booth\_leads**: `id, booth_code, name, company, email, phone, message, status (new|contacted|qualified|closed) default 'new', assignee_id?, notes text, created_at, updated_at`

### Pitch

* **pitch\_sessions**: `id, name, date, capacity, open_from, open_to`
* **pitch\_applications**: `id, user_id, session_id, title, logline, link, status (submitted|approved|waitlist|declined) default 'submitted', timeslot_start, timeslot_end, created_at`

### Notifications & audit

* **notifications**: `id, user_id, kind, payload jsonb, sent_at`
* **audit\_logs**: `id, actor_id, action, object_type, object_id, diff jsonb, created_at`

**Constraints & policies**

* Unique email per user.
* One **ticket** per attendee.
* Meeting overlap prevention (accepted): exclusion constraint or application-level lock.
* RLS/ACL: public read on published lists; write restricted to owners/staff; staff role gates mutations.

---

## 6) APIs (Contract)

> All responses JSON unless stated. Auth via session/JWT. Staff routes require `staff_roles`.

### Auth & profile

* `POST /auth/register` — {name, email, phone, role, password? or OTP}
* `POST /auth/login`
* `GET /me` — user, attendee status, roles
* `GET /me/ticket` — QR payload, valid dates, ICS link

### Passes & orders

* `GET /passes` — list active pass products
* `POST /orders` — {badge\_sku, currency?} → returns `{order_id, amount_kobo, strategy: "payment_request", message: "Invoice sent"}`
* `POST /webhooks/paystack` — signature-verified; verifies invoice/transaction; idempotently marks order paid; issues ticket; returns 200

### Directory & meetings

* `GET /directory?role=&q=&available=` — public profiles
* `POST /meetings` — {recipient\_id, proposed\_windows?} → creates pending
* `PATCH /meetings/:id` — recipient Accept/Decline/Cancel via `{action: "accept"|"decline"|"cancel"}`; once accepted, requester schedules with `{action: "schedule", start_at, end_at, location_type, location_value}` (30-min window, required on schedule)
* `GET /me/meetings`

### Booths & leads

* `GET /booths?zone=&status=&size=` — list public
* `GET /booths/:code` — details for card modal
* `POST /booth-leads` — {booth\_code, name, company, email, phone, message}

**Staff**

* `PATCH /staff/booths/:code/status` — {status, hold\_expires\_at?}
* `POST /staff/booths/import` — CSV upload
* `PATCH /staff/booth-leads/:id` — {status, assignee\_id?, notes?}
* `GET /staff/exports/booth-leads.csv`
* `GET /staff/meetings` (grid)
* `PATCH /staff/pitch-applications/:id` — {status, timeslot\_start?, timeslot\_end?}

**Error codes**

* `400` validation, `401/403` auth/RBAC, `404` not found, `409` conflict (meeting overlap, double-spend), `422` invalid state.

---

## 7) Payments (Paystack)

**Preferred:** **Payment Request** (invoice). Paystack sends the email and link.
**Webhook verification:**

* Validate `X-Paystack-Signature` (HMAC-SHA512 over raw body with `SECRET_KEY`).
* Then call `GET /paymentrequest/verify/{code}` (or `GET /transaction/verify/{reference}` for the alternate flow).
* If paid and **not previously processed**, set order/attendee paid, issue ticket, send confirmation.

**Idempotency**

* Store a `processed_at` on orders; ignore duplicate webhooks.
* Use database transactions to guarantee one ticket per attendee.

---

## 8) Tickets, QR & ICS

**QR payload (compact)**

```
AFCM1.<base64url(hmac_sha256(payload, QR_SECRET))>.<base64url(json)>
json = { t:"TKT", tid:"<ticket_id>", aid:"<attendee_id>", sku:"PASS-4D", exp:<unix_epoch> }
```

* Validate signature at scan; confirm `exp` not passed; fetch attendee/ticket.

**ICS**

* UID: `ticket_id@afcm.app`
* DTSTART/DTEND per pass days; TZID **Africa/Lagos**; SUMMARY “AFCM Access – <Pass Name>”.

---

## 9) PWA & Frontend

* Installable manifest; service worker caches **App Shell**, **Floor Plan image (WebP + PNG fallback)**, `/me/ticket`, `/booths`.
* Offline behavior: show My Ticket (QR), cached floor plan, cached agenda.
* Performance target: First load **P95 ≤ 3 s** (3G-fast).
* Accessibility: alt text for images; focus states; keyboard navigable forms; color-contrast AA.

---

## 10) Emails & Notifications

**System-sent**

* Payment link (if using `transaction/initialize`) *or* rely on Paystack invoice email.
* Payment confirmation with QR + ICS.
* Meeting: accept/update/cancel; reminders **T-24h** & **T-2h**.
* Pitch: submission received; approved (with slot + ICS); declined.

**Deliverability**

* Verified sender domain, DKIM/SPF.
* Suppression list & retry policy.

---

## 11) Security & Compliance

* TLS everywhere; strong password KDF (if using passwords); session CSRF protection.
* RBAC on all mutating endpoints; **rate limits** on auth/lead creation.
* PII minimization; NDPR/GDPR-style data export/delete by Admin on request.
* Webhook secrets stored server-side; never exposed client-side.
* Audit log for staff actions (who/what/when/diff).

---

## 12) Observability & Ops

* Structured logs with request ID; error tracking.
* Health checks for DB and webhook handler.
* Scheduled jobs:

  * Meeting reminders (24h, 2h)
  * Expire booth holds → set status `available`
  * Abandoned pending orders cleanup
* Dashboards: orders/day, active users, meetings volume, lead pipeline, webhook success rate.

---

## 13) Acceptance Criteria (by feature)

**Registration & Checkout**

* ≥95% paid orders reflected via webhook **<60 s** after payment.
* Ticket & QR issued on first verified payment; never duplicated.
* ICS attaches; My Ticket available offline.

**Meetings**

* Users can request/accept/decline; accepted meetings cannot overlap for a user.
* ICS and reminders delivered correctly.

**Booths**

* Public list shows **43** booths with correct zone counts.
* Status changes reflect publicly **<10 s** after staff update.
* Holds expire automatically; leads captured with booth\_code and visible in staff console.

**Pitch**

* Only **PAID** users can apply; approvals assign timeslot; ICS sent; capacity respected with waitlist.

**PWA**

* Installable; offline ticket & floor plan; performance target met.

---

## 14) Test Plan

**Unit**

* Order state machine; webhook signature; QR sign/verify; meeting overlap check; RBAC guards.

**Integration**

* Paystack verify (success/fail/refund); ICS generation; email send; cron jobs.

**E2E (staging)**

* Register → invoice → webhook → ticket QR;
* Directory → request → accept → slot → ICS;
* Booth lead submission & staff status change;
* Pitch submission → approval → timeslot → ICS.

**Load (light)**

* 300 concurrent directory views; 30 RPS on meetings endpoints; webhook burst 20/min.

---

## 15) Deployment & Config

**Environment variables**

```
PAYSTACK_SECRET_KEY
QR_SECRET
EMAIL_PROVIDER_KEY / SMTP_URL
SITE_URL
TZ=Africa/Lagos
```

**Build/Release**

* Single web app + DB; blue/green deploy recommended.
* Migrations for schema; seed scripts for `pass_products`, `booths`.
* Backups: daily DB snapshot during event week.

---

## 16) Risks & Mitigations

* **Webhook misses** → retry handling + manual reconcile view; verify endpoint health.
* **Meeting spam** → per-day limits; blocklist; rate limit.
* **Lead flood** → assignment & SLA fields; CSV export for call team.
* **Cache staleness** → versioned assets; “Update available” toast for PWA.
* **Timezone mishaps** → force TZ **Africa/Lagos** in UI and ICS.

---

## 17) Delivery Plan (4 stages)

1. **Registration & Checkout** → passes, orders, Paystack invoice flow, webhook, ticket/QR, ICS, PWA cache.
2. **Meetings** → directory, request/accept, slot grid, reminders.
3. **Booths** → image + list, leads, staff console, holds, exports.
4. **Pitch** → sessions, applications, approvals/timeslots, ICS.

---

### Seed Data Requirements (for import)

* **Passes:** 5 rows (1D, 2D, 3D, 4D, 4D-EarlyBird) with amounts above.
* **Booths:** 43 rows with `booth_code, zone, size (default 3×3)`.
* **Rooms (optional):** named rooms for slot locations.
* **Pitch sessions (optional):** names, dates, capacity.

---