import { useState } from 'react';
import { useApp } from '../store';
import { Icon } from '../ui';
import { HOME_BRANCH } from '../data';

/** checkSlots() in appointment_homepage.dart — view free slots for any service, without booking. */
export function CheckSlotsDialog() {
  const { db, closeDialog, openDialog } = useApp();
  const services = db.services.filter((s) => s.active);
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 500, height: 680 }} onClick={(e) => e.stopPropagation()} data-tour="checkslots-dialog">
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '16px 16px 12px' }}>
          <span style={{ width: 34, height: 34, borderRadius: 8, background: 'var(--success-soft)', display: 'grid', placeItems: 'center' }}><Icon n="calendar_month" size={18} style={{ color: 'var(--success)' }} /></span>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 16, fontWeight: 600 }}>Check Available Slots</div>
            <div style={{ fontSize: 12.5, color: 'var(--muted)', marginTop: 2 }}>Branch: Klinik Aurora Bukit Rimau</div>
          </div>
          <button type="button" className="ka-dialog-close" title="Tutup" data-tour="checkslots-close" onClick={closeDialog}><Icon n="close" size={20} /></button>
        </div>
        <div style={{ padding: '0 16px 8px', fontSize: 13.5, color: 'var(--muted)' }}>{services.length} service(s) available</div>
        <div style={{ flex: 1, overflow: 'auto', padding: '0 12px 16px' }}>
          {services.map((s) => (
            <button key={s.id} type="button" data-tour={`checkslot-${s.id}`} onClick={() => openDialog({ kind: 'slotPicker', serviceId: s.id, branchId: HOME_BRANCH, onPick: () => {}, readOnly: true })}
              style={{ display: 'flex', alignItems: 'center', gap: 14, width: '100%', padding: '12px 8px', border: 'none', borderBottom: '1px solid var(--surface-subtle)', background: 'none', textAlign: 'left', borderRadius: 6 }}>
              <span style={{ width: 32, height: 32, borderRadius: 8, background: 'var(--info-soft)', display: 'grid', placeItems: 'center' }}><Icon n="medical_services" size={16} style={{ color: 'var(--sky-text)' }} /></span>
              <span style={{ flex: 1, fontSize: 14 }}>{s.name}</span>
              <Icon n="chevron_right" size={20} style={{ color: 'var(--muted)' }} />
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

interface SopTask { title: string; description: string; icon: string; tag: string }
interface SopStep { short: string; title: string; description: string; icon: string; color: string; tasks: SopTask[]; ruleTitle: string; rule: string; warning: boolean }

const STEPS: SopStep[] = [
  {
    short: 'Bookings', title: 'Appointment Creation & Patient Search', icon: 'calendar_month', color: '#2563eb',
    description: 'Search existing patient profiles and create portal bookings for patients contacting the branch via call or WhatsApp.',
    tasks: [
      { title: 'Search Mobile / IC First', description: 'Always search Phone Number or IC/Passport first before creating a record to avoid duplicate patient accounts.', icon: 'person_search', tag: 'PATIENT SEARCH' },
      { title: 'Select Service, Doctor & Time Slot', description: 'Click "Add Appointment", choose the pregnancy scan or clinic service package, practitioner on duty, and desired slot.', icon: 'add_circle_outline', tag: 'CREATE BOOKING' },
      { title: 'WhatsApp Booking Confirmation', description: 'Ensure a valid WhatsApp mobile number is saved so the patient receives instant booking alerts and appointment reminders.', icon: 'chat', tag: 'AUTO NOTIFY' },
    ],
    ruleTitle: 'Active Phone Validation', rule: 'Always double-check the phone number with country code (e.g. 60123456789) to enable automated app syncing and WhatsApp pings.', warning: false,
  },
  {
    short: 'Status Update', title: 'Attended Visits & Status Completion', icon: 'fact_check', color: '#059669',
    description: 'Keep attendance real-time by updating appointment statuses immediately after patient visits.',
    tasks: [
      { title: 'Mark "Completed" Upon Attendance', description: 'When the consultation finishes and counter payment is settled, immediately change the appointment status to "Completed".', icon: 'check_circle', tag: 'COMPLETED' },
      { title: 'Auto Loyalty Points Credited', description: 'Marking "Completed" automatically credits 1 Aurora Point per RM 1 spent to the patient’s mobile app account.', icon: 'stars', tag: 'LOYALTY POINTS' },
      { title: '12 00 AM Midnight Auto No-Show', description: 'Any appointment left in "Booked" status when the shift ends will be automatically converted to "No-Show" at midnight. Always update statuses before closing!', icon: 'bedtime', tag: 'MIDNIGHT RULE' },
    ],
    ruleTitle: 'Shift Closing Invariant', rule: '⚠️ Never leave attended appointments in "Booked" status. Update to "Completed" before leaving the clinic.', warning: true,
  },
  {
    short: 'Cancel & Refund', title: 'Cancellations vs HQ Refund Protocol', icon: 'account_balance_wallet', color: '#dc2626',
    description: 'Strict operational distinction between unpaid cancellations and payments requiring HQ refund processing.',
    tasks: [
      { title: 'Cancelled (RM 0.00 Paid)', description: 'Select status "Cancelled" ONLY if RM 0.00 was paid and no online deposit or counter payment was collected from the patient.', icon: 'cancel', tag: 'RM 0 PAID' },
      { title: 'Refunds MUST be Raised to HQ', description: 'Branch staff CANNOT process refunds directly. If money was collected (online deposit or counter payment), submit a refund ticket/request to HQ Finance with receipt and reason.', icon: 'admin_panel_settings', tag: 'HQ APPROVAL' },
      { title: 'Preserve Audit Records', description: 'Never delete an appointment record. All cancellations and HQ refunds must remain tracked in portal logs for monthly finance reconciliation.', icon: 'history_edu', tag: 'AUDIT LOGS' },
    ],
    ruleTitle: 'Finance Refund Policy', rule: '⚠️ Strict HQ Policy: Clinics are not permitted to issue cash/gateway refunds directly. Every refund must be approved and processed by the HQ Finance Department.', warning: true,
  },
  {
    short: 'Transfers', title: 'Inter-Branch Patient Transfer Protocol', icon: 'swap_horiz', color: '#7c3aed',
    description: 'Coordinate seamless patient slot reallocation between Aurora clinic locations.',
    tasks: [
      { title: 'Contact Receiving Branch', description: 'Contact the target Aurora clinic via phone/WhatsApp to confirm doctor availability and desired time slot before initiating the transfer.', icon: 'phone_forwarded', tag: 'SLOT CHECK' },
      { title: 'Receiving Branch Adds New Booking', description: 'The receiving branch creates the new appointment under their clinic calendar to reserve doctor and machine time.', icon: 'storefront', tag: 'NEW BRANCH' },
      { title: 'Origin Marks "Transferred"', description: 'Origin clinic updates their original appointment status to "Transferred" and adds remarks noting the destination branch.', icon: 'sync_alt', tag: 'ORIGIN CLINIC' },
    ],
    ruleTitle: 'Double-Booking Prevention', rule: 'Both branches must coordinate to prevent overlapping bookings. Never delete the original record — "Transferred" status preserves both branches\' audit trails.', warning: false,
  },
  {
    short: 'Follow-Up & Reports', title: 'Patient Follow-Up & Daily Finance Export', icon: 'analytics', color: '#d97706',
    description: 'Follow up on unbooked pregnancy milestone scans and export end-of-day financial summaries for review.',
    tasks: [
      { title: 'Milestone Recall Follow-Up', description: 'Open Patients → Patient Follow-Up to view expectant mothers whose next pregnancy scan milestone (Dating → Detail Anomaly → 4D/5D → Growth) has not been booked yet.', icon: 'pregnant_woman', tag: 'TRIMESTER RECALL' },
      { title: '1-Tap WhatsApp Recall Outreach', description: 'Click the WhatsApp icon on the recall list to send friendly personalized scan reminders with booking links directly to patients.', icon: 'send', tag: 'OUTREACH' },
      { title: 'Export Daily Reports for Finance', description: 'At shift end, go to Payment Report / Appointments, set today’s date filter, and click "Export" (CSV/Excel) to review daily revenue against counter terminal slips.', icon: 'file_download', tag: 'FINANCE' },
    ],
    ruleTitle: 'Daily Closing Routine', rule: 'Daily export reports must match counter collections, credit card terminal totals, and QR payment settlements before concluding shift.', warning: false,
  },
];

const CHECKLIST = [
  'Patient Bookings: Verified all incoming phone/WhatsApp appointment requests are created in calendar.',
  'Status Completion: Marked all attended patient visits as "Completed" (0 leftovers in "Booked").',
  'HQ Refund Requests: Submitted tickets to HQ Finance for any paid cancellations requiring refund.',
  'Branch Transfers: Confirmed receiving branch bookings for all inter-branch transferred patients.',
  'Patient Follow-Up: Checked Patient Follow-Up module and pinged mothers due for their next pregnancy scan.',
];

/** _AppointmentGuidelineDialog — "Clinic Appointment Playbook". */
export function GuidelineDialog() {
  const closeDialog = useApp((s) => s.closeDialog);
  const [step, setStep] = useState(0);
  const [done, setDone] = useState<number[]>([]);
  const s = STEPS[step]!;
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 860, maxHeight: 790, background: 'var(--canvas)', borderRadius: 14 }} onClick={(e) => e.stopPropagation()} data-tour="guide-dialog">
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 14px 14px 18px', background: 'linear-gradient(135deg, #DF6E98, #7E2D40)', color: '#fff' }}>
          <span style={{ width: 38, height: 38, borderRadius: 10, background: 'rgba(255,255,255,.16)', display: 'grid', placeItems: 'center' }}><Icon n="menu_book" size={21} style={{ color: '#fff' }} /></span>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 16, fontWeight: 800 }}>Clinic Appointment Playbook</div>
            <div style={{ fontSize: 12, opacity: 0.85, marginTop: 2 }}>Interactive Frontdesk Standard Operating Procedures (SOP) &amp; Stepper</div>
          </div>
          <button type="button" className="ka-dialog-close" title="Close" onClick={closeDialog}><Icon n="close" size={22} style={{ color: '#fff' }} /></button>
        </div>
        <div style={{ display: 'flex', gap: 14, padding: 14, minHeight: 0, overflow: 'auto' }} data-tour="guide-body">
          <div style={{ width: 230, flex: 'none', display: 'flex', flexDirection: 'column', gap: 6 }}>
            {STEPS.map((x, i) => (
              <button key={x.short} type="button" data-tour={`guide-step-${i}`} onClick={() => setStep(i)}
                style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 10px', borderRadius: 10, textAlign: 'left', border: `1px solid ${i === step ? x.color : 'var(--border)'}`, background: i === step ? `color-mix(in srgb, ${x.color} 10%, var(--surface))` : 'var(--surface)' }}>
                <span style={{ width: 30, height: 30, borderRadius: 8, display: 'grid', placeItems: 'center', background: i === step ? x.color : 'var(--surface-subtle)' }}><Icon n={x.icon} size={17} style={{ color: i === step ? '#fff' : 'var(--muted)' }} /></span>
                <span style={{ fontSize: 13, fontWeight: i === step ? 700 : 500, color: i === step ? 'var(--ink)' : 'var(--ink-2)' }}>{i + 1}. {x.short}</span>
              </button>
            ))}
            <div className="ka-card" style={{ marginTop: 8, padding: 12, borderRadius: 10 }} data-tour="guide-checklist">
              <div style={{ fontSize: 12.5, fontWeight: 700, marginBottom: 6 }}>Checklist ({done.length}/{CHECKLIST.length})</div>
              {CHECKLIST.map((c, i) => (
                <button key={i} type="button" data-tour={`guide-check-${i}`} onClick={() => setDone(done.includes(i) ? done.filter((x) => x !== i) : [...done, i])} style={{ display: 'flex', gap: 6, width: '100%', border: 'none', background: 'none', padding: '4px 0', textAlign: 'left', fontSize: 11.5, lineHeight: 1.35, color: done.includes(i) ? 'var(--muted)' : 'var(--ink-2)' }}>
                  <Icon n={done.includes(i) ? 'check_box' : 'check_box_outline_blank'} size={16} style={{ color: done.includes(i) ? 'var(--success)' : 'var(--muted)', flex: 'none' }} />
                  <span style={{ textDecoration: done.includes(i) ? 'line-through' : 'none' }}>{c.split(':')[0]}</span>
                </button>
              ))}
            </div>
          </div>
          <div style={{ flex: 1, minWidth: 0 }} data-tour="guide-detail">
            <div className="ka-card" style={{ padding: 16, borderRadius: 12, borderTop: `3px solid ${s.color}` }}>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1, color: s.color }}>STEP {step + 1} OF {STEPS.length}</div>
              <div style={{ fontSize: 17, fontWeight: 800, marginTop: 4 }}>{s.title}</div>
              <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 6, lineHeight: 1.5 }}>{s.description}</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 14 }}>
                {s.tasks.map((t) => (
                  <div key={t.title} style={{ display: 'flex', gap: 12, padding: 12, borderRadius: 10, border: '1px solid var(--border)', background: 'var(--surface)' }}>
                    <span style={{ width: 34, height: 34, borderRadius: 9, flex: 'none', display: 'grid', placeItems: 'center', background: `color-mix(in srgb, ${s.color} 12%, transparent)` }}><Icon n={t.icon} size={18} style={{ color: s.color }} /></span>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><b style={{ fontSize: 13.5 }}>{t.title}</b><span className="ka-pill grey" style={{ height: 18, fontSize: 10, letterSpacing: .5 }}>{t.tag}</span></div>
                      <div style={{ fontSize: 12.5, color: 'var(--ink-2)', marginTop: 4, lineHeight: 1.5 }}>{t.description}</div>
                    </div>
                  </div>
                ))}
              </div>
              <div data-tour="guide-rule" style={{ marginTop: 14, padding: 12, borderRadius: 10, background: s.warning ? 'var(--warning-soft)' : 'var(--info-soft)', border: `1px solid ${s.warning ? 'rgba(245,158,11,.45)' : 'color-mix(in srgb, #2563eb 30%, transparent)'}` }}>
                <div style={{ fontSize: 12.5, fontWeight: 700, color: s.warning ? 'var(--warning-text)' : 'var(--info-text)' }}>{s.ruleTitle}</div>
                <div style={{ fontSize: 12.5, color: 'var(--ink-2)', marginTop: 4, lineHeight: 1.5 }}>{s.rule}</div>
              </div>
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: '1px solid var(--border)', background: 'var(--surface)' }}>
          <div style={{ width: 90, height: 6, borderRadius: 3, background: 'var(--surface-subtle)' }}><div style={{ width: `${((step + 1) / STEPS.length) * 100}%`, height: '100%', borderRadius: 3, background: s.color, transition: 'width .25s' }} /></div>
          <span style={{ flex: 1, fontSize: 12.5, color: 'var(--ink-2)' }}>Step {step + 1} of {STEPS.length}: {step + 1}. {s.short}</span>
          <button type="button" className="ka-btn sm" onClick={() => setStep(Math.min(STEPS.length - 1, step + 1))} disabled={step === STEPS.length - 1}>Next<Icon n="arrow_forward" size={15} /></button>
          <button type="button" className="ka-btn sm" data-tour="guide-done" style={{ background: 'var(--primary)', borderColor: 'var(--primary)', color: '#fff', fontWeight: 700 }} onClick={closeDialog}>Got It</button>
        </div>
      </div>
    </div>
  );
}
