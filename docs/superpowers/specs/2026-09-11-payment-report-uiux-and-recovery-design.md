# Design Spec: Payment Report Executive UI/UX & Smart Recovery

**Date:** 2026-09-11  
**Status:** Approved (Option A: Executive Bento)  
**Target Repos:** `klinik-aurora-portal`, `membership-api`

---

## 1. Problem Statement
1. Current Payment Report UI/UX in `klinik-aurora-portal` has jarring design inconsistencies:
   - Pitch-black chart container (`_bgDark = Color(0xff232d37)`) embedded in a light theme page.
   - 2015-era metric cards with raw saturated primary colors and colored 4px vertical stripes.
   - Mismatched icons (e.g. delivery motorcycle icon for GrabPay).
   - Bulky filter row with raw blue chip borders.
2. The "Click to rescue" feature lacked cross-checking:
   - If a patient failed an initial payment attempt but retried and succeeded (same appointment or subsequent booking on the same day), they were still surfaced in the failed list, prompting staff to message already-paying customers.

---

## 2. Solution Architecture

### A. Executive Bento UI/UX (`klinik-aurora-portal`)
- **Visual Style:** Modern Stripe/Linear aesthetic with clean white cards (`#FFFFFF`), subtle slate borders (`#E2E8F0`), soft drop-shadows (`boxShadow: [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))]`), and Klinik Aurora brand accents (`#DF6E98`, `#7E2D40`).
- **Header & Filter Toolbar:**
  - Single unified executive bar with Date Range display, Superadmin Branch Selector, Segmented Date Chips (`Today`, `Yesterday`, `7 Days`, `This Month`, `Custom`), CSV Export, and Refresh action.
- **Bento KPI Cards:**
  - Card 1: **Total Net Revenue** (RM formatted, bold slate-900 typography, subtle sparkline/growth tag).
  - Card 2: **Successful Bookings** (Booking count + conversion rate pill).
  - Card 3: **Incomplete / Needs Rescue** (Warning red pill `⚠ X lost sales`, click to open recovery modal).
  - Card 4: **Average Transaction Value (ATV)** (RM per booking).
- **Chart Container:**
  - Modern white card container replacing pitch-black background.
  - Soft horizontal gridlines (`#F1F5F9`).
  - Bar gradients using Klinik Aurora primary rose (`#DF6E98`) transitioning into deep berry (`#7E2D40`).
- **Channel & Branch Breakdown:**
  - Modern financial icons (`account_balance_wallet_rounded` for GrabPay/e-wallets, `account_balance_rounded` for FPX, `credit_card_rounded` for Cards).
  - Clean pill badges and rounded progress tracks (`#F1F5F9` background, `#DF6E98` fill).
- **Ledger Table:**
  - Modern card container with `#F8FAFC` column header, right-aligned formatted currency, and emerald/rose status chips.

### B. False Alarm Cross-Check (`membership-api`)
- In `admin/payment/get-successful-payment.ts`:
  - When `status === 'failed'`, query cross-checks:
    1. `a.appointment_status IN (1, 5)` (Booked or Completed).
    2. Existence of any successful transaction (`payment_transaction_state = 'paid'`) for the same `appointment_id`.
    3. Existence of any successful appointment for the same patient (`user_account_id`) on the same date.
  - Return `isRecovered: boolean` in `items`:
    - `true` if patient completed payment subsequently.
    - `false` if true abandoned booking.
  - Support query param `unrecoveredOnly=true` (defaults to true for rescue list).

### C. Modal Redesign (`appointment_ids.dart`)
- Segmented filter tabs:
  - **Needs Rescue (X)**: Only patients who genuinely dropped off and haven't paid.
  - **All Attempts (Y)**: Full audit history including recovered attempts.
- True drop-offs: **Rescue via WhatsApp** button active.
- Recovered items: **✓ Recovered (Paid)** badge, WhatsApp button hidden to avoid awkward customer messages.

---

## 3. Verification Plan
- `fvm flutter analyze` in `klinik-aurora-portal` (0 errors).
- Build web release: `fvm flutter build web --release`.
- Deploy web to Firebase Hosting.
- API build: `npm run build` in `membership-api`.
- Git commit & push for both repos.
