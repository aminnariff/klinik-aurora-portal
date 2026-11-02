# Design Spec: Aurora Baby Superadmin UI/UX Overhaul & Beg Hospital Readiness Bug Fix

- **Date:** 2026-11-02
- **Target Repositories:** `membership-api` (Backend logic), `klinik-aurora-portal` (Superadmin Web UI)
- **Status:** Approved / In Planning

---

## 1. Executive Summary & Problem Statement

Superadmins monitoring expectant mothers via **Aurora Baby** face two critical friction points:
1. **Mathematical Accuracy Bug in Beg Hospital Readiness**:
   - The system displays `100%` readiness for patients who have only checked 1 or a few items.
   - **Root Cause**: The backend calculation in `admin/baby-tracker/baby-tracker.service.ts` uses `COUNT(*)` of `baby_checklist_item` matching `category_key = 'beg_hospital'` as the denominator. Because mobile users only sync rows for items they have interacted with, a patient who only synced 1 checked item has `hospitalBagTotal = 1` and `hospitalBagCompleted = 1`, resulting in `1/1 = 100%`.
   - **Solution**: Compute the true clinic baseline from the active master checklist template (currently 10 hospital bag items) plus any user-defined custom items:
     $$\text{hospitalBagTotal} = \max(\text{masterTemplateHospitalBagCount}, \text{userSyncedHospitalBagCount})$$
     A patient with 1 item completed will now display an honest and clinically actionable `1/10 (10%)`.

2. **Substandard UI/UX Quality**:
   - The current view is utilitarian, cramped, and visually dated (generic Flutter `DataTable2`, flat pastel tags, monolithic 900-line popup dialogs, lack of fluid feedback).
   - **Solution**: A 40+ years experience executive clinical overhaul inspired by Linear, Apple Health, and modern medical cockpits:
     - **Executive Clinical Bento**: Four high-contrast KPI stations with micro-distributions (Trimester split, urgent alert pills).
     - **Dual Inspection Mode**: **Executive Patient Cards** (default, dense cards with 40-week visual scrubber and progress track) and **Surgical Grid** (ultra-dense table for rapid triage).
     - **Patient Deep-Dive Slide-over Drawer**: Replaces the jarring modal dialog with a fluid edge-anchored sheet featuring gestational timelines, kick velocity logs, and categorized item accordions.

---

## 2. Backend Bug Fix: Honest Denominator Calculation

### 2.1 Files Affected
- `admin/baby-tracker/baby-tracker.service.ts`
- `admin/user-management/get-user-baby-checklist.ts`
- `mobile/baby-checklist/get-checklist.ts`

### 2.2 Mathematical Formula & Query Logic
1. Query active master template count for hospital bag:
   ```sql
   SELECT COUNT(*) AS total
   FROM baby_checklist_template
   WHERE is_active = 1 AND (category_key = 'beg_hospital' OR is_hospital_bag = 1);
   ```
2. When evaluating a patient's checklist in `baby-tracker.service.ts`:
   - `hospitalBagCompleted`: Count of `baby_checklist_item` where `(category_key = 'beg_hospital' OR is_hospital_bag = 1) AND is_checked = 1 AND is_deleted = 0`.
   - `customBagCount`: Count of custom items created by patient with `is_custom = 1`.
   - `effectiveTotal`: $\max(\text{masterTemplateCount}, \text{customBagCount} + \text{syncedTemplateItemsCount})$.
   - `hospitalBagPercentage`: $\text{round}\left(\frac{\text{hospitalBagCompleted}}{\text{effectiveTotal}} \times 100\right)$.
3. Clinic-wide Average `avgHospitalBagPercentage`:
   - Sum individual patient percentages and divide by total active profiles:
     $$\text{avgHospitalBagPercentage} = \text{round}\left(\frac{\sum \text{hospitalBagPercentage}}{N}\right)$$

---

## 3. Frontend UI/UX Architecture (`klinik-aurora-portal`)

### 3.1 Design Foundations & Visual Language
- **Color Palette**:
  - Primary Brand: Clinical Deep Teal (`Color(0xFF0F766E)` / `Color(0xFF14B8A6)`)
  - Accent Rose: Maternity Rose (`Color(0xFFE11D48)` / `Color(0xFFFDA4AF)`)
  - Dark Surface / Slate: Modern Obsidian (`Color(0xFF0F172A)`, `Color(0xFF1E293B)`)
  - Card Surfaces: Crisp White (`#FFFFFF`) with border `Color(0xFFE2E8F0)` and subtle drop shadows (`0 4px 20px -2px rgba(15,23,42,0.06)`).
  - Background: Clinical Pearl (`Color(0xFFF8FAFC)`).
- **Typography Hierarchy**:
  - Display KPI Numbers: `Poppins` 28px SemiBold, tabular numbers.
  - Section Headers: 16px Bold, `letter-spacing: -0.2px`.
  - Body & Subtitles: 13px / 11px, `Color(0xFF64748B)`.

### 3.2 Layout Structure

```
lib/views/baby_tracker/
├── baby_tracker_homepage.dart          # Executive Bento, Search Toolbar, Dual-Mode Patient List
├── widgets/
│   ├── aurora_3d_womb_visualizer.dart  # Interactive 3D Fetal Orb (Existing)
│   ├── patient_clinical_card.dart      # High-density patient bento card with 40-week timeline
│   ├── patient_detail_drawer.dart      # Smooth edge-anchored slide-over inspection drawer
│   ├── template_item_editor_dialog.dart# Template CRUD modal (Existing)
```

### 3.3 Executive Bento KPI Stations
1. **Ibu Hamil Aktif**:
   - Total count + live Trimester pills: `T1: 12` • `T2: 24` • `T3: 14`.
2. **Perhatian Klinikal (Urgent Alerts)**:
   - Overdue pregnancies (>40w) + Low kicks (<10 kicks at ≥28w).
   - Crimson badge with warning glow and instant 1-tap filter trigger.
3. **Kesiapsiagaan Beg Hospital**:
   - Honest clinic average percentage (e.g. `34%`).
   - Micro progress track with benchmark goal indicator.
4. **Pemantauan Fetal Harian**:
   - Total kick sessions logged today with active monitor pulse.

### 3.4 Patient Clinical Card Specification
Each card represents one pregnant patient in a responsive grid (2 columns on standard desktop, 3 columns on wide 1440p+ screens):
- **Card Header**:
  - Patient Full Name, Phone, and Branch tag.
  - Due Date Badge: `40 Hari Lagi` (Emerald) or `Overdue 3 Hari` (Crimson Pulse).
- **40-Week Gestational Timeline Track**:
  - Horizontal progress bar displaying current week (e.g., `Minggu 32 / 40`).
  - Visual trimester break indicators (Week 13, Week 27, Week 40).
- **Clinical Vital Metrics**:
  - **Fetal Movement Badge**:
    - `≥ 10 tendangan`: Emerald pill with checked icon.
    - `< 10 tendangan` (Week 28+): Amber glowing pill with warning icon.
    - Not logged today: Neutral slate pill.
  - **Beg Hospital Progress**:
    - True ratio pill: `e.g. 4/10 barangan (40%)`.
- **Card Actions**:
  - WhatsApp Quick-Chat: 1-click opens WhatsApp Web to patient phone with tailored greeting.
  - "Periksa Detail": Opens the smooth Patient Detail Drawer.

### 3.5 Patient Detail Slide-Over Drawer
Replaces `UserBabyTrackerDialog` popup modal with an edge-anchored sliding sheet (width: 580px desktop, full-width mobile):
- Smooth slide transition (`Tween<Offset>(begin: Offset(1, 0), end: Offset.zero)`).
- **Tab 1: Status & Garis Masa Kehamilan**:
  - Gestational age calculator, EDD, current fetal developmental milestone, and doctor remarks.
- **Tab 2: Log Tendangan (Fetal Kicks)**:
  - Daily kick totals, time-of-day velocity, and historical kick logs.
- **Tab 3: Senarai Semak & Beg Hospital**:
  - Accordion categories with progress bars:
    - 🏥 Beg Hospital Ibu & Anak (`4/10 siap`)
    - 👕 Pakaian Bayi
    - 🍼 Kelengkapan Penyusuan
    - 🛏️ Bilik & Tempat Tidur
    - 🧴 Penjagaan & Mandian
    - 👩‍🦰 Keperluan Ibu Berpantang
    - 🏠 Keselamatan & Rumah
  - Inline checkbox toggle for clinic staff review.

---

## 4. Verification & Testing Plan

1. **Backend Verification**:
   - Unit test on `baby-tracker.service.ts`:
     - Patient with 1 checked hospital bag item out of 10 master items returns `10%` (not `100%`).
     - Patient with 10 checked hospital bag items returns `100%`.
     - Patient with 0 checked items returns `0%`.
     - Patient with custom items has total properly incremented.
2. **Frontend Verification**:
   - `fvm flutter analyze` passes with 0 issues.
   - Dual-view toggle switches seamlessly between Cards and Table.
   - Trimester filters accurately partition the patient set.
   - Slide-over drawer smoothly opens and closes with ESC key or backdrop tap.
   - Production web build compiles cleanly with `fvm flutter build web --release`.

---

## 5. Deployment Constraints
- Code changes in `membership-api` tested locally, committed, and pushed.
- Production web application in `klinik-aurora-portal` compiled and deployed to Firebase Hosting (`https://klinik-aurora.web.app`).
