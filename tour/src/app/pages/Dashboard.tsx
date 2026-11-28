import { useApp } from '../store';
import { Icon } from '../ui';
import { HOME_BRANCH, fmtRange, startOfToday, addDays, ymd } from '../data';

function Kpi({ label, value, sub, color, icon, tour }: { label: string; value: string; sub: string; color: string; icon: string; tour?: string }) {
  return (
    <div className="ka-card" data-tour={tour} style={{ flex: 1, borderTop: `3px solid ${color}`, padding: '18px 14px 16px', borderRadius: 6 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: 1, color: 'var(--ink-2)', textTransform: 'uppercase' }}>{label}</span>
        <span style={{ width: 24, height: 24, borderRadius: 6, background: `color-mix(in srgb, ${color} 14%, transparent)`, display: 'grid', placeItems: 'center' }}><Icon n={icon} size={15} style={{ color }} /></span>
      </div>
      <div style={{ fontSize: 22, fontWeight: 800, margin: '14px 0 8px' }}>{value}</div>
      <div style={{ fontSize: 12, fontWeight: 600, color }}>{sub}</div>
    </div>
  );
}

function Header({ branch }: { branch: boolean }) {
  const now = new Date();
  const time = now.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  return (
    <div className="ka-card" style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', borderRadius: 12 }}>
      <div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <span style={{ fontSize: 18, fontWeight: 700 }}>Network Intelligence Dashboard</span>
          <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: 1, color: 'var(--info)', background: 'var(--info-soft)', padding: '3px 8px', borderRadius: 6 }}>{branch ? 'BRANCH LEVEL' : 'EXECUTIVE'}</span>
        </div>
        <div style={{ fontSize: 13, color: 'var(--muted)', marginTop: 6 }}>Updated {time}</div>
      </div>
      <span style={{ flex: 1 }} />
      <div className="ka-input" style={{ width: 240, height: 40, justifyContent: 'space-between', background: 'var(--surface-subtle)', fontSize: 14, fontWeight: 500 }}>
        {branch ? 'Klinik Aurora Bukit Rimau' : 'All Branches (Network View)'}<Icon n="keyboard_arrow_down" />
      </div>
      <span className="ka-icon-square" style={{ marginLeft: 10 }}><Icon n="refresh" /></span>
    </div>
  );
}

function NetworkDashboard() {
  const db = useApp((s) => s.db);
  const points = [12, 11, 52, 9, 128, 150];
  const months = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'];
  const w = 1250, h = 120;
  const xs = points.map((_, i) => (i / (points.length - 1)) * w);
  const ys = points.map((p) => h - (p / 160) * h);
  const path = xs.map((x, i) => `${i ? 'L' : 'M'}${x},${ys[i]}`).join(' ');
  return (
    <div className="ka-page">
      <Header branch={false} />
      <div style={{ display: 'flex', gap: 12 }}>
        <Kpi label="Network Revenue" value="RM 2,480.00" sub="This Month" color="#16a34a" icon="payments" />
        <Kpi label="Total Appointments" value={String(db.appointments.length)} sub="This Month" color="#2563eb" icon="event" />
        <Kpi label="Doctors on Duty" value={`${db.practitioners.length} Doctors`} sub="Active Roster Today" color="#0d9488" icon="medical_services" />
        <Kpi label="Active Clinics" value={`${db.branches.length} Clinics`} sub="100% Operational" color="#ea580c" icon="store" />
        <Kpi label="Total Patients" value={String(db.patients.length)} sub="8 Active Users" color="#7c3aed" icon="people" />
      </div>
      <div className="ka-card" style={{ padding: '20px 16px', borderRadius: 12 }}>
        <div style={{ fontSize: 15, fontWeight: 600 }}>Monthly Network Revenue (6 Months)</div>
        <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 4 }}>Gross revenue progression across all operational clinics</div>
        <svg width="100%" viewBox={`-50 -10 ${w + 70} ${h + 40}`} style={{ marginTop: 18, display: 'block' }}>
          <path d={`${path} L${w},${h} L0,${h} Z`} fill="rgba(22,163,74,.08)" />
          <path d={path} fill="none" stroke="#16a34a" strokeWidth="2.5" />
          {xs.map((x, i) => <circle key={i} cx={x} cy={ys[i]} r="4" fill="#16a34a" stroke="#fff" strokeWidth="1.5" />)}
          {months.map((m, i) => <text key={m} x={xs[i]} y={h + 26} fontSize="12" textAnchor="middle" fill="var(--muted)">{m}</text>)}
        </svg>
      </div>
    </div>
  );
}

function BranchDashboard() {
  const db = useApp((s) => s.db);
  const go = useApp((s) => s.go);
  const today = ymd(startOfToday());
  const todays = db.appointments.filter((a) => a.branchId === HOME_BRANCH && a.start.length && ymd(new Date(a.start)) === today);
  const done = todays.filter((a) => a.status === 'Completed').length;
  const upcoming = todays.filter((a) => a.status === 'Booked');
  const missed = db.appointments.filter((a) => a.status === 'Cancelled' || a.status === 'No-Show').length;
  // Fixed sample week so the chart reads naturally whatever day the tour is opened.
  const sample = [[6, 5], [8, 7], [5, 5], [9, 8], [7, 6], [10, 9], [todays.length, done]];
  const week = sample.map(([scheduled, completed], i) => ({ label: addDays(startOfToday(), i - 6).toLocaleDateString('en-US', { weekday: 'short' }), scheduled: scheduled!, completed: completed! }));
  const max = Math.max(...week.map((w) => w.scheduled), 1);
  return (
    <div className="ka-page">
      <Header branch />
      <div style={{ display: 'flex', gap: 12 }}>
        <Kpi tour="kpi-seen" label="Seen vs Scheduled" value={`${done} / ${todays.length}`} sub={todays.length ? `${Math.round((done / todays.length) * 100)}% seen today` : 'No visits scheduled today'} color="#0d9488" icon="fact_check" />
        <Kpi label="Remaining Visits" value={String(upcoming.length)} sub={upcoming.length ? 'Upcoming today' : 'None pending'} color="#2563eb" icon="schedule" />
        <Kpi label="Doctors on Duty" value="3" sub="3 Doctors Active" color="#7c3aed" icon="medical_services" />
        <Kpi label="Cancelled / No-Show" value={String(missed)} sub={missed ? 'Requires follow-up' : 'Zero missed visits'} color="#dc2626" icon="event_busy" />
      </div>
      <div style={{ display: 'flex', gap: 12, flex: 1 }}>
        <div className="ka-card" style={{ flex: 1.4, padding: '18px 18px', borderRadius: 12 }}>
          <div style={{ fontSize: 15, fontWeight: 600 }}>Weekly Appointments (Last 7 Days)</div>
          <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 4 }}>Completed vs Scheduled visits</div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 30, height: 230, padding: '24px 12px 0' }}>
            {week.map((w) => (
              <div key={w.label} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
                <div style={{ display: 'flex', alignItems: 'flex-end', gap: 5, height: 180 }}>
                  <span style={{ width: 16, height: `${(w.completed / max) * 100}%`, background: '#0d9488', borderRadius: '4px 4px 0 0' }} />
                  <span style={{ width: 16, height: `${(w.scheduled / max) * 100}%`, background: 'color-mix(in srgb, #2563eb 30%, transparent)', borderRadius: '4px 4px 0 0' }} />
                </div>
                <span style={{ fontSize: 12, color: 'var(--muted)' }}>{w.label}</span>
              </div>
            ))}
          </div>
          <div style={{ display: 'flex', gap: 16, fontSize: 12, color: 'var(--ink-2)', marginTop: 12 }}>
            <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 3, background: '#0d9488', marginRight: 6 }} />Completed</span>
            <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 3, background: 'color-mix(in srgb, #2563eb 30%, transparent)', marginRight: 6 }} />Scheduled</span>
          </div>
        </div>
        <div className="ka-card" style={{ flex: 1, padding: '18px 18px', borderRadius: 12 }} data-tour="next-patients">
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <div style={{ fontSize: 15, fontWeight: 600, flex: 1 }}>Next Patients Today</div>
            <button type="button" className="ka-btn sm" data-tour="view-board" onClick={() => go('queue')}>View Board<Icon n="arrow_forward" size={16} /></button>
          </div>
          <div style={{ marginTop: 12 }}>
            {upcoming.length === 0 && <div style={{ color: 'var(--muted)', padding: 20, textAlign: 'center' }}>No more scheduled patients for today</div>}
            {upcoming.map((a) => {
              const p = db.patients.find((x) => x.id === a.patientId)!;
              const s = db.services.find((x) => x.id === a.serviceId)!;
              const pr = db.practitioners.find((x) => x.id === a.practitionerId);
              return (
                <div key={a.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 0', borderBottom: '1px solid var(--border)' }}>
                  <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--primary-ink)', width: 132 }}>{fmtRange(a.start, s.minutes)}</span>
                  <span style={{ flex: 1, minWidth: 0 }}>
                    <b style={{ display: 'block', fontSize: 14, fontWeight: 600 }}>{p.name}</b>
                    <span style={{ fontSize: 12, color: 'var(--muted)' }}>{s.name} · {pr?.name ?? 'Unassigned'}</span>
                  </span>
                  <span className="ka-pill blue">Booked</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

export function Dashboard() {
  const role = useApp((s) => s.role);
  return role === 'superadmin' ? <NetworkDashboard /> : <BranchDashboard />;
}
