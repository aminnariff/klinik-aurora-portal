import { useState } from 'react';
import { useApp } from '../store';
import { Icon } from '../ui';
import { HOME_BRANCH, fmtTime, startOfToday, ymd, type Appointment, type QueueStatus } from '../data';

type Stage = 'scheduled' | 'checked_in' | 'in_room' | 'done';
const COLUMNS: { stage: Stage; title: string; icon: string; color: string }[] = [
  { stage: 'scheduled', title: 'Scheduled', icon: 'schedule', color: 'var(--info)' },
  { stage: 'checked_in', title: 'Checked In', icon: 'how_to_reg', color: 'var(--warning)' },
  { stage: 'in_room', title: 'In Scan / Room', icon: 'medical_services', color: 'var(--primary-ink)' },
  { stage: 'done', title: 'Completed / No-Show', icon: 'check_circle_outline', color: 'var(--success)' },
];

const stageOf = (a: Appointment): Stage => {
  const q: QueueStatus = a.queue ?? (a.status === 'Completed' ? 'completed' : a.status === 'No-Show' ? 'no_show' : 'scheduled');
  return q === 'completed' || q === 'no_show' ? 'done' : q;
};

function KpiPill({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', height: 38, padding: '0 12px', borderRadius: 8, background: 'var(--surface)', border: '1px solid var(--border)' }}>
      <span style={{ fontSize: 12, color: 'var(--muted)', fontWeight: 500 }}>{label}: </span>
      <span style={{ fontSize: 13, color, fontWeight: 800, marginLeft: 4 }}>{value}</span>
    </span>
  );
}

function Card({ a }: { a: Appointment }) {
  const { db, setQueue, openDialog } = useApp();
  const p = db.patients.find((x) => x.id === a.patientId)!;
  const s = db.services.find((x) => x.id === a.serviceId)!;
  const pr = db.practitioners.find((x) => x.id === a.practitionerId);
  const stage = stageOf(a);
  const paid = a.payment !== 'No Payment';
  const wait = a.queue === 'checked_in' && a.checkedInAt ? Math.max(1, Math.round((Date.now() - new Date(a.checkedInAt).getTime()) / 60000) % 40) : 0;
  const noShow = a.queue === 'no_show' || a.status === 'No-Show';
  return (
    <div data-tour={`q-card-${a.id}`} style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 8, padding: 12, display: 'flex', flexDirection: 'column', gap: 8, animation: 'ka-dialog-in .3s ease' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <span style={{ fontSize: 11, fontWeight: 800, color: 'var(--primary-ink)', background: 'var(--primary-soft)', borderRadius: 6, padding: '3px 7px' }}>{fmtTime(new Date(a.start))}</span>
        <span style={{ fontSize: 11, fontWeight: 700, borderRadius: 6, padding: '3px 7px', background: paid ? 'var(--success-soft)' : 'var(--warning-soft)', color: paid ? 'var(--success-text)' : 'var(--warning-text)' }}>{paid ? 'Deposit Paid' : 'Unpaid'}</span>
        <span style={{ flex: 1 }} />
        {wait > 0 && <span style={{ fontSize: 11, fontWeight: 800, color: wait >= 20 ? 'var(--danger)' : 'var(--warning-text)' }}>{wait}m wait</span>}
        {noShow && <span style={{ fontSize: 11, fontWeight: 800, color: 'var(--danger)' }}>NO-SHOW</span>}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
        <span style={{ fontSize: 14, fontWeight: 700 }}>{p.name}</span><Icon n="open_in_new" size={13} style={{ color: 'var(--muted)' }} />
      </div>
      <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--ink-2)', marginTop: -4 }}>{s.name}</div>
      <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: -4, display: 'flex', alignItems: 'center', gap: 4 }}>
        <Icon n="person" size={13} />{pr?.name ?? 'Unassigned'}{a.room && stage === 'in_room' && <><span>·</span><Icon n="meeting_room" size={13} />{a.room}</>}
      </div>
      <div style={{ display: 'flex', gap: 6, marginTop: 2 }}>
        {stage === 'scheduled' && (
          <>
            <button type="button" className="ka-btn primary sm" data-tour={`q-checkin-${a.id}`} style={{ flex: 1, height: 32 }} onClick={() => setQueue(a.id, 'checked_in')}>Check In</button>
            <button type="button" title="Mark no-show" className="ka-icon-square" style={{ width: 32, height: 32 }} onClick={() => setQueue(a.id, 'no_show')}><Icon n="person_off" size={18} style={{ color: 'var(--danger)' }} /></button>
          </>
        )}
        {stage === 'checked_in' && (
          <>
            <button type="button" className="ka-btn sm" data-tour={`q-room-${a.id}`} style={{ flex: 1, height: 32 }} onClick={() => openDialog({ kind: 'roomPicker', appointmentId: a.id })}>To Room</button>
            <button type="button" className="ka-btn sm" data-tour={`q-checkout-${a.id}`} style={{ height: 32 }} onClick={() => openDialog({ kind: 'checkout', appointmentId: a.id })}><Icon n="point_of_sale" size={14} />Checkout</button>
          </>
        )}
        {stage === 'in_room' && (
          <button type="button" className="ka-btn sm" data-tour={`q-complete-${a.id}`} style={{ flex: 1, height: 32, background: '#059669', borderColor: '#059669', color: '#fff' }} onClick={() => openDialog({ kind: 'checkout', appointmentId: a.id })}><Icon n="point_of_sale" size={15} />Complete &amp; Checkout</button>
        )}
        {stage === 'done' && (
          <>
            <span style={{ flex: 1, fontSize: 11, color: 'var(--muted)', fontWeight: 600, alignSelf: 'center' }}>Done · {noShow ? 'No-Show' : 'Completed'}</span>
            <button type="button" className="ka-btn sm" data-tour={`q-next-${a.id}`} style={{ height: 28 }} onClick={() => openDialog({ kind: 'newAppointment', patientId: p.id })}>Next</button>
          </>
        )}
      </div>
    </div>
  );
}

export function Queue() {
  const db = useApp((s) => s.db);
  const [q, setQ] = useState('');
  const today = ymd(startOfToday());
  const list = db.appointments
    .filter((a) => a.branchId === HOME_BRANCH && ymd(new Date(a.start)) === today && a.status !== 'Cancelled')
    .filter((a) => {
      if (!q) return true;
      const p = db.patients.find((x) => x.id === a.patientId)!;
      const s = db.services.find((x) => x.id === a.serviceId)!;
      return `${p.name} ${s.name}`.toLowerCase().includes(q.toLowerCase());
    })
    .sort((a, b) => a.start.localeCompare(b.start));
  const count = (st: Stage | 'completed' | 'no_show') => list.filter((a) => (st === 'completed' ? a.queue === 'completed' || (a.status === 'Completed' && !a.queue) : st === 'no_show' ? a.status === 'No-Show' : stageOf(a) === st)).length;
  const waits = list.filter((a) => a.queue === 'checked_in').length;
  const dateLabel = startOfToday().toLocaleDateString('en-GB', { weekday: 'short', day: '2-digit', month: 'short', year: 'numeric' }).replace(',', ',');
  return (
    <div className="ka-page" style={{ height: '100%', padding: '20px 24px' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 22, fontWeight: 800 }}>Today&apos;s Schedule &amp; Appointments</div>
          <div style={{ fontSize: 13, color: 'var(--muted)', marginTop: 2 }}>View daily booked appointments, check patients in, and complete visits with automatic counter math &amp; points reward.</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, border: '1px solid var(--border)', borderRadius: 8, background: 'var(--surface)', height: 40 }}>
          <button type="button" className="ka-tb-icon" style={{ width: 36, height: 36 }}><Icon n="chevron_left" /></button>
          <span style={{ fontSize: 13, fontWeight: 600, padding: '0 4px' }}>{dateLabel}</span>
          <button type="button" className="ka-tb-icon" style={{ width: 36, height: 36 }}><Icon n="chevron_right" /></button>
        </div>
        <div style={{ display: 'flex', border: '1px solid var(--border)', borderRadius: 8, background: 'var(--surface)', height: 40, alignItems: 'center' }}>
          <span style={{ width: 40, display: 'grid', placeItems: 'center' }}><Icon n="view_agenda" size={18} style={{ color: 'var(--muted)' }} /></span>
          <span style={{ width: 1, height: 20, background: 'var(--border)' }} />
          <span style={{ width: 40, display: 'grid', placeItems: 'center' }}><Icon n="view_column" size={18} style={{ color: 'var(--primary-ink)' }} /></span>
        </div>
        <button type="button" className="ka-btn primary lg"><Icon n="refresh" size={16} />Refresh</button>
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, alignItems: 'center' }}>
        <label className="ka-search" style={{ flex: 'none', width: 280, height: 38 }}>
          <Icon n="search" /><input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Filter patient, service, doctor... (/)" />
        </label>
        <KpiPill label="Total Bookings" value={String(list.length)} color="var(--ink)" />
        <KpiPill label="Scheduled" value={String(count('scheduled'))} color="var(--info)" />
        <KpiPill label="Checked In" value={String(count('checked_in'))} color="var(--warning)" />
        <KpiPill label="In Room" value={String(count('in_room'))} color="var(--primary-ink)" />
        <KpiPill label="Completed" value={String(count('completed'))} color="var(--success)" />
        <KpiPill label="No-Show" value={String(count('no_show'))} color="var(--danger)" />
        <KpiPill label="Avg Wait" value={`${waits ? 12 : 0} min`} color="var(--ink-2)" />
      </div>
      <div style={{ flex: 1, minHeight: 0, display: 'grid', gridTemplateColumns: 'repeat(4, minmax(0, 1fr))', gap: 12 }}>
        {COLUMNS.map((c) => {
          const items = list.filter((a) => stageOf(a) === c.stage);
          return (
            <div key={c.stage} data-tour={`q-col-${c.stage}`} style={{ display: 'flex', flexDirection: 'column', minHeight: 0, borderRadius: 8, border: '1px solid var(--border)', background: 'var(--surface-subtle)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 12px', borderBottom: `2px solid ${c.color}`, background: 'var(--surface)', borderRadius: '8px 8px 0 0' }}>
                <Icon n={c.icon} size={17} style={{ color: c.color }} />
                <span style={{ flex: 1, fontSize: 13, fontWeight: 700 }}>{c.title}</span>
                <span style={{ fontSize: 11, fontWeight: 800, color: c.color, background: `color-mix(in srgb, ${c.color} 14%, transparent)`, borderRadius: 999, padding: '2px 8px' }}>{items.length}</span>
              </div>
              <div style={{ flex: 1, overflow: 'auto', padding: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
                {items.length === 0 && <div style={{ fontSize: 12, color: 'var(--muted)', textAlign: 'center', padding: 24 }}>No patients here</div>}
                {items.map((a) => <Card key={a.id} a={a} />)}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
