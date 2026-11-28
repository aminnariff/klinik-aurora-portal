import { useEffect, useRef, useState } from 'react';
import { useApp } from '../store';
import { Avatar, Icon, Pager } from '../ui';
import { Cell2 } from '../kit';
import { HOME_BRANCH, fmtDayDate, fmtRange, fmtStamp } from '../data';

/** fiuu_audit_dialog.dart — re-checks unpaid Fiuu transactions against Fiuu. */
function FiuuAuditDialog() {
  const closeDialog = useApp((s) => s.closeDialog);
  const [mode, setMode] = useState<'recent' | 'full'>('recent');
  const [state, setState] = useState<'idle' | 'scanning' | 'done'>('idle');
  const [checked, setChecked] = useState(0);
  const timer = useRef<ReturnType<typeof setInterval> | null>(null);
  const total = mode === 'recent' ? 18 : 64;
  useEffect(() => () => { if (timer.current) clearInterval(timer.current); }, []);
  const start = () => {
    setState('scanning'); setChecked(0);
    timer.current = setInterval(() => setChecked((c) => { if (c + 3 >= total) { clearInterval(timer.current!); setState('done'); return total; } return c + 3; }), 90);
  };
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 520, padding: 20, gap: 14 }} onClick={(e) => e.stopPropagation()} data-tour="fiuu-dialog">
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <Icon n="fact_check" size={22} style={{ color: 'var(--primary-ink)' }} />
          <b style={{ flex: 1, fontSize: 16 }}>Audit Fiuu Payments</b>
          <button type="button" className="ka-dialog-close" title="Tutup" onClick={closeDialog}><Icon n="close" size={20} /></button>
        </div>
        <div style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.5 }}>Checks every transaction we have marked as NOT paid directly against Fiuu's records, in case a payment went through but our side missed it.</div>
        <div style={{ display: 'flex', gap: 8 }}>
          {([['recent', 'Last 3 hours'], ['full', 'Full history (first run)']] as const).map(([k, l]) => (
            <button key={k} type="button" onClick={() => setMode(k)} disabled={state === 'scanning'} className="ka-btn sm" style={k === mode ? { background: 'var(--primary-soft)', borderColor: 'var(--primary)', color: 'var(--primary-ink)' } : {}}>{l}</button>
          ))}
        </div>
        {state !== 'idle' && (
          <div data-tour="fiuu-progress">
            <div style={{ height: 6, borderRadius: 3, background: 'var(--surface-subtle)' }}><div style={{ width: `${(checked / total) * 100}%`, height: '100%', borderRadius: 3, background: 'var(--primary)', transition: 'width .1s' }} /></div>
            <div style={{ fontSize: 12.5, color: 'var(--ink-2)', marginTop: 8 }}>
              {state === 'scanning' ? `Scanning… checked ${checked} so far (${checked} confirmed still unpaid)` : `Done — checked ${total}, 0 discrepancies.`}
            </div>
            {state === 'done' && <div style={{ marginTop: 8, padding: '10px 12px', borderRadius: 8, background: 'var(--success-soft)', color: 'var(--success-text)', fontSize: 13, fontWeight: 600, display: 'flex', gap: 6, alignItems: 'center' }}><Icon n="verified" size={17} />No discrepancies found.</div>}
          </div>
        )}
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
          <button type="button" className="ka-btn" data-tour="fiuu-close" onClick={closeDialog}>Close</button>
          <button type="button" className="ka-btn primary" data-tour="fiuu-start" disabled={state === 'scanning'} onClick={start}><Icon n="play_arrow" size={17} />Start Scan</button>
        </div>
      </div>
    </div>
  );
}

export function PaymentIssues() {
  const { db, go, openDialog, closeDialog, patch, nextId } = useApp();
  const reclaim = (id: string) => {
    const m = db.mismatches.find((x) => x.id === id)!;
    const p = db.patients.find((x) => x.id === m.patientId)!;
    openDialog({
      kind: 'confirm', title: 'Reclaim Slot?', confirmLabel: 'Reclaim',
      message: `This will book the slot for ${p.name} on ${fmtDayDate(m.start)} if it's still free, and clear the payment issue.`,
      onConfirm: () => {
        closeDialog();
        const sv = db.services.find((s) => s.id === m.serviceId)!;
        const pr = db.practitioners.find((x) => x.branchId === HOME_BRANCH && x.type === sv.type);
        patch((d) => ({
          ...d,
          mismatches: d.mismatches.filter((x) => x.id !== id),
          appointments: [...d.appointments, { id: nextId('ap'), patientId: m.patientId, serviceId: m.serviceId, branchId: HOME_BRANCH, start: m.start, status: 'Booked', payment: 'Fee Paid', practitionerId: pr?.id, receiptNo: m.ref, created: new Date().toISOString() }],
        }));
        openDialog({ kind: 'status', tone: 'success', title: 'Success!', message: `Slot reclaimed. ${p.name} is back in the schedule.` });
      },
    });
  };
  return (
    <div className="ka-page" style={{ height: '100%', padding: '16px 24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <button type="button" className="ka-icon-square" data-tour="issues-back" title="Back" onClick={() => go('appointments')}><Icon n="arrow_back" /></button>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 19, fontWeight: 800 }}>Payment Issues</div>
          <div style={{ fontSize: 13, color: 'var(--muted)', marginTop: 2 }}>Payment succeeded but the appointment is not in the schedule — needs manual follow-up.</div>
        </div>
        <button type="button" className="ka-btn lg" data-tour="issues-audit" onClick={() => openDialog({ kind: 'custom', render: () => <FiuuAuditDialog /> })}><Icon n="fact_check" size={18} />Audit Fiuu Payments</button>
        <button type="button" className="ka-btn primary lg"><Icon n="refresh" size={18} />Refresh</button>
      </div>
      <div className="ka-card ka-table-wrap" style={{ borderRadius: 12 }} data-tour="issues-table">
        <div className="ka-table-scroll">
          <table className="ka-table">
            <thead><tr>{['Patient', 'Service', 'Appointment Time', 'Payment', 'Flagged Since', 'Actions'].map((h) => <th key={h}>{h}</th>)}</tr></thead>
            <tbody>
              {db.mismatches.map((m, i) => {
                const p = db.patients.find((x) => x.id === m.patientId)!;
                const s = db.services.find((x) => x.id === m.serviceId)!;
                return (
                  <tr key={m.id} data-tour={`issue-row-${m.id}`}>
                    <td><div className="ka-cell-person"><Avatar name={p.name} idx={i + 2} /><Cell2 title={p.name} sub={p.phone} /></div></td>
                    <td>{s.name}</td>
                    <td><Cell2 title={fmtDayDate(m.start)} sub={fmtRange(m.start, s.minutes)} /></td>
                    <td><Cell2 title={<b>RM {m.amount.toFixed(2)}</b>} sub={<span style={{ fontFamily: 'ui-monospace, monospace' }}>Fiuu · {m.ref}</span>} /></td>
                    <td style={{ fontSize: 12.5, color: 'var(--ink-2)' }}>{fmtStamp(m.flaggedAt)}</td>
                    <td><button type="button" className="ka-btn sm" data-tour={`issue-reclaim-${m.id}`} style={{ background: '#059669', borderColor: '#059669', color: '#fff' }} onClick={() => reclaim(m.id)}><Icon n="event_available" size={15} />Reclaim</button></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {db.mismatches.length === 0 && <div className="ka-empty" style={{ padding: 60 }}><div><div className="ka-empty-icon" style={{ background: 'var(--success-soft)' }}><Icon n="verified" style={{ color: 'var(--success)' }} /></div><b>No payment issues</b>Every paid booking is in the schedule.</div></div>}
        </div>
        <Pager total={db.mismatches.length} shown={db.mismatches.length} />
      </div>
    </div>
  );
}
