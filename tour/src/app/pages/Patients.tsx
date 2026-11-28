import { useRef, useState } from 'react';
import { useApp } from '../store';
import { Avatar, Icon, Pager, Popover } from '../ui';
import { fmtStamp } from '../data';

function RowMenu({ patientId }: { patientId: string }) {
  const ref = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);
  const { openDialog, go } = useApp();
  const pick = (fn: () => void) => () => { setOpen(false); fn(); };
  return (
    <>
      <button ref={ref} type="button" className="ka-dots" data-tour={`row-menu-${patientId}`} onClick={() => setOpen(true)}><Icon n="more_horiz" /></button>
      {open && (
        <Popover anchor={ref.current} onClose={() => setOpen(false)} width={224} align="right" offset={14} className="ka-menu rich" tour="row-menu">
          <button type="button" className="ka-menu-item"><Icon n="edit" v="o" />Update Info</button>
          <button type="button" className="ka-menu-item" data-tour="menu-book" onClick={pick(() => openDialog({ kind: 'newAppointment', patientId }))}><Icon n="calendar_today" v="o" />Book Appointment</button>
          <button type="button" className="ka-menu-item" onClick={pick(() => go('appointments'))}><Icon n="history" />Appointment History</button>
          <button type="button" className="ka-menu-item" onClick={pick(() => go('points'))}><Icon n="stars" />Manage Points</button>
          <button type="button" className="ka-menu-item danger"><Icon n="block" />Deactivate</button>
        </Popover>
      )}
    </>
  );
}

export function Patients() {
  const { db, openDialog, highlightId } = useApp();
  const [q, setQ] = useState('');
  const branchName = (id: string | null) => db.branches.find((b) => b.id === id)?.name ?? '—';
  const list = db.patients.filter((p) => !q || `${p.name} ${p.username} ${p.phone} ${p.email}`.toLowerCase().includes(q.toLowerCase()));
  return (
    <div className="ka-page" style={{ height: '100%' }}>
      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        <label className="ka-search" data-tour="patient-search">
          <Icon n="search" />
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search by name, username..." />
        </label>
        <button type="button" className="ka-btn lg"><Icon n="tune" />Filter</button>
        <span className="ka-icon-square"><Icon n="refresh" /></span>
        <button type="button" className="ka-btn primary lg" data-tour="add-patient" onClick={() => openDialog({ kind: 'registerPatient' })}><Icon n="person_add_alt_1" />Add Patient</button>
      </div>
      <div className="ka-card ka-table-wrap">
        <div className="ka-table-scroll">
          <table className="ka-table">
            <thead>
              <tr><th>Patient</th><th>Mobile No.</th><th>Points</th><th>Registered Branch</th><th>Status</th><th>Joined</th><th style={{ width: 60 }} /></tr>
            </thead>
            <tbody>
              {list.map((p, i) => (
                <tr key={p.id} className={p.id === highlightId ? 'hl' : ''} data-tour={p.id === highlightId ? 'patient-row-new' : `patient-row-${p.id}`}>
                  <td>
                    <div className="ka-cell-person"><Avatar name={p.name} idx={i} /><div><b>{p.name}</b><span>{p.email}</span></div></div>
                  </td>
                  <td>{p.phone}</td>
                  <td><span className="ka-pts">{p.points}</span></td>
                  <td>{branchName(p.branchId)}</td>
                  <td><span className="ka-pill green">Active</span></td>
                  <td style={{ fontSize: 12, color: 'var(--muted)' }}>{fmtStamp(p.joined)}</td>
                  <td><RowMenu patientId={p.id} /></td>
                </tr>
              ))}
            </tbody>
          </table>
          {!list.length && <div className="ka-empty" style={{ padding: 60 }}><div><b>No patients found</b>Try a different name or number</div></div>}
        </div>
        <Pager total={list.length} shown={Math.min(15, list.length)} />
      </div>
    </div>
  );
}
