# Aurora Baby Clinical & Maternity Sanctuary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the Beg Hospital 100% denominator calculation bug across backend services, upgrade the Superadmin Aurora Baby portal into an Executive Clinical Bento with high-density patient cards and a slide-over inspection drawer, and transform the mobile app into a warm Maternity Sanctuary with a 3-Bag Ward Organizer, tactile check-offs, and partner WhatsApp sharing.

**Architecture:** 
1. `membership-api`: Compute hospital bag metrics using active master template baseline (`Math.max(templateCount, userItemCount)`).
2. `klinik-aurora-portal`: Linear/Apple Health clinical aesthetic with Bento KPI station, `PatientClinicalCard` grid with 40-week timeline, and `PatientDetailDrawer`.
3. `klinik-aurora-mobile`: Warm Rose-Pearl & Champagne Alabaster aesthetic, 3-Bag Ward Organizer (Beg Mama, Beg Baby, Dokumen), tactile haptic check-offs, and husband WhatsApp car-trunk checklist sharing.

**Tech Stack:** TypeScript/Node.js, MySQL (mysql2), Flutter/Dart (Flutter Web & Mobile), Provider state management.

---

### Task 1: Backend Denominator Bug Fix & Master Baseline Integration (`membership-api`)

**Files:**
- Modify: `admin/baby-tracker/baby-tracker.service.ts:350-435`
- Modify: `admin/user-management/get-user-baby-checklist.ts:160-175`
- Modify: `mobile/baby-checklist/get-checklist.ts:150-168`
- Test: `scripts/test-baby-checklist-denominator.ts`

- [ ] **Step 1: Write test verifying accurate denominator calculation**

Create `scripts/test-baby-checklist-denominator.ts`:

```typescript
import assert from 'assert';

function calculateHospitalBagProgress(
  completedCount: number,
  syncedCount: number,
  masterTemplateBagCount: number
): { total: number; completed: number; percentage: number } {
  const total = Math.max(masterTemplateBagCount, syncedCount);
  const percentage = total > 0 ? Math.round((completedCount / total) * 100) : 0;
  return { total, completed: completedCount, percentage };
}

// Test case 1: User checked 1 item out of 10 master items -> must be 10%, NOT 100%
const res1 = calculateHospitalBagProgress(1, 1, 10);
assert.strictEqual(res1.percentage, 10, '1 out of 10 must be 10%');
assert.strictEqual(res1.total, 10);

// Test case 2: User checked 10 items out of 10 master items -> must be 100%
const res2 = calculateHospitalBagProgress(10, 10, 10);
assert.strictEqual(res2.percentage, 100, '10 out of 10 must be 100%');

// Test case 3: User checked 0 items -> must be 0%
const res3 = calculateHospitalBagProgress(0, 0, 10);
assert.strictEqual(res3.percentage, 0, '0 items must be 0%');

// Test case 4: User added 2 custom bag items (total 12) and completed 6 -> must be 50%
const res4 = calculateHospitalBagProgress(6, 12, 10);
assert.strictEqual(res4.percentage, 50, '6 out of 12 must be 50%');

console.log('✓ All denominator test cases passed!');
```

- [ ] **Step 2: Run test to verify calculation logic**

Run: `npx ts-node scripts/test-baby-checklist-denominator.ts`  
Expected: `✓ All denominator test cases passed!`

- [ ] **Step 3: Update `admin/baby-tracker/baby-tracker.service.ts`**

In `getPregnancyReportsService`:
1. Query active master template count for hospital bag before querying patients:
```typescript
    // Fetch master template baseline count for hospital bag
    const [[templateMeta]] = (await connection.query(`
        SELECT 
            COUNT(*) AS masterHospitalBagCount
        FROM baby_checklist_template
        WHERE is_active = 1 AND (category_key = 'beg_hospital' OR is_hospital_bag = 1)
    `)) as [any[], any];

    const masterHospitalBagCount = Number(templateMeta?.masterHospitalBagCount) || 10;
```
2. When iterating over patients, calculate `hospitalBagTotal` as:
```typescript
    const syncedBagTotal = Number(r.hospitalBagTotal) || 0;
    const hospitalBagCompleted = Number(r.hospitalBagCompleted) || 0;
    const hospitalBagTotal = Math.max(masterHospitalBagCount, syncedBagTotal);
    const hospitalBagPercentage =
        hospitalBagTotal > 0 ? Math.round((hospitalBagCompleted / hospitalBagTotal) * 100) : 0;
```

- [ ] **Step 4: Update `admin/user-management/get-user-baby-checklist.ts` and `mobile/baby-checklist/get-checklist.ts`**

Ensure `hospitalBagCategory` uses `Math.max(10, hospitalBagCategory.itemCount)` so that baseline is never 1 or 0 when items exist.

- [ ] **Step 5: Verify against production database data**

Run query via script to verify that patients who completed 1 item now display 10% instead of 100%.

- [ ] **Step 6: Commit backend changes**

```bash
git add admin/baby-tracker/baby-tracker.service.ts admin/user-management/get-user-baby-checklist.ts mobile/baby-checklist/get-checklist.ts scripts/test-baby-checklist-denominator.ts
git commit -m "fix(baby-tracker): calculate hospital bag percentage using master template baseline"
```

---

### Task 2: Superadmin Portal Executive Bento & Patient Clinical Cards (`klinik-aurora-portal`)

**Files:**
- Create: `lib/views/baby_tracker/widgets/patient_clinical_card.dart`
- Modify: `lib/views/baby_tracker/baby_tracker_homepage.dart`

- [ ] **Step 1: Create `PatientClinicalCard`**

In `lib/views/baby_tracker/widgets/patient_clinical_card.dart`:
- Modern 2-column or 3-column responsive card.
- Header: Patient name, Phone, Branch pill, Due date indicator (`Due in X days` or `Overdue X days`).
- 40-Week Gestational Timeline Bar (`LinearProgressIndicator` styled with custom milestones at week 13, 27, 40).
- Vitals:
  - Fetal Kicks pill (`12 tendangan hari ini` in emerald vs warning in amber).
  - Beg Hospital readiness pill (`4/10 barangan • 40%`).
- Quick Actions: WhatsApp 1-click button + "Periksa Pesakit" button.

- [ ] **Step 2: Update `baby_tracker_homepage.dart` to support Executive Cards & Table Toggle**

In `lib/views/baby_tracker/baby_tracker_homepage.dart`:
- Add `bool _isCardView = true;` toggle state in `_BabyTrackerHomepageState`.
- Update Bento Metric cards to display Trimester distribution pills under `Ibu Hamil Aktif`.
- Add Urgent alert banner for overdue / low kick mothers with 1-click filter.
- Build grid view of `PatientClinicalCard` widgets when `_isCardView == true`.
- Keep high-density table view as secondary toggle option.

- [ ] **Step 3: Analyze code for syntax and type issues**

Run: `cd ../klinik-aurora-portal && fvm flutter analyze lib/views/baby_tracker/`  
Expected: `No issues found!`

- [ ] **Step 4: Commit portal card & bento changes**

```bash
cd ../klinik-aurora-portal
git add lib/views/baby_tracker/widgets/patient_clinical_card.dart lib/views/baby_tracker/baby_tracker_homepage.dart
git commit -m "feat(portal): add executive bento KPI and clinical patient cards for aurora baby"
```

---

### Task 3: Superadmin Portal Sliding Inspection Drawer (`klinik-aurora-portal`)

**Files:**
- Create: `lib/views/baby_tracker/widgets/patient_detail_drawer.dart`
- Modify: `lib/views/baby_tracker/baby_tracker_homepage.dart`

- [ ] **Step 1: Create `PatientDetailDrawer` widget**

In `lib/views/baby_tracker/widgets/patient_detail_drawer.dart`:
- Edge-anchored right slide-over sheet (width: 580px desktop, full width on mobile).
- Top bar with patient name, trimester badge, and close button.
- Three tabs:
  - **Status & Garis Masa**: Gestational week, LMP, EDD recalculation trigger, doctor clinical notes.
  - **Log Tendangan**: Daily kick count, session list with timestamps and velocity.
  - **Senarai Semak & Beg Hospital**: Accordion categories showing item-by-item status with true hospital bag completion ratio.

- [ ] **Step 2: Wire drawer trigger into `baby_tracker_homepage.dart`**

Replace `showDialog(builder: (_) => UserBabyTrackerDialog(...))` with `showGeneralDialog` using `SlideTransition` from right:
```dart
void _openPatientDrawer(Map<String, dynamic> patient) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) => Align(
      alignment: Alignment.centerRight,
      child: PatientDetailDrawer(
        patient: patient,
        onRefresh: _fetchReports,
      ),
    ),
    transitionBuilder: (ctx, anim1, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}
```

- [ ] **Step 3: Analyze code with `fvm flutter analyze`**

Run: `cd ../klinik-aurora-portal && fvm flutter analyze`  
Expected: `No issues found!`

- [ ] **Step 4: Commit sliding drawer changes**

```bash
cd ../klinik-aurora-portal
git add lib/views/baby_tracker/widgets/patient_detail_drawer.dart lib/views/baby_tracker/baby_tracker_homepage.dart
git commit -m "feat(portal): add smooth slide-over inspection drawer for aurora baby patient details"
```

---

### Task 4: Mobile App Maternity Sanctuary Theme & Hero Progress Card (`klinik-aurora-mobile`)

**Files:**
- Modify: `lib/views/baby_tracker/baby_checklist_page.dart`
- Create: `lib/views/baby_tracker/widgets/aurora_baby_progress_sanctuary_card.dart`

- [ ] **Step 1: Create `AuroraBabyProgressSanctuaryCard`**

In `lib/views/baby_tracker/widgets/aurora_baby_progress_sanctuary_card.dart`:
- Replace cold slate `#0F172A` with warm Rose Blush & Champagne Alabaster:
  - Gradient: `[Color(0xFFFFF0F3), Color(0xFFFFF9F5)]`.
  - Border: `Color(0xFFFDE2E8)` 1.5px.
  - Soft shadow: `BoxShadow(color: Color(0xFFFDA4AF).withValues(alpha: 0.18), blurRadius: 18)`.
- Dual circular progress rings:
  - Outer ring: Beg Hospital (`%` in maternal rose).
  - Inner ring: Total Baby Preparation (`%` in calming sage).
- Dynamic reassuring micro-copy based on gestational week:
  - Week < 28: *"Awal lagi Mama. Rancang & kumpul senarai perlahan-lahan 🌸"*
  - Week 28–34: *"Masa ideal kemaskan Beg Hospital untuk wad bersalin 🏥"*
  - Week 35+: *"Bertenang Mama, bila-bila masa sahaja si manja akan tiba ✨"*

- [ ] **Step 2: Update `baby_checklist_page.dart` background and integration**

Set scaffold background to Alabaster Silk `Color(0xFFFAFAF8)` and replace old progress card with `AuroraBabyProgressSanctuaryCard`.

- [ ] **Step 3: Run `fvm flutter analyze` in mobile repo**

Run: `cd ../klinik-aurora-mobile && fvm flutter analyze lib/views/baby_tracker/`  
Expected: `No issues found!`

- [ ] **Step 4: Commit mobile sanctuary progress card**

```bash
cd ../klinik-aurora-mobile
git add lib/views/baby_tracker/widgets/aurora_baby_progress_sanctuary_card.dart lib/views/baby_tracker/baby_checklist_page.dart
git commit -m "feat(mobile): add maternity sanctuary progress card with dual rings and empathetic copy"
```

---

### Task 5: Mobile App 3-Bag Ward Organizer & Husband WhatsApp Share (`klinik-aurora-mobile`)

**Files:**
- Create: `lib/views/baby_tracker/widgets/husband_share_sheet.dart`
- Modify: `lib/views/baby_tracker/baby_checklist_page.dart`
- Modify: `lib/views/baby_tracker/widgets/dr_aurora_item_sheet.dart`

- [ ] **Step 1: Create 3-Bag Ward Organizer tabs**

In `baby_checklist_page.dart`:
- Top Stage Filter Selector:
  - 🏥 **Beg Hospital Wad (10 Utama)**
  - 🧸 **Persediaan Rumah & Bilik**
  - 🌿 **Ibu Berpantang & Susu**
- When "Beg Hospital Wad" is active, display 3 distinct pouch sections:
  1. **Beg Mama**: Kain batik, nursing bra, disposable panties, maternity pad, selipar wad.
  2. **Beg Si Manja**: Baju butang depan, barut, bedung bayi, sarung tangan & stoking, lampin newborn.
  3. **Dokumen Penting**: Buku Pink, Kad Pengenalan Suami & Isteri, Surat Jaminan / GL Insurans.

- [ ] **Step 2: Add tactile check-off with haptic feedback**

In `_buildChecklistItemTile`:
- Add `HapticFeedback.lightImpact()` on tap.
- Smooth scale bounce animation (`AnimatedScale`).
- Reassuring transient snackbar/toast on completion: *"Satu lagi beban selesai, Mama."*

- [ ] **Step 3: Create `HusbandShareSheet` for WhatsApp car-trunk dispatch**

In `lib/views/baby_tracker/widgets/husband_share_sheet.dart`:
- Generate formatted text message:
```text
Salam sayang 🌸
Ini senarai semak Beg Hospital wad bersalin Klinik Aurora yang dah siap & belum:

✅ SIAP DIKEMAS:
• Kain batik & baju wad
• Baju butang depan & bedung baby

⏳ BELUM DIKEMAS:
• Buku pink & dokumen GL
• Pampers newborn

Mohon periksa dalam bonet kereta sebelum kita gerak ke wad ya! ❤️
```
- Open WhatsApp Web / WhatsApp App via `url_launcher` with encoded text.

- [ ] **Step 4: Run `fvm flutter analyze` across mobile repo**

Run: `cd ../klinik-aurora-mobile && fvm flutter analyze`  
Expected: `No issues found!`

- [ ] **Step 5: Commit mobile 3-bag organizer and husband share**

```bash
cd ../klinik-aurora-mobile
git add lib/views/baby_tracker/widgets/husband_share_sheet.dart lib/views/baby_tracker/baby_checklist_page.dart lib/views/baby_tracker/widgets/dr_aurora_item_sheet.dart
git commit -m "feat(mobile): add 3-bag ward organizer, tactile check-offs, and husband whatsapp share"
```

---

### Task 6: Full Verification, Web Release Build & Production Deploy

- [ ] **Step 1: Test backend calculations on staging/production**
- [ ] **Step 2: Build portal release**: `cd ../klinik-aurora-portal && fvm flutter build web --release`
- [ ] **Step 3: Deploy portal to Firebase Hosting**: `firebase deploy --project klinik-aurora --only hosting:production`
- [ ] **Step 4: Test mobile test suite**: `cd ../klinik-aurora-mobile && fvm flutter test`
- [ ] **Step 5: Final git push across all repositories**
