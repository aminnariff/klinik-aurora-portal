import { create } from 'zustand';
import { HOME_BRANCH, iso, seedDb, type Appointment, type Db, type Patient, type QueueStatus, type Role } from './data';

export type Route =
  | 'dashboard' | 'queue' | 'appointments' | 'patients' | 'points'
  | 'babyTracker' | 'followUp' | 'doctors' | 'services' | 'branches' | 'peakHours'
  | 'payments' | 'eod' | 'vouchers' | 'rewards' | 'redemptions' | 'campaigns' | 'promotions'
  | 'staff' | 'activity';

export const ROUTE_TITLES: Record<Route, string> = {
  dashboard: 'Dashboard', queue: "Today's Schedule", appointments: 'Appointments', patients: 'Patients', points: 'Points',
  babyTracker: 'Baby Tracker', followUp: 'Patient Follow-Up', doctors: 'Doctors', services: 'Services & Pricing', branches: 'Branches',
  peakHours: 'Peak Hours & Capacity', payments: 'Payment Records', eod: 'Daily Closing (EOD)', vouchers: 'Vouchers', rewards: 'Rewards',
  redemptions: 'Redemption History', campaigns: 'Campaigns', promotions: 'Promotions', staff: 'Staff Accounts', activity: 'Activity Logs',
};

export interface CheckoutSummary {
  appointmentId: string; deposit: number; counterPaid: number; addons: number; discount: number; total: number; points: number; newBalance: number;
}

export type Dialog =
  | { kind: 'registerPatient' }
  | { kind: 'newAppointment'; patientId: string }
  | { kind: 'updateAppointment'; appointmentId: string }
  | { kind: 'transfer'; appointmentId: string }
  | { kind: 'slotPicker'; serviceId: string; branchId: string; onPick: (slot: string) => void }
  | { kind: 'roomPicker'; appointmentId: string }
  | { kind: 'checkout'; appointmentId: string }
  | { kind: 'checkoutDone'; summary: CheckoutSummary }
  | { kind: 'claimUpdate'; claimId: string }
  | { kind: 'status'; tone: 'success' | 'error' | 'info'; title: string; message: string; button?: string }
  | { kind: 'confirm'; title: string; message: string; confirmLabel?: string; onConfirm: () => void }
  | { kind: 'claimReward'; patientId: string; rewardId: string; onDone?: () => void }
  | { kind: 'awardSuccess'; patientId: string; earned: number; newTotal: number }
  | { kind: 'commandPalette' }
  | { kind: 'custom'; render: () => import('react').ReactNode };

interface Toast { id: number; text: string }

interface AppState {
  role: Role;
  route: Route;
  dark: boolean;
  db: Db;
  dialogs: Dialog[];
  toast: Toast | null;
  groupsOpen: Record<string, boolean>;
  highlightId: string | null;

  reset: (role?: Role) => void;
  go: (route: Route) => void;
  setDark: (dark: boolean) => void;
  toggleGroup: (key: string) => void;
  openDialog: (d: Dialog) => void;
  closeDialog: () => void;
  showToast: (text: string) => void;
  /** Apply an immutable update to the database. */
  patch: (fn: (db: Db) => Db, highlightId?: string | null) => void;
  nextId: (prefix: string) => string;

  addPatient: (p: Omit<Patient, 'id' | 'points' | 'joined' | 'active'>) => Patient;
  addAppointment: (a: Omit<Appointment, 'id' | 'created'>) => Appointment;
  updateAppointment: (id: string, patch: Partial<Appointment>) => void;
  setQueue: (id: string, queue: QueueStatus, room?: string) => void;
  checkout: (id: string, v: { counterPaid: number; addons: number; discount: number; method: string }) => CheckoutSummary;
  awardPoints: (patientId: string, points: number, description: string) => number;
  claimReward: (patientId: string, rewardId: string) => void;
}

let toastSeq = 0;
let idSeq = 100;
const staffName = (s: { role: Role }) => (s.role === 'superadmin' ? 'Super Admin' : 'Bukit Rimau');

const initialGroups = { doctors: true, billing: true, vouchers: false, staff: false };

export const useApp = create<AppState>((set, get) => ({
  role: 'frontdesk',
  route: 'dashboard',
  dark: false,
  db: seedDb(),
  dialogs: [],
  toast: null,
  groupsOpen: { ...initialGroups },
  highlightId: null,

  reset: (role = 'frontdesk') =>
    set({ role, route: 'dashboard', db: seedDb(), dialogs: [], toast: null, groupsOpen: { ...initialGroups, staff: role === 'superadmin', vouchers: role === 'superadmin' }, highlightId: null }),
  go: (route) => set({ route, dialogs: [] }),
  setDark: (dark) => set({ dark }),
  toggleGroup: (key) => set((s) => ({ groupsOpen: { ...s.groupsOpen, [key]: !s.groupsOpen[key] } })),
  openDialog: (d) => set((s) => ({ dialogs: [...s.dialogs, d] })),
  closeDialog: () => set((s) => ({ dialogs: s.dialogs.slice(0, -1) })),
  showToast: (text) => {
    const id = ++toastSeq;
    set({ toast: { id, text } });
    setTimeout(() => { if (get().toast?.id === id) set({ toast: null }); }, 2600);
  },
  patch: (fn, highlightId) => set((s) => ({ db: fn(s.db), ...(highlightId !== undefined ? { highlightId } : {}) })),
  nextId: (prefix) => `${prefix}-new-${++idSeq}`,

  addPatient: (p) => {
    const patient: Patient = { ...p, id: get().nextId('pt'), points: 0, joined: iso(new Date()), active: true };
    get().patch((db) => ({ ...db, patients: [patient, ...db.patients] }), patient.id);
    return patient;
  },
  addAppointment: (a) => {
    const appt: Appointment = { ...a, id: get().nextId('ap'), created: iso(new Date()) };
    get().patch((db) => ({ ...db, appointments: [...db.appointments, appt] }), appt.id);
    return appt;
  },
  updateAppointment: (id, p) => get().patch((db) => ({ ...db, appointments: db.appointments.map((a) => (a.id === id ? { ...a, ...p } : a)) }), id),
  setQueue: (id, queue, room) => {
    const extra: Partial<Appointment> = { queue };
    if (queue === 'checked_in') extra.checkedInAt = iso(new Date());
    if (room) extra.room = room;
    if (queue === 'no_show') extra.status = 'No-Show';
    get().updateAppointment(id, extra);
  },
  checkout: (id, v) => {
    const s = get();
    const a = s.db.appointments.find((x) => x.id === id)!;
    const svc = s.db.services.find((x) => x.id === a.serviceId)!;
    const deposit = a.payment === 'Fee Paid' ? svc.fee ?? 0 : 0;
    const total = Math.max(0, deposit + v.counterPaid);
    const points = Math.floor(total);
    s.patch((db) => ({
      ...db,
      appointments: db.appointments.map((x) => (x.id === id ? { ...x, status: 'Completed', queue: 'completed', payment: 'Paid' } : x)),
      payments: [{ id: s.nextId('py'), appointmentId: id, patientId: a.patientId, branchId: a.branchId, at: iso(new Date()), amount: v.counterPaid, channel: 'Counter', method: v.method, kind: 'Counter Payment', status: 'Successful', ref: `RC${String(Date.now()).slice(-6)}` }, ...db.payments],
    }), id);
    const newBalance = s.awardPoints(a.patientId, points, `Completed ${svc.name} — RM ${total.toFixed(2)} visit`);
    return { appointmentId: id, deposit, counterPaid: v.counterPaid, addons: v.addons, discount: v.discount, total, points, newBalance };
  },
  awardPoints: (patientId, points, description) => {
    let total = 0;
    set((s) => {
      const patients = s.db.patients.map((p) => {
        if (p.id !== patientId) return p;
        total = p.points + points;
        return { ...p, points: total };
      });
      const log = { id: `pl-new-${++idSeq}`, patientId, description, points, at: iso(new Date()), by: staffName(s) };
      return { db: { ...s.db, patients, pointsLog: [log, ...s.db.pointsLog] } };
    });
    return total;
  },
  claimReward: (patientId, rewardId) =>
    set((s) => {
      const reward = s.db.rewards.find((r) => r.id === rewardId)!;
      const patients = s.db.patients.map((p) => (p.id === patientId ? { ...p, points: p.points - reward.points } : p));
      const rewards = s.db.rewards.map((r) => (r.id === rewardId && r.left != null ? { ...r, left: r.left - 1 } : r));
      const by = staffName(s);
      const claim = { id: `cl-${++idSeq}`, patientId, rewardId, at: iso(new Date()), status: 'Completed' as const, by, remark: 'Claimed at counter' };
      const log = { id: `pl-new-${++idSeq}`, patientId, description: `Redeemed: ${reward.name}`, points: -reward.points, at: iso(new Date()), by };
      return { db: { ...s.db, patients, rewards, claims: [claim, ...s.db.claims], pointsLog: [log, ...s.db.pointsLog] } };
    }),
}));

export const homeBranch = () => useApp.getState().db.branches.find((b) => b.id === HOME_BRANCH)!;
