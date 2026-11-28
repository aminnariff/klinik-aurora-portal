import { useState } from 'react';
import { useApp } from '../store';
import { FloatSelect, Icon } from '../ui';
import { TextInput } from '../kit';
import { fmtSlot, rm } from '../data';

/** transfer_appointment_dialog.dart */
export function TransferDialog({ appointmentId }: { appointmentId: string }) {
  const { db, closeDialog, openDialog, updateAppointment } = useApp();
  const a = db.appointments.find((x) => x.id === appointmentId)!;
  const p = db.patients.find((x) => x.id === a.patientId)!;
  const s = db.services.find((x) => x.id === a.serviceId)!;
  const from = db.branches.find((b) => b.id === a.branchId)!;
  const [target, setTarget] = useState<string | null>(null);
  const [slot, setSlot] = useState<string | null>(null);
  const [reason, setReason] = useState('');
  const [remark, setRemark] = useState('');
  const err = (message: string) => openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message });
  const confirm = () => {
    if (!target) return err('Please select the target branch.');
    if (!slot) return err('Please select an available timeslot at the target branch.');
    if (!reason.trim()) return err('Please enter the reason for transfer.');
    const name = db.branches.find((b) => b.id === target)!.name;
    updateAppointment(a.id, { branchId: target, fromBranchId: a.branchId, start: slot, status: 'Booked', adminRemark: remark || undefined, note: `Transferred: ${reason}` });
    useApp.setState((st) => ({ dialogs: st.dialogs.filter((d) => d.kind !== 'transfer' && d.kind !== 'updateAppointment') }));
    openDialog({ kind: 'status', tone: 'success', title: 'Success!', message: `Appointment successfully transferred to ${name}!` });
  };
  const info = (label: string, value: string) => (
    <div><div style={{ fontSize: 11.5, color: 'var(--muted)', fontWeight: 600 }}>{label}</div><div style={{ fontSize: 13.5, fontWeight: 600, marginTop: 3 }}>{value}</div></div>
  );
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 560 }} onClick={(e) => e.stopPropagation()} data-tour="transfer-dialog">
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '18px 20px', borderBottom: '1px solid var(--border)' }}>
          <span style={{ width: 40, height: 40, borderRadius: 10, display: 'grid', placeItems: 'center', background: 'color-mix(in srgb, #2563eb 12%, transparent)' }}><Icon n="swap_horiz" size={22} style={{ color: '#2563eb' }} /></span>
          <div style={{ flex: 1 }}><div style={{ fontSize: 16, fontWeight: 800 }}>Transfer Appointment</div><div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>Move this appointment to another branch</div></div>
          <button type="button" className="ka-dialog-close" onClick={closeDialog} title="Tutup"><Icon n="close" size={20} /></button>
        </div>
        <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, padding: 14, borderRadius: 10, background: 'var(--surface-subtle)', border: '1px solid var(--border)' }}>
            {info('Patient', p.name)}{info('Contact', p.phone)}{info('Current Branch', from.name)}{info('Service', s.name)}
          </div>
          <div>
            <div className="ka-field-label">Target Branch *</div>
            <FloatSelect tour="transfer-branch" label="Branch" icon="store" value={target} placeholder="Select destination clinic branch..." onChange={(v) => { setTarget(v); setSlot(null); }}
              options={db.branches.filter((b) => b.id !== a.branchId).map((b) => ({ value: b.id, label: b.name }))} />
          </div>
          <div>
            <div className="ka-field-label">New Appointment Timeslot *</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 8px 8px 14px', borderRadius: 8, border: '1px solid var(--border-strong)' }} data-tour="transfer-slot">
              <Icon n="event" size={18} style={{ color: 'var(--muted)' }} />
              <span style={{ flex: 1, fontSize: 13, fontWeight: slot ? 600 : 400, color: slot ? 'var(--ink)' : 'var(--muted)' }}>{slot ? fmtSlot(slot) : 'No slot selected'}</span>
              <button type="button" data-tour="transfer-pick" onClick={() => target ? openDialog({ kind: 'slotPicker', serviceId: a.serviceId, branchId: target, onPick: setSlot }) : err('Please select the target branch first.')}
                style={{ height: 32, padding: '0 12px', borderRadius: 8, border: 'none', background: '#2563eb', color: '#fff', fontSize: 12, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>
                <Icon n="calendar_month" size={15} />Pick Slot
              </button>
            </div>
          </div>
          <div>
            <div className="ka-field-label">Transfer Reason *</div>
            <TextInput area tour="transfer-reason" value={reason} onChange={setReason} placeholder="e.g. Patient moved closer to another branch" height={70} />
          </div>
          <div>
            <div className="ka-field-label">Internal Admin Remark (Optional)</div>
            <TextInput value={remark} onChange={setRemark} placeholder="Optional staff notes" height={42} />
          </div>
        </div>
        <div className="ka-dialog-foot" style={{ background: 'var(--surface)', borderTop: '1px solid var(--border)' }}>
          <button type="button" className="ka-btn lg" onClick={closeDialog}>Cancel</button>
          <button type="button" className="ka-btn lg" data-tour="transfer-confirm" onClick={confirm} style={{ background: '#2563eb', borderColor: '#2563eb', color: '#fff' }}><Icon n="swap_horiz" size={18} />Confirm Transfer</button>
        </div>
      </div>
    </div>
  );
}

const ROOMS = ['Scan Room 1', 'Scan Room 2', 'Consult Room A', 'Consult Room B'];

/** _promptRoomAndMove in queue_board_page.dart */
export function RoomPickerDialog({ appointmentId }: { appointmentId: string }) {
  const { db, closeDialog, setQueue, showToast } = useApp();
  const a = db.appointments.find((x) => x.id === appointmentId)!;
  const p = db.patients.find((x) => x.id === a.patientId)!;
  const taken = db.appointments.filter((x) => x.queue === 'in_room' && x.id !== a.id).map((x) => x.room);
  const [room, setRoom] = useState(ROOMS.find((r) => !taken.includes(r)) ?? ROOMS[0]!);
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-alert" style={{ width: 460, background: 'var(--surface-elevated)' }} onClick={(e) => e.stopPropagation()} data-tour="room-dialog">
        <h3><Icon n="meeting_room" size={22} style={{ color: 'var(--primary-ink)' }} />Assign Room / Station</h3>
        <div style={{ fontSize: 13, color: 'var(--ink-2)' }}>Moving {p.name} into active scan/consultation.</div>
        <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--muted)', margin: '16px 0 8px' }}>Room Label</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {ROOMS.map((r) => {
            const busy = taken.includes(r);
            const on = r === room;
            return (
              <button key={r} type="button" disabled={busy} data-tour={`room-${r.replace(/\s+/g, '-').toLowerCase()}`} onClick={() => setRoom(r)}
                style={{ height: 34, padding: '0 12px', borderRadius: 999, fontSize: 13, fontWeight: 600, border: `1px solid ${on ? 'var(--primary)' : 'var(--border-strong)'}`, background: on ? 'var(--primary-soft)' : 'transparent', color: busy ? 'var(--muted)' : on ? 'var(--primary-ink)' : 'var(--ink-2)', opacity: busy ? 0.5 : 1 }}>
                {r}{busy && ' · in use'}
              </button>
            );
          })}
        </div>
        <div className="ka-alert-actions">
          <button type="button" className="ka-text-btn" style={{ color: 'var(--ink-2)' }} onClick={closeDialog}>Cancel</button>
          <button type="button" className="ka-btn primary" data-tour="room-confirm" onClick={() => { setQueue(a.id, 'in_room', room); closeDialog(); showToast(`${p.name} moved to ${room}`); }}>Move to Room</button>
        </div>
      </div>
    </div>
  );
}

function Row({ label, value, strong, tone }: { label: string; value: string; strong?: boolean; tone?: string }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: strong ? 14 : 13, fontWeight: strong ? 700 : 500, padding: '5px 0', color: tone ?? (strong ? 'var(--ink)' : 'var(--ink-2)') }}>
      <span>{label}</span><span>{value}</span>
    </div>
  );
}

function MoneyField({ label, value, onChange, tour }: { label: string; value: string; onChange: (v: string) => void; tour?: string }) {
  return (
    <div>
      <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--ink-2)', marginBottom: 6 }}>{label}</div>
      <TextInput tour={tour} value={value} onChange={(v) => onChange(v.replace(/[^\d.]/g, ''))} height={42} prefix={<span style={{ fontWeight: 600, color: 'var(--ink-2)', fontSize: 13 }}>RM</span>} placeholder="0.00" />
    </div>
  );
}

/** appointment_checkout_dialog.dart — "Complete Visit & Award Points" */
export function CheckoutDialog({ appointmentId }: { appointmentId: string }) {
  const { db, closeDialog, openDialog, checkout } = useApp();
  const a = db.appointments.find((x) => x.id === appointmentId)!;
  const p = db.patients.find((x) => x.id === a.patientId)!;
  const s = db.services.find((x) => x.id === a.serviceId)!;
  const deposit = a.payment === 'Fee Paid' ? s.fee ?? 0 : 0;
  const expected = Math.max(0, s.price - deposit);
  const [paid, setPaid] = useState(expected.toFixed(2));
  const [addons, setAddons] = useState('');
  const [discount, setDiscount] = useState('');
  const [remark, setRemark] = useState('');
  const [method, setMethod] = useState('Card terminal');
  const counter = Number(paid) || 0;
  const total = deposit + counter;
  const pts = Math.floor(total);
  const done = () => {
    if (counter < 0 || Number.isNaN(Number(paid))) return openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Please enter a valid counter payment amount.' });
    const summary = checkout(a.id, { counterPaid: counter, addons: Number(addons) || 0, discount: Number(discount) || 0, method });
    closeDialog();
    openDialog({ kind: 'checkoutDone', summary });
  };
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 540, borderRadius: 16 }} onClick={(e) => e.stopPropagation()} data-tour="checkout-dialog">
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '18px 20px', borderBottom: '1px solid var(--border)' }}>
          <span style={{ width: 40, height: 40, borderRadius: 10, display: 'grid', placeItems: 'center', background: 'var(--success-soft)' }}><Icon n="point_of_sale" size={21} style={{ color: 'var(--success)' }} /></span>
          <div style={{ flex: 1 }}><div style={{ fontSize: 16, fontWeight: 800 }}>Complete Visit &amp; Award Points</div><div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>Verify counter payment &amp; award patient points.</div></div>
          <button type="button" className="ka-dialog-close" onClick={closeDialog}><Icon n="close" size={20} /></button>
        </div>
        <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 14, maxHeight: 600, overflow: 'auto' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 13 }}>
            <Icon n="person" size={17} style={{ color: 'var(--muted)' }} /><b>{p.name}</b><span style={{ color: 'var(--muted)' }}>· {s.name}</span>
          </div>
          <div style={{ padding: '8px 14px', borderRadius: 10, background: 'var(--surface-subtle)', border: '1px solid var(--border)' }} data-tour="checkout-math">
            <Row label="Service Price" value={rm(s.price)} />
            <Row label="Deposit (Paid Online / Booked)" value={`− ${rm(deposit)}`} tone="var(--success-text)" />
            <div style={{ height: 1, background: 'var(--border)', margin: '4px 0' }} />
            <Row label="Expected Counter Balance" value={rm(expected)} strong />
          </div>
          <MoneyField tour="checkout-paid" label="Amount Paid at Counter Today (RM)" value={paid} onChange={setPaid} />
          <div style={{ display: 'flex', gap: 6 }}>
            {['Card terminal', 'Cash', 'DuitNow QR'].map((m) => (
              <button key={m} type="button" data-tour={`checkout-method-${m.split(' ')[0]!.toLowerCase()}`} onClick={() => setMethod(m)}
                style={{ height: 30, padding: '0 12px', borderRadius: 999, fontSize: 12, fontWeight: 600, border: `1px solid ${m === method ? 'var(--primary)' : 'var(--border-strong)'}`, background: m === method ? 'var(--primary-soft)' : 'transparent', color: m === method ? 'var(--primary-ink)' : 'var(--ink-2)' }}>{m}</button>
            ))}
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <MoneyField label="Extra Add-ons / Items" value={addons} onChange={setAddons} />
            <MoneyField label="Discount / Adjustment" value={discount} onChange={setDiscount} />
          </div>
          <div style={{ display: 'flex', alignItems: 'center', padding: '12px 14px', borderRadius: 10, background: 'var(--success-soft)', border: '1px solid rgba(34,197,94,.35)' }} data-tour="checkout-total">
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--success-text)' }}>Total Patient Spend Today</div>
              <div style={{ fontSize: 20, fontWeight: 800, color: 'var(--success-text)' }}>{rm(total)}</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 11, color: 'var(--muted)' }}>RM 1 = 1 pt</div>
              <div style={{ fontSize: 15, fontWeight: 800, color: 'var(--success-text)' }}>+{pts} pts</div>
            </div>
          </div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--ink-2)', marginBottom: 6 }}>Staff Remarks / Note (Optional)</div>
            <TextInput value={remark} onChange={setRemark} height={42} placeholder="e.g. Paid with card, receipt #" />
          </div>
        </div>
        <div className="ka-dialog-foot" style={{ background: 'var(--surface)', borderTop: '1px solid var(--border)' }}>
          <button type="button" className="ka-btn lg" onClick={closeDialog}>Cancel</button>
          <button type="button" className="ka-btn lg" data-tour="checkout-complete" onClick={done} style={{ background: '#059669', borderColor: '#059669', color: '#fff' }}><Icon n="check_circle" size={18} />Complete &amp; Award {pts} Pts</button>
        </div>
      </div>
    </div>
  );
}

const NEXT_SCAN: Record<string, { title: string; desc: string }> = {
  'sv-anatomy': { title: '4D/5D Bonding Scan', desc: 'Real-time facial features & emotional bonding ultrasound.' },
  'sv-5d': { title: 'Growth & Position Scan', desc: 'Late pregnancy fetal biometry & placental check.' },
  'sv-combo': { title: 'Growth & Position Scan', desc: 'Late pregnancy fetal biometry & placental check.' },
  'sv-breast': { title: 'Next Follow-Up Appointment', desc: 'Routine review in 6 months.' },
};

export function CheckoutDoneDialog({ summary }: { summary: import('../store').CheckoutSummary }) {
  const { db, closeDialog, openDialog } = useApp();
  const a = db.appointments.find((x) => x.id === summary.appointmentId)!;
  const p = db.patients.find((x) => x.id === a.patientId)!;
  const s = db.services.find((x) => x.id === a.serviceId)!;
  const next = NEXT_SCAN[s.id];
  return (
    <div className="ka-overlay">
      <div className="ka-dialog" style={{ width: 480, borderRadius: 16, padding: 22 }} data-tour="checkout-done">
        <div style={{ textAlign: 'center' }}>
          <span style={{ width: 54, height: 54, borderRadius: '50%', display: 'inline-grid', placeItems: 'center', background: '#10b981', color: '#fff', boxShadow: '0 8px 16px rgba(16,185,129,.3)' }}><Icon n="check" size={30} /></span>
          <div style={{ fontSize: 18, fontWeight: 800, marginTop: 12 }}>Appointment Completed!</div>
        </div>
        <div style={{ marginTop: 16, padding: '8px 14px', borderRadius: 10, background: 'var(--surface-subtle)', border: '1px solid var(--border)' }}>
          <Row label="Patient" value={p.name} />
          <Row label="Service" value={s.name} />
          <Row label="Deposit (Included)" value={rm(summary.deposit)} />
          <Row label="Paid at Counter Today" value={rm(summary.counterPaid)} />
          <Row label="Total Spend" value={rm(summary.total)} strong />
          <Row label="Points Awarded" value={`+${summary.points} pts`} tone="var(--success-text)" strong />
          <Row label="New Patient Balance" value={`${summary.newBalance} pts`} />
        </div>
        {next && (
          <div style={{ marginTop: 12, padding: 12, borderRadius: 10, background: 'var(--info-soft)', border: '1px solid color-mix(in srgb, #2563eb 25%, transparent)' }} data-tour="checkout-next">
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: .4, color: 'var(--sky-text)' }}>CADANGAN IMBASAN SETERUSNYA (PILIHAN)</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 6 }}>
              <div style={{ flex: 1 }}><div style={{ fontSize: 13.5, fontWeight: 700 }}>Imbasan Seterusnya: {next.title}</div><div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>{next.desc}</div></div>
              <button type="button" className="ka-btn sm" data-tour="checkout-book-next" onClick={() => { closeDialog(); openDialog({ kind: 'newAppointment', patientId: p.id }); }}><Icon n="calendar_month" size={16} />Book</button>
            </div>
          </div>
        )}
        <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
          <button type="button" className="ka-btn" data-tour="checkout-close" style={{ flex: 1, height: 44 }} onClick={closeDialog}>Close Window</button>
          <button type="button" className="ka-btn" style={{ flex: 1, height: 44, background: '#25d366', borderColor: '#25d366', color: '#fff' }}><Icon n="chat" size={17} />Share WhatsApp Receipt</button>
        </div>
      </div>
    </div>
  );
}

/** reward_history_detail.dart — update a redemption. */
export function ClaimUpdateDialog({ claimId }: { claimId: string }) {
  const { db, closeDialog, openDialog, patch } = useApp();
  const c = db.claims.find((x) => x.id === claimId)!;
  const p = db.patients.find((x) => x.id === c.patientId)!;
  const r = db.rewards.find((x) => x.id === c.rewardId)!;
  const [status, setStatus] = useState<string>(c.status);
  const [remark, setRemark] = useState(c.remark);
  const save = () => {
    patch((d) => ({ ...d, claims: d.claims.map((x) => (x.id === c.id ? { ...x, status: status as typeof c.status, remark, at: new Date().toISOString(), by: 'Bukit Rimau' } : x)) }), c.id);
    closeDialog();
    openDialog({ kind: 'status', tone: 'success', title: 'Success!', message: 'Redemption updated successfully.' });
  };
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 560 }} onClick={(e) => e.stopPropagation()} data-tour="claim-update">
        <div className="ka-dialog-head">
          <span className="ka-dialog-badge"><Icon n="redeem" size={22} /></span>
          <div style={{ flex: 1 }}><h2>Update Redemption</h2><p>Hand over the reward, then mark it Completed</p></div>
          <button type="button" className="ka-dialog-close" onClick={closeDialog}><Icon n="close" /></button>
        </div>
        <div className="ka-dialog-body" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, padding: 14, borderRadius: 10, background: 'var(--surface-subtle)', border: '1px solid var(--border)', fontSize: 13 }}>
            <div><div style={{ color: 'var(--muted)', fontSize: 11.5, fontWeight: 600 }}>Patient</div><b>{p.name}</b><div style={{ color: 'var(--muted)' }}>{p.phone}</div></div>
            <div><div style={{ color: 'var(--muted)', fontSize: 11.5, fontWeight: 600 }}>Reward</div><b>{r.name}</b><div style={{ color: 'var(--muted)' }}>−{r.points} pts</div></div>
          </div>
          <FloatSelect tour="claim-status" label="Redemption Status" icon="flag" labelTone="muted" value={status} onChange={setStatus}
            options={[{ value: 'In-Progress', label: 'In-Progress' }, { value: 'Completed', label: 'Completed' }]} />
          <div>
            <div className="ka-field-label">Remark</div>
            <TextInput tour="claim-remark" value={remark} onChange={setRemark} placeholder="e.g. Collected at counter" height={44} />
          </div>
        </div>
        <div className="ka-dialog-foot">
          <button type="button" className="ka-btn lg" onClick={closeDialog}>Cancel</button>
          <button type="button" className="ka-btn primary lg" data-tour="claim-save" onClick={save}>Update</button>
        </div>
      </div>
    </div>
  );
}

