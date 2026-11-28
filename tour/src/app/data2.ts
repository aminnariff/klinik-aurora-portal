// Superadmin seed data: vouchers, promotions, campaigns, staff accounts, activity log.
// Voucher codes follow the real setup; staff names and emails are made up.
import { addDays, at, iso, startOfToday } from './data';

export interface Voucher { id: string; code: string; name: string; description: string; points: number | null; from: string; to: string; active: boolean; created: string; rewardId?: string }
export interface Promotion { id: string; title: string; description: string; terms?: string; from: string; to: string; featured: boolean; active: boolean; created: string; art: 'scan' | 'pink' | 'checkup' | 'raya' | 'points' }
export interface Campaign { id: string; name: string; from: string; to: string; multiplier: number; primary: string; accent: string; background: string; active: boolean }
export interface Admin { id: string; name: string; username: string; email: string; phone: string; branchId: string | null; role: 'Super Admin' | 'Branch Manager' | 'Clinic Staff' | 'Sonographer (Locum)'; permissions: string[]; active: boolean; created: string }
export interface AuditEntry { id: string; at: string; admin: string; branch: string; entity: string; entityId: string; action: 'CREATE' | 'UPDATE' | 'TRANSFER' | 'STATUS_CHANGE' | 'CANCEL' | 'DELETE' | 'RECALL_SENT' | 'RESCHEDULE'; summary: string; before?: Record<string, unknown>; after?: Record<string, unknown> }

export const PERMISSIONS: { group: string; items: string[] }[] = [
  { group: 'Clinical & Operations', items: ['Appointment Management', 'Service Management', 'Doctor Management', 'Sonographer'] },
  { group: 'Patients & Loyalty', items: ['User Management', 'Point Management', 'Reward Management', 'Reward History', 'Voucher Management'] },
  { group: 'Finance & Administration', items: ['Payment Management', 'Branch Management', 'Admin Management', 'Promotion Management'] },
];
export const ROLE_PRESETS: Record<Admin['role'], string[]> = {
  'Sonographer (Locum)': ['Appointment Management', 'Sonographer'],
  'Clinic Staff': ['Appointment Management', 'User Management', 'Point Management', 'Payment Management'],
  'Branch Manager': ['Appointment Management', 'Service Management', 'Doctor Management', 'User Management', 'Point Management', 'Reward Management', 'Reward History', 'Voucher Management', 'Payment Management'],
  'Super Admin': PERMISSIONS.flatMap((g) => g.items),
};

export function seedVouchers(): Voucher[] {
  const t = startOfToday();
  const y = t.getFullYear();
  const c = (d: number, h = 2, m = 3) => iso(at(addDays(t, d), h, m));
  const from = iso(at(new Date(y, 0, 1), 8)), to = iso(at(new Date(y + 1, 11, 31), 23, 59));
  return [
    { id: 'vc-1', code: 'AURORA5D20', name: 'POTONGAN RM20 IMBASAN 5D', description: 'RM20 off any 5D scan at participating branches.', points: 0, from, to, active: true, created: c(-6) },
    { id: 'vc-2', code: 'GLOWAURORA', name: 'RAWATAN HYDRAFACIAL PERCUMA', description: 'One complimentary hydrafacial with any postnatal package.', points: 0, from, to, active: true, created: c(-6) },
    { id: 'vc-3', code: 'WELCOME10', name: 'DISKAUN RM10 KONSULTASI', description: 'RM10 off the first doctor consultation for new members.', points: 0, from, to, active: true, created: c(-6) },
    { id: 'vc-4', code: 'STARTNOW', name: 'Start Now', description: 'Early adopter bonus.', points: 100, from: iso(at(new Date(2024, 10, 12), 8)), to: iso(at(new Date(2024, 11, 31), 23)), active: false, created: iso(at(new Date(2024, 10, 12), 18, 30)) },
    { id: 'vc-5', code: 'MERDEKA', name: 'Touch n go FREE', description: 'Merdeka month giveaway.', points: null, from: iso(at(new Date(2024, 7, 1), 8)), to: iso(at(new Date(2024, 7, 31), 23)), active: false, created: iso(at(new Date(2024, 9, 24), 7, 22)) },
  ];
}

export function seedPromotions(): Promotion[] {
  const t = startOfToday();
  const y = t.getFullYear(), m = t.getMonth();
  return [
    { id: 'pm-1', title: 'Promo Hujung Tahun 5D Scan', description: '5D scan + pendrive video from RM99 this month only.', from: iso(at(new Date(y, m, 1), 8)), to: iso(at(new Date(y, m + 1, 0), 23, 59)), featured: true, active: true, created: iso(at(addDays(t, -20), 10)), art: 'scan' },
    { id: 'pm-2', title: 'Pakej Pap Smear Wanita', description: 'Pap smear + breast scan package for women 25 and above.', from: iso(at(new Date(y, m, 1), 8)), to: iso(at(new Date(y, m + 2, 0), 23, 59)), featured: false, active: true, created: iso(at(addDays(t, -14), 11)), art: 'pink' },
    { id: 'pm-3', title: 'Promo September 2024', description: 'Basic health screening DS1 at RM50.', from: iso(at(new Date(2024, 8, 1), 8)), to: iso(at(new Date(2024, 8, 30), 23)), featured: true, active: false, created: iso(at(new Date(2024, 7, 28), 9)), art: 'checkup' },
    { id: 'pm-4', title: 'Promosi Hari Raya', description: 'Raya specials across all branches.', from: iso(at(new Date(2024, 3, 1), 8)), to: iso(at(new Date(2024, 3, 30), 23)), featured: true, active: false, created: iso(at(new Date(2024, 2, 25), 9)), art: 'raya' },
    { id: 'pm-5', title: 'Earn Points, Redeem Rewards!', description: 'Every RM1 earns 1 point. Redeem for vouchers and baby gifts.', from: iso(at(new Date(2024, 9, 1), 8)), to: iso(at(new Date(2025, 4, 13), 23)), featured: true, active: false, created: iso(at(new Date(2024, 8, 28), 9)), art: 'points' },
  ];
}

export function seedCampaigns(): Campaign[] {
  const t = startOfToday();
  const y = t.getFullYear();
  return [
    { id: 'cp-1', name: 'Year-End Baby Boom', from: iso(at(addDays(t, -10), 0)), to: iso(at(new Date(y, 11, 31), 23, 59)), multiplier: 1.5, primary: '#7E2D40', accent: '#F59E0B', background: '#FFF7ED', active: true },
    { id: 'cp-2', name: 'Ramadan Kareem Theme', from: iso(at(new Date(y + 1, 1, 18), 0)), to: iso(at(new Date(y + 1, 2, 19), 23, 59)), multiplier: 1, primary: '#065F46', accent: '#D4AF37', background: '#ECFDF5', active: true },
    { id: 'cp-3', name: 'Merdeka Double Points', from: iso(at(new Date(y, 7, 25), 0)), to: iso(at(new Date(y, 8, 16), 23, 59)), multiplier: 2, primary: '#1D4ED8', accent: '#DC2626', background: '#EFF6FF', active: true },
  ];
}

export function seedAdmins(): Admin[] {
  const c = (y: number, m: number, d: number) => iso(at(new Date(y, m, d), 9, 30));
  return [
    { id: 'ad-1', name: 'Super Admin', username: 'superadmin', email: 'superadmin', phone: 'N/A', branchId: null, role: 'Super Admin', permissions: ROLE_PRESETS['Super Admin'], active: true, created: c(2024, 2, 31) },
    { id: 'ad-2', name: 'Aurora Marketing HQ', username: 'marketinghq', email: 'marketing.hq@example.com', phone: 'N/A', branchId: null, role: 'Branch Manager', permissions: ['Promotion Management', 'Voucher Management', 'Reward Management'], active: true, created: c(2024, 6, 5) },
    { id: 'ad-3', name: 'Klinik Aurora Bukit Rimau', username: 'bukitrimau', email: 'bukit-rimau@example.com', phone: '0355221034', branchId: 'br-bukitrimau', role: 'Clinic Staff', permissions: ROLE_PRESETS['Clinic Staff'], active: true, created: c(2024, 6, 4) },
    { id: 'ad-4', name: 'Klinik Aurora Ampang', username: 'ampang', email: 'ampang@example.com', phone: '0342918830', branchId: 'br-ampang', role: 'Clinic Staff', permissions: ROLE_PRESETS['Clinic Staff'], active: true, created: c(2024, 6, 4) },
    { id: 'ad-5', name: 'Hanis Finance', username: 'hanis.fin', email: 'finance@example.com', phone: '0128840192', branchId: null, role: 'Branch Manager', permissions: ['Payment Management', 'Reward History'], active: true, created: c(2025, 1, 10) },
  ];
}

export function seedAudit(): AuditEntry[] {
  const t = startOfToday();
  const a = (d: number, h: number, m: number) => iso(at(addDays(t, d), h, m));
  return [
    { id: 'au-1', at: a(0, 11, 52), admin: 'Klinik Aurora Bukit Rimau', branch: 'Bukit Rimau', entity: 'Appointment', entityId: 'AP-1F3C9A', action: 'STATUS_CHANGE', summary: 'Chong Pei Wen · Breast Scan marked Completed', before: { status: 'Booked' }, after: { status: 'Completed', paidAtCounter: 70 } },
    { id: 'au-2', at: a(0, 10, 15), admin: 'Klinik Aurora Bukit Rimau', branch: 'Bukit Rimau', entity: 'Appointment', entityId: 'AP-77D210', action: 'RESCHEDULE', summary: 'Kavitha A/P Raman · 5D Scan moved to a later date', before: { slot: 'Sun 09:30' }, after: { slot: 'Thu 10:30', status: 'Rescheduled' } },
    { id: 'au-3', at: a(0, 9, 3), admin: 'Super Admin', branch: 'HQ', entity: 'Service', entityId: 'SV-5D', action: 'UPDATE', summary: '5D Scan booking fee changed', before: { bookingFee: 40 }, after: { bookingFee: 50 } },
    { id: 'au-4', at: a(-1, 17, 40), admin: 'Klinik Aurora Ampang', branch: 'Ampang', entity: 'Appointment', entityId: 'AP-A02B41', action: 'TRANSFER', summary: 'Wan Nur Syafiqah transferred Ampang → Bukit Rimau', before: { branch: 'Ampang' }, after: { branch: 'Bukit Rimau' } },
    { id: 'au-5', at: a(-1, 16, 2), admin: 'Klinik Aurora Bukit Rimau', branch: 'Bukit Rimau', entity: 'Patient', entityId: 'PT-6620', action: 'RECALL_SENT', summary: 'Recall sent to Nurul Izzah Binti Ahmad (WA + Push)' },
    { id: 'au-6', at: a(-2, 12, 31), admin: 'Aurora Marketing HQ', branch: 'HQ', entity: 'Promotion', entityId: 'PM-2', action: 'CREATE', summary: 'Promotion "Pakej Pap Smear Wanita" created', after: { title: 'Pakej Pap Smear Wanita', active: true } },
    { id: 'au-7', at: a(-3, 15, 12), admin: 'Super Admin', branch: 'HQ', entity: 'Admin', entityId: 'AD-5', action: 'UPDATE', summary: 'Hanis Finance permissions updated', before: { permissions: ['Payment Management'] }, after: { permissions: ['Payment Management', 'Reward History'] } },
    { id: 'au-8', at: a(-4, 18, 44), admin: 'Klinik Aurora Bukit Rimau', branch: 'Bukit Rimau', entity: 'Appointment', entityId: 'AP-91CC03', action: 'CANCEL', summary: 'Farah Adibah · Breast Scan cancelled by patient request', before: { status: 'Booked' }, after: { status: 'Cancelled' } },
  ];
}
