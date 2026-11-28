# Klinik Aurora product tour

An interactive walkthrough of the portal for new staff. Each chapter plays a task
on a copy of the real screens (a cursor clicks and types, a panel explains each
step). Clicking the screen pauses the tour so staff can try it themselves.

Everything runs in the browser with made-up data. Nothing is sent to the API and
nothing is saved, so staff can't affect real patients, bookings or payments.

It is served by the portal itself at `/tour/`. Staff reach it from the
"New here? Take the product tour" link on the login page, or from
"Product Tour" in the account menu.

## Run, build, deploy

```bash
cd tour
npm install        # first time only
npm run dev        # http://localhost:5173/tour/
npm run build      # writes the built tour into ../web/tour
```

`web/tour` is checked in, so the usual deploy is unchanged: `flutter build web`
copies `web/tour` into `build/web/tour`, and `firebase deploy` serves it.
Rebuild the tour (`npm run build`) whenever you change it.

## How it is put together

| Path | What it is |
| --- | --- |
| `src/app/` | The replica: sidebar, top bar, pages and dialogs, styled from `DESIGN.md` and `lib/config/app_colors.dart`. |
| `src/app/data.ts` | Seed data. Branches, services, prices and rewards follow the real setup; every patient and practitioner is made up (NRICs use state code `00`, which is never issued). |
| `src/app/store.ts` | Replica state and actions (add patient, book, award points, claim reward). |
| `src/tour/chapters.ts` | The chapters and their step scripts. |
| `src/tour/engine.ts` | Playback: pause/resume, speed, the fake cursor, typing and clicking. |
| `src/tour/TourShell.tsx` | The player around the replica. |

## Adding a chapter

1. Build the screen in `src/app/pages` (and any dialogs in `src/app/dialogs`),
   copying the Flutter view. Add `data-tour="…"` to every element a script
   needs to reach.
2. Route it in `Page()` in `src/app/AppFrame.tsx`.
3. Replace the chapter's `planned(...)` entry in `src/tour/chapters.ts` with
   steps. Each step has the sentence shown in the panel and a script:

   ```ts
   {
     text: 'Open Patients and press Add Patient.',
     run: async (c) => {
       await c.click('nav-patients');
       await c.click('add-patient');
     },
   }
   ```

   `c.click`, `c.type`, `c.move` and `c.wait` drive the replica the same way a
   person would, so a step that works when played also works after someone
   explores and presses Play again.

When a portal screen changes, update its copy here so the tour stays accurate.
