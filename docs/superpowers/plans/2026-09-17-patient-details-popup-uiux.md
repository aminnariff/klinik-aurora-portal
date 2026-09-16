# Patient Details Popup UI/UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign and modernize the patient popup dialog (`UserDetail`) with clean 640px modal, patient avatar, reactive IC auto-detection (age/gender/DOB chips), quick stats, responsive 2-column layout (preserving raw mobile number), and update the menu label from "Appointment" to "Book Appointment".

**Architecture:** Refactor `lib/views/user/user_detail.dart` from rigid `IntrinsicWidth`/`Wrap` scaling to a centered, responsive `Dialog` with header, stats banner, scrollable form, and fixed actions. Update menu item in `lib/views/user/user_homepage.dart`.

**Tech Stack:** Flutter Web, Dart, GetX, Custom UI Components (`AppTypography`, `AppColors`, `InputField`, `AppDropdown`).

---

### Task 1: Update Action Menu Label in User Homepage

**Files:**
- Modify: `lib/views/user/user_homepage.dart:527-529`

- [ ] **Step 1: Update menu item label**
Change `_menuItem('appointment', Icons.calendar_today_outlined, 'Appointment')` to `_menuItem('appointment', Icons.calendar_today_outlined, 'Book Appointment')`.

- [ ] **Step 2: Verify with flutter analyze**
Run: `/Users/aminariff/fvm/cache.git/bin/flutter analyze lib/views/user/user_homepage.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit change**
```bash
git add lib/views/user/user_homepage.dart
git commit -m "fix(user): rename Appointment action to Book Appointment in patient table"
```

---

### Task 2: Implement IC Parsing and Demographic Helper in UserDetail

**Files:**
- Modify: `lib/views/user/user_detail.dart`

- [ ] **Step 1: Add IC demographic parser logic**
Add helper methods to extract:
- Date of Birth (`DD-MM-YYYY` and `DateTime`) from the first 6 digits (`YYMMDD`).
- Age in years calculated from extracted birth year.
- Gender from 12th digit (`odd = Male`, `even = Female`).
- Real-time listener on document ID controller updating reactive state.

- [ ] **Step 2: Verify logic with tests/analyzer**
Run: `/Users/aminariff/fvm/cache.git/bin/flutter analyze lib/views/user/user_detail.dart`

- [ ] **Step 3: Commit**
```bash
git add lib/views/user/user_detail.dart
git commit -m "feat(user): add reactive IC demographic parser for age and gender"
```

---

### Task 3: Redesign UserDetail Dialog Layout and Styling

**Files:**
- Modify: `lib/views/user/user_detail.dart`

- [ ] **Step 1: Replace rigid IntrinsicWidth layout with Dialog container**
  - Use `Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 640, maxHeight: 0.88 * height), ...))`
  - Build header banner with patient avatar circle (initials with gradient), full name, status badge (`Active`/`Inactive`), close button, and auto-derived demographic chips (Age, Gender, DOB).
  - Build quick stats row for existing patients (Registered branch, Total appointments count, Points balance).
  - Build 2-column form grid:
    - Col 1: Full Name, Document ID (NRIC/Passport), Date of Birth (auto-populated from IC).
    - Col 2: Contact Number (raw text input, preserving original input without forced +60 formatting), Email Address, Branch dropdown.
  - Build account status switch card (in update mode).
  - Build footer action bar with Reset Password (left) and Cancel / Save buttons (right).

- [ ] **Step 2: Verify form submissions work properly**
  - Verify `UserController.createUser` and `UserController.updateUser` bindings and loading indicators.
  - Verify phone number is passed directly without alteration.

- [ ] **Step 3: Commit**
```bash
git add lib/views/user/user_detail.dart
git commit -m "feat(user): modernize patient details dialog UI/UX with responsive layout"
```

---

### Task 4: Static Analysis and Verification

**Files:**
- None (verification only)

- [ ] **Step 1: Run flutter analyze on whole project**
Run: `/Users/aminariff/fvm/cache.git/bin/flutter analyze`
Expected: 0 errors

- [ ] **Step 2: Commit any cleanups if needed**
```bash
git status
```
