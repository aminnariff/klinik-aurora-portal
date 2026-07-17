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
- **Bulk save on the backend.** Instead of the frontend looping N create/update
  calls, the backend exposes one bulk endpoint that saves all target services in
  a single request (see "Save (bulk fan-out)"). Reads still use the existing
  `admin/service-branch` and `admin/service-available-datetime` endpoints.
- **Period = explicit available/expiry dates.** Staff picks a start ("available
  from") date and an end ("available until" / expiry) date, not a month count.
- The existing per-service calendar dialog remains available for one-off edits.

## User flow

Entry: a **"Practitioner Schedule"** button on the Service page toolbar
(`lib/views/service/service_homepage.dart`), opening a full-screen dialog wizard
(same presentation as the existing `MultiTimeCalendarPage` dialog). No new route or
permission UUID; access is inherited from the Service page.

### Step 1 — Practitioner & target services

- **Branch:** defaulted from the logged-in user's `branchId`; a branch dropdown is
  shown only when the user is not branch-bound (HQ).
- **Practitioner type:** dropdown built from the `doctorType` enum in
  `lib/views/widgets/global/global.dart` (1 Doctor, 2 Sonographer, 3 Therapist,
  4 Spa Therapist, 5 Dietitian).
- Selecting a type immediately lists **all active services of that type at the
  branch** (`ServiceBranchController.getAll(branchId: ...)` filtered client-side
  to `serviceBranchStatus == 1 && doctorType == selectedType`). Each row shows:
  - checkbox (default ticked)
  - service name
  - **gap/interval field prefilled from that service's `serviceTime`** (via the
    existing `convertToMinutes` logic), **editable per row**. This override is a
    deliberate feature, not a convenience: branches intentionally stretch e.g. a
    45-minute service to 60-minute gaps to buffer walk-in patients and late
    arrivals. The override affects generated slots only — it does not modify the
    service's `serviceTime`.

### Step 2 — Availability timing

- **Period:** **"Available from"** and **"Available until" (expiry)** date
  pickers. Defaults: today → end of the month two months ahead (matching the
  existing 3-month slot horizon). The range bounds slot generation and defines
  the replace-within-period window.
- **Weekly pattern:** which days, one or more time ranges per day, breaks, with
  the existing "Master Timing" weekday/weekend shortcut. **No interval at this
  step** — the window only; gaps were set per service in Step 1.
- **Manual editing:** below the pattern editor, a calendar preview of the period
  where staff can manually adjust the generated schedule before applying —
  exclude specific dates (public holiday, practitioner leave) or tweak a single
  date's time ranges. Manual edits act on the shared **window**, then each
  service's slots are generated from (pattern + manual overrides) × its own gap.
- Live per-service slot count preview, plus an amber warning on services that
  already have slots inside the period: "existing &lt;period&gt; slots will be
  replaced".

The last-used pattern is persisted per branch + practitioner type in
`SharedPreferences` under `practitioner_pattern_<branchId>_<doctorType>` and
preloaded on the next visit. (Device-local; this is the piece that would move
server-side in a future backend iteration.)

### Save (bulk fan-out)

Client side, for each ticked service:

1. Expand pattern × service interval × period (available → expiry date) → new
   datetimes (UTC ISO-8601, past dates filtered — same rule as `filterPastMonths`).
2. `GET admin/service-available-datetime?serviceBranchId=...` → keep existing
   datetimes **outside** the period, drop those inside, merge with the new slots.

Then **one** API call to a new bulk endpoint:

```
POST admin/service-available-datetime/bulk-upsert
{
  "items": [
    {
      "serviceBranchId": "...",
      "availableDatetimes": ["2026-08-03T01:00:00Z", ...]
    },
    ...
  ]
}
```

Backend contract:

- Upsert semantics per item: update the service's existing
  `service_branch_available_datetime` record if one exists, otherwise create it —
  identical outcome to today's per-service create/update, just batched.
- **Writes into the same records/tables as the existing endpoints.** The patient
  booking flow (`admin/service-available-datetime/available`) and every other
  admin read remain completely unchanged — no patient-side or admin-side rework.
- Response reports per-item success/failure so the UI can show which services
  failed and offer retry; the whole batch should run in one transaction where
  practical.

The wizard finishes with that per-service success/failure summary (not just a
count).

**Fallback:** the client-side helper is written so that, until the bulk endpoint
ships, the same merged payloads can be saved via the existing per-service
create/update loop behind a flag. This keeps frontend and backend work
independently deliverable.

Expected behavior note: because each service keeps its own interval, slot *times*
will differ across services within the same window (09:00/09:45/10:30 for a 45-min
service vs 09:00/10:00/11:00 for a 60-min one). This is intended.

## Editing flow

Two edit paths coexist:

1. **Standalone (per service):** the existing per-service calendar dialog,
   unchanged — for one-off fixes affecting a single service.
2. **Practitioner-level (re-run the wizard):** reopening Practitioner Schedule for
   the same branch + type preloads the last saved pattern, manual overrides, and
   per-service gap overrides. Staff adjusts and re-applies; the replace-within-
   period rule makes editing equivalent to re-applying.

Consequences, surfaced in the UI:

- Re-applying **overwrites standalone per-service tweaks inside the period**. The
  Step 2 warning states this explicitly: "existing slots in this period,
  including manual per-service edits, will be replaced."
- The saved pattern is device-local. Fallback (included in v1): a **"Load from
  existing service"** action in Step 2 that reconstructs the editable schedule
  from one target service's current slots (grouped by weekday/time, same
  mechanism the per-service calendar uses for `initialDateTimes`). Breaks/ranges
  are inferred, marked as reconstructed, and editable before re-applying.

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
  Reads reuse `ServiceBranchController` and `ServiceBranchAvailableDtController`;
  no new `ChangeNotifier` provider is required.
- `ServiceBranchAvailableDtController` gains one static method
  `bulkUpsert(context, List<BulkSlotItem> items)` →
  `POST admin/service-available-datetime/bulk-upsert`, following the existing
  static-method + `ApiResponse<T>` controller pattern. A small request/response
  model pair is added under `lib/models/service/`.

## Usability & production readiness

The wizard must be self-explanatory for non-technical clinic staff:

- **In-app help guide:** a Help button on each wizard step (reusing the
  `_showHelpGuide` pattern from the existing calendar) with a short illustrated
  walkthrough: what a "gap" is and why it's editable, what the pattern does, what
  "replace within period" means. Plain language, no jargon ("gap between
  appointments", not "interval").
- **Step indicator** across the top (1 Practitioner & services → 2 Timing →
  3 Confirm) so staff always know where they are and can go back without losing
  input.
- **Confirmation summary before applying:** a final review screen listing every
  affected service, its gap, its new slot count, and the period being replaced —
  the save button is on this screen, not on the editor.
- **States:** loading skeletons while services load; clear empty state when a
  type has no active services ("No active Doctor services at this branch");
  save button disabled with an inline reason whenever input is incomplete.
- **Safety:** inputs disabled during save; wizard cannot be dismissed mid-save;
  a failed bulk save shows exactly which services failed with a one-tap
  "Retry failed" that resends only those items.
- **Staff guide document:** `docs/guides/practitioner-schedule.md` — a short
  step-by-step usage guide with screenshots placeholders, written for clinic
  staff, delivered with the feature.

## Error handling

- Empty pattern or zero targets → save disabled with inline explanation.
- Expiry date before available date, or range fully in the past → validation
  error before Step 2.
- Bulk-save failures are reported per item by the backend and shown in the
  summary with a retry option for failed items only.
- All datetimes stored as UTC ISO-8601, consistent with
  `_getAllDateTimeValues()` in the existing calendar.

## Testing

Unit tests on `practitioner_schedule_helper.dart`:

- expansion for intervals 30/45/60/90 within a window
- per-service gap overrides produce differing slot times from one shared window
- breaks excluded from generated slots
- manual overrides: excluded dates yield no slots; per-date tweaked ranges win
  over the weekly pattern for that date
- period boundaries (slots strictly between available and expiry dates, inclusive)
- local→UTC conversion round-trip
- merge rule: slots outside the period preserved, inside replaced
- past-date filtering

Wizard UI verified manually (per-service intervals, warning display, partial-failure
summary).

## Out of scope (explicitly)

- Per-individual-practitioner schedules (no doctorId–slot link).
- Any change to the slot **data model** — no new schedule entity, no patient-app
  or admin-read changes. The only backend addition is the bulk-upsert endpoint
  writing to the existing structure (server-side schedule storage stays a future
  Option C).
- Changes to the existing per-service calendar or its sync dialog.
