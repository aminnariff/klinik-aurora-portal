import { useState } from 'react';
import { useApp } from '../store';
import { Icon } from '../ui';
import { Toggle } from '../kit';
import { addDays, fmtShortDate, gestationToday, startOfToday, ymd, type Patient } from '../data';

const WINDOWS = [
  { key: 'nt', label: 'W11–13 NT', from: 11, to: 13, scan: 'NT & First Trimester Scan' },
  { key: 'detail', label: 'W18–24 Detail', from: 18, to: 24, scan: 'Detail Scan (Anomaly Screening)' },
  { key: '4d5d', label: 'W26–32 4D/5D', from: 26, to: 32, scan: '4D/5D/6D Ultrasound Scan' },
  { key: 'growth', label: 'W33–36 Growth', from: 33, to: 36, scan: 'Third Trimester Growth & Position Scan' },
] as const;

const SCHEME = [
  ['W11–13', 'NT & First Trimester Scan', '+50 Bonus Pts', 'Early chromosomal & nuchal translucency risk screening'],
  ['W18–24', 'Detail Anomaly Screening Scan', '+100 Bonus Pts', 'Comprehensive fetal organ anatomy & structural evaluation'],
  ['W26–32', '4D/5D Bonding Scan', '+100 Bonus Pts', 'High-definition real-time facial features & emotional bonding scan'],
  ['W33–36', 'Growth & Position Doppler Scan', '+50 Bonus Pts', 'Late pregnancy fetal biometry, amniotic fluid, and presentation check'],
  ['Postnatal', 'Maternal & Newborn Postnatal Check', '+50 Bonus Pts', 'Mother and baby wellness review after delivery'],
];

function windowOf(p: Patient) {
  const { w } = gestationToday(p.edd!);
  return WINDOWS.find((x) => w >= x.from && w <= x.to) ?? null;
}

export function FollowUp() {
  const { db, patch, showToast } = useApp();
  const [tab, setTab] = useState<'recalls' | 'points' | 'scheme'>('recalls');
  const [win, setWin] = useState<'all' | (typeof WINDOWS)[number]['key']>('all');
  const [unbookedOnly, setUnbookedOnly] = useState(true);
  const today = ymd(startOfToday());
  const hasBooking = (p: Patient) => db.appointments.some((a) => a.patientId === p.id && (a.status === 'Booked' || a.status === 'Rescheduled') && ymd(new Date(a.start)) >= today && db.services.find((s) => s.id === a.serviceId)?.pregnancy);
  const mothers = db.patients.filter((p) => p.edd && windowOf(p)).sort((a, b) => a.edd!.localeCompare(b.edd!));
  const unbooked = mothers.filter((p) => !hasBooking(p));
  const list = (unbookedOnly ? unbooked : mothers).filter((p) => win === 'all' || windowOf(p)!.key === win);
  const recalled = Object.keys(db.recalls).filter((id) => mothers.some((m) => m.id === id)).length;
  const send = (p: Patient, channel: string) => {
    patch((d) => ({ ...d, recalls: { ...d.recalls, [p.id]: { at: new Date().toISOString(), channel } } }));
    showToast(`Recall logged for ${p.name} (${channel}).`);
  };
  const members = db.patients.filter((p) => p.points >= 500 && !db.appointments.some((a) => a.patientId === p.id && a.status === 'Booked'));
  const offer = (p: Patient) => { patch((d) => ({ ...d, offers: { ...d.offers, [p.id]: fmtShortDate(new Date().toISOString()) } })); showToast(`Points offer logged for ${p.name}.`); };

  const tabBtn = (k: typeof tab, label: string, count?: number) => (
    <button key={k} type="button" data-tour={`fu-tab-${k}`} onClick={() => setTab(k)} style={{ flex: 1, height: 38, borderRadius: 8, fontSize: 12.5, fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, border: `1px solid ${tab === k ? 'var(--primary)' : 'transparent'}`, background: tab === k ? 'var(--primary-soft)' : 'transparent', color: tab === k ? 'var(--primary-ink)' : 'var(--ink)' }}>
      {label}{count != null && <span style={{ minWidth: 18, height: 18, borderRadius: 9, background: 'var(--primary)', color: '#fff', fontSize: 11, display: 'grid', placeItems: 'center', padding: '0 5px' }}>{count}</span>}
    </button>
  );

  return (
    <div className="ka-page" style={{ height: '100%', padding: '18px 20px', gap: 10 }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 21, fontWeight: 800 }}>Patient Follow-Up &amp; Points Loyalty</div>
          <div style={{ fontSize: 13, color: 'var(--muted)', marginTop: 4 }}>Proactively recall expectant mothers for key milestone scans and re-engage patients with unspent points.</div>
        </div>
        <div className="ka-input" style={{ width: 230, height: 40, justifyContent: 'space-between', fontSize: 13, fontWeight: 500 }}>Klinik Aurora Bukit Rimau<Icon n="arrow_drop_down" /></div>
        <button type="button" className="ka-btn primary lg"><Icon n="refresh" size={17} />Refresh</button>
      </div>
      <div className="ka-card" style={{ display: 'flex', gap: 4, padding: 4, borderRadius: 10 }}>
        {tabBtn('recalls', 'Clinical Scan Recalls', unbooked.length)}{tabBtn('points', 'Points Re-Engagement')}{tabBtn('scheme', 'Milestone Bonus Scheme')}
      </div>

      {tab === 'recalls' && (
        <>
          <div className="ka-card" style={{ padding: 12, borderRadius: 10, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <div style={{ display: 'flex', gap: 8 }}>
              {[{ key: 'all', label: `All Windows (${(unbookedOnly ? unbooked : mothers).length})` }, ...WINDOWS.map((w) => ({ key: w.key, label: `${w.label} (${(unbookedOnly ? unbooked : mothers).filter((p) => windowOf(p)!.key === w.key).length})` }))].map((o) => (
                <button key={o.key} type="button" data-tour={`fu-win-${o.key}`} onClick={() => setWin(o.key as typeof win)} className="ka-btn sm" style={{ height: 32, fontSize: 12, ...(win === o.key ? { background: 'var(--primary-soft)', borderColor: 'var(--primary)', color: 'var(--primary-ink)' } : {}) }}>
                  {win === o.key && <Icon n="check" size={14} />}{o.label}
                </button>
              ))}
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <label className="ka-search" style={{ flex: 'none', width: 280, height: 38 }}><Icon n="search" /><input placeholder="Search mother name or phone... (/)" /></label>
              <Toggle tour="fu-unbooked" on={unbookedOnly} onChange={setUnbookedOnly} label={`Unbooked only (${unbooked.length})`} />
              <span className="ka-pill red" style={{ height: 26 }}>Pending Outreach: {unbooked.length - recalled}</span>
              <span className="ka-pill green" style={{ height: 26 }}>Recalled: {recalled}</span>
            </div>
          </div>
          <div style={{ flex: 1, overflow: 'auto', display: 'flex', flexDirection: 'column', gap: 8 }} data-tour="fu-list">
            {list.length === 0 && <div className="ka-card ka-empty" style={{ padding: 40 }}>No expectant mothers due in this milestone filter.</div>}
            {list.map((p) => {
              const w = windowOf(p)!;
              const g = gestationToday(p.edd!);
              const booked = hasBooking(p);
              const rc = db.recalls[p.id];
              return (
                <div key={p.id} className="ka-card" data-tour={`fu-row-${p.id}`} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderRadius: 8 }}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span style={{ fontSize: 11, fontWeight: 800, color: '#fff', background: 'var(--primary)', borderRadius: 4, padding: '2px 6px' }}>W{g.w}</span>
                      <span style={{ fontSize: 15, fontWeight: 600, color: 'var(--primary-ink)' }}>{p.name}</span>
                      {booked ? <span className="ka-pill green" style={{ height: 20, fontSize: 11 }}>Booked</span> : <span className="ka-pill amber" style={{ height: 20, fontSize: 11 }}>Needs Booking</span>}
                      {rc && <span className="ka-pill blue" style={{ height: 20, fontSize: 11 }}>Recalled on {fmtShortDate(rc.at)} · {rc.channel}</span>}
                    </div>
                    <div style={{ fontSize: 12.5, color: 'var(--ink-2)', marginTop: 6 }}>{w.scan} · EDD {p.edd} · Klinik Aurora Bukit Rimau · {p.phone}</div>
                  </div>
                  <button type="button" className="ka-btn" data-tour={`fu-push-${p.id}`} onClick={() => send(p, 'Push')}><Icon n="notifications_active" v="o" size={17} />Push Only</button>
                  <button type="button" className="ka-btn primary" data-tour={`fu-send-${p.id}`} onClick={() => send(p, 'WA + Push')}><Icon n="send" size={16} />{rc ? 'Follow Up (WA + Push)' : 'Send WA + Push'}</button>
                </div>
              );
            })}
          </div>
        </>
      )}

      {tab === 'points' && (
        <div style={{ flex: 1, overflow: 'auto', display: 'flex', flexDirection: 'column', gap: 8 }} data-tour="fu-points">
          <div className="ka-card" style={{ display: 'flex', alignItems: 'center', gap: 12, padding: 12, borderRadius: 10 }}>
            <label className="ka-search" style={{ flex: 'none', width: 300, height: 38 }}><Icon n="search" /><input placeholder="Search patient by name or phone... (/)" /></label>
            <span className="ka-pill grey" style={{ height: 26 }}>Minimum 500 pts · Unbooked patients only</span>
            <span style={{ flex: 1 }} />
            <span style={{ fontSize: 13, fontWeight: 700 }}>Eligible Members: {members.length}</span>
          </div>
          {members.map((p) => (
            <div key={p.id} className="ka-card" data-tour={`fu-member-${p.id}`} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderRadius: 8 }}>
              <span style={{ width: 40, height: 40, borderRadius: 10, background: 'var(--warning-soft)', display: 'grid', placeItems: 'center' }}><Icon n="stars" size={21} style={{ color: '#d97706' }} /></span>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><b style={{ fontSize: 14.5 }}>{p.name}</b><span className="ka-pill amber" style={{ height: 20, fontSize: 11 }}>No Booking</span>{db.offers[p.id] && <span className="ka-pill blue" style={{ height: 20, fontSize: 11 }}>Outreach sent on {db.offers[p.id]}</span>}</div>
                <div style={{ fontSize: 12.5, color: 'var(--ink-2)', marginTop: 4 }}>{p.points.toLocaleString()} pts · Earliest points expiry: {fmtShortDate(addDays(startOfToday(), 41).toISOString())} · {p.phone}</div>
              </div>
              <button type="button" className="ka-btn primary" data-tour={`fu-offer-${p.id}`} onClick={() => offer(p)}><Icon n="send" size={16} />{db.offers[p.id] ? 'Follow Up (WhatsApp)' : 'Send Points Offer'}</button>
            </div>
          ))}
        </div>
      )}

      {tab === 'scheme' && (
        <div className="ka-card" style={{ borderRadius: 10, padding: 18 }} data-tour="fu-scheme">
          <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 12 }}>Pregnancy Scan Milestone Loyalty Rewards (Admin Scheme)</div>
          {SCHEME.map(([w, t, pts, d]) => (
            <div key={w} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '12px 0', borderBottom: '1px solid var(--border)' }}>
              <span style={{ width: 82, fontSize: 12, fontWeight: 800, color: 'var(--violet-text)', background: 'var(--violet-soft)', borderRadius: 6, padding: '6px 0', textAlign: 'center' }}>{w}</span>
              <div style={{ flex: 1 }}><div style={{ fontSize: 14, fontWeight: 600 }}>{t}</div><div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>{d}</div></div>
              <span style={{ fontSize: 13, fontWeight: 900, color: 'var(--violet-text)', background: 'var(--violet-soft)', borderRadius: 6, padding: '6px 10px' }}>{pts}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
