# Payment Report Executive Bento UI/UX & Smart Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Payment Report dashboard into a modern Stripe/Linear-style Executive Bento interface, eliminate dark-box chart jarringness, and filter out false alarms in the WhatsApp rescue flow so already-paid patients are never messaged.

**Architecture:** 
- Backend (`membership-api`): Enhance `admin/payment/get-successful-payment.ts` with subquery cross-checks against `payment_transaction = 'paid'` and `appointment_status IN (1, 5)` for the same appointment or patient on that day, tagging items with `isRecovered`.
- Frontend (`klinik-aurora-portal`): Redesign `payment_homepage.dart` using a white-themed Bento grid, sleek segmented date controls, refined chart gradients, and clean financial channel badges; refactor `appointment_ids.dart` with dual tabs (`Needs Rescue` vs `All / Recovered`).

**Tech Stack:** Flutter Web, TypeScript / Express / MySQL, Firebase Hosting.

---

### Task 1: Backend False Alarm Cross-Check (`membership-api`)

**Files:**
- Modify: `/Users/aminariff/Documents/Github/membership-api/admin/payment/get-successful-payment.ts`

- [ ] **Step 1: Update SQL query in `get-successful-payment.ts` to detect and filter false alarms**

Add cross-check logic for failed queries (`isFailedQuery`):
```typescript
    const isFailedQuery = status === "failed";
    const unrecoveredOnly = req.query.unrecoveredOnly !== "false"; // default true for rescue

    // Recovery subquery: check if same appointment or patient succeeded on same date
    const recoveredCondition = `
      EXISTS (
        SELECT 1 FROM appointment a_succ
        JOIN payment p_succ ON p_succ.appointment_id = a_succ.appointment_id
        JOIN payment_transaction pt_succ ON pt_succ.payment_id = p_succ.payment_id
        WHERE (
          a_succ.appointment_id = p.appointment_id
          OR (
            a_succ.user_account_id = a.user_account_id
            AND a_succ.service_branch_id = a.service_branch_id
            AND DATE(a_succ.appointment_datetime) = DATE(a.appointment_datetime)
          )
        )
        AND pt_succ.payment_transaction_state = 'paid'
      ) OR a.appointment_status IN (1, 5)
    `;
```
Select `(${recoveredCondition}) AS isRecovered` in SELECT clause, and when `isFailedQuery && unrecoveredOnly`, append `AND NOT (${recoveredCondition})`.

- [ ] **Step 2: Build backend**

Run:
```bash
npm run build
```
Verify: compiles with zero TypeScript errors.

- [ ] **Step 3: Commit backend changes**

```bash
git add admin/payment/get-successful-payment.ts
git commit -m "feat(payment): cross-check failed payment false alarms against successful bookings"
```

---

### Task 2: Portal Model & Controller Update (`klinik-aurora-portal`)

**Files:**
- Modify: `/Users/aminariff/Documents/Github/klinik-aurora-portal/lib/models/payment/payment_success_response.dart`

- [ ] **Step 1: Add `isRecovered` field to `PaymentAppointmentItem`**

Add `final bool? isRecovered;` to model and handle parsing in `fromJson` and `toJson`.

- [ ] **Step 2: Verify model changes**

Run:
```bash
fvm flutter analyze lib/models/payment/payment_success_response.dart
```
Verify: 0 issues found.

- [ ] **Step 3: Commit model updates**

```bash
git add lib/models/payment/payment_success_response.dart
git commit -m "feat(payment): add isRecovered field to PaymentAppointmentItem"
```

---

### Task 3: Smarter Recovery Modal (`appointment_ids.dart`)

**Files:**
- Modify: `/Users/aminariff/Documents/Github/klinik-aurora-portal/lib/views/payment/appointment_ids.dart`

- [ ] **Step 1: Implement segmented tabs (`Needs Rescue` vs `All / Recovered`) and badge states**

1. Add state variable `int _tabIndex = 0; // 0 = Needs Rescue, 1 = All`
2. Filter list based on `item.isRecovered == true` vs false.
3. For recovered items:
   - Display `✓ Recovered (Paid)` soft green badge.
   - Omit the `Rescue via WhatsApp` button.
4. For unrecovered drop-offs:
   - Keep prominent `Rescue via WhatsApp` button.

- [ ] **Step 2: Analyze modal code**

Run:
```bash
fvm flutter analyze lib/views/payment/appointment_ids.dart
```
Verify: 0 issues.

- [ ] **Step 3: Commit modal update**

```bash
git add lib/views/payment/appointment_ids.dart
git commit -m "feat(payment): add tabs and suppress whatsapp rescue for recovered patients"
```

---

### Task 4: Modern Executive Bento Dashboard (`payment_homepage.dart`)

**Files:**
- Modify: `/Users/aminariff/Documents/Github/klinik-aurora-portal/lib/views/payment/payment_homepage.dart`

- [ ] **Step 1: Replace pitch-black chart container with clean white executive card**

Replace `_bgDark` container:
- Background: `Colors.white`
- Border: `Border.all(color: Color(0xFFE2E8F0))`
- Grid lines: `Color(0xFFF1F5F9)`
- Left & bottom titles: slate text (`Color(0xFF64748B)`)
- Bar rod gradient: Klinik Aurora primary rose (`Color(0xFFDF6E98)`) to berry burgundy (`Color(0xFF7E2D40)`).

- [ ] **Step 2: Modernize Bento KPI summary cards**

Transform `_SummaryCard`:
- Clean white card, border `Color(0xFFE2E8F0)`, radius 12, light elevation.
- Replace 4px vertical bar with 36x36 rounded icon badge with 10% tinted background.
- Clean 22px bold Slate-900 typography (`Color(0xFF0F172A)`).
- Pill badges for secondary info (`88.5% conv.`, `⚠ 3 lost sales`).

- [ ] **Step 3: Polish header, filter controls, breakdown, and data ledger table**

- Modernize GrabPay icon from delivery motorcycle to `Icons.account_balance_wallet_rounded`.
- Sleek segmented pill date filters (`Today`, `Yesterday`, `Last 7 Days`, `This Month`, `Custom`).
- Table container with `#F8FAFC` header styling and right-aligned currency.

- [ ] **Step 4: Analyze portal code**

Run:
```bash
fvm flutter analyze lib/views/payment/payment_homepage.dart
```
Verify: 0 issues.

- [ ] **Step 5: Commit dashboard modernization**

```bash
git add lib/views/payment/payment_homepage.dart
git commit -m "style(payment): modernize payment report executive bento UI/UX"
```

---

### Task 5: Build, Verify, and Deploy

- [ ] **Step 1: Build Flutter web release**

```bash
fvm flutter build web --release
```

- [ ] **Step 2: Deploy to Firebase Hosting**

```bash
firebase deploy --project klinik-aurora --only hosting
```

- [ ] **Step 3: Push changes to remote repositories**

In `membership-api`:
```bash
git push origin production
```
In `klinik-aurora-portal`:
```bash
git push origin main
```
