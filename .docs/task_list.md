# EPIC 0 — Foundation / Project Skeleton (finish before Stage 1)

**Repo & tooling**

* [ ] Init mono-repo or single app; set Node/PNPM versions; Prettier/ESLint/TypeScript strict.
* [ ] Add `.env.example` with all keys (see ENV list below) and a safe `docker-compose` for local DB.
* [ ] Configure CI (build, lint, typecheck).

**App shell & PWA**

* [ ] Create Next app shell, base layout, auth gates, error boundary.
* [ ] Manifest + service worker; cache app shell + `/booths` + `/me/ticket`.

**Design system**

* [ ] Tailwind + shadcn/ui base theme; typography, buttons, inputs, badges, tabs, tables, dialogs, toast.

**RBAC & Auth**

* [ ] Supabase Auth (email OTP or password) + server session.
* [ ] `users`, `companies`, `staff_roles` tables + seed admin.
* [ ] RLS policies: public read where needed, user-owns-their-stuff, staff write access.

**Observability & Ops**

* [ ] Structured logger (request id), error tracking hook, health check route.
* [ ] “Ops Dashboard” page (protected) to show pings, queue/counters.

**ENV (populate in Vercel/Supabase & local)**

```
PAYSTACK_SECRET_KEY=
QR_SECRET=
RESEND_API_KEY=  # or SMTP_URL/USER/PASS
SITE_URL=https://<your-domain>
TZ=Africa/Lagos
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE=
```

**Content**

* [ ] Upload floor plan (WebP + PNG fallback) with alt text.
* [ ] Static pages: Home, Agenda, Venue/FAQ/Contact.

**Definition of Done (Epic 0)**

* App deploys; PWA installs; sign-in works; RBAC gates pages; floor plan renders.

---

# EPIC 1 — Registration & Pass Checkout (PASS)

### DB & server

* [ ] Tables: `pass_products`, `attendees`, `orders`, `tickets`.
* [ ] Seed `pass_products` (1D,2D,3D,4D, Early-Bird 4D).
* [ ] Snapshot pricing logic (amount in **kobo**) at order creation.
* [ ] Webhook route `/api/webhooks/paystack` with HMAC-SHA512 verify (raw body).
* [ ] Verify invoice/transaction via Paystack API; idempotent state machine (`pending → paid`).
* [ ] QR generator (HMAC-signed compact payload) + `tickets` insert.
* [ ] ICS generator for access dates (TZID Africa/Lagos).

### API

* [ ] `GET /passes`
* [ ] `POST /orders` → creates attendee (UNPAID) + order (pending) + **Payment Request** (invoice) → returns “invoice sent”
* [ ] `GET /me/ticket` → returns QR payload + ICS link

### UI

* [ ] `/passes` (grid) → `/register` form (name, email, phone, role, pass selection).
* [ ] Post-submit screen: “Invoice sent” + resend link if needed.
* [ ] Confirmation page + email with QR + ICS when webhook confirms.
* [ ] `/me/ticket` page is offline-ready (cached).

### Email

* [ ] Confirmation w/ QR + “Add to Calendar” ICS.
* [ ] (Optional) If you use `transaction/initialize`: your own “Complete payment” email template.

### QA & Ops

* [ ] Duplicate webhook safe; one ticket per attendee guaranteed.
* [ ] Abandoned orders cleanup cron.
* [ ] Refund admin flow (manual) → sets states and sends receipt.

**DoD (Epic 1)**

* ✅ ≥95% of paid invoices reflect in app within 60s; ticket/QR issued once; ICS attaches; `/me/ticket` works offline.

---

# EPIC 2 — Meeting Scheduling & Management (MEET)

### DB

* [ ] Tables: `rooms`, `meetings`.
* [ ] Optional seed: named rooms and basic capacity.
* [ ] Constraint/guard: no overlapping **accepted** meetings per user.

### Server/API

* [ ] `GET /directory?role=&q=&available=` (public profile list).
* [ ] `POST /meetings` (create `pending` request).
* [ ] `PATCH /meetings/:id` (accept/decline/cancel and, on accept, set `{start_at,end_at,location_type,location_value}`).
* [ ] `GET /me/meetings` (my upcoming/past).
* [ ] Cron: reminders T-24h & T-2h (email, optional SMS).

### UI

* [ ] `/directory` with filters (role/company/interests).
* [ ] `/meetings` inbox/sent, request modal, accept/decline actions.
* [ ] When accepted: slot picker (fixed 30-min grid across event days/hours).
* [ ] ICS send on accept/update/cancel.

### QA

* [ ] Overlap prevention tested; timezone safe (WAT everywhere).
* [ ] Reminders fire; calendar files open in common clients.

**DoD (Epic 2)**

* ✅ Users can request/accept; no double-book; ICS + reminders work.

---

# EPIC 3 — Booth Order Management (BOOTH)

### DB

* [ ] `booths` (PK: `booth_code`) with `zone,width_m,depth_m,area_m2,status,hold_expires_at,features,allocated_to_company_id`.
* [ ] `booth_leads` (pipeline: `new → contacted → qualified → closed`).
* [ ] Seed 43 booths (A1–A18, B1–B9, C1–C11, D1–D2, E, F1–F2). Default 3×3; refine sizes later.

### Server/API

* [ ] `GET /booths?zone=&status=&size=`
* [ ] `GET /booths/:code`
* [ ] `POST /booth-leads`
* [ ] Staff: `PATCH /staff/booths/:code/status` `{status,hold_expires_at?}`
* [ ] Staff: `POST /staff/booths/import` (CSV) & `GET /staff/exports/booth-leads.csv`
* [ ] Cron: expire holds → set `available`.
* [ ] Audit logs on staff mutations.

### UI (public)

* [ ] `/booths` page: floor plan **image** on top (zoomable, no hotspots).
* [ ] Zone tabs (A/B/C/D/F; E info-only), filters, booth cards with **status**, **Call Sales (tel:)**, **Request Details** form.

### UI (staff console — in-app or Appsmith)

* [ ] Booth list with status dropdown, hold expiry set, allocate company optional.
* [ ] Leads table with pipeline transitions, assignee, notes.

### QA

* [ ] Status changes reflect publicly <10s.
* [ ] Holds expire automatically.
* [ ] Leads contain booth\_code, are exportable.

**DoD (Epic 3)**

* ✅ Public sees 43 booths, can submit leads; staff can manage status/holds/leads; audit present.

---

# EPIC 4 — Pitch Session Registration (PITCH)

### DB

* [ ] `pitch_sessions` (name, date, capacity, open\_from/to).
* [ ] `pitch_applications` (user\_id, session\_id, title, logline, link, status, timeslot\_start/end).

### Server/API

* [ ] `GET /pitch-sessions`
* [ ] `POST /pitch-applications` (guard: user has **PAID** ticket).
* [ ] Staff: `PATCH /pitch-applications/:id` `{status, timeslot_start, timeslot_end}`
* [ ] ICS send to presenter on approve/slot assign.

### UI

* [ ] `/pitch` list + apply form (disable if not PAID).
* [ ] My Applications list; status badges.
* [ ] Staff page to approve/decline and assign slots.

### QA

* [ ] Capacity respected; waitlist is FIFO by submission timestamp.
* [ ] ICS details/timezone correct.

**DoD (Epic 4)**

* ✅ Only PAID users can apply; approvals send ICS with slot; waitlist behaves.

---

# EPIC 5 — Hardening, UAT, & Launch

**Security & compliance**

* [ ] Rate limits on auth and `booth-leads` form.
* [ ] CSRF where applicable; secrets never leak to client.
* [ ] Data export/delete flows (admin-mediated).
* [ ] Access logs and audit review.

**Performance**

* [ ] First load P95 ≤ 3s on 3G-fast; images compressed; cache headers sane.
* [ ] DB indexes in place (`meetings.start_at`, `orders.status`, `booths.status`).

**Monitoring**

* [ ] Dashboards: orders/day, webhook success %, meetings volume, lead pipeline.
* [ ] Incident runbook: webhook retry, manual reconcile, refund procedure.

**UAT script**

* [ ] Pass purchase path (invoice → webhook → ticket/QR).
* [ ] Meetings flow (req/accept/slot/ICS/reminders).
* [ ] Booth lead + staff pipeline + hold expiry.
* [ ] Pitch apply → approve → ICS.

**Go/No-Go**

* [ ] Checklists green; backups configured; staff trained on console.

---

## Deliverables per epic (for Jira “Definition of Done”)

* **PASS:** schema/migrations, seed passes, endpoints, webhook, QR & ICS, UI `/register` + `/me/ticket`, confirmation email, tests.
* **MEET:** schema, endpoints, directory & meetings UI, ICS/reminders cron, tests.
* **BOOTH:** schema/seed, public page & forms, staff console, cron expiry, exports, tests.
* **PITCH:** schema, endpoints, public & staff UIs, ICS on approve, tests.
* **HARDEN:** rate limits, RLS checks, perf budget, dashboards, runbook, UAT sign-off.

---

## Nice-to-add later (doesn’t block MVP)

* Two-way calendar sync (Google/Microsoft).
* SVG booth hotspots.
* Sponsor placements & analytics.
* Multi-currency checkout (if Paystack USD enabled).

---