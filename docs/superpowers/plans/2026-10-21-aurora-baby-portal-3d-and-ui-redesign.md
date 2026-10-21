# Aurora Baby Portal UI Overhaul & 3D Fetal Womb Orb Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul the Aurora Baby admin portal UI with an executive 2-column template editor dialog and an interactive 3D Matrix4 Fetal Womb Visualizer with a week 1–40 gestational scrubber.

**Architecture:** 
- A dedicated `TemplateItemEditorDialog` replaces raw, unstyled dialogs with structured, filled rounded inputs and card toggles.
- A standalone `Aurora3DWombVisualizer` component uses pure Flutter vector math (`Matrix4` 3D projection) and hardware-accelerated Skia `CustomPainter` to render an interactive rotatable amniotic womb orb, dynamic biometric scaling across weeks 1–40, and simulated Doppler heartbeat.
- Deep integration into `BabyTrackerHomepage` (hero panel and template list) and `UserBabyTrackerDialog`.

**Tech Stack:** Flutter Web, Skia/CanvasKit, Vector Math, Material 3, Firebase Hosting.

---

## File Structure Map
```
lib/views/baby_tracker/
├── widgets/
│   ├── aurora_3d_womb_visualizer.dart       # 3D Matrix4 Canvas Womb Orb & Scrubber HUD
│   ├── template_item_editor_dialog.dart     # Executive 2-Column Add/Edit Modal Dialog
├── baby_tracker_homepage.dart               # Main Aurora Baby Admin page (Updated with 3D hero panel & dialog)
lib/views/user/
├── user_baby_tracker_dialog.dart            # Patient tracker dialog (Updated with mini 3D week preview)
test/
├── template_item_editor_dialog_test.dart    # Widget tests for dialog layout & callbacks
├── aurora_3d_womb_visualizer_test.dart      # Widget tests for 3D scrubber & projection
```

---

## Tasks

### Task 1: Build `TemplateItemEditorDialog`
**Files to create/modify:**
- Create: `lib/views/baby_tracker/widgets/template_item_editor_dialog.dart`
- Create: `test/template_item_editor_dialog_test.dart`

**Detailed Steps:**
- [ ] Write widget tests in `test/template_item_editor_dialog_test.dart` asserting:
  - Header displays title and category icon.
  - Form fields render with labels (Nama Barangan, Cadangan Kuantiti, Spesifikasi, Keselamatan, Tip Penjimatan).
  - Toggling "Item WAJIB" and "Beg Hospital" updates visual state.
  - Pressing "Simpan" invokes `onSave` callback with serialized payload.
- [ ] Implement `TemplateItemEditorDialog` in `lib/views/baby_tracker/widgets/template_item_editor_dialog.dart`:
  - 720px wide card modal, 24px border radius, subtle rose border (`0xFFFFD1DC`).
  - Header: Category badge pill, title ("Tambah / Kemaskini Item Templat"), subtitle, close button.
  - Left column:
    - Title TextField (filled, 12px rounded borders, icon prefix).
    - Category dropdown with emojis and labels.
    - Quantity TextField.
    - Card toggle 1: **Item WAJIB** (Rose illuminated card, `Icons.verified_rounded`).
    - Card toggle 2: **Beg Hospital** (Cyan illuminated card, `Icons.medical_services_rounded`).
  - Right column:
    - Grouped Dr. Aurora clinical guidance cards:
      - Spesifikasi (Soft blue background, `Icons.tune_rounded`).
      - Keselamatan (Soft amber background, `Icons.gpp_good_rounded`).
      - Tip Penjimatan (Soft emerald background, `Icons.savings_rounded`).
  - Sticky footer: "Batal" text button + gradient "Simpan & Kemaskini" button with hover elevation.
  - Static helper method: `TemplateItemEditorDialog.show(context, {item, categoryKey, onSave})`.
- [ ] Run `flutter test test/template_item_editor_dialog_test.dart` and verify passing.
- [ ] Run `flutter analyze` and ensure 0 issues.
- [ ] Commit: `feat(portal): add executive 2-column TemplateItemEditorDialog`.

---

### Task 2: Build Interactive `Aurora3DWombVisualizer`
**Files to create/modify:**
- Create: `lib/views/baby_tracker/widgets/aurora_3d_womb_visualizer.dart`
- Create: `test/aurora_3d_womb_visualizer_test.dart`

**Detailed Steps:**
- [ ] Write widget tests in `test/aurora_3d_womb_visualizer_test.dart` asserting:
  - Visualizer mounts with default week.
  - Dragging the week scrubber updates displayed week and biometric stats.
  - CustomPainter renders without throwing exception during animation ticks.
- [ ] Implement `Aurora3DWombVisualizer` in `lib/views/baby_tracker/widgets/aurora_3d_womb_visualizer.dart`:
  - Mathematical 3D projection engine (`_WombOrbPainter`):
    - Latitude and longitude spherical harmonic rings projected with 3D perspective (`Matrix4.identity()..rotateX(..)..rotateY(..)`).
    - Depth sorting for ring segments and particles.
    - Glowing translucent amniotic fluid radial gradient.
    - Pulsating Doppler cardiac core driven by an `AnimationController` (simulating 140 bpm heartbeat).
    - Biometric fetal scale avatar morphing by gestational week:
      - Weeks 1–4: Microscopic blastocyst orb.
      - Weeks 5–12: Embryonic curve with cranial node and limb buds.
      - Weeks 13–27: Developed fetus with anatomical proportions.
      - Weeks 28–40: Full-term neonatal curled posture.
  - Mouse/touch drag listener for interactive yaw & pitch rotation with smooth spring-back / idle precession.
  - Biometrics HUD Header: Gestational Week badge, CRL (cm), BPD (cm), EFW (g/kg), fruit scale comparison (e.g., Week 33 = Nanas 🍍), and trimester indicator.
  - Interactive week slider (Week 1–40) with fast tick jumps.
- [ ] Run `flutter test test/aurora_3d_womb_visualizer_test.dart` and verify passing.
- [ ] Run `flutter analyze` and ensure 0 issues.
- [ ] Commit: `feat(portal): add interactive 3D Matrix4 Aurora3DWombVisualizer engine`.

---

### Task 3: Integrate into `BabyTrackerHomepage` and `UserBabyTrackerDialog`
**Files to modify:**
- `lib/views/baby_tracker/baby_tracker_homepage.dart`
- `lib/views/user/user_baby_tracker_dialog.dart`

**Detailed Steps:**
- [ ] In `BabyTrackerHomepage`:
  - Embed `Aurora3DWombVisualizer` as an interactive hero visualizer banner above the tabs with expand/collapse toggle.
  - Wire week scrubber callback to filter the patient reports list by selected gestational week/trimester.
  - Replace `_openEditTemplateItemDialog` and `_openAddTemplateItemDialog` calls with `TemplateItemEditorDialog.show(...)`.
  - Upgrade category accordion rows: Add Dr. Aurora specs chips, hover elevation, and clean action icons.
- [ ] In `UserBabyTrackerDialog`:
  - In Tab 0 (Tendangan), embed the mini 3D Womb orb alongside the patient's gestational week card, showing anatomical scale for that specific mother.
- [ ] Run `flutter analyze` across `klinik-aurora-portal` (0 issues).
- [ ] Run all portal tests (`flutter test`).
- [ ] Commit: `feat(portal): integrate 3D visualizer and modernized dialogs into baby tracker pages`.

---

### Task 4: Full Verification, Web Build & Deployment
**Steps:**
- [ ] Run `flutter analyze` to ensure 0 errors/warnings.
- [ ] Run `flutter test` to ensure all tests pass.
- [ ] Compile production web release:
  ```bash
  cd /Users/aminariff/Documents/Github/klinik-aurora-portal && /Users/aminariff/fvm/versions/3.47.5/bin/flutter build web --release
  ```
- [ ] Deploy to Firebase Hosting:
  ```bash
  firebase deploy --project klinik-aurora --only hosting:production
  ```
- [ ] Verify live URL: `https://klinik-aurora.web.app`.
- [ ] Commit and push all changes to `origin/main`.
- [ ] Report final status to user.
