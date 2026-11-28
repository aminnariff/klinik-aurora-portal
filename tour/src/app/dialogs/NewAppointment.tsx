import { useState } from 'react';
import { useApp } from '../store';
import { Checkbox, FloatSelect, Icon } from '../ui';
import { HOME_BRANCH, fmtSlot, rm, slotKey } from '../data';

function gestation(edd: string, onDate: string, range?: [number, number]) {
  // Same maths as calculateGestationalAge(): conception = EDD − 280 days.
  const days = 280 - Math.round((new Date(edd).getTime() - new Date(onDate).getTime()) / 86400000);
  const w = Math.floor(days / 7), d = days % 7;
  const age = `${w} week${w !== 1 ? 's' : ''} ${d} day${d !== 1 ? 's' : ''}`;
  if (!range) return { ok: true, text: `Estimated gestational age at appointment: ${age}.` };
  const [lo, hi] = range;
  const rangeText = ` (Allowed range: ${lo}-${hi} weeks)`;
  // Messages from getGestationalStatusMessage() in the portal.
  if (w >= lo && w <= hi) return { ok: true, text: `The patient is eligible. Estimated gestational age at appointment: ${age}${rangeText}.` };
  if (w === lo - 1) return { ok: false, text: `The patient is slightly early (gestational age: ${age}).` };
  if (w === hi + 1) return { ok: false, text: `The patient is slightly past the ideal window (gestational age: ${age}).` };
  if (w < lo) return { ok: false, text: `The patient is not yet eligible. She will be ${age} at the time of the appointment${rangeText}.` };
  return { ok: false, text: `The patient is no longer eligible. She will be ${age} at the time of the appointment${rangeText}.` };
}

function AttachmentField({ tour }: { tour: string }) {
  return (
    <div style={{ display: 'flex', gap: 8 }} data-tour={tour}>
      <div className="ka-input" style={{ flex: 1, height: 48 }}><Icon n="link" size={18} /><span style={{ color: 'var(--muted)', fontSize: 13, fontWeight: 500 }}>Attachment URL (optional)</span></div>
      <button type="button" className="ka-btn primary" style={{ height: 32, alignSelf: 'center', fontSize: 13, borderRadius: 6, padding: '0 12px' }}><Icon n="upload_file" size={17} />Upload</button>
    </div>
  );
}

const STATUSES = [
  { value: 'Booked', label: 'Booked' }, { value: 'Rescheduled', label: 'Rescheduled' }, { value: 'Completed', label: 'Completed' },
  { value: 'Cancelled', label: 'Cancelled' }, { value: 'No-Show', label: 'No Show' }, { value: 'Transferred', label: 'Transferred' },
];

function QuickAction({ label, icon, color, onClick, tour }: { label: string; icon: string; color: string; onClick: () => void; tour: string }) {
  return (
    <button type="button" data-tour={tour} onClick={onClick} style={{ height: 32, padding: '0 10px', borderRadius: 8, display: 'flex', alignItems: 'center', gap: 6, fontSize: 12.5, fontWeight: 600, color, background: `color-mix(in srgb, ${color} 10%, transparent)`, border: `1px solid color-mix(in srgb, ${color} 30%, transparent)` }}>
      <Icon n={icon} size={16} />{label}
    </button>
  );
}

export function NewAppointmentDialog({ patientId, appointmentId }: { patientId?: string; appointmentId?: string }) {
  const { db, role, closeDialog, openDialog, addAppointment, updateAppointment } = useApp();
  const existing = appointmentId ? db.appointments.find((a) => a.id === appointmentId) ?? null : null;
  const isUpdate = !!existing;
  const patient = db.patients.find((p) => p.id === (existing?.patientId ?? patientId))!;
  const isSuper = role === 'superadmin';
  const [branchId, setBranchId] = useState<string | null>(existing?.branchId ?? (isSuper ? null : HOME_BRANCH));
  const [serviceId, setServiceId] = useState<string | null>(existing?.serviceId ?? null);
  const [slot, setSlot] = useState<string | null>(existing?.start ?? null);
  const [status, setStatus] = useState<string>(existing?.status ?? 'Booked');
  const [note, setNote] = useState(existing?.note ?? '');
  const [collected, setCollected] = useState(existing?.payment === 'Fee Paid' || existing?.payment === 'Paid');
  const [noPayment, setNoPayment] = useState(false);
  const [receipt, setReceipt] = useState(existing?.receiptNo ?? (existing && existing.payment !== 'No Payment' ? 'FIUU-ONLINE' : ''));
  const slotChanged = isUpdate && slot !== existing!.start;
  // Cancelled / transferred bookings open read-only ("View Details").
  const locked = isUpdate && (existing!.status === 'Cancelled' || existing!.status === 'Transferred');
  const quick = (newStatus: 'Completed' | 'No-Show', label: string) => openDialog({
    kind: 'confirm', title: 'Are you sure?', message: `Mark this appointment as ${label}?`,
    onConfirm: () => {
      updateAppointment(existing!.id, { status: newStatus, queue: newStatus === 'No-Show' ? 'no_show' : 'completed' });
      useApp.setState((s) => ({ dialogs: s.dialogs.slice(0, -2) }));
      openDialog({ kind: 'status', tone: 'success', title: 'Success!', message: `Successfully marked as ${label}` });
    },
  });
  const service = db.services.find((s) => s.id === serviceId) ?? null;
  const hasFee = !!service?.fee;
  const eddLabel = patient.edd ? patient.edd.split('-').reverse().join('-') : '';
  const gest = service?.pregnancy && patient.edd && slot ? gestation(patient.edd, slot, service.eddRange) : null;

  const openSlots = () => {
    if (!branchId) return openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Please select a branch first.' });
    if (!serviceId) return openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Please select a service first.' });
    openDialog({ kind: 'slotPicker', serviceId, branchId, onPick: (s) => { setSlot(s); if (isUpdate && s !== existing!.start) setStatus('Rescheduled'); } });
  };
  const submit = (sessionConfirmed = false) => {
    if (!branchId || !serviceId || !slot) {
      openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Please choose a branch, service and appointment slot.' });
      return;
    }
    if (!isUpdate && hasFee && !noPayment && !(collected && receipt.trim())) {
      openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Either a receipt number or a remark must be provided for services with a booking fee.' });
      return;
    }
    // _confirmSessionOverrideIfNeeded(): staff may book outside the branch's preferred session after confirming.
    const pref = db.timing[slotKey(serviceId, branchId)]?.session ?? 'both';
    const hour = new Date(slot).getHours();
    if (!sessionConfirmed && ((pref === 'first_half' && hour >= 12) || (pref === 'second_half' && hour < 12))) {
      const label = pref === 'first_half' ? 'First Half (before 12:00 PM)' : 'Second Half (12:00 PM onwards)';
      openDialog({ kind: 'confirm', title: 'Are you sure?', message: `This service is configured for ${label}. The selected slot is outside the preferred session. Are you sure you want to proceed?`, onConfirm: () => { useApp.getState().closeDialog(); submit(true); } });
      return;
    }
    if (isUpdate) {
      updateAppointment(existing!.id, { serviceId, branchId, start: slot, note, status: status as typeof existing.status, rescheduled: existing!.rescheduled || slotChanged });
      closeDialog();
      openDialog({ kind: 'status', tone: 'success', title: 'Success!', message: 'Appointment updated successfully.' });
      return;
    }
    const pr = db.practitioners.find((p) => p.branchId === branchId && p.type === service!.type);
    addAppointment({ patientId: patient.id, serviceId, branchId, start: slot, status: 'Booked', payment: hasFee && !noPayment ? 'Fee Paid' : 'No Payment', practitionerId: pr?.id, note, receiptNo: receipt || undefined });
    closeDialog();
    openDialog({ kind: 'status', tone: 'success', title: 'Success!', message: 'Appointment created successfully.' });
  };

  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 940 }} onClick={(e) => e.stopPropagation()} data-tour="appt-dialog">
        <div className="ka-dialog-head canvas">
          <Icon n="event_note" v="o" size={20} style={{ color: 'var(--ink-2)' }} />
          <h2>{isUpdate ? 'Update Appointment' : 'New Appointment'}</h2>
          {isUpdate && existing!.status !== 'Completed' && existing!.status !== 'Cancelled' && (
            <div style={{ display: 'flex', gap: 6, marginLeft: 'auto' }}>
              <QuickAction tour="qa-completed" label="Mark Completed" icon="check_circle_outline" color="var(--success)" onClick={() => quick('Completed', 'Completed')} />
              <QuickAction tour="qa-noshow" label="Mark No-Show" icon="person_off" color="#d97706" onClick={() => quick('No-Show', 'No Show')} />
              <QuickAction tour="qa-transfer" label="Transfer Branch" icon="swap_horiz" color="#2563eb" onClick={() => openDialog({ kind: 'transfer', appointmentId: existing!.id })} />
            </div>
          )}
          <button type="button" className="ka-dialog-close" onClick={closeDialog} style={isUpdate ? { marginLeft: 8 } : undefined}><Icon n="close" /></button>
        </div>
        <div className="ka-dialog-body" style={{ display: 'flex', gap: 24, padding: '28px 24px 20px', maxHeight: 640 }} data-tour="appt-body">
          {/* Left column */}
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <span className="ka-sec-label"><Icon n="person" size={14} />Patient</span>
              <span style={{ flex: 1 }} />
              <button type="button" className="ka-link"><Icon n="content_copy" v="o" />Change Patient</button>
              <button type="button" className="ka-link" style={{ marginLeft: 18 }}><Icon n="content_copy" v="o" />Copy Details</button>
            </div>
            <div style={{ padding: '14px 14px 12px', borderRadius: 8, background: 'var(--surface-subtle)', border: '1px solid var(--border)' }} data-tour="appt-patient">
              <div style={{ display: 'flex' }}><b style={{ fontSize: 15, flex: 1 }}>{patient.name}</b><Icon n="content_copy" v="o" size={14} style={{ color: 'var(--muted)' }} /></div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8, fontSize: 13.5 }}><Icon n="call" v="o" size={15} style={{ color: 'var(--muted)' }} /><span style={{ flex: 1 }}>{patient.phone}</span><Icon n="content_copy" v="o" size={14} style={{ color: 'var(--muted)' }} /></div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6, fontSize: 13.5 }}><Icon n="mail" v="o" size={15} style={{ color: 'var(--muted)' }} /><span style={{ flex: 1 }}>{patient.email}</span><Icon n="content_copy" v="o" size={14} style={{ color: 'var(--muted)' }} /></div>
            </div>
            <label className="ka-input" style={{ height: 54, alignItems: 'flex-start', paddingTop: 10 }} data-tour="appt-note">
              <Icon n="edit_note" size={19} />
              <textarea value={note} onChange={(e) => setNote(e.target.value)} placeholder="Note" rows={1} style={{ border: 'none', outline: 'none', background: 'none', resize: 'none', flex: 1, fontSize: 13, fontWeight: 500, paddingTop: 7 }} />
            </label>
            <div className="ka-input" style={{ height: 54, alignItems: 'flex-start', paddingTop: 10 }}>
              <Icon n="lock" v="o" size={17} />
              <span style={{ color: 'var(--muted)', fontSize: 13, fontWeight: 500, paddingTop: 9 }}>Admin Remark (internal — not shown to patient)</span>
            </div>
            {service?.pregnancy && patient.edd && (
              <div data-tour="appt-edd">
                <div className="ka-float" style={{ height: 48 }}>
                  <span className="ka-float-label muted">Estimated Due Date (EDD)</span>
                  <span className="grow">{eddLabel}</span>
                  <Icon n="calendar_month" size={20} style={{ color: 'var(--ink-2)' }} />
                </div>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, marginTop: 8, fontSize: 11.5, fontWeight: 600, color: 'var(--violet-text)', background: 'color-mix(in srgb, #7c3aed 10%, transparent)', borderRadius: 4, padding: '3px 8px' }}><Icon n="visibility" v="o" size={13} />Pre-filled from Baby Tracker (Click to change)</span>
                <div data-tour="appt-gestation" style={{ marginTop: 10, padding: '9px 12px', borderRadius: 8, fontSize: 12, lineHeight: 1.4, display: 'flex', alignItems: 'flex-start', gap: 6,
                  ...(gest ? { background: gest.ok ? 'rgba(22,163,74,.07)' : 'rgba(217,119,6,.08)', color: gest.ok ? 'var(--success-text)' : 'var(--warning-text)', border: `1px solid ${gest.ok ? 'rgba(22,163,74,.25)' : 'rgba(217,119,6,.3)'}` }
                    : { background: 'rgba(158,158,158,.07)', color: 'var(--muted)', border: '1px solid rgba(158,158,158,.25)' }) }}>
                  <Icon n={gest ? (gest.ok ? 'check_circle' : 'warning_amber') : 'info'} v={gest ? 'r' : 'o'} size={14} style={{ marginTop: 1 }} />
                  {gest ? gest.text : 'Select appointment date to check eligibility'}
                </div>
              </div>
            )}
            {isUpdate && (status === 'Cancelled' || slotChanged) && (
              <div data-tour="appt-policy" style={{ padding: 12, borderRadius: 8, background: 'var(--warning-soft)', border: '1px solid color-mix(in srgb, #fb923c 35%, transparent)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, fontWeight: 700, color: 'var(--orange-text)' }}><Icon n="policy" v="o" size={14} style={{ color: '#ea580c' }} />Cancellation Policy</div>
                <div style={{ fontSize: 11.5, color: 'var(--orange-text)', lineHeight: 1.6, marginTop: 6, whiteSpace: 'pre-line' }}>
                  {'• Each appointment may only be rescheduled once.\n• Refunds, if approved, are processed within 5–7 business days.\n• Klinik Aurora reserves the right to decline refund requests based on internal review.'}
                </div>
              </div>
            )}
            {hasFee && !isUpdate && (
              <div style={{ borderRadius: 8, border: '1px solid var(--fee-border)', background: 'var(--warning-soft)' }} data-tour="appt-fee-box">
                <button type="button" data-tour="appt-fee-collected" onClick={() => { setCollected(!collected); setNoPayment(false); }} style={{ display: 'flex', alignItems: 'center', gap: 12, width: '100%', padding: '12px 14px', background: 'none', border: 'none', textAlign: 'left', fontSize: 13.5 }}>
                  <Checkbox on={collected} /><span>I have collected the booking fee (<b style={{ color: 'var(--success-text)' }}>{rm(service!.fee!)}</b>) from the patient</span>
                </button>
                {collected && (
                  <div style={{ padding: '0 14px 12px 44px' }}>
                    <label className="ka-input" style={{ height: 40, background: 'var(--surface)' }} data-tour="appt-receipt">
                      <Icon n="receipt_long" v="o" size={17} />
                      <input value={receipt} onChange={(e) => setReceipt(e.target.value)} placeholder="Receipt No." style={{ fontSize: 13 }} />
                    </label>
                  </div>
                )}
                <div style={{ height: 1, background: 'var(--fee-border)' }} />
                <button type="button" onClick={() => { setNoPayment(!noPayment); setCollected(false); }} style={{ display: 'flex', alignItems: 'center', gap: 12, width: '100%', padding: '12px 14px', background: 'none', border: 'none', textAlign: 'left', fontSize: 13.5 }}>
                  <Checkbox on={noPayment} /><span>No payment required (e.g. transferred from another branch/ clinic — already paid there)</span>
                </button>
              </div>
            )}
          </div>
          {/* Right column */}
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 16 }}>
            <span className="ka-sec-label" style={{ marginBottom: 2 }}><Icon n="event_note" v="o" size={14} />Appointment Details</span>
            <FloatSelect tour="appt-branch" label="Branch" icon="store" value={branchId} disabled={!isSuper} onChange={(v) => { setBranchId(v); setSlot(null); }}
              options={db.branches.map((b) => ({ value: b.id, label: b.name }))} />
            <FloatSelect tour="appt-service" label="Service" icon="medical_services" disabled={locked} value={serviceId} onChange={(v) => { setServiceId(v); setSlot(null); setCollected(false); setNoPayment(false); }}
              options={db.services.filter((s) => s.active).map((s) => ({ value: s.id, label: s.name }))} />
            {hasFee && (
              <div style={{ marginTop: -4, padding: '9px 12px', borderRadius: 6, background: 'var(--warning-soft)', border: '1px solid var(--fee-border)', color: 'var(--orange-text)', fontSize: 12.5, display: 'flex', alignItems: 'center', gap: 8 }}>
                <Icon n="info" v="o" size={15} />Booking fee required — upload payment proof below
              </div>
            )}
            <FloatSelect tour="appt-status" label="Status" icon="rule" labelTone="muted" value={status} onChange={setStatus} disabled={locked} options={isUpdate ? STATUSES : [{ value: 'Booked', label: 'Booked' }]} />
            {status === 'Transferred' && !locked && (
              <div style={{ marginTop: -6, padding: '9px 12px', borderRadius: 6, background: 'var(--info-soft)', border: '1px solid color-mix(in srgb, #0284c7 30%, transparent)', color: 'var(--sky-text)', fontSize: 12, lineHeight: 1.45 }}>
                Please be noted this transferred only a status for this appointment, to transfer to other branch still need to contact the respective branch to check available slots etc or can check via mobile app
              </div>
            )}
            <button type="button" className="ka-float" data-tour="appt-slot" onClick={locked ? undefined : openSlots} style={{ height: 48 }}>
              <span className="ka-float-label muted">Slots</span>
              <Icon n="calendar_month" size={18} />
              <span className={`grow${slot ? '' : ' placeholder'}`} style={{ fontSize: 13, fontWeight: 500, color: slot ? 'var(--ink)' : undefined }}>{slot ? fmtSlot(slot) : 'Select appointment slot'}</span>
              <Icon n="refresh" size={18} style={{ color: 'var(--blue)' }} />
              <Icon n="date_range" size={18} />
            </button>
            <span className="ka-sec-label" style={{ marginTop: 6 }}><Icon n="attach_file" size={14} />Attachment</span>
            <AttachmentField tour="appt-attach" />
            <span className="ka-sec-label" style={{ marginTop: 6 }}><Icon n="description" v="o" size={14} />Referral Letter (PDF)</span>
            <AttachmentField tour="appt-referral" />
            <div style={{ display: 'flex', gap: 4, fontSize: 10.5, color: 'var(--muted)', lineHeight: 1.4, marginTop: -8 }}>
              <Icon n="info" v="o" size={11} style={{ marginTop: 2 }} />Documents linked here are stored for 6 months to 1 year and may be deleted thereafter. Patients are advised to save their own copy.
            </div>
          </div>
        </div>
        {hasFee && !isUpdate && <div style={{ padding: '0 24px 14px', fontSize: 11, color: 'var(--muted)' }}>* Either a receipt number or a remark must be provided for services with a booking fee.</div>}
        {isUpdate && (
          <div style={{ padding: '0 24px 14px', fontSize: 11.5, color: 'var(--muted)', display: 'flex', gap: 6 }} data-tour="appt-reschedule-note">
            <Icon n="info" v="o" size={13} style={{ marginTop: 1 }} />Changing the appointment slot will automatically set the status to Rescheduled.
          </div>
        )}
        <div className="ka-dialog-foot canvas">
          <button type="button" className="ka-btn lg" onClick={closeDialog}>Close</button>
          {!locked && <button type="button" className="ka-btn primary lg" data-tour="appt-create" onClick={() => submit()} style={{ padding: '0 24px' }}>{isUpdate ? 'Save Changes' : 'Create Appointment'}</button>}
        </div>
      </div>
    </div>
  );
}
