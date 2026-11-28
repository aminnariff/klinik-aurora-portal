import { useRef, useState } from 'react';
import { useApp } from '../store';
import { BoxSelect, Icon, Popover } from '../ui';
import { ActivePill, Field, FormDialog, Grid, ListTable, ListToolbar, TextInput, ToolBtn } from '../kit';
import { HOME_BRANCH, fmtMonthYear, fmtStamp, smartMonthOffset, startOfToday, ymd, type Practitioner } from '../data';

const TYPES = ['Doctor', 'Sonographer', 'Therapist', 'Spa Therapist', 'Dietitian'];

function PractitionerDialog() {
  const { db, role, closeDialog, openDialog, patch } = useApp();
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [type, setType] = useState<string | null>(null);
  const [branch, setBranch] = useState<string | null>(role === 'superadmin' ? null : HOME_BRANCH);
  const [photo, setPhoto] = useState(false);
  const save = () => {
    if (!name || !phone || !type || !branch) return openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Please fill in name, contact number, type and branch.' });
    const pr: Practitioner = { id: useApp.getState().nextId('pr'), name, phone, type: type === 'Sonographer' ? 'Sonographer' : 'Doctor', branchId: branch, joined: new Date().toISOString(), active: true };
    patch((d) => ({ ...d, practitioners: [pr, ...d.practitioners] }), pr.id);
    closeDialog();
    openDialog({ kind: 'status', tone: 'success', title: 'Success!', message: 'Successfully created new practitioner' });
  };
  return (
    <FormDialog title="New Practitioner" subtitle="Set up practitioner details, assigned branch, and photo" icon="person_add" width={680} tour="pr-dialog" onSave={save} saveLabel="Create Practitioner" saveTour="pr-save">
      <div className="ka-sec-label" style={{ marginBottom: 14 }}>General Information</div>
      <Grid>
        <Field label="Practitioner Name" required><TextInput tour="pr-name" value={name} onChange={setName} placeholder="e.g. Dr. Siti Aminah" /></Field>
        <Field label="Practitioner Contact No." required><TextInput tour="pr-phone" value={phone} onChange={setPhone} placeholder="e.g. 0123456789" /></Field>
        <Field label="Practitioner Type" required><BoxSelect tour="pr-type" value={type} onChange={setType} placeholder="Select" options={TYPES.map((t) => ({ value: t, label: t }))} /></Field>
        <Field label="Branch" required><BoxSelect tour="pr-branch" value={branch} onChange={setBranch} options={db.branches.map((b) => ({ value: b.id, label: b.name }))} /></Field>
      </Grid>
      <div className="ka-sec-label" style={{ margin: '22px 0 12px' }}>Practitioner Photo</div>
      <button type="button" data-tour="pr-photo" onClick={() => setPhoto(true)} style={{ width: '100%', padding: 22, borderRadius: 10, border: `1.5px dashed ${photo ? 'var(--success)' : 'var(--border-strong)'}`, background: photo ? 'var(--success-soft)' : 'var(--surface-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12 }}>
        <Icon n={photo ? 'check_circle' : 'cloud_upload'} size={26} style={{ color: photo ? 'var(--success)' : 'var(--muted)' }} />
        <span style={{ textAlign: 'left' }}><b style={{ display: 'block', fontSize: 14 }}>{photo ? 'photo-practitioner.jpg' : 'Upload Photo'}</b><span style={{ fontSize: 12, color: 'var(--muted)' }}>{photo ? 'Uploaded · 412 KB' : 'PNG, JPG up to 5MB'}</span></span>
      </button>
    </FormDialog>
  );
}

const pad = (n: number) => String(n).padStart(2, '0');

function RosterDialog() {
  const { db, closeDialog, patch, showToast, openDialog } = useApp();
  const today = startOfToday();
  const [prId, setPrId] = useState<string | null>(null);
  const [dates, setDates] = useState<string[]>([]);
  const [slots, setSlots] = useState<{ start: string; end: string }[]>([{ start: '09:00', end: '13:00' }]);
  const [view, setView] = useState<'calendar' | 'list'>('calendar');
  const staff = db.practitioners.filter((p) => p.branchId === HOME_BRANCH);
  const [offset, setOffset] = useState(smartMonthOffset);
  const base = new Date(today.getFullYear(), today.getMonth() + offset, 1);
  const y = base.getFullYear(), m = base.getMonth();
  const first = new Date(y, m, 1).getDay();
  const nDays = new Date(y, m + 1, 0).getDate();
  const cells = [...Array((first + 6) % 7).fill(null), ...Array.from({ length: nDays }, (_, i) => i + 1)];
  while (cells.length % 7) cells.push(null);
  const shifts = db.shifts.filter((s) => s.branchId === HOME_BRANCH && s.date.startsWith(`${y}-${pad(m + 1)}`));
  const toggle = (k: string) => setDates((d) => (d.includes(k) ? d.filter((x) => x !== k) : [...d, k].sort()));
  const add = () => {
    if (!prId) return openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Please select both a branch and a practitioner.' });
    if (!dates.length) return openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Please select at least one shift date.' });
    const st = useApp.getState();
    const created = dates.flatMap((d) => slots.map((sl) => ({ id: st.nextId('sh'), practitionerId: prId, branchId: HOME_BRANCH, date: d, start: sl.start, end: sl.end })));
    patch((d) => ({ ...d, shifts: [...d.shifts.filter((s) => !(s.practitionerId === prId && dates.includes(s.date))), ...created] }));
    showToast(`Successfully added ${created.length} shifts`);
    setDates([]);
  };
  const initials = (id: string) => db.practitioners.find((p) => p.id === id)!.name.replace(/^(Dr\.|Pn\.)\s*/, '').split(' ').slice(0, 2).map((w) => w[0]).join('');
  const colorOf = (id: string) => ({ 'pr-aina': '#0d9488', 'pr-mira': '#7c3aed', 'pr-farah': '#db2777' } as Record<string, string>)[id] ?? '#2563eb';
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 1240, height: 800 }} onClick={(e) => e.stopPropagation()} data-tour="roster-dialog">
        <div className="ka-dialog-head">
          <span className="ka-dialog-badge"><Icon n="calendar_month" size={22} /></span>
          <div style={{ flex: 1 }}><h2>Branch Practitioner Roster &amp; Shifts</h2><p>Klinik Aurora Bukit Rimau · Current Branch</p></div>
          <button type="button" className="ka-dialog-close" onClick={closeDialog}><Icon n="close" /></button>
        </div>
        <div style={{ flex: 1, minHeight: 0, display: 'flex' }}>
          <div style={{ width: 380, borderRight: '1px solid var(--border)', padding: 18, display: 'flex', flexDirection: 'column', gap: 14, overflow: 'auto' }} data-tour="roster-form">
            <div style={{ fontSize: 15, fontWeight: 700 }}>Configure Practitioner Shifts</div>
            <Field label="Select Doctor" required>
              <BoxSelect tour="roster-doctor" value={prId} onChange={setPrId} placeholder="Select Practitioner" options={staff.map((p) => ({ value: p.id, label: `${p.name} (${p.type})` }))} />
            </Field>
            <div>
              <span className="ka-field-label">Shift Dates (Multi-Select) <i>*</i></span>
              <div style={{ border: '1px solid var(--border-strong)', borderRadius: 8, padding: 10 }} data-tour="roster-dates">
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 4, textAlign: 'center' }}>
                  {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => <span key={d} style={{ fontSize: 11, color: 'var(--muted)', fontWeight: 600 }}>{d}</span>)}
                  {cells.map((d, i) => {
                    if (!d) return <span key={i} />;
                    const k = ymd(new Date(y, m, d));
                    const on = dates.includes(k);
                    const past = new Date(y, m, d) < today;
                    return (
                      <button key={i} type="button" disabled={past} data-tour={`roster-day-${d}`} onClick={() => toggle(k)} style={{ height: 30, borderRadius: 6, border: 'none', fontSize: 12.5, fontWeight: on ? 700 : 500, background: on ? 'var(--primary)' : 'transparent', color: on ? '#fff' : past ? 'var(--border-strong)' : 'var(--ink)' }}>{d}</button>
                    );
                  })}
                </div>
                <div style={{ fontSize: 11.5, color: 'var(--muted)', marginTop: 6 }}>{dates.length ? `${dates.length} date${dates.length > 1 ? 's' : ''} selected` : 'At least one shift date is required.'}</div>
              </div>
            </div>
            <div>
              <span className="ka-field-label">Daily Shift Slots (Break Time Supported)</span>
              {slots.map((sl, i) => (
                <div key={i} data-tour={`roster-slot-${i}`} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                  <span style={{ fontSize: 12, fontWeight: 600, width: 46, color: 'var(--muted)' }}>Slot {i + 1}</span>
                  <span className="ka-input" style={{ height: 38, flex: 1, fontSize: 13 }}><Icon n="schedule" size={16} />{sl.start}</span>
                  <span style={{ color: 'var(--muted)' }}>–</span>
                  <span className="ka-input" style={{ height: 38, flex: 1, fontSize: 13 }}><Icon n="schedule" size={16} />{sl.end}</span>
                  {i > 0 && <button type="button" className="ka-tb-icon" style={{ width: 30, height: 30 }} onClick={() => setSlots(slots.filter((_, k) => k !== i))}><Icon n="remove_circle_outline" size={18} style={{ color: 'var(--danger)' }} /></button>}
                </div>
              ))}
              <button type="button" className="ka-link" data-tour="roster-add-slot" onClick={() => setSlots([...slots, { start: '14:00', end: '18:00' }])} style={{ fontSize: 12.5 }}><Icon n="add_circle_outline" size={16} />Add Time Slot (e.g. Break Time)</button>
            </div>
            <span style={{ flex: 1 }} />
            <button type="button" className="ka-btn primary lg" data-tour="roster-save" onClick={add}><Icon n="event_available" size={18} />Add Shifts ({dates.length * slots.length})</button>
          </div>
          <div style={{ flex: 1, minWidth: 0, padding: 18, display: 'flex', flexDirection: 'column', gap: 12 }} data-tour="roster-calendar">
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 15, fontWeight: 700 }}>Roster Shifts ({shifts.length})</span>
              <span className="ka-pill violet" style={{ fontSize: 11 }}>Multi-Staff Capacity Active</span>
              <span style={{ flex: 1 }} />
              <button type="button" className="ka-btn sm" disabled={offset === 0} onClick={() => setOffset(offset - 1)}><Icon n="chevron_left" size={16} />Sebelumnya</button>
              <b style={{ fontSize: 14, width: 130, textAlign: 'center' }}>{fmtMonthYear(y, m)}</b>
              <button type="button" className="ka-btn sm" disabled={offset >= 1} onClick={() => setOffset(offset + 1)}>Seterusnya<Icon n="chevron_right" size={16} /></button>
              <div style={{ display: 'flex', padding: 3, borderRadius: 8, background: 'var(--surface-subtle)', marginLeft: 6 }}>
                {(['calendar', 'list'] as const).map((v) => <button key={v} type="button" onClick={() => setView(v)} style={{ height: 28, padding: '0 10px', border: 'none', borderRadius: 6, fontSize: 12, fontWeight: 600, background: view === v ? 'var(--surface)' : 'transparent', color: view === v ? 'var(--ink)' : 'var(--muted)' }}>{v === 'calendar' ? 'Calendar' : 'List'}</button>)}
              </div>
            </div>
            {view === 'calendar' ? (
              <div style={{ flex: 1, minHeight: 0, display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gridAutoRows: '1fr', gap: 4 }}>
                {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => <span key={d} style={{ fontSize: 11.5, fontWeight: 700, color: 'var(--muted)', textAlign: 'center', alignSelf: 'end' }}>{d}</span>)}
                {cells.map((d, i) => {
                  if (!d) return <span key={i} />;
                  const k = ymd(new Date(y, m, d));
                  const day = shifts.filter((s) => s.date === k);
                  const ids = [...new Set(day.map((s) => s.practitionerId))];
                  return (
                    <div key={i} style={{ border: '1px solid var(--border)', borderRadius: 6, padding: 4, overflow: 'hidden', background: k === ymd(today) ? 'var(--primary-soft)' : 'var(--surface)' }}>
                      <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--ink-2)' }}>{d}</div>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 3, marginTop: 2 }}>
                        {ids.map((id) => <span key={id} title={db.practitioners.find((p) => p.id === id)!.name} style={{ fontSize: 9.5, fontWeight: 800, color: '#fff', background: colorOf(id), borderRadius: 4, padding: '1px 4px' }}>{initials(id)}</span>)}
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div style={{ flex: 1, overflow: 'auto' }}>
                <table className="ka-table"><thead><tr>{['Staff', 'Date', 'Day', 'Role', 'Shift Hours'].map((h) => <th key={h}>{h}</th>)}</tr></thead>
                  <tbody>{shifts.slice(0, 40).map((s) => { const p = db.practitioners.find((x) => x.id === s.practitionerId)!; const dt = new Date(s.date); return <tr key={s.id}><td style={{ height: 40 }}>{p.name}</td><td>{s.date}</td><td>{dt.toLocaleDateString('en-US', { weekday: 'long' })}</td><td>{p.type}</td><td>{s.start} – {s.end}</td></tr>; })}</tbody>
                </table>
              </div>
            )}
            <div style={{ display: 'flex', gap: 12, fontSize: 12, color: 'var(--ink-2)' }}>
              {staff.map((p) => <span key={p.id} style={{ display: 'flex', alignItems: 'center', gap: 5 }}><span style={{ width: 10, height: 10, borderRadius: 3, background: colorOf(p.id) }} />{p.name}</span>)}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function RowMenu() {
  const ref = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);
  return (
    <>
      <button ref={ref} type="button" className="ka-dots" onClick={() => setOpen(true)}><Icon n="more_horiz" /></button>
      {open && (
        <Popover anchor={ref.current} onClose={() => setOpen(false)} width={200} align="right" className="ka-menu rich">
          <button type="button" className="ka-menu-item" onClick={() => setOpen(false)}><Icon n="edit" v="o" />Update</button>
          <button type="button" className="ka-menu-item danger" onClick={() => setOpen(false)}><Icon n="block" />Deactivate</button>
        </Popover>
      )}
    </>
  );
}

export function Doctors() {
  const { db, role, openDialog, highlightId } = useApp();
  const [q, setQ] = useState('');
  const list = db.practitioners.filter((p) => (role === 'superadmin' || p.branchId === HOME_BRANCH) && (!q || p.name.toLowerCase().includes(q.toLowerCase())));
  return (
    <div className="ka-page" style={{ height: '100%', padding: 0, gap: 0 }}>
      <ListToolbar placeholder="Search by practitioner name..." value={q} onChange={setQ}>
        <ToolBtn icon="tune" label="Filter" />
        <span className="ka-icon-square"><Icon n="refresh" /></span>
        <ToolBtn icon="calendar_month" label="Branch Roster" tone="plum" tour="branch-roster" onClick={() => openDialog({ kind: 'custom', render: () => <RosterDialog /> })} />
        <ToolBtn icon="person_add_alt_1" label="Add Practitioner" primary tour="add-practitioner" onClick={() => openDialog({ kind: 'custom', render: () => <PractitionerDialog /> })} />
      </ListToolbar>
      <ListTable head={['Practitioners', 'Contact', 'Branch', 'Status', 'Joined', { label: '', width: 60 }]} total={list.length}>
        {list.map((p) => (
          <tr key={p.id} className={p.id === highlightId ? 'hl' : ''} data-tour={p.id === highlightId ? 'pr-row-new' : `pr-row-${p.id}`}>
            <td>
              <div className="ka-cell-person">
                <span style={{ width: 40, height: 40, borderRadius: '50%', background: p.type === 'Doctor' ? 'linear-gradient(135deg,#fecdd3,#fb7185)' : 'linear-gradient(135deg,#ddd6fe,#a78bfa)', display: 'grid', placeItems: 'center' }}><Icon n="person" size={24} style={{ color: '#fff' }} /></span>
                <div><div style={{ fontSize: 14 }}>{p.name}</div><span className={`ka-pill ${p.type === 'Doctor' ? 'blue' : 'violet'}`} style={{ height: 19, fontSize: 11, marginTop: 3 }}>{p.type}</span></div>
              </div>
            </td>
            <td>{p.phone}</td>
            <td>{db.branches.find((b) => b.id === p.branchId)!.name}</td>
            <td><ActivePill on={p.active} /></td>
            <td style={{ fontSize: 13, color: 'var(--ink-2)' }}>{fmtStamp(p.joined)}</td>
            <td><RowMenu /></td>
          </tr>
        ))}
      </ListTable>
    </div>
  );
}
