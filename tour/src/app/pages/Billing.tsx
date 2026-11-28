import { useState } from 'react';
import { useApp } from '../store';
import { Icon } from '../ui';
import { SectionCard, StatCard } from '../kit';
import { addDays, fmtTime, startOfToday, ymd, type Payment } from '../data';

const RANGES = [['today', 'Today'], ['yesterday', 'Yesterday'], ['7d', 'Last 7 Days'], ['month', 'This Month'], ['lastmonth', 'Last Month'], ['custom', 'Custom']] as const;
type Range = (typeof RANGES)[number][0];

function inRange(p: Payment, r: Range) {
  const d = new Date(p.at);
  const t = startOfToday();
  if (r === 'today') return ymd(d) === ymd(t);
  if (r === 'yesterday') return ymd(d) === ymd(addDays(t, -1));
  if (r === '7d') return d >= addDays(t, -6);
  if (r === 'month') return d.getMonth() === t.getMonth() && d.getFullYear() === t.getFullYear();
  if (r === 'lastmonth') { const lm = new Date(t.getFullYear(), t.getMonth() - 1, 1); return d.getMonth() === lm.getMonth() && d.getFullYear() === lm.getFullYear(); }
  return true;
}

const money = (n: number) => `RM ${n.toLocaleString('en-MY', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

function summarize(list: Payment[]) {
  const ok = list.filter((p) => p.status === 'Successful');
  const paid = ok.reduce((s, p) => s + p.amount, 0);
  const refunded = list.filter((p) => p.status === 'Refunded').reduce((s, p) => s + p.amount, 0);
  const attempts = list.filter((p) => p.kind !== 'Refund');
  const rescue = list.filter((p) => p.status === 'Pending' || p.status === 'Failed').length;
  return { total: attempts.length, ok: ok.length, rescue, paid, refunded, net: paid - refunded, conv: attempts.length ? (ok.length / attempts.length) * 100 : 0, atv: ok.length ? paid / ok.length : 0 };
}

export function PaymentRecords() {
  const db = useApp((s) => s.db);
  const showToast = useApp((s) => s.showToast);
  const [range, setRange] = useState<Range>('yesterday');
  const list = db.payments.filter((p) => inRange(p, range));
  const s = summarize(list);
  const channels = [
    { name: 'Fiuu Online (FPX / Card / E-wallet)', amount: list.filter((p) => p.channel === 'Fiuu Online' && p.status === 'Successful').reduce((a, p) => a + p.amount, 0), color: '#0284c7' },
    { name: 'Counter (Card terminal / Cash / QR)', amount: list.filter((p) => p.channel === 'Counter' && p.status === 'Successful').reduce((a, p) => a + p.amount, 0), color: '#059669' },
  ];
  const days = [...new Set(list.map((p) => ymd(new Date(p.at))))].sort().reverse();
  return (
    <div className="ka-page" style={{ height: '100%', padding: '16px 20px', overflow: 'auto' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start' }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 18, fontWeight: 700 }}>Payment Report</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 6 }}>
            <span style={{ fontSize: 14, color: 'var(--muted)' }}>{startOfToday().toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}</span>
            <span className="ka-input" style={{ width: 240, height: 32, fontSize: 13, fontWeight: 500, background: 'var(--surface-subtle)', justifyContent: 'space-between' }}><span style={{ display: 'flex', alignItems: 'center', gap: 6 }}><Icon n="store" size={15} />Your Branch</span><Icon n="keyboard_arrow_down" size={18} /></span>
          </div>
        </div>
        <span className="ka-icon-square"><Icon n="refresh" /></span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {RANGES.map(([k, l]) => (
          <button key={k} type="button" data-tour={`pay-range-${k}`} onClick={() => setRange(k)} className="ka-btn lg" style={{ fontWeight: k === range ? 700 : 500, ...(k === range ? { background: 'var(--primary)', borderColor: 'var(--primary)', color: '#fff' } : {}) }}>{l}</button>
        ))}
        <span style={{ flex: 1 }} />
        <button type="button" className="ka-btn lg" data-tour="pay-export" onClick={() => showToast('CSV exported successfully.')}><Icon n="download" size={18} />Export CSV</button>
      </div>
      <div data-tour="pay-stats" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
        <StatCard icon="receipt_long" color="#2563eb" value={String(s.total)} label="Total Checkouts" />
        <StatCard icon="check_circle" color="#059669" value={String(s.ok)} label="Successful" badge={<span className="ka-pill green" style={{ height: 20, fontSize: 10.5 }}>{s.conv.toFixed(1)}% conv.</span>} />
        <StatCard tour="pay-rescue" icon="warning_amber" color="#dc2626" value={String(s.rescue)} label="Needs Rescue" badge={s.rescue ? <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--danger)' }}>Click to rescue ↗</span> : undefined} />
        <StatCard icon="payments" color="#7c3aed" value={money(s.paid)} label="Paid Amount" />
        <StatCard icon="undo" color="#d97706" value={money(s.refunded)} label="Refunded" />
        <StatCard icon="trending_up" color="#db2777" value={money(s.net)} label="Net Revenue" badge={<span className="ka-pill red" style={{ height: 20, fontSize: 10.5 }}>ATV {money(s.atv)}</span>} />
      </div>
      {list.length === 0 ? (
        <SectionCard title="Branch Breakdown"><div className="ka-empty" style={{ padding: 40 }}><div><Icon n="receipt_long" size={44} style={{ color: 'var(--border-strong)' }} /><b>No payment data for this period</b>Try selecting a different date range</div></div></SectionCard>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.6fr', gap: 10 }}>
          <SectionCard title="Payment Channel Breakdown" tour="pay-channels">
            {channels.map((c) => (
              <div key={c.name} style={{ marginBottom: 14 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13 }}><span>{c.name}</span><b>{money(c.amount)}</b></div>
                <div style={{ height: 8, borderRadius: 4, background: 'var(--surface-subtle)', marginTop: 6 }}><div style={{ width: `${s.paid ? (c.amount / s.paid) * 100 : 0}%`, height: '100%', borderRadius: 4, background: c.color }} /></div>
              </div>
            ))}
          </SectionCard>
          <SectionCard title="Daily Breakdown" tour="pay-daily" pad={0}>
            <table className="ka-table">
              <thead><tr>{['Date', 'Checkouts', 'Conv %', 'Paid (RM)', 'Refund (RM)', 'Net Revenue (RM)'].map((h) => <th key={h} style={{ height: 38, fontSize: 12 }}>{h}</th>)}</tr></thead>
              <tbody>
                {days.map((d) => {
                  const x = summarize(list.filter((p) => ymd(new Date(p.at)) === d));
                  return <tr key={d}><td style={{ height: 40 }}>{d}</td><td>{x.total}</td><td>{x.conv.toFixed(0)}%</td><td>{x.paid.toFixed(2)}</td><td>{x.refunded.toFixed(2)}</td><td style={{ fontWeight: 700 }}>{x.net.toFixed(2)}</td></tr>;
                })}
                <tr style={{ background: 'var(--surface-subtle)' }}><td style={{ height: 40, fontWeight: 800 }}>TOTALS ({days.length} days)</td><td>{s.total}</td><td>{s.conv.toFixed(0)}%</td><td>{s.paid.toFixed(2)}</td><td>{s.refunded.toFixed(2)}</td><td style={{ fontWeight: 800 }}>{s.net.toFixed(2)}</td></tr>
              </tbody>
            </table>
          </SectionCard>
        </div>
      )}
    </div>
  );
}

export function DailyClosing() {
  const db = useApp((s) => s.db);
  const showToast = useApp((s) => s.showToast);
  const today = ymd(startOfToday());
  const list = db.payments.filter((p) => ymd(new Date(p.at)) === today).sort((a, b) => a.at.localeCompare(b.at));
  const ok = list.filter((p) => p.status === 'Successful');
  const fiuu = ok.filter((p) => p.channel === 'Fiuu Online');
  const counter = ok.filter((p) => p.channel === 'Counter');
  const refunds = list.filter((p) => p.status === 'Refunded');
  const sum = (l: Payment[]) => l.reduce((s, p) => s + p.amount, 0);
  const pending = list.filter((p) => p.status === 'Pending').length;
  const appts = db.appointments.filter((a) => ymd(new Date(a.start)) === today);
  const unpaidDone = appts.filter((a) => a.status === 'Completed' && a.payment === 'No Payment').length;
  const clean = pending === 0 && unpaidDone === 0;
  const methods = [...new Set(ok.map((p) => `${p.channel} · ${p.method}`))];
  const op = (label: string, value: number, color: string) => (
    <div style={{ padding: '10px 12px', borderRadius: 6, background: 'var(--surface-subtle)', border: '1px solid var(--border)', minWidth: 140 }}>
      <div style={{ fontSize: 12, color: 'var(--ink-2)' }}>{label}</div>
      <div style={{ fontSize: 16, fontWeight: 800, color, marginTop: 6 }}>{value}</div>
    </div>
  );
  const big = (label: string, value: string, sub: string, color: string, tour?: string) => (
    <div className="ka-card" data-tour={tour} style={{ flex: 1, padding: '24px 14px', borderRadius: 8 }}>
      <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--ink-2)' }}>{label}</div>
      <div style={{ fontSize: 20, fontWeight: 800, color, margin: '6px 0' }}>{value}</div>
      <div style={{ fontSize: 11.5, color: 'var(--muted)' }}>{sub}</div>
    </div>
  );
  return (
    <div className="ka-page" style={{ height: '100%', padding: '18px 20px', overflow: 'auto' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 21, fontWeight: 800 }}>Daily Branch Handover &amp; EOD Reconciliation</div>
          <div style={{ fontSize: 13.5, color: 'var(--muted)', marginTop: 4 }}>Klinik Aurora Bukit Rimau · {startOfToday().toLocaleDateString('en-GB', { weekday: 'long', day: '2-digit', month: 'short', year: 'numeric' })}</div>
        </div>
        <button type="button" className="ka-btn lg"><Icon n="calendar_today" size={17} />{startOfToday().toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}</button>
        <button type="button" className="ka-btn lg" data-tour="eod-copy" onClick={() => showToast('Shift handover summary copied — ready to paste into WhatsApp!')}><Icon n="content_copy" size={17} />Copy Shift Summary</button>
        <button type="button" className="ka-btn primary lg" onClick={() => showToast('Exported EOD handover CSV.')}><Icon n="download" size={17} />Export CSV</button>
      </div>
      <div data-tour="eod-banner" style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px', borderRadius: 8, background: clean ? 'var(--success-soft)' : 'var(--warning-soft)', border: `1px solid ${clean ? 'rgba(16,185,129,.4)' : 'rgba(245,158,11,.45)'}` }}>
        <Icon n={clean ? 'verified' : 'error_outline'} size={24} style={{ color: clean ? 'var(--success)' : '#d97706' }} />
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 14, fontWeight: 700, color: clean ? 'var(--ink)' : 'var(--warning-text)' }}>{clean ? 'EOD Cash & Fiuu Reconciliation Clean' : 'Reconciliation Attention Needed'}</div>
          <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 3 }}>Mismatches: 0 · Unpaid Completed Visits: {unpaidDone} · Pending Payment: {pending}</div>
        </div>
        {!clean && <button type="button" className="ka-btn sm" style={{ color: 'var(--warning-text)', borderColor: 'rgba(245,158,11,.5)' }}>Inspect Payment Issues<Icon n="arrow_forward" size={15} /></button>}
      </div>
      <div style={{ display: 'flex', gap: 12 }} data-tour="eod-kpis">
        {big('Net Revenue', money(sum(ok) - sum(refunds)), `Collected ${money(sum(ok))}`, 'var(--primary-ink)')}
        {big('Fiuu Online', money(sum(fiuu)), `${fiuu.length} online transactions`, 'var(--sky-text)')}
        {big('Counter / Proof', money(sum(counter)), `${counter.length} manual proofs`, 'var(--success-text)')}
        {big('Refunds', money(sum(refunds)), `${refunds.length} refunded`, 'var(--danger)')}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1.7fr 1fr', gap: 12 }}>
        <SectionCard title="Appointment Operations Summary" tour="eod-ops">
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10 }}>
            {op('Total Scheduled', appts.length, 'var(--ink)')}
            {op('Completed', appts.filter((a) => a.status === 'Completed').length, 'var(--success)')}
            {op('Walk-In / Admin Booked', 1, 'var(--primary-ink)')}
            {op('Booked / Active', appts.filter((a) => a.status === 'Booked').length, 'var(--info)')}
            {op('Rescheduled', appts.filter((a) => a.status === 'Rescheduled').length, '#d97706')}
            {op('Cancelled', appts.filter((a) => a.status === 'Cancelled').length, 'var(--danger)')}
            {op('No-Show', appts.filter((a) => a.status === 'No-Show').length, 'var(--danger)')}
          </div>
          <div style={{ marginTop: 12, fontSize: 12, color: 'var(--warning-text)', display: 'flex', gap: 6, alignItems: 'center' }}><Icon n="info" v="o" size={15} />Anything still Booked at midnight becomes No-Show. Update statuses before you leave.</div>
        </SectionCard>
        <SectionCard title="Channel Breakdown">
          {methods.length === 0 ? <div style={{ fontSize: 13, color: 'var(--ink-2)' }}>No payment channels recorded today.</div> : methods.map((m) => {
            const l = ok.filter((p) => `${p.channel} · ${p.method}` === m);
            return <div key={m} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, padding: '6px 0', borderBottom: '1px solid var(--border)' }}><span>{m} <span style={{ color: 'var(--muted)' }}>×{l.length}</span></span><b>{money(sum(l))}</b></div>;
          })}
        </SectionCard>
      </div>
      <SectionCard title={`Daily Payment Ledger (${list.length})`} tour="eod-ledger" pad={0}>
        <table className="ka-table">
          <thead><tr>{['Time', 'Receipt No', 'Patient', 'Service', 'Channel', 'State', 'Amount'].map((h) => <th key={h} style={{ height: 38, fontSize: 12 }}>{h}</th>)}</tr></thead>
          <tbody>
            {list.map((p) => {
              const pt = db.patients.find((x) => x.id === p.patientId)!;
              const a = db.appointments.find((x) => x.id === p.appointmentId);
              const sv = a ? db.services.find((x) => x.id === a.serviceId)!.name : 'Walk-in';
              return (
                <tr key={p.id}>
                  <td style={{ height: 42 }}>{fmtTime(new Date(p.at))}</td>
                  <td style={{ fontFamily: 'ui-monospace, monospace', fontSize: 12 }}>{p.ref}</td>
                  <td>{pt.name}</td><td>{sv}</td>
                  <td><span className={`ka-pill ${p.channel === 'Counter' ? 'green' : 'blue'}`}>{p.channel === 'Counter' ? `Counter · ${p.method}` : `Fiuu · ${p.method}`}</span></td>
                  <td><span className={`ka-pill ${p.status === 'Successful' ? 'green' : p.status === 'Pending' ? 'amber' : 'red'}`}>{p.status}</span></td>
                  <td style={{ fontWeight: 700 }}>{money(p.amount)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </SectionCard>
    </div>
  );
}
