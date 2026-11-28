import { useState } from 'react';
import { useApp } from '../store';
import { Icon } from '../ui';
import { fmtStamp, initials, type Patient } from '../data';

const PRESETS = [50, 80, 100, 150, 200, 250];
const teal = 'linear-gradient(135deg, #2dd4bf, #0e7490)';

function StepHead({ n, title, sub }: { n: number; title: string; sub: string }) {
  return (
    <div style={{ display: 'flex', gap: 10 }}>
      <span style={{ width: 24, height: 24, borderRadius: 6, background: teal, color: '#fff', fontSize: 12, fontWeight: 700, display: 'grid', placeItems: 'center', marginTop: 1 }}>{n}</span>
      <div><div style={{ fontSize: 15, fontWeight: 600 }}>{title}</div><div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 3 }}>{sub}</div></div>
    </div>
  );
}

function RewardsPanel({ patient, projected }: { patient: Patient; projected: number }) {
  const { db, openDialog } = useApp();
  const rewards = db.rewards.filter((r) => r.active);
  const eligible = rewards.filter((r) => patient.points >= r.points);
  const unlocking = rewards.filter((r) => patient.points < r.points && projected >= r.points);
  const amber = eligible.length > 0;
  return (
    <div data-tour="rewards-panel" style={{ marginTop: 12, borderRadius: 10, padding: 12, background: amber ? 'var(--reward-bg)' : 'var(--surface-subtle)', border: `1px solid ${amber ? 'rgba(245,158,11,.45)' : 'var(--border)'}` }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12.5, fontWeight: 700, color: amber ? 'var(--amber-head)' : 'var(--ink-2)', marginBottom: 8 }}>
        <Icon n="redeem" size={16} />
        {amber ? `Rewards (${eligible.length} eligible) — Ask patient if they want to claim:` : `Rewards (${rewards.length} available) — Patient needs more points to claim:`}
      </div>
      {rewards.map((r) => {
        const ok = patient.points >= r.points;
        const soon = !ok && projected >= r.points;
        return (
          <div key={r.id} data-tour={`reward-${r.id}`} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '9px 12px', marginTop: 6, borderRadius: 8, background: ok ? 'var(--surface)' : 'var(--canvas)', border: `1px solid ${soon ? 'color-mix(in srgb, #0ea5e9 50%, transparent)' : 'var(--border)'}`, opacity: ok ? 1 : 'var(--locked-opacity)' as unknown as number }}>
            <Icon n={ok ? 'check_circle' : soon ? 'lock_open' : 'lock'} size={18} style={{ color: ok ? '#d97706' : soon ? 'var(--unlock)' : 'var(--muted)' }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: ok ? 'var(--ink)' : 'var(--muted)' }}>{r.name}</div>
              <div style={{ fontSize: 11.5, color: soon ? 'var(--unlock)' : 'var(--muted)', marginTop: 2, fontWeight: 600 }}>
                {ok ? `${r.points} pts · ${r.left} left` : soon ? `${r.points} pts · Unlocks after this payment (+${projected - patient.points} pts)` : `${r.points} pts · Need ${r.points - patient.points} more pts`}
              </div>
            </div>
            {ok ? (
              <button type="button" className="ka-btn amber sm" data-tour={`claim-${r.id}`} style={{ height: 30, fontWeight: 700 }} onClick={() => openDialog({ kind: 'claimReward', patientId: patient.id, rewardId: r.id })}>Claim</button>
            ) : (
              <span className="ka-pill grey" style={{ fontSize: 11 }}>Locked</span>
            )}
          </div>
        );
      })}
      {unlocking.length > 0 && (
        <div data-tour="unlock-banner" style={{ marginTop: 10, padding: '8px 10px', borderRadius: 8, background: 'color-mix(in srgb, #0ea5e9 10%, transparent)', border: '1px solid color-mix(in srgb, #0ea5e9 25%, transparent)', color: 'var(--sky-text)', fontSize: 12, fontWeight: 600, display: 'flex', gap: 6, alignItems: 'center' }}>
          <Icon n="auto_awesome" size={15} />After this payment ({projected} pts), unlocks: {unlocking.map((r) => `${r.name} (${r.points} pts)`).join(', ')}
        </div>
      )}
    </div>
  );
}

function ActivityLog() {
  const db = useApp((s) => s.db);
  const items = db.pointsLog.slice(0, 8);
  return (
    <div className="ka-card" style={{ width: 490, flex: 'none', borderRadius: 12, display: 'flex', flexDirection: 'column', alignSelf: 'stretch' }} data-tour="activity-log">
      <div style={{ padding: '20px 20px 14px', borderBottom: '1px solid var(--border)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ width: 36, height: 36, borderRadius: 8, background: 'var(--success-soft)', display: 'grid', placeItems: 'center' }}><Icon n="history" size={20} style={{ color: 'var(--success)' }} /></span>
          <span style={{ fontSize: 15, fontWeight: 600, flex: 1 }}>Points Activity Log</span>
          <span className="ka-pill grey" style={{ fontSize: 11 }}>{db.pointsLog.length + 35} total</span>
          <Icon n="refresh" size={19} style={{ color: 'var(--ink-2)' }} />
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
          <span style={{ fontSize: 11.5, fontWeight: 700, color: 'var(--teal)', border: '1px solid var(--teal)', background: 'color-mix(in srgb, var(--teal) 8%, transparent)', padding: '4px 10px', borderRadius: 999 }}>All History ({db.pointsLog.length + 35})</span>
          <span style={{ fontSize: 11.5, fontWeight: 600, color: 'var(--ink-2)', border: '1px solid var(--border)', padding: '4px 10px', borderRadius: 999, display: 'flex', alignItems: 'center', gap: 4 }}><Icon n="today" size={13} />Today's Shift ({db.pointsLog.filter((l) => l.id.startsWith('pl-new')).length})</span>
        </div>
      </div>
      <div style={{ flex: 1, overflow: 'auto', padding: '10px 10px' }}>
        {items.map((l) => {
          const p = db.patients.find((x) => x.id === l.patientId)!;
          const neg = l.points < 0;
          return (
            <div key={l.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 12px', marginBottom: 8, borderRadius: 8, border: '1px solid var(--border)', borderLeft: `3px solid ${neg ? '#d97706' : '#22c55e'}`, animation: l.id.startsWith('pl-new') ? 'ka-dialog-in .4s ease' : undefined }}>
              <span className="ka-avatar" style={{ width: 30, height: 30, fontSize: 11, background: 'var(--success-soft)', color: 'var(--teal-text)' }}>{initials(p.name)}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600 }}>{p.username}</div>
                <div style={{ fontSize: 11.5, color: 'var(--ink-2)', marginTop: 3, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{l.description}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 3, display: 'flex', alignItems: 'center', gap: 4 }}><Icon n="schedule" size={12} />{fmtStamp(l.at)} · by {l.by}</div>
              </div>
              <span style={{ fontSize: 13, fontWeight: 800, color: neg ? 'var(--warning-text)' : 'var(--success-text)', border: `1px solid ${neg ? 'rgba(245,158,11,.45)' : 'rgba(34,197,94,.4)'}`, background: neg ? 'var(--warning-soft)' : 'var(--success-soft)', padding: '5px 10px', borderRadius: 6 }}>
                {neg ? '−' : '+'}{Math.abs(l.points)}<span style={{ fontSize: 10, fontWeight: 600 }}> pts</span>
              </span>
            </div>
          );
        })}
      </div>
      <div style={{ margin: '0 12px 12px', padding: '8px 12px', borderRadius: 8, background: 'var(--surface-subtle)', fontSize: 11.5, color: 'var(--ink-2)', textAlign: 'center' }}>
        ⭐ RM 1 = 1 pt · 100 pts ≈ RM 1 reward value · 12-month expiry
      </div>
    </div>
  );
}

export function Points() {
  const { db, openDialog, closeDialog, awardPoints } = useApp();
  const [mode, setMode] = useState<'phone' | 'ic'>('phone');
  const [q, setQ] = useState('');
  const [results, setResults] = useState<Patient[] | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [amount, setAmount] = useState('');
  const selected = db.patients.find((p) => p.id === selectedId) ?? null;
  const amt = Number(amount) || 0;
  const pts = Math.floor(amt);
  const projected = (selected?.points ?? 0) + pts;

  const find = () => {
    const key = q.replace(/\D/g, '');
    const found = db.patients.filter((p) => (mode === 'phone' ? p.phone.includes(key) : p.nric.includes(key)) && key.length >= 4);
    setResults(found);
    setSelectedId(null);
  };
  const award = () => {
    if (!selected || pts <= 0) return;
    openDialog({
      kind: 'confirm', title: 'Are you sure?', message: `Award ${pts} points to ${selected.name} for RM ${amount} payment?`,
      onConfirm: () => {
        closeDialog();
        const total = awardPoints(selected.id, pts, `Earned ${pts} points for RM ${amount} payment`);
        setAmount('');
        openDialog({ kind: 'awardSuccess', patientId: selected.id, earned: pts, newTotal: total });
      },
    });
  };
  const label = !selected ? '1. Select Patient to Award Points' : amt <= 0 ? '2. Enter Amount or Tap Scan Preset' : `Award ${pts} Points & Send WhatsApp Receipt`;

  return (
    <div className="ka-page" style={{ flexDirection: 'row', gap: 32, padding: '48px 32px 32px 32px', alignItems: 'flex-start', height: '100%' }}>
      <div className="ka-card" style={{ flex: 1, borderRadius: 12, padding: 32, maxHeight: '100%', overflow: 'auto' }} data-tour="pos-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '18px 16px', borderRadius: 12, border: '1px solid var(--border)', background: 'linear-gradient(90deg, color-mix(in srgb, var(--primary) 5%, var(--surface)), var(--surface))' }}>
          <Icon n="star" size={30} style={{ color: '#f59e0b' }} />
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 16, fontWeight: 700 }}>Frontdesk Points POS</span>
              <span style={{ fontSize: 10, fontWeight: 700, letterSpacing: .6, color: 'var(--success-text)', background: 'var(--success-soft)', border: '1px solid rgba(34,197,94,.4)', borderRadius: 4, padding: '2px 6px' }}>⚡ LIVE TERMINAL</span>
            </div>
            <div style={{ fontSize: 12.5, color: 'var(--ink-2)', marginTop: 6 }}>Record walk-in scans &amp; payments to reward loyalty points in real-time.</div>
          </div>
          <span style={{ fontSize: 12, fontWeight: 500, border: '1px solid var(--border)', borderRadius: 6, padding: '6px 10px', display: 'flex', alignItems: 'center', gap: 6 }}><Icon n="info" v="o" size={14} />RM 1 = 1 pt</span>
        </div>

        <div style={{ marginTop: 24 }}><StepHead n={1} title="Identify Patient" sub="Search patient by Mobile Number or MyKad to link transaction." /></div>
        <div style={{ display: 'inline-flex', marginTop: 14, padding: 3, borderRadius: 8, background: 'var(--surface-subtle)' }}>
          {(['phone', 'ic'] as const).map((m) => (
            <button key={m} type="button" onClick={() => setMode(m)} style={{ height: 34, padding: '0 16px', border: 'none', borderRadius: 6, fontSize: 12.5, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6, background: mode === m ? 'var(--surface)' : 'transparent', color: mode === m ? '#22b8cf' : 'var(--ink-2)', boxShadow: mode === m ? '0 1px 2px rgba(0,0,0,.08)' : 'none' }}>
              <Icon n={m === 'phone' ? 'smartphone' : 'badge'} v="o" size={16} />{m === 'phone' ? 'Mobile Number' : 'IC / MyKad Number'}
            </button>
          ))}
        </div>
        <div className="ka-input" style={{ marginTop: 12, paddingRight: 4, height: 46 }} data-tour="pos-input">
          <Icon n="smartphone" v="o" size={18} />
          <input value={q} onChange={(e) => setQ(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && find()} placeholder={mode === 'phone' ? 'Enter mobile number (e.g. 0123456789)...' : 'Enter IC number (e.g. 900101101234)...'} />
          {q && <Icon n="close" size={18} />}
          <button type="button" data-tour="pos-find" onClick={find} style={{ height: 38, padding: '0 16px', border: 'none', borderRadius: 6, background: 'linear-gradient(135deg, #67d3e6, #1d9fd0)', color: '#fff', fontWeight: 700, fontSize: 13.5, display: 'flex', alignItems: 'center', gap: 6 }}>
            <Icon n="search" size={18} style={{ color: '#fff' }} />Find Patient
          </button>
        </div>

        {!selected && results === null && (
          <div style={{ marginTop: 10, padding: '10px 14px', borderRadius: 8, background: 'var(--surface-subtle)', border: '1px solid var(--border)', fontSize: 12, color: 'var(--ink-2)', display: 'flex', alignItems: 'center', gap: 8 }}>
            <Icon n="info" v="o" size={15} />Search patient by Mobile Number or IC above to view balance and award points.
          </div>
        )}
        {!selected && results !== null && (
          <div style={{ marginTop: 10, borderRadius: 8, border: '1px solid var(--border)' }} data-tour="pos-results">
            <div style={{ padding: '10px 14px', fontSize: 12, color: 'var(--ink-2)', borderBottom: '1px solid var(--border)' }}>
              {results.length ? `${results.length} matching patient${results.length > 1 ? 's' : ''} found. Select one to award points:` : 'No patient found with that number.'}
            </div>
            {results.map((p) => (
              <div key={p.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px' }}>
                <span className="ka-avatar" style={{ width: 30, height: 30, fontSize: 11, background: 'var(--surface-subtle)', color: 'var(--ink-2)' }}>{initials(p.name)}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 500 }}>{p.name}</div>
                  <div style={{ fontSize: 11.5, color: 'var(--muted)', marginTop: 2 }}>{p.phone} · IC: {p.nric} · {p.points} pts</div>
                </div>
                <button type="button" className="ka-btn primary sm" data-tour={`pos-select-${p.id}`} onClick={() => setSelectedId(p.id)}>Select</button>
              </div>
            ))}
          </div>
        )}
        {selected && (
          <>
            <div style={{ marginTop: 12, borderRadius: 10, border: '1.5px solid rgba(34,197,94,.45)', overflow: 'hidden' }} data-tour="pos-selected">
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', background: 'var(--surface)' }}>
                <span style={{ width: 42, height: 42, borderRadius: 10, background: teal, color: '#fff', fontWeight: 800, display: 'grid', placeItems: 'center' }}>{initials(selected.name)}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 15, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 6 }}>{selected.name}<Icon n="check_circle" size={17} style={{ color: 'var(--success)' }} /></div>
                  <div style={{ display: 'flex', gap: 6, marginTop: 5 }}>
                    <span className="ka-pill grey" style={{ fontSize: 11 }}><Icon n="call" size={12} />{selected.phone}</span>
                    <span className="ka-pill grey" style={{ fontSize: 11 }}><Icon n="badge" size={12} />{selected.nric}</span>
                  </div>
                </div>
                <button type="button" className="ka-btn sm" onClick={() => { setSelectedId(null); setResults(null); }}><Icon n="swap_horiz" size={16} />Change</button>
              </div>
              <div style={{ padding: '10px 14px 12px', background: 'var(--success-soft)', display: 'flex', alignItems: 'center', gap: 10 }} data-tour="pos-balance">
                <Icon n="star" size={22} style={{ color: '#f59e0b' }} />
                <div>
                  <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: .8, color: 'var(--success-text)' }}>LOYALTY VAULT BALANCE</div>
                  <div style={{ fontSize: 20, fontWeight: 800, color: 'var(--success-text)', transition: 'color .3s' }}>{selected.points} <span style={{ fontSize: 11 }}>pts</span></div>
                </div>
              </div>
            </div>
            <RewardsPanel patient={selected} projected={projected} />
          </>
        )}

        <div style={{ height: 1, background: 'var(--border)', margin: '22px 0' }} />
        <StepHead n={2} title="Payment & Bill Amount" sub="Enter bill amount or tap a quick preset." />
        <div className="ka-input" style={{ marginTop: 14, height: 46 }} data-tour="pos-amount">
          <span style={{ fontWeight: 600, color: 'var(--ink)' }}>RM</span>
          <input value={amount} onChange={(e) => setAmount(e.target.value.replace(/[^\d.]/g, ''))} placeholder="0.00" style={{ fontSize: 16 }} />
          <span style={{ fontSize: 12, fontWeight: 700, color: pts ? 'var(--success-text)' : 'var(--ink-2)', background: pts ? 'var(--success-soft)' : 'var(--surface-subtle)', borderRadius: 6, padding: '4px 8px', display: 'flex', alignItems: 'center', gap: 4 }}>
            <Icon n="add_circle" size={14} />{pts} pts
          </span>
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
          {PRESETS.map((v) => (
            <button key={v} type="button" className="ka-btn" data-tour={`pos-preset-${v}`} onClick={() => setAmount(String(v))} style={{ height: 36, fontWeight: 500, ...(amount === String(v) ? { borderColor: 'var(--primary)', color: 'var(--primary-ink)', background: 'var(--primary-soft)' } : {}) }}>RM {v}</button>
          ))}
        </div>
        <div style={{ height: 1, background: 'var(--border)', margin: '22px 0' }} />
        <button type="button" data-tour="pos-award" onClick={award} disabled={!selected || pts <= 0}
          style={{ width: '100%', height: 48, borderRadius: 10, border: 'none', fontSize: 14, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            background: selected && pts > 0 ? 'linear-gradient(135deg, var(--primary), color-mix(in srgb, var(--primary) 75%, #000))' : 'var(--surface-subtle)', color: selected && pts > 0 ? '#fff' : 'var(--ink-2)', boxShadow: selected && pts > 0 ? '0 6px 16px color-mix(in srgb, var(--primary) 35%, transparent)' : 'none' }}>
          <Icon n={selected && pts > 0 ? 'stars' : 'lock'} v={selected && pts > 0 ? 'r' : 'o'} size={18} />{label}
        </button>
      </div>
      <ActivityLog />
    </div>
  );
}
