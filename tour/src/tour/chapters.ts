import type { Role } from '../app/data';
import type { useApp } from '../app/store';
import type { Ctx } from './engine';

export interface Step { text: string; run: (ctx: Ctx) => Promise<void> }
export interface Chapter {
  id: string;
  group: string;
  title: string;
  icon: string;
  color: string;
  summary: string;
  role: Role;
  /** Feature no longer used in the portal; kept for reference and skipped by autoplay. */
  discontinued?: boolean;
  setup?: (app: ReturnType<typeof useApp.getState>) => void;
  steps: Step[];
}

export type Audience = 'staff' | 'superadmin';
export const audienceOf = (c: Chapter): Audience => (c.role === 'superadmin' ? 'superadmin' : 'staff');

const FRONT = 'Front desk';
const MOTHERS = 'Mothers & babies';
const BILLING = 'Billing';
const SETUP = 'Clinic setup';
const HQ = 'HQ setup';
const LOYALTY = 'Loyalty & marketing';
const REPORTS = 'Reports';

/** dd-mm-yyyy for the last day of next month, typed into date fields. */
function endOfNextMonth() {
  const t = new Date();
  const d = new Date(t.getFullYear(), t.getMonth() + 2, 0);
  return `${String(d.getDate()).padStart(2, '0')}-${String(d.getMonth() + 1).padStart(2, '0')}-${d.getFullYear()}`;
}

const C = { start: '#246e7a', front: '#7e2d40', mothers: '#db2777', billing: '#059669', setup: '#0e7490', super: '#4f46e5' };


const ALL: Chapter[] = [
  {
    id: 'find-your-way', group: 'Getting started', title: 'Find your way around', icon: 'explore', color: C.start, role: 'frontdesk',
    summary: 'Your day starts on the dashboard. The sidebar takes you to every screen, and Quick Search gets you there faster.',
    steps: [
      {
        text: 'Every screen is in the sidebar. Main holds the four you use all day: Dashboard, Appointments, Patients and Points.',
        run: async (c) => {
          for (const t of ['nav-dashboard', 'nav-appointments', 'nav-patients', 'nav-points']) { await c.move(t, { at: [0.3, 0.5] }); await c.wait(380); }
        },
      },
      {
        text: 'The dashboard shows today at your branch: how many patients have been seen, who is still coming, and the next patients in line.',
        run: async (c) => { await c.move('kpi-seen'); await c.wait(1100); await c.move('next-patients', { at: [0.5, 0.35] }); await c.wait(1300); },
      },
      {
        text: 'The other screens sit in groups. Click a group heading to open or close it.',
        run: async (c) => { await c.click('group-vouchers'); await c.wait(700); await c.move('nav-rewards', { at: [0.3, 0.5] }); await c.wait(700); await c.click('group-vouchers'); await c.wait(400); },
      },
      {
        text: 'Quick Search (⌘K) jumps straight to any screen. Type what you need and pick it from the list.',
        run: async (c) => { await c.click('quick-search'); await c.wait(400); await c.type('palette-input', 'points'); await c.wait(600); await c.click('palette-points'); await c.wait(600); },
      },
      {
        text: 'Working late? Switch to dark mode from the top bar. Press it again to switch back.',
        run: async (c) => { await c.click('dark-toggle'); await c.wait(1600); await c.click('dark-toggle'); await c.wait(300); },
      },
    ],
  },
  {
    id: 'register-patient', group: FRONT, title: 'Register a new patient', icon: 'person_add', color: C.front, role: 'frontdesk',
    summary: 'New walk-in? Register them once and they can book, earn points and use the Aurora mobile app.',
    steps: [
      {
        text: 'Open Patients from the sidebar and press Add Patient.',
        run: async (c) => { await c.click('nav-patients', { at: [0.3, 0.5] }); await c.wait(500); await c.click('add-patient'); await c.wait(400); },
      },
      {
        text: 'Type the full name, contact number, NRIC or passport number, and email. Every field marked * is required.',
        run: async (c) => {
          await c.type('reg-name', 'Farhanah Binti Zainal');
          await c.type('reg-phone', '0174452360');
          await c.type('reg-nric', '970918005412');
          await c.type('reg-email', 'farhanah.z@example.com');
        },
      },
      {
        text: 'Add the date of birth, choose the branch the patient registers at, and give them a username for the mobile app.',
        run: async (c) => {
          await c.type('reg-dob', '18-09-1997');
          await c.click('reg-branch'); await c.wait(300);
          await c.click('reg-branch-opt-br-bukitrimau');
          await c.type('reg-username', 'farhanah.z');
        },
      },
      {
        text: 'Press Register Patient. The new patient appears at the top of the list, ready to book.',
        run: async (c) => {
          await c.click('reg-submit'); await c.wait(1300);
          await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(500);
          await c.move('patient-row-new', { at: [0.2, 0.5] }); await c.wait(1200);
        },
      },
    ],
  },
  {
    id: 'book-appointment', group: FRONT, title: 'Book an appointment', icon: 'event_available', color: C.front, role: 'frontdesk',
    setup: (app) => app.go('patients'),
    summary: 'Book a scan or consultation from the patient list: pick the service, choose a free slot, and record the booking fee.',
    steps: [
      {
        text: 'On Patients, search for the patient by name or number, then open the ⋯ menu on their row.',
        run: async (c) => { await c.type('patient-search', 'Siti Hajar'); await c.wait(500); await c.click('row-menu-pt-2'); await c.wait(400); },
      },
      {
        text: "Choose Book Appointment. The patient's name, phone and email are already filled in.",
        run: async (c) => { await c.click('menu-book'); await c.wait(600); await c.move('appt-patient', { at: [0.3, 0.3] }); await c.wait(900); },
      },
      {
        text: 'Your branch is set for you. Pick the service, a 5D Scan here. For pregnancy scans the due date comes from Baby Tracker.',
        run: async (c) => {
          await c.move('appt-branch', { at: [0.4, 0.5] }); await c.wait(500);
          await c.click('appt-service'); await c.wait(300);
          await c.click('appt-service-opt-sv-5d'); await c.wait(600);
          await c.move('appt-edd', { at: [0.3, 0.2] }); await c.wait(1100);
        },
      },
      {
        text: 'Open Slots to see the free dates. Pick a date, then a time, and press Continue. The screen checks the pregnancy week for you.',
        run: async (c) => {
          await c.click('appt-slot'); await c.wait(500);
          if (c.count('slot-day-') < 6) { await c.click('slot-next'); await c.wait(400); }
          await c.clickNth('slot-day-', 4); await c.wait(500);
          await c.click('slot-time-1'); await c.wait(400);
          await c.click('slot-continue'); await c.wait(600);
          await c.move('appt-gestation', { at: [0.5, 0.5] }); await c.wait(1500);
        },
      },
      {
        text: 'A 5D Scan has a RM 50 booking fee. Tick that you collected it and key in the receipt number.',
        run: async (c) => { await c.click('appt-fee-collected', { at: [0.05, 0.5] }); await c.wait(300); await c.type('appt-receipt', 'BR-20417'); },
      },
      {
        text: 'Press Create Appointment. The booking now shows under Upcoming on the Appointments screen.',
        run: async (c) => {
          await c.click('appt-create'); await c.wait(1300);
          await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400);
          await c.click('nav-appointments', { at: [0.3, 0.5] }); await c.wait(700);
          await c.move('appt-row-new', { at: [0.15, 0.5] }); await c.wait(1300);
        },
      },
    ],
  },
  {
    id: 'award-points', group: FRONT, title: 'Award points & offer rewards', icon: 'stars', color: C.front, role: 'frontdesk',
    summary: "After every payment, award loyalty points. The screen tells you when the patient can claim a reward, so you can offer it on the spot.",
    steps: [
      {
        text: 'Open Points. Look the patient up by mobile number (or MyKad) and press Find Patient.',
        run: async (c) => { await c.click('nav-points', { at: [0.3, 0.5] }); await c.wait(400); await c.type('pos-input', '0167723410'); await c.click('pos-find'); await c.wait(500); },
      },
      {
        text: 'Select the patient. Their balance shows straight away, with every reward and how many points they still need.',
        run: async (c) => { await c.click('pos-select-pt-1'); await c.wait(600); await c.move('pos-balance', { at: [0.3, 0.5] }); await c.wait(800); await c.move('rewards-panel', { at: [0.5, 0.2] }); await c.wait(1200); },
      },
      {
        text: 'Key in the bill amount or tap a preset: RM 1 earns 1 point. If this payment unlocks a reward, the screen says so. Mention it to the patient.',
        run: async (c) => { await c.click('pos-preset-150'); await c.wait(600); await c.move('unlock-banner', { at: [0.4, 0.5] }); await c.wait(1800); },
      },
      {
        text: 'Press Award Points and confirm. The patient gets a WhatsApp receipt with the new balance.',
        run: async (c) => {
          await c.click('pos-award'); await c.wait(500);
          await c.click('confirm-yes'); await c.wait(900);
          await c.move('award-success', { at: [0.5, 0.6] }); await c.wait(900);
          await c.click('award-done'); await c.wait(500);
        },
      },
      {
        text: 'At 2,050 points the RM20 treatment voucher is now available. If the patient wants the discount, press Claim and confirm. The points come off right away.',
        run: async (c) => {
          await c.move('reward-rw-rm20', { at: [0.4, 0.5] }); await c.wait(900);
          await c.click('claim-rw-rm20'); await c.wait(600);
          await c.click('claim-confirm'); await c.wait(1000);
          await c.move('activity-log', { at: [0.5, 0.22] }); await c.wait(1400);
        },
      },
    ],
  },
  {
    id: 'appointment-tools', group: FRONT, title: 'Check slots, calendar & guideline', icon: 'calendar_month', color: C.front, role: 'frontdesk',
    setup: (app) => app.go('appointments'),
    summary: 'The coloured buttons on the Appointments screen are quick tools: free slots for any service, a calendar layout, the front-desk playbook, and payment issues.',
    steps: [
      {
        text: 'Patient calling to ask what is free? Press Check Slots (green) and pick a service to see its free dates and times, without booking anything.',
        run: async (c) => {
          await c.move('appt-tool-slots'); await c.wait(700);
          await c.click('appt-tool-slots'); await c.wait(500);
          await c.click('checkslot-sv-abdomen'); await c.wait(500);
          if (c.count('slot-day-') < 4) { await c.click('slot-next'); await c.wait(400); }
          await c.clickNth('slot-day-', 2); await c.wait(500);
          await c.move('slot-times', { at: [0.5, 0.5] }); await c.wait(1000);
          await c.click('slot-close'); await c.wait(300);
          await c.click('checkslots-close'); await c.wait(400);
        },
      },
      {
        text: 'The purple button switches the layout between the table and a calendar. Each day shows how many bookings it has; tap a day to see them.',
        run: async (c) => {
          await c.move('appt-tool-layout'); await c.wait(600);
          await c.click('appt-tool-layout'); await c.wait(700);
          await c.clickNth('cal-day-has-', 1); await c.wait(500);
          await c.move('cal-list', { at: [0.4, 0.2] }); await c.wait(1100);
        },
      },
      {
        text: 'Press it again to go back to the table. The portal remembers the layout you like.',
        run: async (c) => { await c.click('appt-tool-layout'); await c.wait(700); },
      },
      {
        text: 'Guideline opens the front-desk playbook: bookings, status updates, cancellations and refunds, transfers, and the end-of-shift checklist.',
        run: async (c) => {
          await c.move('appt-tool-guide'); await c.wait(500);
          await c.click('appt-tool-guide'); await c.wait(600);
          await c.click('guide-step-1'); await c.wait(500); await c.move('guide-rule', { at: [0.4, 0.5] }); await c.wait(1000);
          await c.click('guide-step-2'); await c.wait(500); await c.move('guide-rule', { at: [0.4, 0.5] }); await c.wait(1000);
          await c.click('guide-check-0'); await c.wait(200); await c.click('guide-check-1'); await c.wait(300);
          await c.click('guide-done'); await c.wait(400);
        },
      },
      {
        text: 'Payment Issues (red) lists patients who paid online but whose booking never reached the schedule. Press Reclaim to put them back in.',
        run: async (c) => {
          await c.move('appt-tool-issues'); await c.wait(600);
          await c.click('appt-tool-issues'); await c.wait(700);
          await c.move('issues-table', { at: [0.3, 0.15] }); await c.wait(700);
          await c.click('issue-reclaim-mm-1'); await c.wait(500);
          await c.click('confirm-yes'); await c.wait(1000);
          await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400);
        },
      },
      {
        text: "Audit Fiuu Payments double-checks unpaid online payments against Fiuu, in case one went through without us knowing.",
        run: async (c) => { await c.click('issues-audit'); await c.wait(500); await c.click('fiuu-start'); await c.wait(1800); await c.move('fiuu-progress', { at: [0.4, 0.6] }); await c.wait(900); await c.click('fiuu-close'); await c.wait(300); },
      },
      {
        text: 'Back on Appointments, Refresh (blue) clears your filters and reloads the list.',
        run: async (c) => { await c.click('issues-back'); await c.wait(500); await c.click('tab-Completed'); await c.wait(600); await c.move('appt-tool-refresh'); await c.wait(500); await c.click('appt-tool-refresh'); await c.wait(700); },
      },
    ],
  },
  {
    id: 'todays-schedule', group: FRONT, title: "Today's schedule & check-in", icon: 'view_kanban', color: C.front, role: 'frontdesk',
    summary: "Today's Schedule is the front-desk board: every patient booked today, from arrival to checkout, in one place.",
    steps: [
      {
        text: "Open Today's Schedule from the dashboard (View Board), or find it with Quick Search.",
        run: async (c) => { await c.move('kpi-seen'); await c.wait(500); await c.click('view-board'); await c.wait(600); },
      },
      {
        text: 'Each column is a stage of the visit: Scheduled, Checked In, In Scan / Room, and Completed / No-Show. The counters show how the day is going.',
        run: async (c) => {
          for (const t of ['q-col-scheduled', 'q-col-checked_in', 'q-col-in_room', 'q-col-done']) { await c.move(t, { at: [0.5, 0.06] }); await c.wait(450); }
        },
      },
      {
        text: 'When the patient arrives, press Check In. Their card moves across and the wait time starts counting.',
        run: async (c) => { await c.click('q-checkin-ap-2'); await c.wait(700); await c.move('q-card-ap-2', { at: [0.5, 0.2] }); await c.wait(800); },
      },
      {
        text: 'When a room is free, press To Room and pick the scan or consult room. The board shows who is in which room.',
        run: async (c) => {
          await c.click('q-room-ap-1'); await c.wait(400);
          await c.click('room-scan-room-1'); await c.wait(300);
          await c.click('room-confirm'); await c.wait(700);
          await c.move('q-card-ap-1', { at: [0.5, 0.5] }); await c.wait(900);
        },
      },
    ],
  },
  {
    id: 'checkout', group: FRONT, title: 'Checkout & payment', icon: 'point_of_sale', color: C.front, role: 'frontdesk',
    setup: (app) => app.go('queue'),
    summary: 'After the scan, check the patient out: the screen works out what is left to pay, records the payment and awards points in one go.',
    steps: [
      {
        text: "When the scan is done, press Complete & Checkout on the patient's card.",
        run: async (c) => { await c.click('q-complete-ap-15'); await c.wait(600); },
      },
      {
        text: 'The balance is worked out for you: the service price minus the deposit paid online. Check the amount paid at the counter and how they paid.',
        run: async (c) => { await c.move('checkout-math', { at: [0.5, 0.8] }); await c.wait(1000); await c.move('checkout-paid'); await c.wait(500); await c.click('checkout-method-cash'); await c.wait(400); },
      },
      {
        text: 'Points are awarded on the total spend, deposit included: RM 1 = 1 point.',
        run: async (c) => { await c.move('checkout-total', { at: [0.8, 0.5] }); await c.wait(1300); },
      },
      {
        text: 'Press Complete & Award. The visit is marked Completed, the payment is recorded, and the points are credited.',
        run: async (c) => { await c.click('checkout-complete'); await c.wait(800); await c.move('checkout-done', { at: [0.5, 0.45] }); await c.wait(1100); },
      },
      {
        text: 'The screen suggests the next scan for this pregnancy. Press Book to schedule it now, or close the window.',
        run: async (c) => { await c.move('checkout-next', { at: [0.4, 0.5] }); await c.wait(1300); await c.click('checkout-close'); await c.wait(500); await c.move('q-col-done', { at: [0.5, 0.2] }); await c.wait(800); },
      },
    ],
  },
  {
    id: 'manage-appointments', group: FRONT, title: 'Reschedule, transfer or cancel', icon: 'edit_calendar', color: C.front, role: 'frontdesk',
    setup: (app) => app.go('appointments'),
    summary: 'Plans change. Reschedule, move a booking to another branch, or cancel it, all from the appointment list.',
    steps: [
      {
        text: 'Appointments lists every booking at your branch. The tabs split Upcoming, Completed, No-Show and Cancelled; the chips change the dates.',
        run: async (c) => { await c.click('tab-Completed'); await c.wait(900); await c.click('tab-Upcoming'); await c.wait(500); },
      },
      {
        text: 'To change a booking, open ⋯ on its row and choose Update.',
        run: async (c) => { await c.click('appt-menu-ap-5'); await c.wait(400); await c.click('appt-menu-update'); await c.wait(600); },
      },
      {
        text: 'Pick a new slot. The status changes to Rescheduled by itself. Each appointment can only be rescheduled once.',
        run: async (c) => {
          await c.click('appt-slot'); await c.wait(500);
          if (c.count('slot-day-') < 8) { await c.click('slot-next'); await c.wait(400); }
          await c.clickNth('slot-day-', 7); await c.wait(400);
          await c.click('slot-time-0'); await c.wait(300);
          await c.click('slot-continue'); await c.wait(600);
          await c.move('appt-status', { at: [0.4, 0.5] }); await c.wait(800);
          await c.move('appt-reschedule-note', { at: [0.3, 0.5] }); await c.wait(900);
        },
      },
      {
        text: 'Press Save Changes.',
        run: async (c) => { await c.click('appt-create'); await c.wait(1100); await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400); },
      },
      {
        text: 'Patient moving to another branch? Choose Transfer Branch, pick the branch and a free slot there, and give a reason.',
        run: async (c) => {
          await c.click('appt-menu-ap-6'); await c.wait(400);
          await c.click('appt-menu-transfer'); await c.wait(500);
          await c.click('transfer-branch'); await c.wait(300);
          await c.click('transfer-branch-opt-br-cheras'); await c.wait(400);
          await c.click('transfer-pick'); await c.wait(500);
          await c.clickNth('slot-day-', 3); await c.wait(300);
          await c.click('slot-time-1'); await c.wait(300);
          await c.click('slot-continue'); await c.wait(400);
          await c.type('transfer-reason', 'Patient moved closer to Cheras');
          await c.click('transfer-confirm'); await c.wait(1100);
          await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400);
        },
      },
      {
        text: "Can't make it at all? Open Update and set the status to Cancelled, or press Mark No-Show. The cancellation policy shows before you save.",
        run: async (c) => {
          await c.click('appt-menu-ap-7'); await c.wait(400);
          await c.click('appt-menu-update'); await c.wait(600);
          await c.move('qa-noshow'); await c.wait(700);
          await c.click('appt-status'); await c.wait(300);
          await c.click('appt-status-opt-Cancelled'); await c.wait(500);
          await c.move('appt-policy', { at: [0.4, 0.4] }); await c.wait(1300);
          await c.click('appt-create'); await c.wait(1000);
          await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(300);
          await c.click('tab-Cancelled'); await c.wait(900);
        },
      },
    ],
  },
  {
    id: 'redemption-history', group: FRONT, title: 'Hand over app rewards', icon: 'history', color: C.front, role: 'frontdesk',
    summary: 'Patients can also claim rewards in the Aurora app. Those claims wait in Redemption History until the patient collects at the counter.',
    steps: [
      {
        text: 'Open Redemption History under Vouchers & Promos. Claims made in the app show as In-Progress.',
        run: async (c) => { await c.click('group-vouchers'); await c.wait(500); await c.click('nav-redemptions', { at: [0.3, 0.5] }); await c.wait(700); await c.move('claim-row-cl-1', { at: [0.55, 0.5] }); await c.wait(800); },
      },
      {
        text: 'When the patient comes to collect, search their name and press the pencil on their claim.',
        run: async (c) => { await c.type('redeem-search', 'Nadia'); await c.wait(400); await c.click('claim-edit-cl-1'); await c.wait(500); },
      },
      {
        text: 'Hand over the reward, set the status to Completed, add a remark and press Update.',
        run: async (c) => {
          await c.click('claim-status'); await c.wait(300);
          await c.click('claim-status-opt-Completed'); await c.wait(300);
          await c.type('claim-remark', 'Collected at counter');
          await c.click('claim-save'); await c.wait(1000);
          await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400);
          await c.move('claim-row-cl-1', { at: [0.55, 0.5] }); await c.wait(1000);
        },
      },
    ],
  },
  {
    id: 'baby-tracker', group: MOTHERS, title: 'Aurora Baby Hub', icon: 'pregnant_woman', color: C.mothers, role: 'frontdesk',
    summary: 'Mothers who add their due date in the Aurora Baby app appear here, so the clinic can watch baby movement and hospital-bag readiness.',
    steps: [
      {
        text: "Open Baby Tracker. Each row is an expecting mother: her pregnancy week, today's baby kicks, and how ready her hospital bag is.",
        run: async (c) => { await c.click('nav-babyTracker', { at: [0.3, 0.5] }); await c.wait(600); await c.move('baby-kpis', { at: [0.4, 0.5] }); await c.wait(900); },
      },
      {
        text: 'Amaran Tendangan counts mothers past week 28 with fewer than 10 kicks today. Tap Pergerakan Rendah to see only them.',
        run: async (c) => { await c.move('baby-kpi-kicks'); await c.wait(800); await c.click('baby-filter-low'); await c.wait(700); },
      },
      {
        text: 'Press WhatsApp to message the mother straight away, and ask her to come in if the baby is still quiet.',
        run: async (c) => { await c.move('baby-wa-pt-7'); await c.wait(1200); },
      },
      {
        text: "Press Buka Fail to open her file: today's kicks against the KKM target of 10, and every kick session she logged.",
        run: async (c) => { await c.click('baby-open-pt-7'); await c.wait(700); await c.move('baby-kicks', { at: [0.5, 0.5] }); await c.wait(1300); },
      },
      {
        text: 'The Beg Hospital tab shows what she has packed for the ward. Tick items as she confirms them.',
        run: async (c) => {
          await c.click('baby-tab-bag'); await c.wait(500); await c.move('baby-bag', { at: [0.3, 0.5] }); await c.wait(800);
          await c.click('bag-item-bag-10', { at: [0.2, 0.5] }); await c.wait(700);
        },
      },
      {
        text: 'Templat Senarai Semak sets the checklist every mother sees in the app. Add, edit or remove items here.',
        run: async (c) => { await c.click('baby-file-close'); await c.wait(500); await c.click('baby-view-templates'); await c.wait(700); await c.move('baby-add-template'); await c.wait(1100); },
      },
    ],
  },
  {
    id: 'follow-up', group: MOTHERS, title: 'Patient follow-up & recalls', icon: 'notification_important', color: C.mothers, role: 'frontdesk',
    summary: "Patient Follow-Up finds mothers who are due for their next milestone scan but haven't booked, and members sitting on unused points.",
    steps: [
      {
        text: 'Open Patient Follow-Up. Clinical Scan Recalls lists mothers due for a milestone scan who have not booked yet.',
        run: async (c) => { await c.click('nav-followUp', { at: [0.3, 0.5] }); await c.wait(600); await c.move('fu-list', { at: [0.4, 0.1] }); await c.wait(900); },
      },
      {
        text: 'Filter by scan window: NT (weeks 11–13), Detail (18–24), 4D/5D (26–32) and Growth (33–36).',
        run: async (c) => { await c.click('fu-win-4d5d'); await c.wait(600); await c.move('fu-row-pt-2', { at: [0.25, 0.5] }); await c.wait(900); },
      },
      {
        text: 'Press Send WA + Push to remind her on WhatsApp and in the app. The card records when she was recalled.',
        run: async (c) => { await c.click('fu-send-pt-2'); await c.wait(800); await c.move('fu-row-pt-2', { at: [0.4, 0.3] }); await c.wait(1000); },
      },
      {
        text: 'Points Re-Engagement lists members with 500+ unused points and no booking. Send a points offer to bring them back.',
        run: async (c) => { await c.click('fu-tab-points'); await c.wait(600); await c.click('fu-offer-pt-1'); await c.wait(900); },
      },
      {
        text: 'Milestone Bonus Scheme shows the bonus points a mother earns for each scan she completes. Mention it when you call.',
        run: async (c) => { await c.click('fu-tab-scheme'); await c.wait(600); await c.move('fu-scheme', { at: [0.5, 0.4] }); await c.wait(1300); },
      },
    ],
  },
  {
    id: 'payment-records', group: BILLING, title: 'Payment records', icon: 'receipt_long', color: C.billing, role: 'frontdesk',
    summary: 'Payment Records totals what your branch collected: booking deposits paid online through Fiuu, and payments at the counter.',
    steps: [
      {
        text: 'Open Payment Records. The cards show checkouts, how many succeeded, what was paid and refunded, and net revenue.',
        run: async (c) => { await c.click('nav-payments', { at: [0.3, 0.5] }); await c.wait(600); await c.move('pay-stats', { at: [0.5, 0.3] }); await c.wait(900); },
      },
      {
        text: 'Pick a period with the chips: Today, Yesterday, Last 7 Days, This Month and so on.',
        run: async (c) => { await c.click('pay-range-7d'); await c.wait(800); },
      },
      {
        text: "Needs Rescue counts online payments that didn't go through. Follow those patients up before the slot is lost.",
        run: async (c) => { await c.move('pay-rescue'); await c.wait(1300); },
      },
      {
        text: 'The channel split and daily table show where the money came from. Export CSV gives you the same figures as a spreadsheet.',
        run: async (c) => { await c.move('pay-channels', { at: [0.5, 0.5] }); await c.wait(900); await c.move('pay-daily', { at: [0.5, 0.5] }); await c.wait(900); await c.click('pay-export'); await c.wait(900); },
      },
    ],
  },
  {
    id: 'daily-closing', group: BILLING, title: 'Daily closing (EOD)', icon: 'fact_check', color: C.billing, role: 'frontdesk',
    summary: "Before you go home, close the day: check today's money against today's visits and hand over to the next shift.",
    steps: [
      {
        text: "At the end of every shift, open Daily Closing (EOD). Today's net revenue is split into Fiuu online, counter and refunds.",
        run: async (c) => { await c.click('nav-eod', { at: [0.3, 0.5] }); await c.wait(600); await c.move('eod-kpis', { at: [0.5, 0.5] }); await c.wait(1000); },
      },
      {
        text: 'Check the reconciliation banner first. Here one online payment is still pending: look into it before you close.',
        run: async (c) => { await c.move('eod-banner', { at: [0.3, 0.5] }); await c.wait(1400); },
      },
      {
        text: 'The operations summary shows how the day went. Anything left Booked turns into No-Show at midnight, so update statuses first.',
        run: async (c) => { await c.move('eod-ops', { at: [0.4, 0.5] }); await c.wait(1400); },
      },
      {
        text: "The ledger lists every payment made today. Match it against the cash drawer and the card terminal's settlement slip.",
        run: async (c) => { await c.move('eod-ledger', { at: [0.5, 0.3] }); await c.wait(1400); },
      },
      {
        text: "Press Copy Shift Summary and paste it into the branch WhatsApp group, or Export CSV for the records.",
        run: async (c) => { await c.click('eod-copy'); await c.wait(1200); },
      },
    ],
  },
  {
    id: 'roster', group: SETUP, title: 'Practitioners & roster', icon: 'badge', color: C.setup, role: 'frontdesk',
    summary: 'Keep the practitioner list current and plan who works when. Patients can only book when someone is rostered.',
    steps: [
      {
        text: 'Doctors lists every practitioner at your branch, both doctors and sonographers.',
        run: async (c) => { await c.click('nav-doctors', { at: [0.3, 0.5] }); await c.wait(600); await c.move('pr-row-pr-aina', { at: [0.2, 0.5] }); await c.wait(700); },
      },
      {
        text: 'New practitioner? Press Add Practitioner and fill in the name, contact number and type, then upload a photo.',
        run: async (c) => {
          await c.click('add-practitioner'); await c.wait(400);
          await c.type('pr-name', 'Dr. Liyana Hamid');
          await c.type('pr-phone', '0137729041');
          await c.click('pr-type'); await c.wait(250); await c.click('pr-type-opt-Doctor'); await c.wait(250);
          await c.click('pr-photo'); await c.wait(400);
          await c.click('pr-save'); await c.wait(1000);
          await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400);
        },
      },
      {
        text: 'Open Branch Roster to plan shifts. Pick the practitioner, then tick every date they work.',
        run: async (c) => {
          await c.click('branch-roster'); await c.wait(600);
          await c.click('roster-doctor'); await c.wait(250); await c.click('roster-doctor-opt-pr-farah'); await c.wait(300);
          for (const n of [1, 3, 5]) { await c.clickNth('roster-day-', n); await c.wait(150); }
        },
      },
      {
        text: 'Set the shift hours. Add a second time slot to leave a lunch break.',
        run: async (c) => { await c.move('roster-slot-0', { at: [0.5, 0.5] }); await c.wait(500); await c.click('roster-add-slot'); await c.wait(500); },
      },
      {
        text: 'Press Add Shifts. The calendar on the right shows who is on duty each day.',
        run: async (c) => { await c.click('roster-save'); await c.wait(800); await c.move('roster-calendar', { at: [0.6, 0.6] }); await c.wait(1300); },
      },
    ],
  },
  {
    id: 'services', group: HQ, title: 'Services & pricing', icon: 'medical_services', color: C.setup, role: 'superadmin',
    summary: 'Services & Pricing holds every service the clinic offers: who performs it, how long it takes, the price and the booking fee.',
    steps: [
      {
        text: 'Open Services & Pricing. Each row shows the duration, price, booking fee and who performs the service.',
        run: async (c) => { await c.click('nav-services', { at: [0.3, 0.5] }); await c.wait(600); await c.move('sv-row-sv-5d', { at: [0.35, 0.5] }); await c.wait(800); },
      },
      {
        text: 'Press Add Service. Give it a name, a category, and who performs it.',
        run: async (c) => {
          await c.click('add-service'); await c.wait(400);
          await c.type('sv-name', 'Gender Scan');
          await c.click('sv-category'); await c.wait(250); await c.click('sv-category-opt-Pregnancy Scan (Baby Scan)'); await c.wait(250);
          await c.click('sv-type'); await c.wait(250); await c.click('sv-type-opt-Sonographer'); await c.wait(250);
        },
      },
      {
        text: 'Set the duration, the price, and the booking fee the patient pays online when booking. Add a short description.',
        run: async (c) => {
          await c.click('sv-duration'); await c.wait(250); await c.click('sv-duration-opt-30'); await c.wait(250);
          await c.type('sv-price', '90');
          await c.type('sv-fee', '30');
          await c.type('sv-desc', 'Penentuan jantina bayi, 18–24 minggu');
        },
      },
      {
        text: 'Press Create Service. It appears in the list and in the booking form straight away.',
        run: async (c) => { await c.click('sv-save'); await c.wait(1000); await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400); await c.move('sv-row-new', { at: [0.3, 0.5] }); await c.wait(900); },
      },
    ],
  },
  {
    id: 'branch-timing', group: SETUP, title: 'Branch timing rules', icon: 'timer', color: C.setup, role: 'frontdesk',
    summary: 'Each branch can tune how long a service takes, use different timing on weekends or special dates, and limit a service to morning or afternoon bookings.',
    steps: [
      {
        text: 'Open Services & Pricing. The time column is how long each booking takes at your branch; Custom means you changed the HQ default.',
        run: async (c) => { await c.click('nav-services', { at: [0.3, 0.5] }); await c.wait(600); await c.move('sv-row-sv-abdomen', { at: [0.25, 0.5] }); await c.wait(800); },
      },
      {
        text: 'Click the time to change it for your branch only. Other branches keep the HQ default.',
        run: async (c) => { await c.click('sv-time-sv-abdomen'); await c.wait(600); },
      },
      {
        text: 'Pick a preset or type your own duration. Here the Abdomen Scan gets 45 minutes.',
        run: async (c) => { await c.click('dur-45'); await c.wait(300); await c.move('dur-willbe', { at: [0.2, 0.5] }); await c.wait(800); },
      },
      {
        text: 'Abdomen scans need 6–8 hours of fasting, so open mornings only: choose First Half (< 12 PM). The Aurora app then hides afternoon slots for it.',
        run: async (c) => { await c.click('session-first_half'); await c.wait(400); await c.move('session-box', { at: [0.5, 0.85] }); await c.wait(1200); },
      },
      {
        text: 'Turn on Advanced Timing Rules for a different duration on weekends, or on a special date such as a promo day.',
        run: async (c) => {
          await c.click('adv-toggle'); await c.wait(400);
          await c.click('adv-weekend'); await c.wait(250); await c.click('adv-weekend-opt-60'); await c.wait(300);
          await c.click('adv-add-date'); await c.wait(400);
          await c.click('adv-date-dur-0'); await c.wait(250); await c.click('adv-date-dur-0-opt-30'); await c.wait(400);
        },
      },
      {
        text: 'Press Save Duration. The service now shows Custom and Rules Active. Staff can still book an afternoon slot at the counter after confirming.',
        run: async (c) => { await c.click('dur-save'); await c.wait(1000); await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400); await c.move('sv-time-sv-abdomen', { at: [0.4, 0.5] }); await c.wait(1100); },
      },
    ],
  },
  {
    id: 'service-timing', group: HQ, title: 'Slot calendar (old)', icon: 'schedule', color: C.super, role: 'superadmin', discontinued: true,
    setup: (app) => app.go('services'),
    summary: "Discontinued: the per-service slot calendar is no longer used. Branches now set timing with Change Duration (Branch staff tab → Branch timing rules). Kept here for reference.",
    steps: [
      {
        text: 'On Services, open ⋯ on a service and choose Update Branch Service.',
        run: async (c) => { await c.click('sv-menu-sv-5d'); await c.wait(400); await c.click('menu-branch-service'); await c.wait(700); },
      },
      {
        text: 'Each card is a time of day; the dates under it are the days patients can book that time. Tap a date to close it, for example a public holiday.',
        run: async (c) => { await c.move('slot-card-0', { at: [0.2, 0.15] }); await c.wait(700); await c.clickNth('slot-chip-0-', 5); await c.wait(500); await c.clickNth('slot-chip-1-', 5); await c.wait(700); },
      },
      {
        text: 'To set up weeks at once, open the Generator. Choose the gap between slots, the working hours with a lunch break, and which days.',
        run: async (c) => {
          await c.click('slot-generator'); await c.wait(500);
          await c.click('gen-interval'); await c.wait(250); await c.click('gen-interval-opt-60'); await c.wait(300);
          await c.move('gen-lunch'); await c.wait(500);
          await c.click('gen-days-weekdays'); await c.wait(400);
        },
      },
      {
        text: 'Press Generate All Slots, check the new times, then Save All. The booking form picks them up straight away.',
        run: async (c) => { await c.click('gen-run'); await c.wait(800); await c.move('slot-cards', { at: [0.4, 0.3] }); await c.wait(1000); await c.click('slot-save'); await c.wait(1000); },
      },
    ],
  },
  {
    id: 'find-your-way-hq', group: 'Getting started', title: 'HQ overview', icon: 'explore', color: C.start, role: 'superadmin',
    summary: 'Superadmin sees every branch and has extra HQ screens for setup, loyalty, marketing and reports.',
    steps: [
      {
        text: 'The dashboard opens on the network view: revenue, appointments, doctors on duty and patients across every clinic.',
        run: async (c) => { await c.move('content', { at: [0.4, 0.2] }); await c.wait(1300); },
      },
      {
        text: 'The sidebar has HQ-only screens: Branches, Campaigns, Promotions, Staff Accounts and Activity Logs.',
        run: async (c) => { for (const t of ['nav-branches', 'nav-campaigns', 'nav-promotions', 'nav-staff', 'nav-activity']) { await c.move(t, { at: [0.3, 0.5] }); await c.wait(450); } },
      },
      {
        text: 'Quick Search (⌘K) jumps to any screen. Type what you need and pick it.',
        run: async (c) => { await c.click('quick-search'); await c.wait(400); await c.type('palette-input', 'campaign'); await c.wait(500); await c.click('palette-campaigns'); await c.wait(700); },
      },
    ],
  },
  {
    id: 'promotions', group: LOYALTY, title: 'Promotions', icon: 'campaign', color: C.super, role: 'superadmin',
    summary: 'Promotions are the banners patients see in the Aurora app. Featured ones pop up full-screen when the app opens.',
    steps: [
      {
        text: 'Open Promotions. Active banners show to patients; the star marks ones featured when the app opens.',
        run: async (c) => { await c.click('nav-promotions', { at: [0.3, 0.5] }); await c.wait(600); await c.move('promo-card-pm-1', { at: [0.5, 0.4] }); await c.wait(900); },
      },
      {
        text: 'Press New Promotion. Write the title and a short description of the offer.',
        run: async (c) => { await c.click('add-promo'); await c.wait(400); await c.type('promo-title', 'Pakej Imbasan Gender'); await c.type('promo-desc', 'Imbasan gender + gambar 4D dari RM89. Tempah melalui aplikasi.'); },
      },
      {
        text: 'Upload the banner image. Portrait images work best on phones.',
        run: async (c) => { await c.click('promo-banner'); await c.wait(800); },
      },
      {
        text: 'Set the end date. Turn on Featured to show it as a pop-up when patients open the app.',
        run: async (c) => { await c.type('promo-to', endOfNextMonth()); await c.click('promo-featured'); await c.wait(500); },
      },
      {
        text: 'Press Create Promotion. Patients see it straight away.',
        run: async (c) => { await c.click('promo-save'); await c.wait(1000); await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400); await c.move('promo-card-new', { at: [0.5, 0.4] }); await c.wait(1000); },
      },
    ],
  },
  {
    id: 'campaigns', group: LOYALTY, title: 'Campaigns & events', icon: 'celebration', color: C.super, role: 'superadmin',
    summary: 'Campaigns boost points for a season, such as double points in Merdeka month, and can re-theme the patient app.',
    steps: [
      {
        text: 'Open Campaigns. A live campaign multiplies the points every patient earns.',
        run: async (c) => { await c.click('nav-campaigns', { at: [0.3, 0.5] }); await c.wait(600); await c.move('camp-list', { at: [0.4, 0.15] }); await c.wait(900); },
      },
      {
        text: 'Press New Campaign. Name it, set the dates, and pick a point multiplier.',
        run: async (c) => { await c.click('add-campaign'); await c.wait(400); await c.type('camp-name', 'Hari Ibu Double Points'); await c.click('camp-mult-2'); await c.wait(400); },
      },
      {
        text: "Choose the app colours. The preview shows how the patient's app will look.",
        run: async (c) => { await c.click('camp-primary-BE185D'); await c.wait(300); await c.click('camp-accent-0EA5E9'); await c.wait(300); await c.move('camp-preview', { at: [0.5, 0.3] }); await c.wait(1100); },
      },
      {
        text: 'Press Create Campaign. It switches on automatically on the start date.',
        run: async (c) => { await c.click('camp-save'); await c.wait(1000); await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400); },
      },
    ],
  },
  {
    id: 'vouchers', group: LOYALTY, title: 'Vouchers', icon: 'confirmation_number', color: C.super, role: 'superadmin',
    summary: 'Vouchers are discount codes patients redeem in the app, either free or in exchange for points.',
    steps: [
      {
        text: 'Open Vouchers. Each voucher has a code, its points price and whether it is active.',
        run: async (c) => { await c.click('nav-vouchers', { at: [0.3, 0.5] }); await c.wait(600); await c.move('voucher-row-vc-1', { at: [0.2, 0.5] }); await c.wait(800); },
      },
      {
        text: 'Press Add Voucher. Name it and set the code patients will enter (10 characters at most).',
        run: async (c) => { await c.click('add-voucher'); await c.wait(400); await c.type('voucher-name', 'DISKAUN RM15 PAP SMEAR'); await c.type('voucher-code', 'PAPSMEAR15'); },
      },
      {
        text: 'Set how many points it costs and when it ends.',
        run: async (c) => { await c.type('voucher-points', '1500'); await c.type('voucher-to', endOfNextMonth()); },
      },
      {
        text: 'Press Create Voucher.',
        run: async (c) => { await c.click('voucher-save'); await c.wait(1000); await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400); await c.move('voucher-row-new', { at: [0.3, 0.5] }); await c.wait(900); },
      },
    ],
  },
  {
    id: 'rewards-catalog', group: LOYALTY, title: 'Rewards catalog', icon: 'redeem', color: C.super, role: 'superadmin',
    summary: 'Rewards are what patients can claim with their points, at the counter or in the app.',
    steps: [
      {
        text: 'Open Rewards. Each reward shows the points it costs and how many are left.',
        run: async (c) => { await c.click('nav-rewards', { at: [0.3, 0.5] }); await c.wait(600); await c.move('reward-row-rw-rm20', { at: [0.3, 0.5] }); await c.wait(800); },
      },
      {
        text: 'Press Add Reward. Give the name, a description, the points it costs, and the stock (0 means unlimited).',
        run: async (c) => {
          await c.click('add-reward'); await c.wait(400);
          await c.type('reward-name', 'Botol Susu Anti-Kolik');
          await c.type('reward-desc', 'Botol susu 240ml dengan injap anti-kolik.');
          await c.type('reward-points', '2500');
          await c.type('reward-qty', '40');
        },
      },
      {
        text: 'Press Create Reward. Front desk sees it on the Points screen as soon as a patient has enough points.',
        run: async (c) => { await c.click('reward-save'); await c.wait(1000); await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400); await c.move('reward-row-new', { at: [0.3, 0.5] }); await c.wait(900); },
      },
    ],
  },
  {
    id: 'staff-accounts', group: HQ, title: 'Staff accounts & permissions', icon: 'admin_panel_settings', color: C.super, role: 'superadmin',
    summary: 'Every portal login is a staff account. Its role and permissions decide which screens that person can open.',
    steps: [
      {
        text: 'Open Staff Accounts. Branch accounts, HQ staff and their roles are listed here.',
        run: async (c) => { await c.click('nav-staff', { at: [0.3, 0.5] }); await c.wait(600); await c.move('staff-row-ad-3', { at: [0.2, 0.5] }); await c.wait(800); },
      },
      {
        text: 'Press Add Admin and fill in the name, username, password and email.',
        run: async (c) => {
          await c.click('add-admin'); await c.wait(400);
          await c.type('staff-name', 'Nur Aina Yusof');
          await c.type('staff-username', 'aina.br');
          await c.type('staff-password', 'Aurora123');
          await c.type('staff-confirm', 'Aurora123');
          await c.type('staff-email', 'aina@example.com');
        },
      },
      {
        text: 'Choose the branch, then a role. The role ticks the right permissions; you can still tick or untick single ones.',
        run: async (c) => {
          await c.click('staff-branch'); await c.wait(250); await c.click('staff-branch-opt-br-bukitrimau'); await c.wait(300);
          await c.click('staff-role-clinic'); await c.wait(400); await c.move('staff-perms', { at: [0.5, 0.4] }); await c.wait(1100);
        },
      },
      {
        text: 'Press Create Account. They can log in to the portal straight away.',
        run: async (c) => { await c.click('staff-save'); await c.wait(1000); await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400); await c.move('staff-row-new', { at: [0.2, 0.5] }); await c.wait(900); },
      },
    ],
  },
  {
    id: 'branches', group: HQ, title: 'Branches', icon: 'store', color: C.super, role: 'superadmin',
    summary: 'Branches lists every Klinik Aurora outlet. A new branch also gets its own portal login.',
    steps: [
      {
        text: 'Open Branches to see every outlet with its city and state.',
        run: async (c) => { await c.click('nav-branches', { at: [0.3, 0.5] }); await c.wait(600); await c.move('branch-row-br-bukitrimau', { at: [0.25, 0.5] }); await c.wait(800); },
      },
      {
        text: 'Opening a new outlet? Press Add Branch and enter its name, code and location.',
        run: async (c) => {
          await c.click('add-branch'); await c.wait(400);
          await c.type('branch-name', 'Klinik Aurora Kota Damansara');
          await c.type('branch-code', 'KOTADAMANSARA');
          await c.type('branch-city', 'Petaling Jaya');
          await c.click('branch-state'); await c.wait(250); await c.click('branch-state-opt-Selangor'); await c.wait(300);
        },
      },
      {
        text: 'Add the contact number and the email the branch logs in with, then press Create Branch.',
        run: async (c) => {
          await c.type('branch-phone', '0361578802');
          await c.type('branch-email', 'kotadamansara@example.com');
          await c.click('branch-save'); await c.wait(1000);
          await c.click('status-overlay', { at: [0.8, 0.85] }); await c.wait(400);
          await c.move('branch-row-new', { at: [0.25, 0.5] }); await c.wait(900);
        },
      },
    ],
  },
  {
    id: 'reports', group: REPORTS, title: 'Dashboards & reports', icon: 'insights', color: C.super, role: 'superadmin',
    summary: 'HQ sees the whole network: revenue and bookings across branches, when each branch is busiest, and every change made in the portal.',
    steps: [
      {
        text: 'As superadmin, the Dashboard covers every branch: revenue, appointments, doctors on duty and patients.',
        run: async (c) => { await c.move('content', { at: [0.5, 0.25] }); await c.wait(1300); },
      },
      {
        text: 'Peak Hours & Capacity shows when each branch is busiest. Amber and red hours need extra staff; quiet hours suit promo vouchers.',
        run: async (c) => { await c.click('nav-peakHours', { at: [0.3, 0.5] }); await c.wait(700); await c.move('peak-matrix', { at: [0.6, 0.5] }); await c.wait(1000); await c.move('peak-bottlenecks', { at: [0.4, 0.5] }); await c.wait(900); },
      },
      {
        text: 'Activity Logs records every change made in the portal: who did what, and when.',
        run: async (c) => { await c.click('nav-activity', { at: [0.3, 0.5] }); await c.wait(700); await c.move('audit-list', { at: [0.4, 0.2] }); await c.wait(1000); },
      },
      {
        text: 'Press Inspect diff to see exactly what changed, before and after.',
        run: async (c) => { await c.click('audit-inspect-au-3'); await c.wait(600); await c.move('audit-diff', { at: [0.5, 0.6] }); await c.wait(1400); },
      },
    ],
  },
];

/** Staff chapters follow a patient's day; superadmin chapters follow HQ setup → loyalty → reports. */
const ORDER = [
  // Branch staff
  'find-your-way', 'register-patient', 'book-appointment', 'manage-appointments', 'appointment-tools', 'todays-schedule', 'checkout', 'award-points', 'redemption-history',
  'baby-tracker', 'follow-up', 'payment-records', 'daily-closing', 'roster', 'branch-timing',
  // Superadmin
  'find-your-way-hq', 'services', 'branches', 'staff-accounts', 'service-timing', 'rewards-catalog', 'vouchers', 'promotions', 'campaigns', 'reports',
];
export const CHAPTERS: Chapter[] = [
  ...ORDER.map((id) => ALL.find((c) => c.id === id)!),
  ...ALL.filter((c) => !ORDER.includes(c.id)),
];
