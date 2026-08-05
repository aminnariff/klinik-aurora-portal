# Announcement Center — Design

**Date:** 2026-08-05
**Status:** Approved

## Problem

The announcement dialog (`lib/views/notification/notification_homepage.dart`, opened from
the top-bar bell / "Announcement" menu in `homepage.dart`) is a single form with three defects:

1. **Null-channel crash.** Tapping "Send" without selecting a channel executes
   `final category = _channel!;` — a null-assertion that surfaces as a red screen in
   debug and a silent no-op in release. The dropdown starts unselected.
2. **No send feedback.** The send has no loading state; a slow API call leaves the
   dialog unresponsive, and the only outcome is a generic success/error toast.
3. **No history.** `GET /admin/notification` exists in the API (used by no UI) but the
   portal offers no way to see what was previously announced.

## Core idea

Replace the single form with a tabbed **Announcement Center**: a **Compose** tab running a
3-step wizard (channel → compose with live phone-style preview → review & confirm) and a
**History** tab listing previously sent announcements. Step gating (disabled buttons)
replaces the null-assertion; the live preview shows admins exactly what a subscriber sees.

## Decisions (confirmed with product owner)

- **Container:** a tabbed dialog (segmented Compose | History) opened from the existing
  top-bar bell / Announcement menu. No new route, no new permission UUID — access stays
  super-admin only (`isSuperAdmin`), as today.
- **Wizard:** exactly 3 steps — Channel, Compose, Review & confirm.
- **History:** read-only list from the existing `GET /admin/notification` endpoint,
  newest first. No edit / re-send / delete (no backend support; non-goal).
- **Validation:** Next / Send buttons disabled until their step's requirements are met.
  Channel required at step 1; title required at step 2; body optional (the API only
  rejects when both title and body are missing).
- **Scope:** portal repo only. No changes to `membership-api` or `klinik-aurora-mobile`.

## User flow

Entry: super-admin taps the bell icon or Announcement menu item → Announcement Center
dialog opens on the **Compose** tab, step 1.

### Step 1 — Channel

Two selectable cards, mutually exclusive:

- **All Users** (`general`) — "Everyone who has the app installed".
- **Signed In Users** (`authorised-user-announcements`) — "Users who are signed in".

Each card shows an icon, name, and description; the selected card gets a highlighted
border (secondary color) and a checkmark. **Next** is disabled until a card is selected.
A footnote explains delivery: "Subscribers receive this as a push notification on their
phone."

### Step 2 — Compose

- **Title:** single-line field, 60-char limit, live counter.
- **Content:** multi-line field, 200-char limit (as today), live counter.
- **Live preview:** a phone-style mockup (rounded device frame, status bar, app icon,
  "Klinik Aurora" app name, bold title, 2-line ellipsized body, "now" timestamp) that
  re-renders on every keystroke. Desktop: right of the form; mobile: below it.
- **Next** enabled only when title is non-empty. **Back** returns to step 1.

### Step 3 — Review & confirm

Summary card showing the selected channel (name + audience note), the full title, and the
full body, plus the phone preview for a final look. **Back** / **Send Announcement**
(gradient `Button`, primaryColors). On tap:

- Button enters a loading state (spinner, actions disabled) while the POST is in flight.
- Success → existing `showDialogSuccess` ("Notification successfully sent to <channel>…");
  on dismiss the wizard resets to step 1 with cleared fields for the next announcement.
- Failure → existing `showDialogError` with the server's `message` when the response
  carries one; the wizard stays on step 3 so the admin can retry.

### History tab

- Fetches `GET /admin/notification` **every time the tab becomes active** (tab switch
  triggers a fresh fetch), so sends made in Compose appear without a manual refresh; a
  refresh icon also re-fetches.
- Rows: title, description (ellipsized), formatted created date (`dd MMM yyyy, hh:mm a`).
- Empty state: "No announcements sent yet."
- Error state: message + Retry button.

## Architecture

### Files (all under `lib/views/notification/` unless noted)

| File                                                        | Responsibility                                                                                                                 |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `notification_homepage.dart`                                | Tabbed container (segmented Compose \| History), wizard step state (current step, selected channel, title/content controllers) |
| `notification_channel_step.dart`                            | Step 1 channel cards                                                                                                           |
| `notification_compose_step.dart`                            | Step 2 title/content fields + counters                                                                                         |
| `notification_preview.dart`                                 | Phone-style notification mockup (shared by step 2 and step 3)                                                                  |
| `notification_review_step.dart`                             | Step 3 summary + Send                                                                                                          |
| `notification_history_tab.dart`                             | History list, empty/error/loading states                                                                                       |
| `lib/controllers/notification/notification_controller.dart` | Add static `fetchHistory()` next to existing `send()`                                                                          |
| `lib/models/notification/notification_history.dart`         | New model for history items                                                                                                    |

### State

Dialog-local `StatefulWidget` state (current step, `DropdownAttribute? _channel`,
`TextEditingController`s) — no provider plumbing, consistent with how the dialog already
behaves. The send path is unchanged: `NotificationController.send(context, topic: …,
title: …, body: …)` → `POST admin/notification/send/topic`.

### Data flow

```
Compose tab: select channel → compose (preview live) → review → send()
   → showConfirmDialog → POST → responseCode() ? showDialogSuccess + reset wizard
                                       : showDialogError (server message if present)
History tab: open → fetchHistory() → GET admin/notification → list / empty / error
```

## API contract

- **Send** (unchanged): `POST {appUrl}admin/notification/send/topic`
  body `{topic, title, body}`; response `{message, id}`.
- **History** (new to the UI, existing endpoint): `GET {appUrl}admin/notification`
  → `{message, data: [{notificationId, notificationTitle, notificationDesciption,
createdDate}], totalCount, totalPage}`.
  - The API aliases `notification_description` as **`notificationDesciption`**
    (typo, missing "r") — the model must parse that exact key.
  - No query params → API returns all rows, newest first. Pagination is out of scope
    for this iteration.

## Validation & error handling

- Step gating: Next/Send disabled until channel chosen (step 1) and title non-empty
  (step 2) — eliminates the `_channel!` null-assertion entirely.
- Send failures: `responseCode(value.code)` false → `showDialogError` with the server
  message when available; wizard stays on step 3.
- History fetch failures: inline error state with Retry (does not block Compose).
- Network/timeout behaviour inherited from the existing `ApiController`.

## Testing

- **Widget test** (`test/notification/announcement_wizard_test.dart`): step 1 Next
  disabled with no channel; step 2 Next disabled with empty title; channel selection
  enables Next. (Project has a test harness — `test/widget_test.dart` and
  `test/practitioner_schedule/`.)
- `fvm flutter analyze` must stay clean.
- Manual QA checklist: send to each channel (staging), history shows the new row,
  empty/error states, mobile layout (preview below form), rapid double-tap on Send.

## Non-goals

- Scheduling, drafts, audience counts.
- Edit / re-send / delete of past announcements (no API support).
- Mobile inbox persistence for topic announcements (needs `membership-api` change —
  separate decision).
- Mobile unsubscribe toggle (separate repo).
