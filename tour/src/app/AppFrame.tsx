import { useMemo, useState, type ReactNode } from 'react';
import { ROUTE_TITLES, useApp, type Route } from './store';
import { DoctorIcon, Icon, StatusDialog } from './ui';
import { Dashboard } from './pages/Dashboard';
import { Patients } from './pages/Patients';
import { Appointments } from './pages/Appointments';
import { Points } from './pages/Points';
import { ComingSoon } from './pages/ComingSoon';
import { Queue } from './pages/Queue';
import { Redemptions } from './pages/Redemptions';
import { BabyTracker } from './pages/BabyTracker';
import { FollowUp } from './pages/FollowUp';
import { DailyClosing, PaymentRecords } from './pages/Billing';
import { Doctors } from './pages/Doctors';
import { Services } from './pages/Services';
import { ActivityLogs, Branches, Campaigns, PeakHours, Promotions, RewardsCatalog, Staff, Vouchers } from './pages/Admin';
import { CheckoutDialog, CheckoutDoneDialog, ClaimUpdateDialog, RoomPickerDialog, TransferDialog } from './dialogs/FrontDesk';
import { RegisterPatientDialog } from './dialogs/RegisterPatient';
import { NewAppointmentDialog } from './dialogs/NewAppointment';
import { SlotPickerDialog } from './dialogs/SlotPicker';
import { ClaimRewardDialog, AwardSuccessDialog, ConfirmDialog } from './dialogs/Rewards';

interface NavItem { route: Route; label: string; icon: string | 'doctor'; superOnly?: boolean }
interface NavGroup { key: string; title: string; items: NavItem[] }

const MAIN: NavItem[] = [
  { route: 'dashboard', label: 'Dashboard', icon: 'dashboard' },
  { route: 'appointments', label: 'Appointments', icon: 'event' },
  { route: 'patients', label: 'Patients', icon: 'people' },
  { route: 'points', label: 'Points', icon: 'stars' },
];
const GROUPS: NavGroup[] = [
  { key: 'doctors', title: 'Doctors & Scans', items: [
    { route: 'babyTracker', label: 'Baby Tracker', icon: 'pregnant_woman' },
    { route: 'followUp', label: 'Patient Follow-Up', icon: 'notification_important' },
    { route: 'doctors', label: 'Doctors', icon: 'doctor' },
    { route: 'services', label: 'Services & Pricing', icon: 'medical_services' },
    { route: 'branches', label: 'Branches', icon: 'store', superOnly: true },
    { route: 'peakHours', label: 'Peak Hours & Capacity', icon: 'grid_on' },
  ] },
  { key: 'billing', title: 'Billing & Cashier', items: [
    { route: 'payments', label: 'Payment Records', icon: 'receipt_long' },
    { route: 'eod', label: 'Daily Closing (EOD)', icon: 'fact_check' },
  ] },
  { key: 'vouchers', title: 'Vouchers & Promos', items: [
    { route: 'vouchers', label: 'Vouchers', icon: 'confirmation_number' },
    { route: 'rewards', label: 'Rewards', icon: 'redeem' },
    { route: 'redemptions', label: 'Redemption History', icon: 'history' },
    { route: 'campaigns', label: 'Campaigns', icon: 'celebration', superOnly: true },
    { route: 'promotions', label: 'Promotions', icon: 'campaign', superOnly: true },
  ] },
  { key: 'staff', title: 'Staff & Settings', items: [
    { route: 'staff', label: 'Staff Accounts', icon: 'admin_panel_settings', superOnly: true },
    { route: 'activity', label: 'Activity Logs', icon: 'policy', superOnly: true },
  ] },
];


function NavIcon({ icon }: { icon: NavItem['icon'] }) {
  return icon === 'doctor' ? <DoctorIcon /> : <Icon n={icon} />;
}

function Sidebar() {
  const { role, route, go, groupsOpen, toggleGroup } = useApp();
  const isSuper = role === 'superadmin';
  const name = isSuper ? 'Super Admin' : 'Klinik Aurora Bukit Rimau';
  const badge = isSuper ? 'Super Admin' : 'Branch Admin';
  return (
    <aside className="ka-sidebar">
      <div className="ka-sb-head">
        <div className="ka-sb-logo"><img src={`${import.meta.env.BASE_URL}logo.png`} alt="" /></div>
        <div className="ka-sb-brand"><b>KLINIK AURORA</b><span>Management Portal</span></div>
      </div>
      <div className="ka-sb-user">
        <span className="ka-sb-avatar">{name[0]}</span>
        <div style={{ minWidth: 0 }}>
          <b style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{name}</b>
          <span className="ka-sb-role">{badge}</span>
        </div>
      </div>
      <div className="ka-sb-scroll" data-tour="sidebar">
        <div className="ka-sb-section">Main</div>
        {MAIN.map((it) => (
          <button key={it.route} type="button" className={`ka-sb-item${route === it.route ? ' active' : ''}`} data-tour={`nav-${it.route}`} onClick={() => go(it.route)}>
            <NavIcon icon={it.icon} />{it.label}
          </button>
        ))}
        {GROUPS.map((g) => {
          const items = g.items.filter((i) => isSuper || !i.superOnly);
          if (!items.length) return null;
          const open = groupsOpen[g.key];
          return (
            <div key={g.key}>
              <button type="button" className={`ka-sb-section${open ? '' : ' collapsed'}`} data-tour={`group-${g.key}`} onClick={() => toggleGroup(g.key)}>
                {g.title}<Icon n="keyboard_arrow_down" />
              </button>
              {open && items.map((it) => (
                <button key={it.route} type="button" className={`ka-sb-item grouped${route === it.route ? ' active' : ''}`} data-tour={`nav-${it.route}`} onClick={() => go(it.route)}>
                  <NavIcon icon={it.icon} />{it.label}
                </button>
              ))}
            </div>
          );
        })}
      </div>
      <div className="ka-sb-foot">
        <button type="button" className="ka-sb-foot-item"><Icon n="palette" v="o" />Appearance</button>
        <button type="button" className="ka-sb-foot-item"><Icon n="logout" />Logout</button>
        <div className="ka-sb-collapse">Collapse Sidebar <Icon n="chevron_left" size={18} /></div>
        <span className="ka-sb-version">v1.3.0</span>
      </div>
    </aside>
  );
}

function TopBar() {
  const { route, role, dark, setDark, openDialog } = useApp();
  const isSuper = role === 'superadmin';
  return (
    <header className="ka-topbar">
      <Icon n="menu_open" size={22} />
      <span className="ka-topbar-title">{ROUTE_TITLES[route]}</span>
      <span className="ka-topbar-spacer" />
      <button type="button" className="ka-qs" data-tour="quick-search" onClick={() => openDialog({ kind: 'commandPalette' })}>
        <Icon n="search" />Quick Search...<span className="ka-kbd">⌘K</span>
      </button>
      <button type="button" className="ka-tb-icon"><Icon n="keyboard" v="o" /></button>
      <button type="button" className="ka-tb-icon" data-tour="dark-toggle" onClick={() => setDark(!dark)}><Icon n={dark ? 'light_mode' : 'dark_mode'} /></button>
      <button type="button" className="ka-tb-icon"><Icon n="palette" v="o" /></button>
      <button type="button" className="ka-tb-icon"><Icon n="notifications" v="o" /></button>
      <div className="ka-profile">
        <div className="ka-profile-name"><b>{isSuper ? 'Super Admin' : 'Bukit Rimau'}</b><span>{isSuper ? 'Super Admin' : 'Branch Admin'}</span></div>
        <span className="ka-profile-avatar"><Icon n="person" /></span>
        <Icon n="keyboard_arrow_down" size={18} style={{ color: 'var(--muted)' }} />
      </div>
    </header>
  );
}

interface PaletteItem { title: string; subtitle: string; icon: string; category: string; run: () => void; id: string }

function CommandPalette() {
  const { go, closeDialog, setDark, dark, role } = useApp();
  const isSuper = role === 'superadmin';
  const [q, setQ] = useState('');
  const items: PaletteItem[] = useMemo(() => [
    { id: 'book', title: 'Book New Appointment', subtitle: 'Schedule a patient for clinical service', icon: 'add_circle_outline', category: 'Quick Actions', run: () => go('patients') },
    { id: 'dark', title: 'Toggle Dark / Light Mode', subtitle: 'Switch between bright reception view and low-glare dark mode', icon: 'dark_mode', category: 'Quick Actions', run: () => { setDark(!dark); closeDialog(); } },
    { id: 'queue', title: "Today's Flow (Front-Desk Queue)", subtitle: 'Live check-in board, room assignments, and wait timers', icon: 'view_kanban', category: 'Clinic Operations', run: () => go('queue') },
    { id: 'eod', title: 'Daily EOD Branch Handover', subtitle: 'End-of-day cash/Fiuu reconciliation and shift export', icon: 'fact_check', category: 'Clinic Operations', run: () => go('eod') },
    { id: 'recalls', title: 'Next-Trimester Scan Recalls', subtitle: 'Follow up expectant mothers due for NT, Detail, or 4D/5D scans', icon: 'notification_important', category: 'Clinic Operations', run: () => go('followUp') },
    { id: 'appointments', title: 'Appointments', subtitle: 'Bookings calendar and appointment list', icon: 'event', category: 'Navigation', run: () => go('appointments') },
    { id: 'patients', title: 'Patients', subtitle: 'Search patient directory and profiles', icon: 'people', category: 'Navigation', run: () => go('patients') },
    { id: 'points', title: 'Loyalty Points', subtitle: 'Patient reward points and transaction ledger', icon: 'stars', category: 'Navigation', run: () => go('points') },
    { id: 'baby', title: 'Baby Tracker', subtitle: 'Gestational timeline and hospital checklist', icon: 'pregnant_woman', category: 'Navigation', run: () => go('babyTracker') },
    ...(isSuper ? [
      { id: 'branches', title: 'Clinic Branches', subtitle: 'Branch locations and operational timings', icon: 'store', category: 'Navigation', run: () => go('branches') },
      { id: 'campaigns', title: 'Marketing Campaigns', subtitle: 'Seasonal point boosts and app themes', icon: 'celebration', category: 'Navigation', run: () => go('campaigns') },
      { id: 'audit', title: 'Audit Trail & Activity Log', subtitle: 'Super Admin searchable change history and JSON diff viewer', icon: 'policy', category: 'System', run: () => go('activity') },
    ] : []),
  ], [go, setDark, dark, closeDialog, isSuper]);
  const filtered = items.filter((i) => !q || `${i.title} ${i.subtitle}`.toLowerCase().includes(q.toLowerCase()));
  const cats = [...new Set(filtered.map((i) => i.category))];
  return (
    <div className="ka-overlay" style={{ placeItems: 'start center', paddingTop: 110 }} onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 620, borderRadius: 14 }} onClick={(e) => e.stopPropagation()} data-tour="palette">
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 18px', borderBottom: '1px solid var(--border)' }}>
          <Icon n="search" size={22} style={{ color: 'var(--primary-ink)' }} />
          <input data-tour="palette-input" autoFocus value={q} onChange={(e) => setQ(e.target.value)} placeholder="Type a command or search page..." style={{ flex: 1, border: 'none', outline: 'none', background: 'none', fontSize: 16, height: 30 }} />
          <span className="ka-kbd" style={{ marginLeft: 0 }}>ESC</span>
        </div>
        <div style={{ maxHeight: 420, overflow: 'auto', padding: '6px 8px 10px' }}>
          {cats.map((c) => (
            <div key={c}>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase', color: 'var(--muted)', padding: '12px 10px 6px' }}>{c}</div>
              {filtered.filter((i) => i.category === c).map((i, k) => (
                <button key={i.id} type="button" data-tour={`palette-${i.id}`} onClick={i.run} className="ka-menu-item" style={{ borderRadius: 8, minHeight: 54, background: k === 0 && q ? 'var(--primary-soft)' : undefined }}>
                  <span style={{ width: 34, height: 34, borderRadius: 8, background: 'var(--surface-subtle)', display: 'grid', placeItems: 'center' }}><Icon n={i.icon} v="o" /></span>
                  <span style={{ flex: 1 }}>
                    <b style={{ display: 'block', fontSize: 14, fontWeight: 600 }}>{i.title}</b>
                    <span style={{ display: 'block', fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>{i.subtitle}</span>
                  </span>
                  <Icon n="keyboard_return" size={16} style={{ color: 'var(--muted)' }} />
                </button>
              ))}
            </div>
          ))}
          {!filtered.length && <div style={{ padding: 28, textAlign: 'center', color: 'var(--muted)' }}>No matches</div>}
        </div>
        <div style={{ display: 'flex', gap: 18, padding: '10px 18px', borderTop: '1px solid var(--border)', fontSize: 12, color: 'var(--muted)' }}>
          <span><span className="ka-kbd" style={{ marginLeft: 0 }}>↑↓</span> Navigate</span>
          <span><span className="ka-kbd" style={{ marginLeft: 0 }}>↵</span> Open</span>
          <span><span className="ka-kbd" style={{ marginLeft: 0 }}>ESC</span> Dismiss</span>
        </div>
      </div>
    </div>
  );
}

function DialogHost() {
  const { dialogs, closeDialog } = useApp();
  return (
    <>
      {dialogs.map((d, i) => {
        let node: ReactNode = null;
        switch (d.kind) {
          case 'registerPatient': node = <RegisterPatientDialog />; break;
          case 'newAppointment': node = <NewAppointmentDialog patientId={d.patientId} />; break;
          case 'updateAppointment': node = <NewAppointmentDialog appointmentId={d.appointmentId} />; break;
          case 'transfer': node = <TransferDialog appointmentId={d.appointmentId} />; break;
          case 'roomPicker': node = <RoomPickerDialog appointmentId={d.appointmentId} />; break;
          case 'checkout': node = <CheckoutDialog appointmentId={d.appointmentId} />; break;
          case 'checkoutDone': node = <CheckoutDoneDialog summary={d.summary} />; break;
          case 'claimUpdate': node = <ClaimUpdateDialog claimId={d.claimId} />; break;
          case 'slotPicker': node = <SlotPickerDialog {...d} />; break;
          case 'status': node = <StatusDialog {...d} onClose={closeDialog} />; break;
          case 'confirm': node = <ConfirmDialog {...d} />; break;
          case 'claimReward': node = <ClaimRewardDialog {...d} />; break;
          case 'awardSuccess': node = <AwardSuccessDialog {...d} />; break;
          case 'commandPalette': node = <CommandPalette />; break;
          case 'custom': node = d.render(); break;
        }
        return <div key={i} style={{ position: 'absolute', inset: 0, zIndex: 30 + i }}>{node}</div>;
      })}
    </>
  );
}

function Page() {
  const route = useApp((s) => s.route);
  switch (route) {
    case 'dashboard': return <Dashboard />;
    case 'patients': return <Patients />;
    case 'appointments': return <Appointments />;
    case 'points': return <Points />;
    case 'queue': return <Queue />;
    case 'redemptions': return <Redemptions />;
    case 'babyTracker': return <BabyTracker />;
    case 'followUp': return <FollowUp />;
    case 'payments': return <PaymentRecords />;
    case 'eod': return <DailyClosing />;
    case 'doctors': return <Doctors />;
    case 'services': return <Services />;
    case 'promotions': return <Promotions />;
    case 'campaigns': return <Campaigns />;
    case 'vouchers': return <Vouchers />;
    case 'rewards': return <RewardsCatalog />;
    case 'staff': return <Staff />;
    case 'branches': return <Branches />;
    case 'activity': return <ActivityLogs />;
    case 'peakHours': return <PeakHours />;
    default: return <ComingSoon route={route} />;
  }
}

export function AppFrame() {
  const dark = useApp((s) => s.dark);
  const toast = useApp((s) => s.toast);
  return (
    <div id="ka-root" className={`ka-app ${dark ? 'ka-theme-dark' : 'ka-theme-light'}`}>
      <Sidebar />
      <div className="ka-main">
        <TopBar />
        <div className="ka-content" data-tour="content"><Page /></div>
      </div>
      <DialogHost />
      <div id="ka-layer" style={{ position: 'absolute', inset: 0, zIndex: 80, pointerEvents: 'none' }} />
      {toast && <div className="ka-toast" key={toast.id}><Icon n="check_circle" />{toast.text}</div>}
    </div>
  );
}
