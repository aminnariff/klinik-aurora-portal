# Design Spec: Aurora Baby Admin Portal UI Overhaul & Interactive 3D Fetal Womb Orb

- **Date:** 2026-10-21
- **Target Repository:** `klinik-aurora-portal`
- **Status:** Approved / In Planning

---

## 1. Executive Summary & Goals

The Aurora Baby administrative portal currently suffers from unstyled, prototype-tier form dialogs (raw underline `TextField`s, squished checkboxes, and lack of visual hierarchy) and lacks engaging visual representation of fetal gestational milestones for clinic doctors and staff.

This project delivers:
1. **Interactive 3D Fetal Womb Orb Engine (`Aurora3DWombVisualizer`)**:
   - A GPU-accelerated 3D custom painter engine rendering an interactive rotating amniotic womb sphere, dynamic biometric scaling across gestational weeks 1–40, simulated Doppler cardiac pulse, and biometric HUD.
   - User interaction: Full 3D yaw/pitch mouse drag rotation, auto-rotation idle loop, and interactive gestational scrubber.
   - Built with pure Flutter vector math (`Matrix4` 3D perspective projection) ensuring 60fps performance on Flutter Web without heavy external WebGL assets.
2. **Executive Redesign of Template Add & Edit Dialogs**:
   - Replaces the cramped, raw dialog with a modern 720px-wide 2-column card dialog.
   - Clean filled input fields (`Color(0xFFF8FAFC)` fill, subtle outline border, icon prefixes).
   - Modern selectable card switches with rose/cyan illumination for **Item WAJIB** and **Beg Hospital**.
   - Categorized Dr. Aurora clinical guidance cards (Spesifikasi, Keselamatan, Tip Penjimatan) with themed accent badges.
   - Responsive layout with desktop-grade typography and smooth micro-interactions.

---

## 2. Component Architecture

```
lib/views/baby_tracker/
├── widgets/
│   ├── aurora_3d_womb_visualizer.dart    # Pure Flutter 3D Matrix4 Canvas Womb Orb & Scrubber HUD
│   ├── template_item_editor_dialog.dart  # Premium 2-column Add/Edit Modal Dialog
├── baby_tracker_homepage.dart            # Main Aurora Baby Admin page (Updated with 3D hero panel & dialog integration)
```

---

## 3. Detailed Specifications

### 3.1 `Aurora3DWombVisualizer` (3D Womb Orb Engine)
- **Mathematical Projection**:
  - Uses 3D sphere point-cloud and spherical harmonic latitude/longitude rings.
  - Applies 3D rotation matrix around X and Y axes derived from user mouse drag or automatic idle precession.
  - Depth-sorting ($z$-buffering) for rings and particles to ensure natural 3D occlusion.
- **Visual Appearance**:
  - Outer membrane: Translucent rosy-golden amniotic fluid gradient with subtle specular sheen.
  - Inner core: Pulsating Doppler cardiac node beating rhythmically (simulating 140 bpm).
  - Biometric Fetal Avatar: Vector geometry scaling progressively from blastocyst (Week 4), embryonic limb buds (Week 8), early fetus (Week 14), to term baby posture (Week 40).
- **Gestational Scrubber & Biometrics HUD**:
  - Interactive slider selecting Week 1 to Week 40.
  - Displays Crown-Rump Length (CRL), Biparietal Diameter (BPD), Estimated Fetal Weight (g/kg), fruit size comparison, and trimester milestone badge.
  - Quick action to auto-filter patient reports table to mothers in that trimester/week.

### 3.2 `TemplateItemEditorDialog` (Executive Modal Redesign)
- **Dialog Shell**:
  - Width: 720px (responsive up to 92vw on smaller displays).
  - Background: Pure white with soft rose subtle header gradient (`Color(0xFFFFF1F4)` to `Colors.white`).
  - Rounded corners: `BorderRadius.circular(24)`.
  - Elevation & shadow: Soft diffused multi-stop shadow (`BoxShadow(color: Color(0xFFE84C7A).withValues(alpha: 0.12), blurRadius: 24)`).
- **Left Column — Maklumat Item & Kategori**:
  - Title input with label, placeholder, and prefix icon.
  - Category picker dropdown with visual emojis and item count indicators.
  - Recommended quantity counter / input with unit badge.
  - Card Switch 1: **Item WAJIB** (Rose gradient border when active, verified icon badge, description).
  - Card Switch 2: **Beg Hospital** (Cyan gradient border when active, medical bag icon badge, description).
- **Right Column — Panduan Klinikal Dr. Aurora**:
  - Grouped card container with Dr. Aurora branding badge.
  - **Spesifikasi**: Input with soft blue/slate accent card (e.g., 100% organic cotton, breathable).
  - **Keselamatan**: Input with soft amber accent card (e.g., safety limits, choking hazards).
  - **Tip Penjimatan**: Input with soft emerald accent card (e.g., bulk buying, newborn size growth warning).
- **Actions**:
  - "Batal" subtle text button.
  - "Simpan Perubahan" / "Tambah Item" gradient pill button with hover elevation.

---

## 4. Performance & Flutter Web Optimization
- All 3D transformations are rendered directly via `Canvas.drawPath` and `Canvas.drawCircle` using hardware-accelerated Skia/CanvasKit.
- `AnimationController` throttles to screen refresh rate (60Hz) and pauses automatically when widget is offstage or tab is inactive.
- Zero external package dependencies required (`crypto`, `math`, `flutter/material`).

---

## 5. Verification & Acceptance Criteria
1. `flutter analyze` passes with 0 issues across `klinik-aurora-portal`.
2. Both "Tambah Item" and "Kemaskini Item" dialogs render the new 2-column layout flawlessly.
3. 3D Womb Orb smoothly rotates via mouse drag and updates HUD biometrics on slider drag.
4. CRUD operations (Create, Update, Delete) continue working with the backend database.
5. Production web build compiles cleanly with `flutter build web --release` and deploys live to Firebase Hosting.
