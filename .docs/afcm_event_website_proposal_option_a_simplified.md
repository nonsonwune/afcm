# AFCM Event Website — Proposal

**Client:** AFRIFF / African Film & Content Market (AFCM)\
**Attention:** Chioma Udeh\
**Vendor:** RateMe LTD (ratemeltd.com)\
**Proposal Date:** September 23, 2025 (WAT)\
**Target Production Readiness:** October 10, 2025 (WAT)\
**Festival Window:** AFRIFF Nov 2–8, 2025 • AFCM Market Nov 3–6, 2025 (Lagos)

---

## 1. Executive Summary

RateMe LTD will design, build, and deploy an installable event website (progressive web app) for AFCM enabling: (1) pass sales in NGN with QR e‑tickets, (2) 30‑minute meeting booking with conflict prevention, (3) booth visibility and enquiries (no public pricing), and (4) pitch‑session applications with staff‑managed fees and scheduling. Modules are delivered incrementally between September 24 and October 10, 2025, culminating in production‑ready sign‑off.

---

## 2. Objectives & Outcomes

- Launch paid registration and issue reliable QR e‑tickets.
- Provide a simple, clash‑free meeting scheduler for attendees.
- Publish the floor plan and complete booth list with status management and enquiry capture.
- Accept open pitch applications; allow staff to approve/decline and charge or waive fees case‑by‑case.
- Provide a staff dashboard with role‑based access and an activity log.
- Ensure the app is installable and key attendee views (My Ticket, Agenda, Floor Plan) work under degraded connectivity.

---

## 3. Scope of Work (MVP)

### 3.1 Pass Sales & QR E‑Tickets (Paystack NGN)

- Pass catalogue (client‑provided names/prices) with Paystack hosted checkout.
- Email receipt, **QR e‑ticket**, and **.ics** calendar attachment per paid attendee.
- Admin order view; de‑duplication to ensure one ticket per attendee.

### 3.2 Meetings (30‑Minute Slots; No Overlaps)

- Attendee directory (name, company, role).
- Request → Accept/Decline workflow; system enforces non‑overlap and valid time windows.
- Email confirmations with **.ics**; basic agenda view per user.

### 3.3 Booths (No Public Pricing)

- Static floor‑plan **image** + list of **43 booth codes**.
- Statuses: **Available / On Hold / Allocated / Hidden**.
- Public **Call Sales** CTA + short enquiry form; staff can update statuses and review enquiries.

### 3.4 Pitch Sessions (Staff‑Managed Fees)

- Public application form (title, short summary, optional link).
- Staff approve/decline and mark **Fee Required (amount)** or **Fee Waived**.
- If charged, system sends a **Paystack payment link**; payment state visible to staff.
- Upon approval (and payment if required), applicant receives **time slot** and **.ics** invite.

### 3.5 Staff Roles & Activity Log

- Roles: **Admin**, **Supervisor**, **Operator** (least‑privilege RBAC).
- Minimal activity log (who/what/when) for key actions.

### 3.6 PWA Installable & Offline Essentials

- “Add to Home Screen” support.
- Offline caching for **My Ticket**, **Agenda**, **Floor Plan** (degraded mode).
- No offline order/payment creation.

**Out of Scope for this MVP (available post‑launch):** interactive SVG hotspots; CSV exports/advanced lead pipeline; automatic booth hold expiry; SMS reminders; two‑way calendar sync; analytics dashboards; public booth pricing/checkout.

---

## 4. Delivery Plan & Milestones (WAT)

- **Sep 24–26 — Registration LIVE**: Paystack payments, QR e‑tickets, calendar invites, admin order view.
- **Sep 27–30 — Meetings LIVE**: Directory, request/accept, single 30‑min slot, conflict prevention, email + **.ics**.
- **Oct 1–3 — Booths LIVE**: Floor‑plan image, 43 booth codes, status badges, Call Sales + enquiry, staff status updates.
- **Oct 4–5 — Pitch LIVE**: Public apply; staff approve/decline; **set/waive fee**; payment link; time slot + **.ics**.
- **Oct 6–7 — Hardening**: Bug fixes, copy polish, quick‑guides.
- **Oct 8 — UAT & data tidy**
- **Oct 9 — Content freeze & dry‑run**
- **Oct 10 — Production‑ready sign‑off & lock**

---

## 5. Technical Approach

- **Architecture:** Modern single‑page progressive web app with server APIs; responsive, mobile‑first UI; CDN‑backed assets.
- **Payments:** Paystack hosted checkout; no card data stored by Vendor. Webhooks/polling reconcile order state.
- **Identity & Access:** Email authentication; role‑based access control (RBAC).
- **Calendar & Tickets:** Standards‑compliant **.ics** invites; QR e‑tickets per order.
- **Email:** Transactional email via reputable SMTP/API with SPF/DKIM/DMARC alignment on client sender domain.
- **Security:** HTTPS/TLS, least privilege, hashed tokens, segregated secrets; audit trail for admin actions.
- **Observability:** Structured logs, error tracking, health checks.
- **Data Protection:** Personal data minimised; aligned with the **Nigeria Data Protection Act (NDPA) 2023**; opt‑out links where applicable; no card data stored.

---

## 6. Pricing (Fixed‑Fee, Itemised)

**Total Professional Fees (USD): \$6,000**\
Base build **\$5,000** + Expedited delivery **\$1,000**. VAT is **7.5%** applied to NGN totals after USD→NGN conversion at the FMDQ/CBN I&E closing rate on invoice day. Payment processing fees (e.g., Paystack) are client‑borne.

| Deliverable                          | Inclusions                                                                           | Acceptance Trigger                                            | USD       |
| ------------------------------------ | ------------------------------------------------------------------------------------ | ------------------------------------------------------------- | --------- |
| Pass Sales & QR E‑Tickets            | Paystack NGN checkout; email receipt; QR e‑ticket; **.ics** invite; admin order view | Live test payment appears ≤60s; QR scans; **.ics** opens      | **1,100** |
| Meetings (30‑min, no overlaps)       | Directory; request/accept/decline; clash prevention; email + **.ics**                | Two test users cannot double‑book; confirmations received     | **1,000** |
| Booths (43 codes)                    | Floor‑plan image; status badges; Call Sales + enquiry; staff status editing          | 43 codes present; status changes <10s; enquiries in dashboard | **700**   |
| Pitch (staff‑managed fees)           | Apply; approve/decline; set/waive fee; payment link; slot + **.ics**                 | One fee‑required + one fee‑waived succeed end‑to‑end          | **800**   |
| Staff RBAC + Activity Log            | Admin/Supervisor/Operator; minimal audit                                             | Role tests pass (scoped permissions)                          | **400**   |
| PWA installable + offline essentials | A2HS; cached Ticket/Agenda/Floor Plan                                                | Phone installs; cached pages load offline                     | **400**   |
| QA/UAT/Docs                          | Test passes; copy polish; quick‑guides (PDF); dry‑run                                | UAT checklist signed; guides delivered                        | **350**   |
| PM/DevOps basics                     | Environments; DNS/SSL; sender auth (SPF/DKIM/DMARC); logs/alerts                     | Domain live over HTTPS; emails deliver                        | **250**   |
| **Base subtotal**                    |                                                                                      |                                                               | **5,000** |
| **Expedited delivery**               | Parallel workstreams; extended hours                                                 | Modules delivered per Section 4 schedule                      | **1,000** |
| **Grand Total**                      |                                                                                      |                                                               | **6,000** |

---

## 7. Payment Terms

- **70% at Kickoff (Sep 24): \$4,200** — Work commences upon receipt.
- **20% on Staging Readiness (Oct 7): \$1,200** — All modules live on staging; **User Acceptance Testing (UAT) begins** (client tests the staging site and logs issues for fix).
- **10% at Production Sign‑off (Oct 10): \$600** — Acceptance upon production readiness confirmation on Oct 10 (WAT).

**Commercial Notes**

- Invoices are issued in USD; NGN payable at the invoice‑day FMDQ/CBN I&E closing rate; **7.5% VAT** applies on NGN totals.
- Payment terms **net 0–3 business days**. If an invoice is overdue by **3 business days**, delivery milestones **pause** until payment clears.
- Discounts do not apply unless expressly stated in this document.

---

## 8. Support & Service Level Agreement (SLA)

**Coverage window:** Monday–Friday, **09:00–18:00 WAT** (West Africa Time), public holidays excluded.\
**Response targets:**

- **Critical issues** (site down, payments not processing): response within **4 hours** during coverage window.
- **Payments/Meetings issues** (non‑critical defects affecting transactions or scheduling): response by the **next business day**.
- **Minor issues** (copy changes, non‑blocking bugs): response within **2–3 business days**.\
  **Included support period:** First **3 months** after production sign‑off are complimentary. From **Month 4**, support is **\$500/month** (NGN + VAT) covering monitoring, security updates, minor content/bugs, and up to **8 developer hours**; overage billed at **\$40/hour**.\
  **Channels:** Email and chat (Slack/WhatsApp group agreed at kickoff).\
  **Escalation:** Named technical contact provided at handover; emergency contact for critical issues.

---

## 9. Assumptions & Dependencies

- Approvals and content provided within **4 business hours** to maintain the expedited schedule.
- Client supplies content, branding, floor‑plan image, booth codes, and Paystack credentials on time.
- Sender domain access granted for email deliverability setup.
- No regulatory barriers to Paystack processing for AFCM.
- Hosting and email providers remain available/operational.

---

## 10. Data Protection & Security

- Compliance aligned with the **Nigeria Data Protection Act (NDPA) 2023**. Minimal data collection; data encrypted in transit; access controls enforced by RBAC.
- No cardholder data is stored by Vendor; payments handled via Paystack.

---

## 11. Intellectual Property & Licensing

- Client owns all client‑provided content, branding, and data.
- Vendor retains ownership of pre‑existing tools and libraries. Client receives a non‑exclusive, perpetual licence to the delivered implementation for AFCM operations.

---

## 12. Handover & Documentation

- Admin quick‑guides (PDF) and a 30‑minute handover call/meeting.
- Credentials transferred securely; basic runbook (backups, restores, emergency contacts) supplied.

---

## 13. Validity & Acceptance

This proposal is valid for **14 calendar days** from the Proposal Date. By signing below or confirming in writing, Client authorises RateMe LTD to proceed per this Statement of Work and Pricing.

**Client (AFRIFF/AFCM)**\
Name/Title: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\
Signature: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\
Date: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

**Vendor (RateMe LTD)**\
Name/Title: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\
Signature: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\
Date: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

