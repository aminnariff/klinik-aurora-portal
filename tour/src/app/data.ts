// Seed data for the tour.
// Branches, services, prices and rewards follow the real clinic setup.
// Every patient, practitioner, phone number, NRIC and email is made up.
// NRICs use state code 00, which is never issued, so they cannot match a real person.

export type Role = 'superadmin' | 'frontdesk';

export interface Branch { id: string; name: string; code: string; city: string; state: string; created: string; }
export interface Service {
  id: string; name: string; category: string; description?: string; minutes: number; price: number; fee?: number;
  type: 'Sonographer' | 'Doctor'; active: boolean; created: string; pregnancy?: boolean; eddRange?: [number, number];
}
export interface Practitioner { id: string; name: string; type: 'Doctor' | 'Sonographer'; branchId: string; phone: string; joined: string; active: boolean; }
export interface Patient {
  id: string; name: string; username: string; email: string; phone: string; nric: string; dob: string;
  branchId: string | null; points: number; joined: string; active: boolean; edd?: string;
}
export type ApptStatus = 'Booked' | 'Completed' | 'No-Show' | 'Cancelled' | 'Rescheduled' | 'Transferred';
export type QueueStatus = 'scheduled' | 'checked_in' | 'in_room' | 'completed' | 'no_show';
export interface Appointment {
  id: string; patientId: string; serviceId: string; branchId: string; start: string; status: ApptStatus;
  payment: 'Paid' | 'No Payment' | 'Fee Paid'; practitionerId?: string; note?: string; receiptNo?: string; created: string;
  queue?: QueueStatus; room?: string; checkedInAt?: string; rescheduled?: boolean; adminRemark?: string; fromBranchId?: string;
}
export interface Payment {
  id: string; appointmentId?: string; patientId: string; branchId: string; at: string; amount: number;
  channel: 'Fiuu Online' | 'Counter'; method: string; kind: 'Booking Deposit' | 'Counter Payment' | 'Refund';
  status: 'Successful' | 'Pending' | 'Failed' | 'Refunded'; ref: string;
}
export interface PointsLog { id: string; patientId: string; description: string; points: number; at: string; by: string; }
export interface Reward {
  id: string; name: string; description: string; points: number; left: number | null; from: string; to: string; active: boolean; created: string;
}
export interface Claim { id: string; patientId: string; rewardId: string; at: string; status: 'Completed' | 'In-Progress'; by: string; remark: string; }

export interface KickSession { start: string; end: string; count: number; note?: string }
export interface BabyInfo { kicksToday: number; sessions: KickSession[]; bagDone: string[]; lastSync: string }
export type ChecklistCategory = 'Beg Hospital' | 'Baju' | 'Mandi' | 'Tidur' | 'Penyusuan';
export interface ChecklistItem { id: string; category: ChecklistCategory; name: string; required: boolean; tip?: string }

export type Session = 'both' | 'first_half' | 'second_half';
/** Branch-level timing for one service (change_service_duration_dialog.dart). */
export interface TimingRule { minutes?: number; weekday?: number; weekend?: number; dates: Record<string, number>; session: Session }
export const emptyTiming = (): TimingRule => ({ dates: {}, session: 'both' });

export interface Shift { id: string; practitionerId: string; branchId: string; date: string; start: string; end: string }
export interface SlotConfig { times: string[]; dates: string[] }

export interface Db {
  branches: Branch[];
  services: Service[];
  practitioners: Practitioner[];
  patients: Patient[];
  appointments: Appointment[];
  pointsLog: PointsLog[];
  rewards: Reward[];
  claims: Claim[];
  payments: Payment[];
  baby: Record<string, BabyInfo>;
  checklist: ChecklistItem[];
  recalls: Record<string, { at: string; channel: string }>;
  offers: Record<string, string>;
  shifts: Shift[];
  slotConfig: Record<string, SlotConfig>;
  timing: Record<string, TimingRule>;
  vouchers: Voucher[];
  promotions: Promotion[];
  campaigns: Campaign[];
  admins: Admin[];
  audit: AuditEntry[];
}

export const HOME_BRANCH = 'br-bukitrimau';

import { seedAdmins, seedAudit, seedCampaigns, seedPromotions, seedVouchers, type Admin, type AuditEntry, type Campaign, type Promotion, type Voucher } from './data2';

// ── Date helpers ──────────────────────────────────────────
const pad = (n: number) => String(n).padStart(2, '0');
export const startOfToday = () => { const d = new Date(); d.setHours(0, 0, 0, 0); return d; };
export const addDays = (d: Date, n: number) => { const x = new Date(d); x.setDate(x.getDate() + n); return x; };
export const at = (d: Date, h: number, m = 0) => { const x = new Date(d); x.setHours(h, m, 0, 0); return x; };
export const iso = (d: Date) => d.toISOString();
export const ymd = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const MONTH = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const DOW = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const DOW_LONG = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
export const fmtStamp = (s: string) => { const d = new Date(s); return `${pad(d.getDate())}-${pad(d.getMonth() + 1)}-${d.getFullYear()} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`; };
export const fmtDayDate = (s: string) => { const d = new Date(s); return `${DOW[d.getDay()]}, ${d.getDate()} ${MON[d.getMonth()]} ${d.getFullYear()}`; };
export const fmtLongDate = (s: string) => { const d = new Date(s); return `${DOW_LONG[d.getDay()]}, ${d.getDate()} ${MON[d.getMonth()]} ${d.getFullYear()}`; };
export const fmtMonthYear = (y: number, m: number) => `${MONTH[m]} ${y}`;
export const fmtTime = (d: Date) => { let h = d.getHours(); const ap = h >= 12 ? 'pm' : 'am'; h = h % 12 || 12; return `${h}.${pad(d.getMinutes())} ${ap}`; };
export const fmtTimeUpper = (d: Date) => { let h = d.getHours(); const ap = h >= 12 ? 'PM' : 'AM'; h = h % 12 || 12; return `${h}:${pad(d.getMinutes())} ${ap}`; };
export const fmtRange = (s: string, minutes: number) => { const d = new Date(s); return `${fmtTime(d)} - ${fmtTime(new Date(d.getTime() + minutes * 60000))}`; };
export const fmtShortDate = (s: string) => { const d = new Date(s); return `${pad(d.getDate())} ${MON[d.getMonth()]} ${d.getFullYear()}`; };
export const fmtSlot = (s: string) => { const d = new Date(s); return `${pad(d.getDate())}-${pad(d.getMonth() + 1)}-${d.getFullYear()} ${fmtTimeUpper(d)}`; };
export const rm = (n: number) => `RM ${n.toFixed(2)}`;
export const initials = (name: string) => name.split(/\s+/).filter((w) => /^[A-Za-z]/.test(w)).slice(0, 2).map((w) => w[0]!.toUpperCase()).join('');
export const durationLabel = (m: number) => (m % 60 === 0 ? `${m / 60} hour${m === 60 ? '' : 's'}` : `${m} minutes`);
export const ageOf = (dob: string) => { const d = new Date(dob); const t = new Date(); let a = t.getFullYear() - d.getFullYear(); if (t < new Date(t.getFullYear(), d.getMonth(), d.getDate())) a--; return a; };

// ── Seed ──────────────────────────────────────────────────
const branchRows: [string, string, string][] = [
  ['Ampang', 'Ampang', 'Selangor'],
  ['Bandar Sri Damansara', 'Kuala Lumpur', 'Kuala Lumpur'],
  ['Banting', 'Banting', 'Selangor'],
  ['Bukit Indah', 'Ampang', 'Selangor'],
  ['Bukit Jalil', 'Bukit Jalil', 'Kuala Lumpur'],
  ['Bukit Rimau', 'Shah Alam', 'Selangor'],
  ['Butterworth', 'Butterworth', 'Pulau Pinang'],
  ['Cheras', 'Cheras', 'Kuala Lumpur'],
  ['Damansara Damai', 'Petaling Jaya', 'Selangor'],
  ['Denai Puchong', 'Puchong', 'Selangor'],
  ['Putrajaya', 'Putrajaya', 'Putrajaya'],
  ['Sendayan', 'Seremban', 'Negeri Sembilan'],
  ['Seri Pristana', 'Sungai Buloh', 'Selangor'],
  ['Sungai Besi', 'Kuala Lumpur', 'Kuala Lumpur'],
  ['Sungai Petani', 'Sungai Petani', 'Kedah'],
];

function seedBranches(): Branch[] {
  return branchRows.map(([n, city, state], i) => ({
    id: `br-${n.toLowerCase().replace(/\s+/g, '')}`,
    name: `Klinik Aurora ${n}`,
    code: n.toUpperCase().replace(/\s+/g, ''),
    city, state,
    created: iso(at(new Date(2024, 3 + (i % 4), 5 + i), 9 + (i % 8), (i * 7) % 60)),
  }));
}

function seedServices(): Service[] {
  const c = (m: number, d: number) => iso(at(new Date(2025, m, d), 23, 30));
  return [
    { id: 'sv-5d', name: '5D Scan', category: 'Pregnancy Scan (Baby Scan)', minutes: 45, price: 120, fee: 50, type: 'Sonographer', active: true, created: c(6, 2), pregnancy: true, eddRange: [26, 32] },
    { id: 'sv-anatomy', name: 'Anatomy Scan', category: 'Pregnancy Scan (Baby Scan)', minutes: 45, price: 130, fee: 50, type: 'Sonographer', active: true, created: c(6, 2), pregnancy: true, eddRange: [18, 24] },
    { id: 'sv-anatomy-int', name: 'Anatomy Scan (Internal)', category: 'Pregnancy Scan (Baby Scan)', description: '- 28-34 minggu\n- gambar & video berwarna', minutes: 120, price: 130, fee: 50, type: 'Sonographer', active: true, created: c(9, 21), pregnancy: true, eddRange: [28, 34] },
    { id: 'sv-abdomen', name: 'Abdomen Scan', category: 'General Scan', description: '- Puasa 6–8 jam sebelum imbasan\n- Hati, pundi hempedu, buah pinggang', minutes: 30, price: 100, type: 'Sonographer', active: true, created: c(6, 3) },
    { id: 'sv-breast', name: 'Breast Scan', category: 'General Scan', minutes: 30, price: 120, fee: 50, type: 'Sonographer', active: true, created: c(6, 3) },
    { id: 'sv-combo', name: 'Combo Scan', category: 'Pregnancy Scan (Baby Scan)', minutes: 45, price: 160, fee: 50, type: 'Sonographer', active: true, created: c(6, 2), pregnancy: true, eddRange: [26, 32] },
    { id: 'sv-implanon', name: 'Implanon', category: 'Family Planning', minutes: 60, price: 700, fee: 200, type: 'Doctor', active: true, created: c(6, 2) },
    { id: 'sv-depo', name: 'Injection Depo Provera', category: 'Family Planning', minutes: 30, price: 60, type: 'Doctor', active: true, created: c(6, 2) },
    { id: 'sv-iucd', name: 'IUCD', category: 'Family Planning', minutes: 60, price: 290, fee: 50, type: 'Doctor', active: true, created: c(6, 2) },
    { id: 'sv-khatan', name: 'Khatan Lelaki – Dewasa & Kanak-Kanak', category: 'Circumcision', minutes: 20, price: 230, type: 'Doctor', active: true, created: c(6, 3) },
    { id: 'sv-papsmear', name: 'Pap Smear', category: "Women's Health", minutes: 30, price: 80, type: 'Doctor', active: true, created: c(6, 4) },
    { id: 'sv-rescan', name: 'Rescan', category: 'Pregnancy Scan (Baby Scan)', minutes: 30, price: 0, type: 'Sonographer', active: true, created: c(7, 10), pregnancy: true },
  ];
}

function seedPractitioners(): Practitioner[] {
  const j = (y: number, m: number, d: number) => iso(at(new Date(y, m, d), 10, 12));
  return [
    { id: 'pr-aina', name: 'Pn. Aina Syuhada', type: 'Sonographer', branchId: HOME_BRANCH, phone: '0172210345', joined: j(2026, 8, 10), active: true },
    { id: 'pr-mira', name: 'Pn. Mira Azlan', type: 'Sonographer', branchId: HOME_BRANCH, phone: '0136650982', joined: j(2026, 8, 8), active: true },
    { id: 'pr-farah', name: 'Dr. Farah Nadia', type: 'Doctor', branchId: HOME_BRANCH, phone: '0193318204', joined: j(2024, 8, 5), active: true },
    { id: 'pr-hidayah', name: 'Dr. Hidayah Rahim', type: 'Doctor', branchId: 'br-ampang', phone: '0145528130', joined: j(2024, 7, 13), active: true },
    { id: 'pr-mariam', name: 'Dr. Siti Mariam', type: 'Doctor', branchId: 'br-cheras', phone: '0182240517', joined: j(2024, 6, 12), active: true },
    { id: 'pr-kavya', name: 'Dr. Kavya Nair', type: 'Doctor', branchId: 'br-bukitjalil', phone: '0129947031', joined: j(2024, 6, 12), active: true },
  ];
}

const patientRows: [string, string, string, string, number, string | null][] = [
  // name, username, phone, nric, points, edd offset (days from today) — null when not pregnant
  ['Nurul Izzah Binti Ahmad', 'nurulizzah', '0167723410', '960214001284', 1900, '58'],
  ['Siti Hajar Binti Kamal', 'sitihajar', '0123004101', '980611004512', 0, '76'],
  ['Tan Mei Ling', 'meiling.tan', '0182219904', '950903007731', 450, '70'],
  ['Kavitha A/P Raman', 'kavitha.r', '0145502278', '940122003316', 3200, '56'],
  ['Aisyah Humaira Binti Rahman', 'aisyahhumaira', '0193345120', '990730001190', 120, '133'],
  ['Nur Farhana Binti Zulkifli', 'farhana.z', '0112287345', '970405002265', 0, '119'],
  ['Nadia Binti Hassan', 'nadiahassan', '0138824106', '930818006640', 5600, '36'],
  ['Lim Siew Fong', 'siewfong', '0176631258', '910227004473', 80, null],
  ['Farah Adibah Binti Yusof', 'farahadibah', '0105539921', '000512003358', 0, null],
  ['Priya A/P Suresh', 'priya.s', '0164478210', '921109005521', 650, null],
  ['Wan Nur Syafiqah', 'wansyafiqah', '0197713642', '980923002217', 0, '150'],
  ['Chong Pei Wen', 'peiwen', '0123348876', '960701004129', 900, null],
  ['Hafizah Binti Omar', 'hafizah.o', '0138890431', '890316007702', 720, null],
  ['Amirah Binti Ismail', 'amirah.i', '0116542290', '010204005518', 0, '200'],
];

function seedPatients(): Patient[] {
  const today = startOfToday();
  return patientRows.map(([name, username, phone, nric, points, edd], i) => {
    const yy = Number(nric.slice(0, 2));
    const year = yy > 30 ? 1900 + yy : 2000 + yy;
    const dob = `${year}-${nric.slice(2, 4)}-${nric.slice(4, 6)}`;
    return {
      id: `pt-${i + 1}`,
      name, username, phone, nric, dob,
      email: `${username.replace(/\./g, '')}@example.com`,
      branchId: HOME_BRANCH,
      points,
      joined: iso(at(addDays(today, -6 - i * 9), 9 + (i % 7), (i * 13) % 60)),
      active: true,
      edd: edd ? ymd(addDays(today, Number(edd))) : undefined,
    };
  });
}

function seedAppointments(): Appointment[] {
  const t = startOfToday();
  const mk = (id: number, p: number, sv: string, day: number, h: number, m: number, status: ApptStatus, payment: Appointment['payment'], pr?: string): Appointment => ({
    id: `ap-${id}`, patientId: `pt-${p}`, serviceId: sv, branchId: HOME_BRANCH, start: iso(at(addDays(t, day), h, m)), status, payment,
    practitionerId: pr, created: iso(at(addDays(t, day - 10), 11, 20)),
  });
  return [
    { ...mk(14, 12, 'sv-breast', 0, 9, 0, 'Completed', 'Paid', 'pr-aina'), queue: 'completed' as const },
    { ...mk(15, 14, 'sv-anatomy', 0, 9, 30, 'Booked', 'Fee Paid', 'pr-mira'), queue: 'in_room' as const, room: 'Scan Room 2', checkedInAt: iso(at(t, 9, 22)) },
    { ...mk(1, 3, 'sv-5d', 0, 10, 0, 'Booked', 'Fee Paid', 'pr-aina'), queue: 'checked_in' as const, checkedInAt: iso(at(t, 9, 48)) },
    mk(2, 5, 'sv-anatomy', 0, 11, 0, 'Booked', 'Fee Paid', 'pr-mira'),
    mk(3, 8, 'sv-papsmear', 0, 14, 30, 'Booked', 'No Payment', 'pr-farah'),
    mk(4, 7, 'sv-combo', 0, 16, 0, 'Booked', 'Fee Paid', 'pr-aina'),
    mk(5, 4, 'sv-5d', 1, 9, 30, 'Booked', 'Fee Paid', 'pr-aina'),
    mk(6, 11, 'sv-anatomy', 2, 15, 0, 'Booked', 'Fee Paid', 'pr-mira'),
    mk(7, 12, 'sv-iucd', 3, 10, 30, 'Booked', 'Fee Paid', 'pr-farah'),
    mk(8, 6, 'sv-anatomy', 5, 11, 30, 'Booked', 'Fee Paid', 'pr-mira'),
    mk(9, 1, 'sv-5d', -6, 10, 0, 'Completed', 'Paid', 'pr-aina'),
    mk(10, 7, 'sv-anatomy', -12, 11, 0, 'Completed', 'Paid', 'pr-mira'),
    mk(11, 10, 'sv-depo', -3, 15, 30, 'Completed', 'Paid', 'pr-farah'),
    mk(12, 13, 'sv-papsmear', -2, 9, 30, 'No-Show', 'No Payment', 'pr-farah'),
    mk(13, 9, 'sv-breast', -1, 16, 0, 'Cancelled', 'No Payment', 'pr-aina'),
  ];
}

function seedPointsLog(): PointsLog[] {
  const t = startOfToday();
  return [
    { id: 'pl-1', patientId: 'pt-7', description: 'Pakej 5D HD Live Scan - Tempahan Selesai', points: 3000, at: iso(at(addDays(t, -5), 15, 35)), by: 'Staff' },
    { id: 'pl-2', patientId: 'pt-4', description: 'Ganjaran Lawatan - Detailed Anatomy Scan (Bukit Rimau)', points: 2500, at: iso(at(addDays(t, -9), 11, 30)), by: 'Staff' },
    { id: 'pl-3', patientId: 'pt-1', description: 'Earned 160 points for RM 160 payment', points: 160, at: iso(at(addDays(t, -6), 10, 52)), by: 'Bukit Rimau' },
    { id: 'pl-4', patientId: 'pt-7', description: 'Mata Selamat Datang Ahli Baharu', points: 500, at: iso(at(addDays(t, -40), 17, 5)), by: 'Staff' },
    { id: 'pl-5', patientId: 'pt-12', description: 'Earned 140 points for RM 140 payment', points: 140, at: iso(at(addDays(t, -14), 15, 23)), by: 'Bukit Rimau' },
    { id: 'pl-6', patientId: 'pt-3', description: 'Earned 120 points for RM 120 payment', points: 120, at: iso(at(addDays(t, -19), 12, 10)), by: 'Bukit Rimau' },
    { id: 'pl-7', patientId: 'pt-10', description: 'Earned 60 points for RM 60 payment', points: 60, at: iso(at(addDays(t, -3), 16, 40)), by: 'Bukit Rimau' },
  ];
}

function seedRewards(): Reward[] {
  const y = startOfToday().getFullYear();
  const from = iso(at(new Date(y, 0, 1), 8));
  const to = iso(at(new Date(y + 2, 0, 1), 7, 59));
  const created = iso(at(addDays(startOfToday(), -6), 2, 3));
  return [
    { id: 'rw-rm20', name: 'Baucar Rawatan RM20', description: 'Diskaun segera RM20 untuk sebarang rawatan antenatal & estetik.', points: 2000, left: 50, from, to, active: true, created },
    { id: 'rw-bedung', name: 'Set Bedung & Beanie Organik', description: 'Set bedung premium 100% kapas organik mesra kulit bayi.', points: 3500, left: 30, from, to, active: true, created },
    { id: 'rw-beg', name: 'Beg Hospital Bersalin Eksklusif', description: 'Beg bersalin berbilang ruang kalis air untuk kegunaan di wad.', points: 5000, left: 25, from, to, active: true, created },
  ];
}

export const BAG_ITEMS = ['bag-1', 'bag-2', 'bag-3', 'bag-4', 'bag-5', 'bag-6', 'bag-7', 'bag-8', 'bag-9', 'bag-10'];

function seedChecklist(): ChecklistItem[] {
  const bag: [string, boolean, string?][] = [
    ['Kad pengenalan, buku pink & surat rujukan', true, 'Simpan dalam fail kalis air di poket hadapan beg.'],
    ['Pakaian bersalin berbutang depan (2 pasang)', true],
    ['Pad bersalin & seluar dalam pakai buang', true],
    ['Tuala, berus gigi & barangan mandian', false],
    ['Baju bayi (3 pasang) & topi', true],
    ['Bedung & selimut bayi', true],
    ['Lampin pakai buang saiz NB', true],
    ['Sarung tangan & stokin bayi', false],
    ['Selipar & stokin ibu', false],
    ['Pengecas telefon & kabel panjang', false, 'Soket di wad selalunya jauh dari katil.'],
  ];
  const others: [ChecklistCategory, string, boolean][] = [
    ['Baju', 'Baju bayi saiz 0–3 bulan (6 pasang)', true],
    ['Mandi', 'Tab mandi bayi & termometer air', false],
    ['Tidur', 'Katil bayi & tilam pejal', true],
    ['Penyusuan', 'Pam susu & beg simpanan susu', false],
  ];
  return [
    ...bag.map(([name, required, tip], i) => ({ id: BAG_ITEMS[i]!, category: 'Beg Hospital' as const, name, required, tip })),
    ...others.map(([category, name, required], i) => ({ id: `ck-${i + 1}`, category, name, required })),
  ];
}

function seedBaby(): Record<string, BabyInfo> {
  const t = startOfToday();
  const ses = (h: number, m: number, mins: number, count: number, note?: string): KickSession => ({ start: iso(at(t, h, m)), end: iso(new Date(at(t, h, m).getTime() + mins * 60000)), count, note });
  const done = (n: number) => BAG_ITEMS.slice(0, n);
  const sync = (h: number, m: number) => iso(at(t, h, m));
  return {
    'pt-1': { kicksToday: 12, sessions: [ses(9, 5, 25, 7), ses(13, 40, 20, 5)], bagDone: done(7), lastSync: sync(13, 58) },
    'pt-2': { kicksToday: 4, sessions: [ses(10, 15, 30, 4, 'Bayi kurang aktif pagi ini')], bagDone: done(3), lastSync: sync(10, 45) },
    'pt-3': { kicksToday: 6, sessions: [ses(8, 30, 40, 6)], bagDone: done(5), lastSync: sync(9, 12) },
    'pt-4': { kicksToday: 11, sessions: [ses(9, 0, 30, 6), ses(12, 10, 25, 5)], bagDone: done(8), lastSync: sync(12, 36) },
    'pt-5': { kicksToday: 0, sessions: [], bagDone: done(1), lastSync: sync(8, 2) },
    'pt-6': { kicksToday: 0, sessions: [], bagDone: [], lastSync: sync(7, 40) },
    'pt-7': { kicksToday: 3, sessions: [ses(11, 20, 45, 3, 'Rasa pergerakan berkurang')], bagDone: done(9), lastSync: sync(12, 5) },
    'pt-11': { kicksToday: 0, sessions: [], bagDone: [], lastSync: sync(6, 55) },
    'pt-14': { kicksToday: 0, sessions: [], bagDone: [], lastSync: sync(8, 31) },
  };
}

/** Gestational week + day today from an EDD (EDD = 40w0d). */
export function gestationToday(edd: string) {
  const days = 280 - Math.round((new Date(edd).getTime() - startOfToday().getTime()) / 86400000);
  return { w: Math.floor(days / 7), d: days % 7, days };
}

function seedShifts(): Shift[] {
  const t = startOfToday();
  const out: Shift[] = [];
  let n = 0;
  for (let mo = 0; mo < 2; mo++) {
  const first = new Date(t.getFullYear(), t.getMonth() + mo, 1);
  const days = new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate();
  for (let d = 1; d <= days; d++) {
    const date = new Date(first.getFullYear(), first.getMonth(), d);
    const dow = date.getDay();
    if (dow === 0) continue;
    const key = ymd(date);
    const add = (pr: string, start: string, end: string) => out.push({ id: `sh-${++n}`, practitionerId: pr, branchId: HOME_BRANCH, date: key, start, end });
    add('pr-aina', '09:00', '13:00'); add('pr-aina', '14:00', '18:00');
    if (dow !== 6) { add('pr-mira', '09:00', '17:00'); }
    if (dow === 1 || dow === 3 || dow === 5) add('pr-farah', '10:00', '17:00');
  }
  }
  return out;
}

/** Month offset to open calendars on: next month when fewer than 7 days are left in this one. */
export const smartMonthOffset = () => { const t = startOfToday(); return new Date(t.getFullYear(), t.getMonth() + 1, 0).getDate() - t.getDate() < 7 ? 1 : 0; };

export const slotKey = (serviceId: string, branchId: string) => `${serviceId}|${branchId}`;

function seedSlotConfig(): Record<string, SlotConfig> {
  const t = startOfToday();
  const dates: string[] = [];
  for (let i = 0; i <= 35; i++) { const d = addDays(t, i); if (d.getDay() !== 0) dates.push(ymd(d)); }
  return { [slotKey('sv-5d', HOME_BRANCH)]: { times: ['09:30', '10:30', '11:30', '14:30', '15:30', '16:30'], dates } };
}

function seedClaims(): Claim[] {
  const t = startOfToday();
  return [
    { id: 'cl-1', patientId: 'pt-7', rewardId: 'rw-bedung', at: iso(at(addDays(t, -1), 20, 14)), status: 'In-Progress', by: 'Mobile App', remark: 'Claim reward' },
    { id: 'cl-2', patientId: 'pt-4', rewardId: 'rw-rm20', at: iso(at(addDays(t, -2), 13, 2)), status: 'In-Progress', by: 'Mobile App', remark: 'Claim reward' },
    { id: 'cl-3', patientId: 'pt-12', rewardId: 'rw-rm20', at: iso(at(addDays(t, -9), 11, 40)), status: 'Completed', by: 'Bukit Rimau', remark: 'Used for anatomy scan' },
    { id: 'cl-4', patientId: 'pt-10', rewardId: 'rw-rm20', at: iso(at(addDays(t, -16), 16, 5)), status: 'Completed', by: 'Bukit Rimau', remark: 'customer redeem' },
  ];
}

/** Booking deposits (Fiuu online) and counter payments that match the seeded appointments. */
function seedPayments(): Payment[] {
  const t = startOfToday();
  let n = 0;
  const ref = (k: string) => `${k}${String(482190 + n * 37).slice(-6)}`;
  const pay = (appointmentId: string | undefined, patientId: string, day: number, h: number, m: number, amount: number, channel: Payment['channel'], method: string, kind: Payment['kind'], status: Payment['status'] = 'Successful'): Payment => {
    n++;
    return { id: `py-${n}`, appointmentId, patientId, branchId: HOME_BRANCH, at: iso(at(addDays(t, day), h, m)), amount, channel, method, kind, status, ref: channel === 'Fiuu Online' ? ref('FIUU') : ref('RC') };
  };
  return [
    pay('ap-14', 'pt-12', -4, 21, 10, 50, 'Fiuu Online', 'FPX', 'Booking Deposit'),
    pay('ap-14', 'pt-12', 0, 9, 52, 70, 'Counter', 'Card terminal', 'Counter Payment'),
    pay('ap-15', 'pt-14', -3, 22, 41, 50, 'Fiuu Online', 'FPX', 'Booking Deposit'),
    pay('ap-1', 'pt-3', -5, 12, 5, 50, 'Fiuu Online', 'Card', 'Booking Deposit'),
    pay('ap-2', 'pt-5', -2, 19, 33, 50, 'Fiuu Online', 'FPX', 'Booking Deposit'),
    pay('ap-4', 'pt-7', -1, 8, 47, 50, 'Fiuu Online', 'E-wallet', 'Booking Deposit'),
    pay(undefined, 'pt-2', 0, 8, 55, 50, 'Fiuu Online', 'FPX', 'Booking Deposit', 'Pending'),
    pay('ap-5', 'pt-4', -1, 14, 2, 50, 'Fiuu Online', 'FPX', 'Booking Deposit'),
    pay('ap-11', 'pt-10', -3, 15, 58, 60, 'Counter', 'Cash', 'Counter Payment'),
    pay('ap-9', 'pt-1', -6, 10, 51, 110, 'Counter', 'Card terminal', 'Counter Payment'),
    pay('ap-13', 'pt-9', -1, 12, 0, 50, 'Fiuu Online', 'FPX', 'Refund', 'Refunded'),
    pay('ap-10', 'pt-7', -12, 11, 55, 80, 'Counter', 'QR', 'Counter Payment'),
    pay('ap-6', 'pt-11', 0, 8, 12, 50, 'Fiuu Online', 'FPX', 'Booking Deposit'),
    pay('ap-7', 'pt-12', 0, 9, 41, 50, 'Fiuu Online', 'Card', 'Booking Deposit'),
    pay('ap-8', 'pt-6', 0, 10, 26, 50, 'Fiuu Online', 'E-wallet', 'Booking Deposit'),
    pay(undefined, 'pt-10', 0, 11, 5, 80, 'Counter', 'Cash', 'Counter Payment'),
    pay(undefined, 'pt-13', 0, 11, 48, 30, 'Counter', 'DuitNow QR', 'Counter Payment'),
    pay(undefined, 'pt-9', -2, 15, 20, 50, 'Fiuu Online', 'FPX', 'Booking Deposit', 'Failed'),
    pay(undefined, 'pt-8', -4, 10, 2, 120, 'Counter', 'Card terminal', 'Counter Payment'),
    pay(undefined, 'pt-3', -5, 16, 40, 160, 'Counter', 'Card terminal', 'Counter Payment'),
    pay(undefined, 'pt-4', -2, 12, 30, 130, 'Counter', 'Cash', 'Counter Payment'),
  ];
}

export function seedDb(): Db {
  return {
    branches: seedBranches(),
    services: seedServices(),
    practitioners: seedPractitioners(),
    patients: seedPatients(),
    appointments: seedAppointments(),
    pointsLog: seedPointsLog(),
    rewards: seedRewards(),
    claims: seedClaims(),
    payments: seedPayments(),
    baby: seedBaby(),
    checklist: seedChecklist(),
    recalls: {},
    offers: {},
    shifts: seedShifts(),
    slotConfig: seedSlotConfig(),
    timing: {},
    vouchers: seedVouchers(),
    promotions: seedPromotions(),
    campaigns: seedCampaigns(),
    admins: seedAdmins(),
    audit: seedAudit(),
  };
}

/** Free slots for a branch + service over the next five weeks (Mon–Sat, skipping booked times). */
export function availableSlots(db: Db, serviceId: string, branchId: string): Record<string, string[]> {
  const svc = db.services.find((s) => s.id === serviceId);
  const out: Record<string, string[]> = {};
  if (!svc) return out;
  const t = startOfToday();
  const cfg = db.slotConfig[slotKey(serviceId, branchId)];
  if (cfg) {
    const now = Date.now();
    for (const day of cfg.dates) {
      const [y, m, d] = day.split('-').map(Number);
      const list = cfg.times
        .map((tm) => { const [h, mi] = tm.split(':').map(Number); return new Date(y!, m! - 1, d!, h!, mi!); })
        .filter((s) => s.getTime() > now && !db.appointments.some((a) => a.branchId === branchId && a.status === 'Booked' && Math.abs(new Date(a.start).getTime() - s.getTime()) < 30 * 60000))
        .map(iso);
      if (list.length) out[day] = list;
    }
    return out;
  }
  const times = svc.type === 'Sonographer' ? [[9, 30], [10, 30], [11, 30], [14, 30], [15, 30], [16, 30]] : [[10, 0], [11, 0], [14, 0], [15, 0], [16, 0]];
  for (let i = 1; i <= 35; i++) {
    const d = addDays(t, i);
    if (d.getDay() === 0) continue;
    if ((i * 7 + 3) % 11 === 0) continue; // a few fully booked days
    const list: string[] = [];
    times.forEach(([h, m], k) => {
      if ((i + k) % 5 === 0) return; // some taken slots
      const s = at(d, h!, m!);
      const clash = db.appointments.some((a) => a.branchId === branchId && a.status === 'Booked' && Math.abs(new Date(a.start).getTime() - s.getTime()) < 30 * 60000);
      if (!clash) list.push(iso(s));
    });
    if (list.length) out[ymd(d)] = list;
  }
  return out;
}
