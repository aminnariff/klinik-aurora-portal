# Calendar Redesign — Appointment Google Calendar-Style View

## Overview

Redesign the calendar view on the Appointment page to be more like Google Calendar's month view: dense day cells with appointment chips, a toggle between full-width and side-by-side layouts, and WhatsApp access from the detail dialog.

## Motivation

The current `TableCalendar` view occupies ~70% of the screen vertically with sparse day cells (only red dot markers). Users must scroll to see appointments for a selected day. The table view's WhatsApp action column is hidden when switching to calendar mode.

## Changes

### 1. Calendar Layout Toggle (Full-Width ↔ Side-by-Side)

A new toggle button inside the calendar view switches between two layouts:

**Full-Width Mode:**

- Month calendar grid takes ~55% of the available vertical space
- Below it: selected day summary bar + appointment list (same as current flow)
- Each day cell shows appointment chips

**Side-by-Side Mode:**

- Month calendar grid on the left (~40% width)
- Appointment list on the right (~60% width)
- Both visible at the same time — no scrolling needed to see appointments
- Ideal for wider screens / tablets / desktops

**Toggle placement:** Next to the existing Table/Calendar toggle in the action bar.

### 2. Dense Google Calendar-Style Month Cells

Replace the current sparse day cells (empty cells with red dots) with compact, information-dense cells:

- **Appointment chips** — Up to 3 colored chips per day cell, each showing:
  - Status-colored left bar (blue=booked, green=completed, amber=no-show, red=cancelled)
  - Time (e.g., "10am")
  - Patient name (truncated to fit)
- **+N overflow** — When more than 3 appointments exist, a "+2 more" label appears
- **Tap behavior:**
  - Tap a chip → open Appointment Details dialog directly for that appointment
  - Tap empty area / day number → select the day (populates the appointment list)
- **Colors** — Chips use `appointmentStatusColors` from `config/color.dart`

### 3. WhatsApp Button in Detail Dialog

Add a WhatsApp icon button in the Appointment Details dialog header.

**Placement:** In the header bar, between the Copy button and the Close button.

**Behavior:**

- Only visible in "update" mode (i.e., existing appointment, not create)
- Opens the existing `showWhatsAppTemplateDialog` with patient data pre-filled
- Needs access to `ServiceController` for template retrieval (same as table view)

**Data passed:**

- `name` ← `appointment.user.userFullName`
- `phone` ← `appointment.user.userPhone`
- `service` ← `appointment.service.serviceName`
- `branchName` ← `appointment.branch.branchName`
- `branchPhone` ← `appointment.branch.branchPhone`
- `dateTime` ← `appointment.appointmentDatetime`

### 4. Files Modified

| File                                                   | Change                                                                                                                |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `lib/views/appointment/appointment_calendar_view.dart` | Rework into full Google Calendar-style view with chip cells, layout toggle (full/side-by-side), persistent preference |
| `lib/views/appointment/appointment_homepage.dart`      | Pass service templates fetch context to the detail dialog (minimal change)                                            |
| `lib/views/appointment/create_appointment.dart`        | Add WhatsApp icon button in detail dialog header, wire up template fetch and `showWhatsAppTemplateDialog`             |

### 5. User Preference

Layout preference (full-width vs side-by-side) for the current session via `_isSideBySide` state variable in `AppointmentCalendarView`.

### 6. Non-Goals

- No changes to the table view
- No changes to appointment CRUD logic
- No changes to the date filter bar, stats strip, or tab system
- No changes to the backend API

## Verification

1. Toggle between table view and calendar view — existing behavior preserved
2. Toggle full-width / side-by-side within calendar view — layout switches correctly
3. Appointments appear as colored chips in day cells with time + name
4. Tapping a chip opens the detail dialog directly
5. WhatsApp button appears in detail dialog and opens the template dialog
6. "+N more" overflow shows when >3 appointments on a day
