import { useRef, useState } from 'react';
import { useApp } from '../store';
import { Icon, Pager, Popover } from '../ui';
import { HOME_BRANCH, addDays, ageOf, fmtDayDate, fmtLongDate, fmtMonthYear, fmtRange, startOfToday, ymd, type Appointment, type ApptStatus } from '../data';
import { CheckSlotsDialog, GuidelineDialog } from '../dialogs/AppointmentTools';

type Tab = 'Upcoming' | 'Completed' | 'No-Show' | 'Cancelled';
const TAB_STATUS: Record<Tab, ApptStatus[]> = { Upcoming: ['Booked', 'Rescheduled'], Completed: ['Completed'], 'No-Show': ['No-Show'], Cancelled: ['Cancelled'] };
const TAB_COLOR: Record<Tab, [string, string]> = {
  Upcoming: ['#2196f3', '#e3f2fd'], Completed: ['#16a34a', '#dcfce7'], 'No-Show': ['#d97706', '#fef3c7'], Cancelled: ['#dc2626', '#fee2e2'],
};
const RANGES = ['Today', 'Yesterday', 'Last Month', 'This Month', 'Next Month', 'Next 3 Months', 'All Time'];

function StatusPill({ s }: { s: ApptStatus }) {
  const map: Record<ApptStatus, string> = { Booked: 'blue', Completed: 'green', 'No-Show': 'amber', Cancelled: 'red', Rescheduled: 'violet', Transferred: 'blue' };
  return <span className={`ka-pill ${map[s]}`} style={{ border: '1px solid color-mix(in srgb, currentColor 30%, transparent)' }}>● {s}</span>;
}

function PaymentPill({ p }: { p: string }) {
  if (p === 'Paid') return <span className="ka-pill green"><Icon n="check_circle" size={15} />Paid</span>;
  if (p === 'Fee Paid') return <span className="ka-pill amber"><Icon n="receipt" size={15} />Booking Fee</span>;
  return <span className="ka-pill blue"><Icon n="block" size={15} />No Payment</span>;
}

function RowMenu({ id, patientId, status }: { id: string; patientId: string; status: ApptStatus }) {
  const ref = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);
  const openDialog = useApp((s) => s.openDialog);
  const pick = (fn: () => void) => () => { setOpen(false); fn(); };
  const locked = status === 'Cancelled' || status === 'Transferred';
  const canTransfer = status === 'Booked' || status === 'Rescheduled';
  const item = (tour: string, icon: string, color: string, label: string, fn: () => void) => (
    <button type="button" className="ka-menu-item" data-tour={tour} onClick={pick(fn)}><Icon n={icon} size={20} style={{ color }} />{label}</button>
  );
  return (
    <>
      <button ref={ref} type="button" className="ka-dots" data-tour={`appt-menu-${id}`} onClick={() => setOpen(true)}><Icon n="more_horiz" /></button>
      {open && (
        <Popover anchor={ref.current} onClose={() => setOpen(false)} width={260} align="right" offset={6} tour="appt-menu">
          {/* Same rules as appointment_homepage.dart: cancelled/transferred bookings are locked; only Booked/Rescheduled can transfer. */}
          {!locked && item('appt-menu-checkout', 'point_of_sale', 'var(--success)', 'Counter Checkout & Points', () => openDialog({ kind: 'checkout', appointmentId: id }))}
          {item('appt-menu-next', 'calendar_month', '#2563eb', 'Book Next Appointment', () => openDialog({ kind: 'newAppointment', patientId }))}
          {item('appt-menu-update', locked ? 'visibility' : 'edit', 'var(--ink-2)', locked ? 'View Details' : 'Update', () => openDialog({ kind: 'updateAppointment', appointmentId: id }))}
          {canTransfer && item('appt-menu-transfer', 'swap_horiz', '#2563eb', 'Transfer Branch', () => openDialog({ kind: 'transfer', appointmentId: id }))}
        </Popover>
      )}
    </>
  );
}

function ToolButton({ icon, tip, color, tour, onClick, alignRight }: { icon: string; tip: string; color: string; tour: string; onClick: () => void; alignRight?: boolean }) {
  return (
    <button type="button" className={`ka-tip${alignRight ? ' r' : ''}`} data-tip={tip} data-tour={tour} aria-label={tip} onClick={onClick}
      style={{ width: 34, height: 34, borderRadius: 8, border: 'none', display: 'grid', placeItems: 'center', background: `color-mix(in srgb, ${color} 12%, transparent)` }}>
      <Icon n={icon} size={18} style={{ color }} />
    </button>
  );
}

/** appointment_calendar_view.dart — month grid with counts, selected day's bookings on the right. */
function CalendarLayout({ rows }: { rows: Appointment[] }) {
  const db = useApp((s) => s.db);
  const today = startOfToday();
  const [offset, setOffset] = useState(0);
  const [twoWeeks, setTwoWeeks] = useState(false);
  const [sel, setSel] = useState(ymd(today));
  const view = new Date(today.getFullYear(), today.getMonth() + offset, 1);
  const y = view.getFullYear(), m = view.getMonth();
  let cells: (Date | null)[] = [...Array(view.getDay()).fill(null), ...Array.from({ length: new Date(y, m + 1, 0).getDate() }, (_, i) => new Date(y, m, i + 1))];
  while (cells.length % 7) cells.push(null);
  if (twoWeeks) {
    const start = addDays(today, -today.getDay());
    cells = Array.from({ length: 14 }, (_, i) => addDays(start, i));
  }
  const byDay = (k: string) => rows.filter((a) => ymd(new Date(a.start)) === k);
  const day = byDay(sel).sort((a, b) => a.start.localeCompare(b.start));
  const tomorrow = ymd(addDays(today, 1));
  const label = sel === ymd(today) ? 'Today' : sel === tomorrow ? 'Tomorrow' : fmtLongDate(sel);
  return (
    <div style={{ flex: 1, minHeight: 0, display: 'flex', borderTop: '1px solid var(--border)' }} data-tour="cal-view">
      <div style={{ width: 540, flex: 'none', padding: '18px 24px', background: 'var(--surface)', borderRight: '1px solid var(--border)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
          <button type="button" className="ka-tb-icon" onClick={() => setOffset(offset - 1)}><Icon n="chevron_left" /></button>
          <b style={{ fontSize: 17, flex: 1 }}>{fmtMonthYear(y, m)}</b>
          <button type="button" data-tour="cal-weeks" onClick={() => setTwoWeeks(!twoWeeks)} style={{ height: 28, padding: '0 12px', borderRadius: 8, border: 'none', background: 'var(--primary)', color: '#fff', fontSize: 13, fontWeight: 700 }}>{twoWeeks ? 'Month' : '2 weeks'}</button>
          <button type="button" className="ka-tb-icon" onClick={() => setOffset(offset + 1)}><Icon n="chevron_right" /></button>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', rowGap: 6 }}>
          {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) => <span key={d} style={{ textAlign: 'center', fontSize: 12, color: 'var(--ink-2)', paddingBottom: 6 }}>{d}</span>)}
          {cells.map((d, i) => {
            if (!d) return <span key={i} />;
            const k = ymd(d);
            const n = byDay(k).length;
            const isToday = k === ymd(today);
            const isSel = k === sel;
            const outside = d.getMonth() !== m && !twoWeeks;
            return (
              <button key={i} type="button" data-tour={n ? `cal-day-has-${k}` : `cal-day-${k}`} onClick={() => setSel(k)}
                style={{ height: 48, border: isSel && !isToday ? '1.5px solid var(--primary)' : '1.5px solid transparent', borderRadius: 8, background: isSel ? 'var(--primary-soft)' : 'transparent', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 3 }}>
                <span style={{ width: 26, height: 26, borderRadius: '50%', display: 'grid', placeItems: 'center', fontSize: 13, fontWeight: isToday ? 800 : 500, background: isToday ? 'var(--primary)' : 'transparent', color: isToday ? '#fff' : outside ? 'var(--border-strong)' : 'var(--ink)' }}>{d.getDate()}</span>
                {n > 0 && <span style={{ minWidth: 16, height: 16, borderRadius: 8, padding: '0 4px', fontSize: 10, fontWeight: 700, display: 'grid', placeItems: 'center', background: 'var(--danger-soft)', color: 'var(--primary-ink)' }}>{n}</span>}
              </button>
            );
          })}
        </div>
      </div>
      <div style={{ flex: 1, minWidth: 0, padding: '18px 20px', overflow: 'auto', background: 'var(--canvas)' }} data-tour="cal-list">
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
          <Icon n="event" v="o" size={18} style={{ color: 'var(--primary-ink)' }} />
          <b style={{ fontSize: 15 }}>{label}</b>
          <span className="ka-pill red" style={{ background: 'var(--danger-soft)', color: 'var(--primary-ink)' }}>{day.length} appointment{day.length === 1 ? '' : 's'}</span>
        </div>
        {day.length === 0 && <div className="ka-empty" style={{ paddingTop: 140 }}><div><div className="ka-empty-icon" style={{ background: 'var(--surface-subtle)' }}><Icon n="event_busy" style={{ color: 'var(--muted)' }} /></div>No appointments on this day</div></div>}
        {day.map((a) => {
          const p = db.patients.find((x) => x.id === a.patientId)!;
          const s = db.services.find((x) => x.id === a.serviceId)!;
          const pr = db.practitioners.find((x) => x.id === a.practitionerId);
          return (
            <div key={a.id} className="ka-card" style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '12px 14px', borderRadius: 10, marginBottom: 8 }}>
              <div style={{ width: 120, fontSize: 12.5, fontWeight: 700, color: 'var(--primary-ink)' }}>{fmtRange(a.start, s.minutes)}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{p.name}</div>
                <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>{s.name} · {pr?.name ?? 'N/A'}</div>
              </div>
              <StatusPill s={a.status} />
            </div>
          );
        })}
      </div>
    </div>
  );
}

export function Appointments() {
  const { db, role, highlightId, apptCalendar, openDialog, go } = useApp();
  const [tab, setTab] = useState<Tab>('Upcoming');
  const [range, setRange] = useState('All Time');
  const branch = db.branches.find((b) => b.id === HOME_BRANCH)!;
  const inBranch = db.appointments.filter((a) => a.branchId === HOME_BRANCH);
  const count = (t: Tab) => inBranch.filter((a) => TAB_STATUS[t].includes(a.status)).length;
  const rows = inBranch.filter((a) => TAB_STATUS[tab].includes(a.status)).sort((a, b) => (tab === 'Upcoming' ? a.start.localeCompare(b.start) : b.start.localeCompare(a.start)));
  return (
    <div className="ka-page" style={{ height: '100%', padding: 0, gap: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 32px 8px 32px', background: 'var(--surface)' }}>
        <span style={{ fontSize: 14, fontWeight: 500, marginRight: 8 }}>Branch</span>
        <div className="ka-input" style={{ width: 320, height: 48, justifyContent: 'space-between', background: role === 'superadmin' ? 'var(--surface)' : 'var(--surface-subtle)' }}>
          <span style={{ display: 'flex', alignItems: 'center', gap: 12 }}><Icon n="store" size={17} />{branch.name}</span>
          <Icon n="keyboard_arrow_down" size={20} />
        </div>
        <span style={{ width: 1, height: 28, background: 'var(--border)', margin: '0 6px' }} />
        {!apptCalendar && RANGES.map((r) => (
          <button key={r} type="button" className="ka-btn" onClick={() => setRange(r)}
            style={{ height: 36, fontSize: 12.5, fontWeight: r === range ? 700 : 500, padding: '0 12px', ...(r === range ? { background: 'var(--primary)', color: '#fff', borderColor: 'var(--primary)' } : {}) }}>
            {r === range && <Icon n="check" size={15} />}{r}
          </button>
        ))}
        <span style={{ flex: 1 }} />
        <button type="button" className="ka-btn" style={{ height: 36, fontSize: 13 }}><Icon n="tune" size={16} />Filter</button>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 32px' }}>
        {(Object.keys(TAB_STATUS) as Tab[]).map((t) => {
          const [c, soft] = TAB_COLOR[t];
          const on = t === tab;
          return (
            <button key={t} type="button" data-tour={`tab-${t}`} onClick={() => setTab(t)} className="ka-btn"
              style={{ height: 42, fontSize: 15, fontWeight: on ? 700 : 500, gap: 10, padding: '0 16px', background: on ? c : 'var(--surface)', color: on ? '#fff' : 'var(--muted)', borderColor: on ? c : 'var(--border)' }}>
              {t}<span style={{ minWidth: 22, height: 22, padding: '0 6px', borderRadius: 6, display: 'grid', placeItems: 'center', fontSize: 13, fontWeight: 700, background: on ? 'rgba(255,255,255,.25)' : soft, color: on ? '#fff' : c }}>{count(t)}</span>
            </button>
          );
        })}
        <span style={{ flex: 1 }} />
        <div style={{ display: 'flex', gap: 4 }}>
          <ToolButton tour="appt-tool-refresh" icon="refresh" tip="Refresh" color="#2196f3" onClick={() => { setTab('Upcoming'); setRange('All Time'); }} />
          <ToolButton tour="appt-tool-slots" icon="calendar_month" tip="Check Slots" color="#059669" onClick={() => openDialog({ kind: 'custom', render: () => <CheckSlotsDialog /> })} />
          <ToolButton tour="appt-tool-layout" icon={apptCalendar ? 'table_chart' : 'calendar_month'} tip={apptCalendar ? 'Table View' : 'Calendar View'} color="#7c3aed" onClick={() => useApp.setState({ apptCalendar: !apptCalendar })} />
          <ToolButton tour="appt-tool-guide" icon="menu_book" tip="Guideline" color="var(--primary)" onClick={() => openDialog({ kind: 'custom', render: () => <GuidelineDialog /> })} />
          <ToolButton tour="appt-tool-issues" icon="warning_amber" tip="Payment Issues (paid but not in schedule)" color="#ef4444" alignRight onClick={() => go('paymentMismatch')} />
        </div>
      </div>
      {apptCalendar ? <CalendarLayout rows={rows} /> : (<>
      <div className="ka-card ka-table-wrap" style={{ margin: '0 32px', borderRadius: 10, borderBottomLeftRadius: 0, borderBottomRightRadius: 0 }}>
        <div className="ka-table-scroll">
          <table className="ka-table">
            <thead>
              <tr><th>Patient</th><th>Service</th><th>Branch</th><th>Type</th><th>Status</th><th>Payment</th><th>Date &amp; Time <Icon n="unfold_more" size={15} /></th><th>Actions</th></tr>
            </thead>
            <tbody>
              {rows.map((a) => {
                const p = db.patients.find((x) => x.id === a.patientId)!;
                const s = db.services.find((x) => x.id === a.serviceId)!;
                const pr = db.practitioners.find((x) => x.id === a.practitionerId);
                return (
                  <tr key={a.id} className={a.id === highlightId ? 'hl' : ''} data-tour={a.id === highlightId ? 'appt-row-new' : `appt-row-${a.id}`} style={{ height: 48 }}>
                    <td style={{ height: 48 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span style={{ color: 'var(--primary-ink)', fontSize: 14 }}>{p.name}</span>
                        <span style={{ fontSize: 11, fontWeight: 600, background: 'var(--surface-subtle)', border: '1px solid var(--border)', borderRadius: 4, padding: '0 5px' }}>{ageOf(p.dob)}F</span>
                      </div>
                      <div style={{ fontSize: 11, color: 'var(--muted)' }}>{p.phone}</div>
                    </td>
                    <td>{s.name}</td>
                    <td style={{ maxWidth: 150, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>Klinik Aurora Bukit ...</td>
                    <td>
                      <span style={{ display: 'inline-block', background: 'var(--surface-subtle)', borderRadius: 4, padding: '4px 8px', fontSize: 13 }}>
                        {s.type}{pr && <span style={{ display: 'block', fontSize: 11, color: 'var(--primary-ink)' }}>{pr.name}</span>}
                      </span>
                    </td>
                    <td><StatusPill s={a.status} /></td>
                    <td><PaymentPill p={a.payment} /></td>
                    <td>
                      <div style={{ fontSize: 14 }}>{fmtDayDate(a.start)}</div>
                      <div style={{ fontSize: 11, color: 'var(--muted)' }}>{fmtRange(a.start, s.minutes)}</div>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="#16a34a" aria-hidden><path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2zm0 18.2a8.2 8.2 0 0 1-4.2-1.2l-.3-.2-3 .8.8-2.9-.2-.3A8.2 8.2 0 1 1 12 20.2zm4.5-6.1c-.2-.1-1.5-.7-1.7-.8-.2-.1-.4-.1-.6.1l-.8 1c-.1.2-.3.2-.5.1a6.7 6.7 0 0 1-3.3-2.9c-.3-.4.3-.4.8-1.4.1-.2 0-.3 0-.4l-.8-1.8c-.2-.5-.4-.4-.6-.4h-.5a1 1 0 0 0-.7.3 3 3 0 0 0-.9 2.2 5.2 5.2 0 0 0 1.1 2.7 11.8 11.8 0 0 0 4.5 4c1.7.7 2.4.8 3.2.6.5-.1 1.5-.6 1.7-1.2.2-.6.2-1.1.2-1.2-.1-.1-.3-.2-.5-.3z" /></svg>
                        <RowMenu id={a.id} patientId={a.patientId} status={a.status} />
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {!rows.length && (
            <div className="ka-empty" style={{ padding: 120 }}>
              <div><div className="ka-empty-icon"><Icon n="event_busy" /></div><b>No {tab.toLowerCase()} appointments</b>Try adjusting the date range or filters</div>
            </div>
          )}
        </div>
      </div>
      <div style={{ margin: '0 0 0', background: 'var(--canvas)' }}><Pager total={rows.length} shown={rows.length} /></div>
      </>)}
    </div>
  );
}
