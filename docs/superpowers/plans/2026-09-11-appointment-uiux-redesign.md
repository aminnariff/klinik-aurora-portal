# Appointment UI/UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate the Appointment Homepage toolbar into 2 compact rows, make table rows clickable, and refactor the appointment details modal into a responsive 2-column layout (desktop) with contextual status badges and quick actions.

**Architecture:** Frontend Flutter refactoring inside `klinik-aurora-portal`. Reorganize widget hierarchies in `appointment_homepage.dart` and `create_appointment.dart` without modifying backend API contracts or adding heavy client-side queries.

**Tech Stack:** Flutter Web, Dart, Provider, DataTable2, easy_localization.

---

### Task 1: Appointment Homepage Toolbar & Clickable Rows

**Files:**
- Modify: `lib/views/appointment/appointment_homepage.dart`

- [x] **Step 1: Consolidate `_buildBranchBar` and `_buildDateFilterBar` into single unified toolbar**
  - Combine Branch selector (for Superadmin) and Date filter dropdown into a single responsive Row.
  - Remove emoji and icons from Branch and Date labels for clean typography.
  - Integrate Filter modal trigger, Reset filter, Check Slots, Calendar View, and Refresh into the right-hand action cluster.
  - Remove `_buildStatsStrip()` from `_buildBody()`.

- [x] **Step 2: Clean up tab bar**
  - Ensure tabs `Upcoming`, `Completed`, `No-Show`, `Cancelled` maintain their badges.
  - Remove Potential Sales chip from the view.

- [x] **Step 3: Enable whole-row clickability on appointment table**
  - In `_buildDataRow(context, item, index, authController)`, add `onTap: () => _handleMenuSelection("update", item)` to `DataRow2`.
  - Ensure WhatsApp button continues to handle its own tap event without conflicting with row tap.

- [x] **Step 4: Run flutter analysis**
  - Run: `fvm flutter analyze`
  - Expected: `No issues found!`

- [x] **Step 5: Commit changes**
  - Run: `git commit -am "feat(appointment): consolidate homepage toolbar and make table rows clickable"`

---

### Task 2: Appointment Details Modal Two-Column & Context-Aware Status Redesign

**Files:**
- Modify: `lib/views/appointment/create_appointment.dart`

- [x] **Step 1: Add prominent status banner & quick actions in modal header**
  - In `editBranch()`, show status badge in header.
  - For active appointments (`appointmentStatus == 1`), add quick status transition buttons: `[✓ Mark Completed]` and `[Mark No-Show]` with confirmation prompt.
  - For cancelled appointments (`appointmentStatus == 2`), show red cancellation reason alert banner and lock fields.
  - For transferred/rescheduled appointments (`appointmentStatus == 7 || 8`), show branch destination info with original/new appointment reference link.

- [x] **Step 2: Implement responsive 2-column layout for desktop**
  - For `!isMobile`:
    - Left Column (fixed width ~280px): Patient profile card, Booking deposit status card with receipt button, and Record Info (Created, Created By, Last Updated).
    - Right Column (Expanded): Appointment schedule form, Practitioner selection, Date & Time picker, Customer note, and Admin remarks.
  - For `isMobile`:
    - Clean stacked cards maintaining single-column scrolling.

- [x] **Step 3: Quick status action handlers**
  - Implement `_quickUpdateStatus(int newStatus)` that calls `AppointmentController.updateStatus` and refreshes parent table upon success.

- [x] **Step 4: Run flutter analysis**
  - Run: `fvm flutter analyze`
  - Expected: `No issues found!`

- [x] **Step 5: Commit changes**
  - Run: `git commit -am "feat(appointment): responsive 2-column layout and quick actions for appointment details"`

---

### Task 3: Local Verification & Review Walkthrough

- [ ] **Step 1: Run static analysis across entire project**
  - Run: `fvm flutter analyze`
  - Expected: `No issues found!`

- [ ] **Step 2: Test local build without deploying**
  - Run: `fvm flutter build web --release`
  - Confirm: Build succeeds cleanly. **DO NOT DEPLOY TO PRODUCTION** (per user constraint).

- [ ] **Step 3: Create Walkthrough documentation**
  - Update `walkthrough.md` with visual breakdown and guide for local review.
