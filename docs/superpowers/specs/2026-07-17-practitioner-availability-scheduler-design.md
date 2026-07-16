# Practitioner Availability Scheduler — Design

**Date:** 2026-07-17
**Status:** Approved

## Problem

Appointment slots are configured per service-branch, one at a time, via the calendar
dialog (`lib/views/widgets/calendar/multi_time_calendar.dart`). For a branch with many
active services under the same practitioner (e.g. all Doctor services), staff must
re-key the same schedule repeatedly. The existing "Sync Configuration" dialog does not
solve this because it:

1. Copies the **exact same datetimes** to every selected service, ignoring each
   target's own interval (`serviceTime`) — a 60-minute service ends up with
   30-minute-spaced slots (acknowledged by the dialog's own warning text).
2. Lists all active services with **manual selection** — it does not group by
   practitioner type (`doctorType`), even though the field exists on the
   service-branch model.
3. Discards the reusable part: the practitioner's **availability window**
   (days, time ranges, breaks) is thrown away once the generator expands it into
   concrete datetimes. Saved templates live in device-local `SharedPreferences`.

## Core idea

**Stop syncing slots; sync the availability window.** What services under the same
practitioner share is the practitioner's availability window (e.g. "Doctor: Mon–Fri
09:00–17:00, break 13:00–14:00"). What differs per service is only the slot interval.
The new flow captures the window once, then generates each service's slots from the
shared window using that service's own interval.

## Decisions (confirmed with product owner)

- **Granularity:** per practitioner **type** (Doctor / Sonographer / Therapist /
  Spa Therapist / Dietitian), not per individual practitioner. Slots remain attached
  to `serviceBranchId`; no doctor–slot link is introduced.
- **Conflict rule:** **replace within period, keep the rest.** Applying a schedule
  for a period wipes each target service's existing slots inside that period and
  replaces them; slots outside the period are untouched.
- **No backend changes.** The feature is a smarter front door over the existing
  `admin/service-branch` and `admin/service-available-datetime` endpoints.
- The existing per-service calendar dialog remains available for one-off edits.

## User flow

Entry: a **"Practitioner Schedule"** button on the Service page toolbar
(`lib/views/service/service_homepage.dart`), opening a full-screen dialog wizard
(same presentation as the existing `MultiTimeCalendarPage` dialog). No new route or
permission UUID; access is inherited from the Service page.

### Step 1 — Scope

- **Branch:** defaulted from the logged-in user's `branchId`; a branch dropdown is
  shown only when the user is not branch-bound (HQ).
- **Practitioner type:** dropdown built from the `doctorType` enum in
  `lib/views/widgets/global/global.dart` (1 Doctor, 2 Sonographer, 3 Therapist,
  4 Spa Therapist, 5 Dietitian).
- **Period:** start month + number of months (1–3), matching the existing 3-month
  slot horizon.

### Step 2 — Availability pattern

Weekly availability window: which days, one or more time ranges per day, breaks,
with the existing "Master Timing" weekday/weekend shortcut. **No interval at this
step** — the window only.

The last-used pattern is persisted per branch + practitioner type in
`SharedPreferences` under `practitioner_pattern_<branchId>_<doctorType>` and
preloaded on the next visit. (Device-local; this is the piece that would move
server-side in a future backend iteration.)

### Step 3 — Targets & preview

Targets are loaded via `ServiceBranchController.getAll(branchId: ...)` and filtered
client-side to `serviceBranchStatus == 1 && doctorType == selectedType`. Each row
shows:

- checkbox (default ticked)
- service name
- **interval field prefilled from that service's `serviceTime`** (via the existing
  `convertToMinutes` logic), editable per row
- live preview slot count (pattern × interval × period)
- amber warning when the service already has slots inside the period:
  "existing &lt;period&gt; slots will be replaced"

### Save (fan-out)

For each ticked service, sequentially with progress feedback:

1. Expand pattern × service interval × period → new datetimes
   (UTC ISO-8601, past dates filtered — same rule as `filterPastMonths`).
2. `GET admin/service-available-datetime?serviceBranchId=...` → keep existing
   datetimes **outside** the period, drop those inside.
3. Merged list → existing `create` / `update` endpoint (create when no
   `serviceBranchAvailableDatetimeId` exists, update otherwise) — same call pattern
   as the current sync loop.

Finish with a per-service success/failure summary (not just a count) so a failed
service is visible and can be retried.

Expected behavior note: because each service keeps its own interval, slot *times*
will differ across services within the same window (09:00/09:45/10:30 for a 45-min
service vs 09:00/10:00/11:00 for a 60-min one). This is intended.

## Code layout

- `lib/views/practitioner_schedule/practitioner_schedule_wizard.dart`
  — the dialog wizard (plus small per-step widgets in the same folder).
- `lib/views/widgets/calendar/weekly_availability_editor.dart`
  — pattern editor **extracted from** `WeeklySlotGenerator`
  (`lib/views/service/slot_generator.dart`); returns a pattern object
  (`day → [TimeRange]`, breaks) instead of expanded datetimes.
  `WeeklySlotGenerator` is refactored to compose this widget so there is a single
  source of truth for the pattern UI.
- `lib/controllers/practitioner_schedule/practitioner_schedule_helper.dart`
  — pure functions: pattern → slot expansion, and replace-within-period merge.
  I/O reuses `ServiceBranchController` and `ServiceBranchAvailableDtController`;
  no new `ChangeNotifier` provider is required.

## Error handling

- Empty pattern or zero targets → save disabled with inline explanation.
- Fan-out failures are collected per service and shown in the summary; successes
  are not rolled back (each service is an independent record, matching current
  sync behavior).
- All datetimes stored as UTC ISO-8601, consistent with
  `_getAllDateTimeValues()` in the existing calendar.

## Testing

Unit tests on `practitioner_schedule_helper.dart`:

- expansion for intervals 30/45/60/90 within a window
- breaks excluded from generated slots
- month/period boundaries (slots strictly inside the selected period)
- local→UTC conversion round-trip
- merge rule: slots outside the period preserved, inside replaced
- past-date filtering

Wizard UI verified manually (per-service intervals, warning display, partial-failure
summary).

## Out of scope (explicitly)

- Per-individual-practitioner schedules (no doctorId–slot link).
- Server-side schedule storage / backend endpoint changes (future Option C).
- Changes to the existing per-service calendar or its sync dialog.
