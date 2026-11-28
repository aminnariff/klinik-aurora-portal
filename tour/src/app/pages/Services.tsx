import { useRef, useState } from 'react';
import { useApp } from '../store';
import { BoxSelect, Icon, Popover } from '../ui';
import { ActivePill, Field, FormDialog, Grid, ListTable, ListToolbar, TextInput, Toggle, ToolBtn } from '../kit';
import { HOME_BRANCH, addDays, durationLabel, emptyTiming, fmtMonthYear, fmtStamp, slotKey, smartMonthOffset, startOfToday, ymd, type Service, type Session, type TimingRule } from '../data';

const CATEGORIES = ['Pregnancy Scan (Baby Scan)', 'General Scan', 'Family Planning', "Women's Health", 'Circumcision', 'Spa Service'];
const DURATIONS = [15, 20, 30, 45, 60, 90, 120];

function ServiceDialog() {
  const { closeDialog, openDialog, patch } = useApp();
  const [f, setF] = useState({ name: '', category: null as string | null, type: null as string | null, price: '', fee: '', minutes: null as string | null, desc: '', active: true });
  const set = <K extends keyof typeof f>(k: K) => (v: (typeof f)[K]) => setF((x) => ({ ...x, [k]: v }));
  const save = () => {
    if (!f.name) return openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Service Name is required' });
    if (!f.category) return openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Category is required' });
    if (!f.minutes) return openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Duration is required' });
    const sv: Service = { id: useApp.getState().nextId('sv'), name: f.name, category: f.category, description: f.desc, minutes: Number(f.minutes), price: Number(f.price) || 0, fee: Number(f.fee) || undefined, type: f.type === 'Doctor' ? 'Doctor' : 'Sonographer', active: f.active, created: new Date().toISOString(), pregnancy: f.category.startsWith('Pregnancy') };
    patch((d) => ({ ...d, services: [sv, ...d.services] }), sv.id);
    closeDialog();
    openDialog({ kind: 'status', tone: 'success', title: 'Success!', message: 'Successfully created new Service' });
  };
  return (
    <FormDialog title="New Clinical Service" subtitle="Service details, pricing and booking fee" icon="medical_services" width={760} tour="sv-dialog" onSave={save} saveLabel="Create Service" saveTour="sv-save"
      extraHead={<Toggle on={f.active} onChange={set('active')} label={f.active ? 'Active' : 'Inactive'} />}>
      <div className="ka-sec-label" style={{ marginBottom: 14 }}>Service Information</div>
      <Grid>
        <Field label="Service Name" required><TextInput tour="sv-name" value={f.name} onChange={set('name')} placeholder="e.g. 5D Scan" /></Field>
        <Field label="Service Category" required><BoxSelect tour="sv-category" value={f.category} onChange={set('category')} options={CATEGORIES.map((c) => ({ value: c, label: c }))} /></Field>
        <Field label="Performed By / Doctor Type" required><BoxSelect tour="sv-type" value={f.type} onChange={set('type')} placeholder="Select practitioner role" options={['Doctor', 'Sonographer', 'Therapist', 'Spa Therapist', 'Dietitian'].map((c) => ({ value: c, label: c }))} /></Field>
        <Field label="Estimated Duration" required><BoxSelect tour="sv-duration" value={f.minutes} onChange={set('minutes')} options={DURATIONS.map((m) => ({ value: String(m), label: durationLabel(m) }))} /></Field>
        <Field label="Price (RM)" required><TextInput tour="sv-price" value={f.price} onChange={(v) => set('price')(v.replace(/[^\d.]/g, ''))} prefix={<span style={{ fontWeight: 600, color: 'var(--ink-2)' }}>RM</span>} placeholder="0.00" /></Field>
        <Field label="Booking Fee (RM)" hint="Paid online when the patient books. Leave empty if none."><TextInput tour="sv-fee" value={f.fee} onChange={(v) => set('fee')(v.replace(/[^\d.]/g, ''))} prefix={<span style={{ fontWeight: 600, color: 'var(--ink-2)' }}>RM</span>} placeholder="0.00" /></Field>
        <Field label="Description" required span={2}><TextInput area tour="sv-desc" value={f.desc} onChange={set('desc')} placeholder="Clinical scope, procedure overview, and instructions..." height={80} /></Field>
      </Grid>
      <div className="ka-sec-label" style={{ margin: '22px 0 12px' }}>Service Image</div>
      <div style={{ padding: 16, borderRadius: 10, border: '1.5px dashed var(--border-strong)', background: 'var(--surface-subtle)', fontSize: 13, color: 'var(--muted)', display: 'flex', alignItems: 'center', gap: 10 }}><Icon n="image" size={22} />Upload or paste an image URL below</div>
      <div className="ka-sec-label" style={{ margin: '22px 0 0' }}>WhatsApp Notification Templates</div>
    </FormDialog>
  );
}

const PRESETS = [15, 30, 45, 60, 90, 120];
const fmtDur = (m: number) => (m < 60 ? `${m} minutes` : m % 60 === 0 ? `${m / 60} hour${m === 60 ? '' : 's'}` : `${Math.floor(m / 60)}h ${m % 60}m`);

/** change_service_duration_dialog.dart — branch-level duration, session and timing rules. */
function DurationDialog({ sv }: { sv: Service }) {
  const { db, closeDialog, openDialog, patch } = useApp();
  const key = slotKey(sv.id, HOME_BRANCH);
  const saved = db.timing[key] ?? emptyTiming();
  const current = saved.minutes ?? sv.minutes;
  const [mins, setMins] = useState(current);
  const [custom, setCustom] = useState('');
  const [unit, setUnit] = useState<string | null>('minutes');
  const [session, setSession] = useState<Session>(saved.session);
  const [adv, setAdv] = useState(saved.weekday != null || saved.weekend != null || Object.keys(saved.dates).length > 0);
  const [weekday, setWeekday] = useState<string | null>(saved.weekday ? String(saved.weekday) : 'default');
  const [weekend, setWeekend] = useState<string | null>(saved.weekend ? String(saved.weekend) : 'default');
  const [dates, setDates] = useState<[string, string][]>(Object.entries(saved.dates).map(([d, m]) => [d, String(m)]));
  const durOpts = [{ value: 'default', label: 'Default (Branch)' }, ...PRESETS.map((m) => ({ value: String(m), label: fmtDur(m) }))];
  const applyCustom = (v: string, u = unit) => { setCustom(v); const n = Number(v); if (n > 0) setMins(u === 'hours' ? Math.round(n * 60) : n); };
  const addDate = () => {
    const used = new Set(dates.map(([d]) => d));
    let d = addDays(startOfToday(), 14);
    while (d.getDay() !== 6 || used.has(ymd(d))) d = addDays(d, 1);
    setDates([...dates, [ymd(d), String(mins)]]);
  };
  const rule = (): TimingRule => ({
    minutes: mins === sv.minutes ? undefined : mins,
    weekday: adv && weekday !== 'default' ? Number(weekday) : undefined,
    weekend: adv && weekend !== 'default' ? Number(weekend) : undefined,
    dates: adv ? Object.fromEntries(dates.map(([d, m]) => [d, Number(m)])) : {},
    session,
  });
  const commit = (r: TimingRule) => {
    patch((d) => ({ ...d, timing: { ...d.timing, [key]: r } }), sv.id);
    useApp.setState((st) => ({ dialogs: st.dialogs.filter((x) => x.kind !== 'custom') }));
    openDialog({ kind: 'status', tone: 'success', title: 'Success!', message: r.minutes == null && !adv && session === 'both' ? `Duration reverted to HQ standard (${fmtDur(sv.minutes)}).` : `Service duration updated to ${fmtDur(mins)} for Klinik Aurora Bukit Rimau.` });
  };
  const save = () => {
    const overlaps = mins > current ? db.appointments.filter((a) => a.serviceId === sv.id && a.branchId === HOME_BRANCH && a.status === 'Booked' && new Date(a.start) >= startOfToday()) : [];
    if (!overlaps.length) return commit(rule());
    const lines = overlaps.slice(0, 5).map((a) => `• ${db.patients.find((p) => p.id === a.patientId)!.name} (${new Date(a.start).toLocaleString('en-GB', { day: '2-digit', month: 'short', hour: 'numeric', minute: '2-digit' })})`).join('\n');
    openDialog({ kind: 'custom', render: () => (
      <div className="ka-overlay blur" onClick={() => useApp.getState().closeDialog()}>
        <div className="ka-alert" style={{ width: 480, background: 'var(--surface-elevated)' }} onClick={(e) => e.stopPropagation()} data-tour="overlap-dialog">
          <h3><Icon n="warning_amber" size={22} style={{ color: '#d97706' }} />Future Appointments Will Overlap</h3>
          <div style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.55, whiteSpace: 'pre-line' }}>{`Changing this duration will update future appointments and cause ${overlaps.length} slot overlap(s):\n\n${lines}\n\nAre you sure you want to proceed?`}</div>
          <div className="ka-alert-actions">
            <button type="button" className="ka-text-btn" data-tour="overlap-cancel" style={{ color: 'var(--ink-2)' }} onClick={() => useApp.getState().closeDialog()}>Cancel</button>
            <button type="button" className="ka-btn primary" onClick={() => commit(rule())}>Proceed Anyway</button>
          </div>
        </div>
      </div>
    ) });
  };
  const sessionChip = (v: Session, label: string, icon: string) => (
    <button key={v} type="button" data-tour={`session-${v}`} onClick={() => setSession(v)} className="ka-btn" style={{ height: 38, fontSize: 13, ...(session === v ? { background: 'var(--primary-soft)', borderColor: 'var(--primary)', color: 'var(--primary-ink)', fontWeight: 700 } : {}) }}>
      <Icon n={icon} v="o" size={17} />{label}
    </button>
  );
  const secLabel = (t: string) => <div style={{ fontSize: 13, fontWeight: 700, margin: '0 0 8px' }}>{t}</div>;
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 640 }} onClick={(e) => e.stopPropagation()} data-tour="duration-dialog">
        <div className="ka-dialog-head">
          <span className="ka-dialog-badge"><Icon n="timer" size={22} /></span>
          <div style={{ flex: 1 }}><h2>Change Service Duration</h2><p>{sv.name} · Klinik Aurora Bukit Rimau</p></div>
          <button type="button" className="ka-dialog-close" onClick={closeDialog} title="Close"><Icon n="close" /></button>
        </div>
        <div className="ka-dialog-body" style={{ display: 'flex', flexDirection: 'column', gap: 18, maxHeight: 600 }} data-tour="duration-body">
          <div style={{ display: 'flex', gap: 24, padding: '12px 14px', borderRadius: 10, background: 'var(--surface-subtle)', border: '1px solid var(--border)', fontSize: 13 }}>
            <span><span style={{ color: 'var(--muted)' }}>HQ Standard Duration: </span><b>{fmtDur(sv.minutes)}</b></span>
            <span><span style={{ color: 'var(--muted)' }}>Current Status: </span><b style={{ color: saved.minutes != null ? 'var(--violet-text)' : 'var(--ink)' }}>{saved.minutes != null ? `Branch Custom: ${fmtDur(saved.minutes)}` : 'Using HQ Default'}</b></span>
          </div>
          <div>
            {secLabel('Quick Presets')}
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {PRESETS.map((m) => <button key={m} type="button" data-tour={`dur-${m}`} onClick={() => { setMins(m); setCustom(''); }} className="ka-btn" style={m === mins ? { background: 'var(--primary)', borderColor: 'var(--primary)', color: '#fff' } : {}}>{fmtDur(m)}</button>)}
            </div>
          </div>
          <div>
            {secLabel('Or Set Custom Duration')}
            <div style={{ display: 'flex', gap: 8 }}>
              <div style={{ flex: 1 }}><TextInput tour="dur-custom" value={custom} onChange={(v) => applyCustom(v.replace(/[^\d.]/g, ''))} placeholder="e.g. 40" height={42} /></div>
              <div style={{ width: 150 }}><BoxSelect tour="dur-unit" value={unit} onChange={(u) => { setUnit(u); if (custom) applyCustom(custom, u); }} options={[{ value: 'minutes', label: 'Minutes' }, { value: 'hours', label: 'Hours' }]} /></div>
            </div>
            <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 8 }} data-tour="dur-willbe">Will be set to: <b style={{ color: 'var(--primary-ink)' }}>{fmtDur(mins)}</b></div>
          </div>
          <div data-tour="session-box">
            {secLabel('Preferred Session (Mobile Booking)')}
            <div style={{ display: 'flex', gap: 8 }}>
              {sessionChip('both', 'Both (All Day)', 'schedule')}{sessionChip('first_half', 'First Half (< 12 PM)', 'wb_sunny')}{sessionChip('second_half', 'Second Half (≥ 12 PM)', 'nights_stay')}
            </div>
            <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 8, display: 'flex', gap: 6 }}><Icon n="info" v="o" size={14} style={{ marginTop: 1 }} />Mobile app hides slots outside this session. Staff can still override with a confirmation prompt.</div>
          </div>
          <div style={{ borderRadius: 10, border: `1px solid ${adv ? 'color-mix(in srgb, var(--primary) 40%, transparent)' : 'var(--border)'}`, overflow: 'hidden' }} data-tour="adv-box">
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: 12, background: adv ? 'var(--primary-soft)' : 'transparent' }}>
              <Icon n="tune" size={20} style={{ color: adv ? 'var(--primary-ink)' : 'var(--muted)' }} />
              <div style={{ flex: 1 }}><div style={{ fontSize: 13.5, fontWeight: 700 }}>Advanced Timing Rules</div><div style={{ fontSize: 12, color: 'var(--muted)' }}>Configure separate weekday, weekend, or date-specific durations</div></div>
              <Toggle tour="adv-toggle" on={adv} onChange={setAdv} label="Active" />
            </div>
            {adv && (
              <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 12, borderTop: '1px solid var(--border)' }}>
                {([['Weekday Duration (Mon–Fri)', 'Overrides standard duration on weekdays', weekday, setWeekday, 'adv-weekday'], ['Weekend Duration (Sat–Sun)', 'Overrides standard duration on weekends', weekend, setWeekend, 'adv-weekend']] as const).map(([t, sub, val, set, tour]) => (
                  <div key={tour} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div style={{ flex: 1 }}><div style={{ fontSize: 13, fontWeight: 600 }}>{t}</div><div style={{ fontSize: 11.5, color: 'var(--muted)' }}>{sub}</div></div>
                    <div style={{ width: 180 }}><BoxSelect tour={tour} value={val} onChange={set} options={durOpts} /></div>
                  </div>
                ))}
                <div style={{ height: 1, background: 'var(--border)' }} />
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <div style={{ flex: 1 }}><div style={{ fontSize: 13, fontWeight: 600 }}>Specific Date Overrides</div><div style={{ fontSize: 11.5, color: 'var(--muted)' }}>For promotional campaigns or special clinic events</div></div>
                  <button type="button" className="ka-btn sm" data-tour="adv-add-date" onClick={addDate}><Icon n="add" size={16} />Add Date</button>
                </div>
                {dates.length === 0 && <div style={{ fontSize: 12, color: 'var(--muted)', textAlign: 'center', padding: 8 }}>No specific date overrides configured</div>}
                {dates.map(([d, m], i) => (
                  <div key={d} data-tour={`adv-date-${i}`} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 10px', borderRadius: 8, background: 'var(--surface-subtle)' }}>
                    <Icon n="event" v="o" size={16} style={{ color: 'var(--ink-2)' }} />
                    <span style={{ flex: 1, fontSize: 13, fontWeight: 600 }}>{new Date(d).toLocaleDateString('en-GB', { weekday: 'short', day: '2-digit', month: 'short', year: 'numeric' })}</span>
                    <div style={{ width: 150 }}><BoxSelect tour={`adv-date-dur-${i}`} value={m} onChange={(v) => setDates(dates.map((x, k) => (k === i ? [x[0], v] : x)))} options={PRESETS.map((p) => ({ value: String(p), label: fmtDur(p) }))} /></div>
                    <button type="button" className="ka-tb-icon" title="Remove" style={{ width: 30, height: 30 }} onClick={() => setDates(dates.filter((_, k) => k !== i))}><Icon n="delete_outline" size={18} style={{ color: 'var(--danger)' }} /></button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
        <div className="ka-dialog-foot" style={{ justifyContent: 'space-between' }}>
          <button type="button" className="ka-text-btn" style={{ color: 'var(--ink-2)' }} onClick={() => commit(emptyTiming())}>Reset to HQ Default ({fmtDur(sv.minutes)})</button>
          <div style={{ display: 'flex', gap: 10 }}>
            <button type="button" className="ka-btn lg" onClick={closeDialog}>Cancel</button>
            <button type="button" className="ka-btn primary lg" data-tour="dur-save" onClick={save}>Save Duration</button>
          </div>
        </div>
      </div>
    </div>
  );
}

function SlotCalendar({ sv }: { sv: Service }) {
  const { db, closeDialog, patch, openDialog } = useApp();
  const key = slotKey(sv.id, HOME_BRANCH);
  const saved = db.slotConfig[key] ?? { times: [], dates: [] };
  const [times, setTimes] = useState<string[]>(saved.times);
  const [dates, setDates] = useState<Record<string, string[]>>(() => Object.fromEntries(saved.times.map((t) => [t, [...saved.dates]])));
  const [gen, setGen] = useState(false);
  const [interval, setInterval] = useState(String(db.timing[key]?.minutes ?? sv.minutes));
  const [days, setDays] = useState<'weekdays' | 'mon-sat' | 'all'>('mon-sat');
  const [lunch, setLunch] = useState(true);
  const today = startOfToday();
  const [offset, setOffset] = useState(smartMonthOffset);
  const view = new Date(today.getFullYear(), today.getMonth() + offset, 1);
  const monthDays = Array.from({ length: new Date(view.getFullYear(), view.getMonth() + 1, 0).getDate() }, (_, i) => new Date(view.getFullYear(), view.getMonth(), i + 1)).filter((d) => d >= today);
  const toggleDate = (t: string, k: string) => setDates((x) => ({ ...x, [t]: x[t]!.includes(k) ? x[t]!.filter((d) => d !== k) : [...x[t]!, k] }));
  const generate = () => {
    const step = Number(interval);
    const out: string[] = [];
    for (let m = 9 * 60; m + step <= 17 * 60; m += step) {
      if (lunch && m < 14 * 60 && m + step > 13 * 60) { m = 14 * 60 - step; continue; }
      out.push(`${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`);
    }
    const target = Array.from({ length: 42 }, (_, i) => addDays(today, i + 1)).filter((d) => (days === 'all' ? true : days === 'weekdays' ? d.getDay() >= 1 && d.getDay() <= 5 : d.getDay() !== 0)).map(ymd);
    setTimes(out);
    setDates(Object.fromEntries(out.map((t) => [t, target])));
    setGen(false);
  };
  const save = () => {
    const all = [...new Set(Object.values(dates).flat())].sort();
    patch((d) => ({ ...d, slotConfig: { ...d.slotConfig, [key]: { times, dates: all } } }));
    closeDialog();
    openDialog({ kind: 'status', tone: 'success', title: 'Success!', message: 'Successfully saved the available appointment slots.' });
  };
  const label = (t: string) => { const [h, m] = t.split(':').map(Number); return `${(h! % 12) || 12}:${String(m).padStart(2, '0')} ${h! >= 12 ? 'PM' : 'AM'}`; };
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 1260, height: 820, background: 'var(--canvas)' }} onClick={(e) => e.stopPropagation()} data-tour="slot-calendar">
        <div className="ka-dialog-head" style={{ background: 'var(--surface)' }}>
          <span className="ka-dialog-badge"><Icon n="edit_calendar" size={22} /></span>
          <div style={{ flex: 1 }}><h2>{sv.name} · Appointment Slots</h2><p>Klinik Aurora Bukit Rimau · times patients can book</p></div>
          <button type="button" className="ka-btn" data-tour="slot-generator" onClick={() => setGen(true)}><Icon n="auto_fix_high" size={18} />Generator</button>
          <button type="button" className="ka-btn primary" data-tour="slot-save" onClick={save}><Icon n="save" size={18} />Save All</button>
          <button type="button" className="ka-dialog-close" onClick={closeDialog} style={{ marginLeft: 6 }}><Icon n="close" /></button>
        </div>
        <div style={{ flex: 1, minHeight: 0, display: 'flex', gap: 16, padding: 16 }}>
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
            <div className="ka-card" style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 8px 6px 16px', borderRadius: 8 }}>
              <Icon n="calendar_month" size={20} style={{ color: 'var(--primary-ink)' }} />
              <b style={{ fontSize: 15, flex: 1 }}>{fmtMonthYear(view.getFullYear(), view.getMonth())}</b>
              <button type="button" className="ka-tb-icon" disabled={offset === 0} onClick={() => setOffset(0)}><Icon n="chevron_left" /></button>
              <button type="button" className="ka-tb-icon" data-tour="slotcal-next" onClick={() => setOffset(1)}><Icon n="chevron_right" /></button>
            </div>
            <div style={{ flex: 1, overflow: 'auto', marginTop: 12, display: 'flex', flexDirection: 'column', gap: 12 }} data-tour="slot-cards">
              {times.length === 0 && <div className="ka-empty"><div><Icon n="event_note" size={60} style={{ color: 'var(--border)' }} /><b>No slots configured</b></div></div>}
              {times.map((t, ti) => {
                const picked = (dates[t] ?? []).filter((k) => k.startsWith(ymd(view).slice(0, 7)));
                return (
                  <div key={t} className="ka-card" data-tour={`slot-card-${ti}`} style={{ borderRadius: 8 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 14px', background: 'var(--surface-subtle)', borderRadius: '8px 8px 0 0' }}>
                      <span style={{ width: 34, height: 34, borderRadius: 8, background: 'var(--primary-soft)', display: 'grid', placeItems: 'center' }}><Icon n="access_time_filled" size={19} style={{ color: 'var(--primary-ink)' }} /></span>
                      <div style={{ flex: 1 }}><div style={{ fontSize: 15, fontWeight: 800 }}>{label(t)}</div><div style={{ fontSize: 11, color: 'var(--muted)' }}>{picked.length} dates picked</div></div>
                    </div>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 5, padding: 10 }}>
                      {monthDays.map((d) => {
                        const k = ymd(d);
                        const on = (dates[t] ?? []).includes(k);
                        return <button key={k} type="button" data-tour={`slot-chip-${ti}-${d.getDate()}`} onClick={() => toggleDate(t, k)} style={{ width: 40, height: 34, borderRadius: 6, fontSize: 12, fontWeight: 600, border: `1px solid ${on ? 'var(--primary)' : 'var(--border)'}`, background: on ? 'var(--primary)' : 'var(--surface)', color: on ? '#fff' : d.getDay() === 0 ? 'var(--danger)' : 'var(--muted)' }}><div style={{ fontSize: 9, fontWeight: 500, opacity: 0.8 }}>{d.toLocaleDateString('en-US', { weekday: 'short' })}</div>{d.getDate()}</button>;
                      })}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
          <div style={{ width: 340, display: 'flex', flexDirection: 'column', gap: 12 }}>
            {gen ? (
              <div className="ka-card" style={{ borderRadius: 10, padding: 16, display: 'flex', flexDirection: 'column', gap: 14 }} data-tour="gen-panel">
                <div><div style={{ fontSize: 15, fontWeight: 800 }}>Weekly Slot Generator</div><div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>Fast-track your schedule by syncing working hours across days.</div></div>
                <Field label="Slot Interval"><BoxSelect tour="gen-interval" value={interval} onChange={setInterval} options={[30, 45, 60].map((m) => ({ value: String(m), label: `${m} minutes` }))} /></Field>
                <div>
                  <div className="ka-field-label">Master Timing</div>
                  <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}><span className="ka-input" style={{ height: 38, fontSize: 13 }}>09:00 AM</span>–<span className="ka-input" style={{ height: 38, fontSize: 13 }}>05:00 PM</span></div>
                  <div style={{ marginTop: 10 }}><Toggle tour="gen-lunch" on={lunch} onChange={setLunch} label="Lunch break 1:00 – 2:00 PM" /></div>
                </div>
                <div>
                  <div className="ka-field-label">Quick Select Days</div>
                  <div style={{ display: 'flex', gap: 6 }}>
                    {([['weekdays', 'Weekdays'], ['mon-sat', 'Mon – Sat'], ['all', 'All']] as const).map(([k, l]) => <button key={k} type="button" data-tour={`gen-days-${k}`} onClick={() => setDays(k)} className="ka-btn sm" style={k === days ? { background: 'var(--primary)', borderColor: 'var(--primary)', color: '#fff' } : {}}>{l}</button>)}
                  </div>
                </div>
                <button type="button" className="ka-btn primary lg" data-tour="gen-run" onClick={generate}><Icon n="bolt" size={18} />Generate All Slots</button>
              </div>
            ) : (
              <div className="ka-card" style={{ borderRadius: 10, padding: 16 }} data-tour="slot-summary">
                <div style={{ fontSize: 15, fontWeight: 800 }}>Summary</div>
                <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>Overview of scheduled appointments.</div>
                <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
                  <div style={{ flex: 1, padding: 12, borderRadius: 8, background: 'var(--surface-subtle)' }}><div style={{ fontSize: 22, fontWeight: 800 }}>{times.length}</div><div style={{ fontSize: 12, color: 'var(--muted)' }}>times a day</div></div>
                  <div style={{ flex: 1, padding: 12, borderRadius: 8, background: 'var(--surface-subtle)' }}><div style={{ fontSize: 22, fontWeight: 800 }}>{Object.values(dates).reduce((s, l) => s + l.length, 0)}</div><div style={{ fontSize: 12, color: 'var(--muted)' }}>bookable slots</div></div>
                </div>
                <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 14, lineHeight: 1.5 }}>Tap a date under a time to close just that slot, for example a public holiday or staff leave. Press <b>Save All</b> when done.</div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function RowMenu({ sv, branch }: { sv: Service; branch: boolean }) {
  const ref = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);
  const openDialog = useApp((s) => s.openDialog);
  const pick = (fn: () => void) => () => { setOpen(false); fn(); };
  return (
    <>
      <button ref={ref} type="button" className="ka-dots" data-tour={`sv-menu-${sv.id}`} onClick={() => setOpen(true)} style={{ width: 30, height: 30, background: 'var(--surface-subtle)', border: 'none' }}><Icon n={branch ? 'more_vert' : 'more_horiz'} /></button>
      {open && (
        <Popover anchor={ref.current} onClose={() => setOpen(false)} width={260} align="right" className="ka-menu rich" tour="sv-menu">
          {!branch && <button type="button" className="ka-menu-item" onClick={() => setOpen(false)}><Icon n="edit" v="o" />Edit Service</button>}
          {!branch && (
            <button type="button" className="ka-menu-item" data-tour="menu-branch-service" onClick={pick(() => openDialog({ kind: 'custom', render: () => <SlotCalendar sv={sv} /> }))}>
              <Icon n="edit_calendar" v="o" />Update Branch Service<span className="ka-pill grey" style={{ height: 18, fontSize: 10, marginLeft: 'auto' }}>Discontinued</span>
            </button>
          )}
          <button type="button" className="ka-menu-item" data-tour="menu-duration" onClick={pick(() => openDialog({ kind: 'custom', render: () => <DurationDialog sv={sv} /> }))}><Icon n="timer" v="o" />Change Duration</button>
          <button type="button" className="ka-menu-item danger" onClick={() => setOpen(false)}><Icon n="power_settings_new" />{branch ? 'Disable at this branch' : 'Deactivate'}</button>
        </Popover>
      )}
    </>
  );
}

const HUE: Record<string, string> = { 'Pregnancy Scan (Baby Scan)': '#0d9488', 'General Scan': '#0d9488', 'Family Planning': '#db2777', "Women's Health": '#7c3aed', Circumcision: '#2563eb' };

function TimeBadge({ s, branch }: { s: Service; branch: boolean }) {
  const { db, openDialog } = useApp();
  const t = db.timing[slotKey(s.id, HOME_BRANCH)];
  const mins = t?.minutes ?? s.minutes;
  const rules = !!t && (t.weekday != null || t.weekend != null || Object.keys(t.dates).length > 0 || t.session !== 'both');
  return (
    <button type="button" data-tour={`sv-time-${s.id}`} title={branch ? 'Click to change duration' : undefined} onClick={() => branch && openDialog({ kind: 'custom', render: () => <DurationDialog sv={s} /> })}
      style={{ border: 'none', background: 'none', padding: '4px 6px', margin: '-4px -6px', borderRadius: 6, textAlign: 'left', cursor: branch ? 'pointer' : 'default' }}>
      <span style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 13, color: 'var(--ink)' }}><Icon n="schedule" size={15} style={{ color: 'var(--muted)' }} />{durationLabel(mins)}{branch && <Icon n="edit" size={13} style={{ color: 'var(--muted)' }} />}</span>
      {(t?.minutes != null || rules) && (
        <span style={{ display: 'flex', gap: 4, marginTop: 4 }}>
          {t?.minutes != null && <span className="ka-pill violet" style={{ height: 18, fontSize: 10.5 }}>Custom</span>}
          {rules && <span className="ka-pill amber" style={{ height: 18, fontSize: 10.5 }}>Rules Active</span>}
        </span>
      )}
    </button>
  );
}

export function Services() {
  const { db, role, openDialog, highlightId } = useApp();
  const [q, setQ] = useState('');
  const branch = role !== 'superadmin';
  const list = db.services.filter((s) => !q || s.name.toLowerCase().includes(q.toLowerCase()));
  return (
    <div className="ka-page" style={{ height: '100%', padding: 0, gap: 0 }}>
      <ListToolbar placeholder="Search services..." value={q} onChange={setQ}>
        <ToolBtn icon="calendar_month" label="Branch Roster" tone="plum" />
        {!branch && <ToolBtn icon="filter_list" label="Filter" tone="blue" />}
        <ToolBtn icon="refresh" label={branch ? 'Refresh' : 'Reset'} onClick={() => setQ('')} />
        {!branch && <ToolBtn icon="add" label="Add Service" primary tour="add-service" onClick={() => openDialog({ kind: 'custom', render: () => <ServiceDialog /> })} />}
      </ListToolbar>
      <ListTable head={['Service', 'Description', 'Time', 'Price', 'Type', 'Status', 'Created', { label: 'Actions', width: 80 }]} total={list.length} pages={branch ? 1 : 3}>
        {list.map((s) => {
          const hue = HUE[s.category] ?? '#0d9488';
          return (
            <tr key={s.id} className={s.id === highlightId ? 'hl' : ''} data-tour={s.id === highlightId && !branch ? 'sv-row-new' : `sv-row-${s.id}`} style={{ height: 64 }}>
              <td>
                <div className="ka-cell-person">
                  <span style={{ width: 38, height: 38, borderRadius: 8, background: `color-mix(in srgb, ${hue} 14%, transparent)`, display: 'grid', placeItems: 'center' }}><Icon n={s.type === 'Sonographer' ? 'sensors' : 'healing'} size={19} style={{ color: hue }} /></span>
                  <div><div style={{ fontSize: 14 }}>{s.name}</div><span className="ka-pill grey" style={{ height: 19, fontSize: 11, marginTop: 3 }}>{s.category}</span></div>
                </div>
              </td>
              <td style={{ fontSize: 12.5, color: 'var(--ink-2)', whiteSpace: 'pre-line', maxWidth: 220 }}>{s.description || '—'}</td>
              <td><TimeBadge s={s} branch={branch} /></td>
              <td><div style={{ fontSize: 14 }}>RM {s.price.toFixed(2)}</div>{s.fee && <div style={{ fontSize: 11.5, color: 'var(--muted)' }}>Fee: RM {s.fee.toFixed(2)}</div>}</td>
              <td><span className={`ka-pill ${s.type === 'Doctor' ? 'blue' : 'violet'}`}>{s.type}</span></td>
              <td><ActivePill on={s.active} /></td>
              <td style={{ fontSize: 12.5, color: 'var(--ink-2)' }}>{fmtStamp(s.created).split(' ')[0]}<div>{fmtStamp(s.created).split(' ')[1]}</div></td>
              <td><RowMenu sv={s} branch={branch} /></td>
            </tr>
          );
        })}
      </ListTable>
    </div>
  );
}
