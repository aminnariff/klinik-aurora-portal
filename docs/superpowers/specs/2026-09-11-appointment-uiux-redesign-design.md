# Appointment UI/UX Redesign Specification

**Date:** 2026-09-11  
**Author:** Antigravity  
**Status:** Approved by User  
**Target Repository:** `klinik-aurora-portal`  

---

## 1. Overview & Objectives

Optimize the Appointment Homepage and Appointment Details Popup to improve daily operational workflow for clinic receptionists and admins:
1. **Reduce vertical clutter on the Homepage**: Consolidate 4 vertically stacked toolbars into 2 compact rows, giving clinic staff immediate visibility into 10+ rows instead of 5–6 on laptop screens.
2. **Improve table ergonomics**: Make entire table rows clickable to open appointment details directly. Maintain existing row styling and status colors.
3. **Streamline details modal**: Refactor the modal into a responsive 2-column layout on desktop/tablet to eliminate vertical scrolling, while keeping clean stacked cards on mobile.
4. **Context-aware status handling**: Surface clear status banners and quick transition actions (`Mark Completed`, `Mark No-Show`) for active appointments, while locking completed, cancelled, and transferred appointments with clear audit trails.

---

## 2. Requirements & Design Decisions

### A. Appointment Homepage (`appointment_homepage.dart`)
1. **Toolbar Consolidation**:
   - **Row 1 (Controls)**:
     - Branch Selector (for Superadmin) — clean text label "Branch", no emojis/icons.
     - Date Range Selector — clean text label "Date", no emojis/icons.
     - Filter button (opens existing detailed filter panel) with active filter badge.
     - Reset filter button (↺).
     - Action buttons: "Check Slots", "Calendar View", "Refresh" (↻).
   - **Row 2 (Tabs)**:
     - Tabs: `Upcoming`, `Completed`, `No-Show`, `Cancelled` with live count badges.
     - Remove "Potential Sales" chip (per user requirement to keep the view clean).
     - Remove "Stats Strip" above the tabs (redundant with the tab counts and saves 70px vertical space).
2. **Table Ergonomics**:
   - Make the entire `DataRow2` clickable via `onTap` / `onSelectChanged`, opening the appointment details dialog.
   - Maintain existing table colors, font styles, and badge designs.
   - Retain WhatsApp quick button and action menu for compatibility.

### B. Appointment Details Modal (`create_appointment.dart`)
1. **Responsive Layout**:
   - **Desktop / Tablet (`!isMobile`)**: 2-Column Split:
     - **Left Column (~300px)**:
       - Patient Profile: Full Name, Phone (with direct link/action), Email, NRIC.
       - Booking Deposit & Payment: Deposit amount paid vs outstanding, payment channel, receipt viewer.
       - Record Metadata: Created timestamp, Created By (Staff vs Self-booked), Last Modified.
     - **Right Column (Remaining width)**:
       - Schedule Form: Branch, Service, Practitioner Type, Assigned Doctor, Appointment Date & Time, Reschedule button.
       - Customer Notes & Admin Remarks.
       - Patient Feedback & Rating (visible when Completed).
   - **Mobile (`isMobile`)**:
     - Maintain single-column vertical flow with clean card-based groupings (Header, Patient, Schedule, Deposit, Actions).
2. **Status Contexts & Action Buttons**:
   - **Upcoming (Active)**:
     - Prominent blue `Upcoming` badge in header.
     - Quick Action buttons in header/action row: `[✓ Mark Completed]` and `[Mark No-Show]`.
   - **Completed**:
     - Green `Completed` badge.
     - Star rating & patient feedback visible.
     - All scheduling inputs locked.
   - **Cancelled**:
     - Red `Cancelled` badge.
     - Cancellation reason banner displayed.
     - Inputs locked read-only; status transition buttons hidden.
   - **Transferred / Rescheduled**:
     - Purple `Transferred` badge.
     - Destination branch banner with clickable link to parent or new appointment (`#APT-XXXX ↗`).

### C. Deployment Constraints
- **Frontend (`klinik-aurora-portal`)**: DO NOT deploy to Firebase Hosting production. Code changes will remain local for user review and testing.
- **Backend (`membership-api`)**: No backend changes required; if any auxiliary API tweaks are made, backend may deploy, but frontend remains undeployed.

---

## 3. Implementation Breakdown

1. **`lib/views/appointment/appointment_homepage.dart`**:
   - Remove `_buildStatsStrip()` call from `_buildBody()`.
   - Redesign `_buildBranchBar()` and `_buildDateFilterBar()` into a unified compact control bar.
   - Add `onTap` callback to `DataRow2` in `_buildDataRow()` to open `_handleMenuSelection("update", item)`.
2. **`lib/views/appointment/create_appointment.dart`**:
   - Restructure `editBranch()` layout:
     - Wrap dialog body in responsive condition: if `isMobile`, render stacked card layout; else render 2-column flex/grid.
     - Surface status banner and quick status actions in the modal header.
     - Move booking deposit and payment section to the left column.
     - Group record metadata (Created, Created By, Last Updated) neatly below payment info.

---

## 4. Verification Plan

1. **Static Analysis**: Run `fvm flutter analyze` to guarantee 0 issues.
2. **Local Testing**:
   - Verify layout responsiveness across desktop viewport (1280px+), laptop (1024px), and mobile (400px).
   - Verify row clickability: clicking any appointment row opens the details modal.
   - Verify all appointment statuses (Upcoming, Completed, Cancelled, Transferred) display their respective banners and action states accurately.
