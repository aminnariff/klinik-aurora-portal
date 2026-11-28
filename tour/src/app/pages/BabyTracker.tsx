import { useState } from 'react';
import { useApp } from '../store';
import { Icon } from '../ui';
import { BAG_ITEMS, fmtTime, gestationToday, type ChecklistCategory, type Patient } from '../data';

type Filter = 'all' | 'overdue' | 'low' | 't3';
const KKM_TARGET = 10;

function riskOf(p: Patient, kicks: number) {
  const { w } = gestationToday(p.edd!);
  if (w > 40) return 'Overdue';
  if (w >= 28 && kicks < KKM_TARGET) return 'Pergerakan Rendah';
  return 'Stabil';
}

function WaIcon({ size = 15 }: { size?: number }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden><path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2zm4.5 12.1c-.2-.1-1.5-.7-1.7-.8-.2-.1-.4-.1-.6.1l-.8 1c-.1.2-.3.2-.5.1a6.7 6.7 0 0 1-3.3-2.9c-.3-.4.3-.4.8-1.4.1-.2 0-.3 0-.4l-.8-1.8c-.2-.5-.4-.4-.6-.4h-.5a1 1 0 0 0-.7.3 3 3 0 0 0-.9 2.2 5.2 5.2 0 0 0 1.1 2.7 11.8 11.8 0 0 0 4.5 4c1.7.7 2.4.8 3.2.6.5-.1 1.5-.6 1.7-1.2.2-.6.2-1.1.2-1.2-.1-.1-.3-.2-.5-.3z" /></svg>;
}

function PatientFile({ p, onClose }: { p: Patient; onClose: () => void }) {
  const { db, patch } = useApp();
  const info = db.baby[p.id]!;
  const g = gestationToday(p.edd!);
  const bag = db.checklist.filter((c) => c.category === 'Beg Hospital');
  const [tab, setTab] = useState<'kicks' | 'bag'>('kicks');
  const pct = Math.round((info.bagDone.length / bag.length) * 100);
  const risk = riskOf(p, info.kicksToday);
  const toggle = (id: string) => patch((d) => {
    const cur = d.baby[p.id]!;
    const has = cur.bagDone.includes(id);
    return { ...d, baby: { ...d.baby, [p.id]: { ...cur, bagDone: has ? cur.bagDone.filter((x) => x !== id) : [...cur.bagDone, id] } } };
  });
  return (
    <>
      <div onClick={onClose} style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,.35)', zIndex: 20, animation: 'ka-fade .2s' }} />
      <aside data-tour="baby-file" style={{ position: 'absolute', top: 0, right: 0, bottom: 0, width: 560, zIndex: 21, background: 'var(--surface)', boxShadow: '-12px 0 32px rgba(0,0,0,.2)', display: 'flex', flexDirection: 'column', animation: 'ka-slide-in .28s cubic-bezier(.2,.8,.2,1)' }}>
        <div style={{ padding: '18px 20px 14px', borderBottom: '1px solid var(--border)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ width: 44, height: 44, borderRadius: 12, background: 'linear-gradient(135deg, #f9a8d4, #db2777)', display: 'grid', placeItems: 'center' }}><Icon n="pregnant_woman" size={24} style={{ color: '#fff' }} /></span>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 17, fontWeight: 800 }}>{p.name}</div>
              <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>{p.phone} · Klinik Aurora Bukit Rimau</div>
            </div>
            <button type="button" className="ka-dialog-close" data-tour="baby-file-close" onClick={onClose}><Icon n="close" /></button>
          </div>
          <div style={{ display: 'flex', gap: 6, marginTop: 12, flexWrap: 'wrap' }}>
            <span className="ka-pill grey"><Icon n="event" size={13} />EDD {p.edd!.split('-').reverse().join('-')}</span>
            <span className="ka-pill blue">Minggu {g.w} (Trimester {g.w >= 28 ? 3 : g.w >= 14 ? 2 : 1})</span>
            <span className={`ka-pill ${risk === 'Stabil' ? 'green' : 'amber'}`}>{risk}</span>
          </div>
        </div>
        <div style={{ display: 'flex', borderBottom: '1px solid var(--border)', padding: '0 12px' }}>
          {([['kicks', 'Pergerakan Janin', 'monitor_heart'], ['bag', 'Beg Hospital (Wad)', 'luggage']] as const).map(([k, l, ic]) => (
            <button key={k} type="button" data-tour={`baby-tab-${k}`} onClick={() => setTab(k)} style={{ height: 44, padding: '0 14px', border: 'none', background: 'none', fontSize: 13, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 6, color: tab === k ? 'var(--primary-ink)' : 'var(--muted)', borderBottom: `2px solid ${tab === k ? 'var(--primary)' : 'transparent'}` }}>
              <Icon n={ic} size={16} />{l}
            </button>
          ))}
        </div>
        <div style={{ flex: 1, overflow: 'auto', padding: 20 }}>
          {tab === 'kicks' ? (
            <>
              <div data-tour="baby-kicks" style={{ display: 'flex', gap: 18, alignItems: 'center', padding: 16, borderRadius: 12, border: '1px solid var(--border)', background: 'var(--surface-subtle)' }}>
                <div>
                  <div style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: .5, color: 'var(--muted)' }}>JUMLAH HARI INI</div>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                    <span style={{ fontSize: 28, fontWeight: 800, color: info.kicksToday >= KKM_TARGET ? 'var(--success-text)' : '#d97706' }}>{info.kicksToday}</span>
                    <span style={{ fontSize: 13, color: 'var(--muted)', fontWeight: 600 }}>/ 10 kali</span>
                  </div>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13.5, fontWeight: 700, color: info.kicksToday >= KKM_TARGET ? 'var(--success-text)' : 'var(--warning-text)' }}>{info.kicksToday >= KKM_TARGET ? 'Sasaran KKM Dicapai' : 'Sedang Memantau Pergerakan'}</div>
                  <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 4 }}>Protokol KKM: Minimum 10 pergerakan dalam tempoh 12 jam (9:00 AM – 9:00 PM).</div>
                  <div style={{ height: 6, borderRadius: 3, background: 'var(--border)', marginTop: 8 }}><div style={{ width: `${Math.min(100, info.kicksToday * 10)}%`, height: '100%', borderRadius: 3, background: info.kicksToday >= KKM_TARGET ? '#10b981' : '#f59e0b' }} /></div>
                </div>
              </div>
              <div style={{ fontSize: 13.5, fontWeight: 700, margin: '18px 0 8px' }}>Log Sesi Pergerakan</div>
              {info.sessions.length === 0 && <div style={{ fontSize: 12.5, color: 'var(--muted)', padding: 14, textAlign: 'center', border: '1px dashed var(--border)', borderRadius: 8 }}>Belum ada sesi tendangan direkodkan hari ini.</div>}
              {info.sessions.map((s, i) => (
                <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'center', padding: '10px 12px', borderRadius: 8, border: '1px solid var(--border)', marginBottom: 8 }}>
                  <span style={{ width: 34, height: 34, borderRadius: 8, background: 'var(--info-soft)', display: 'grid', placeItems: 'center', fontWeight: 800, color: 'var(--info-text)' }}>{s.count}</span>
                  <div style={{ flex: 1, fontSize: 12.5 }}>
                    <div style={{ fontWeight: 600 }}>Mula {fmtTime(new Date(s.start))} · Tamat {fmtTime(new Date(s.end))}</div>
                    {s.note && <div style={{ color: 'var(--muted)', marginTop: 2 }}>Nota: {s.note}</div>}
                  </div>
                </div>
              ))}
            </>
          ) : (
            <>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: 14, borderRadius: 12, border: '1px solid var(--border)', background: 'var(--surface-subtle)' }} data-tour="baby-bag">
                <div style={{ position: 'relative', width: 58, height: 58 }}>
                  <svg width="58" height="58" viewBox="0 0 36 36"><circle cx="18" cy="18" r="15.5" fill="none" stroke="var(--border)" strokeWidth="3.5" /><circle cx="18" cy="18" r="15.5" fill="none" stroke="#db2777" strokeWidth="3.5" strokeDasharray={`${pct * 0.974} 100`} transform="rotate(-90 18 18)" strokeLinecap="round" /></svg>
                  <span style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', fontSize: 13, fontWeight: 800 }}>{pct}%</span>
                </div>
                <div>
                  <div style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: .5, color: 'var(--muted)' }}>KESIAPSIAGAAN WAD</div>
                  <div style={{ fontSize: 14, fontWeight: 700, marginTop: 2 }}>Barangan Kemasukan Wad Bersalin</div>
                  <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>{info.bagDone.length} daripada {bag.length} barang sudah dikemas</div>
                </div>
              </div>
              <div style={{ marginTop: 12 }}>
                {bag.map((it) => {
                  const on = info.bagDone.includes(it.id);
                  return (
                    <button key={it.id} type="button" data-tour={`bag-item-${it.id}`} onClick={() => toggle(it.id)} style={{ display: 'flex', alignItems: 'center', gap: 10, width: '100%', textAlign: 'left', padding: '9px 10px', border: 'none', borderBottom: '1px solid var(--border)', background: 'none', fontSize: 13 }}>
                      <Icon n={on ? 'check_circle' : 'radio_button_unchecked'} size={19} style={{ color: on ? 'var(--success-text)' : 'var(--muted)' }} />
                      <span style={{ flex: 1, color: on ? 'var(--ink)' : 'var(--ink-2)' }}>{it.name}</span>
                      {it.required && <span className="ka-pill red" style={{ fontSize: 10, height: 18 }}>WAJIB</span>}
                    </button>
                  );
                })}
              </div>
            </>
          )}
        </div>
        <div style={{ display: 'flex', gap: 10, padding: '12px 20px', borderTop: '1px solid var(--border)' }}>
          <button type="button" className="ka-btn" style={{ flex: 1, height: 40, background: '#25d366', borderColor: '#25d366', color: '#fff' }}><WaIcon size={16} />Buka WhatsApp</button>
          <button type="button" className="ka-btn" style={{ flex: 1, height: 40 }} onClick={onClose}>Tutup Fail</button>
        </div>
      </aside>
    </>
  );
}

const CATS: ChecklistCategory[] = ['Beg Hospital', 'Baju', 'Mandi', 'Tidur', 'Penyusuan'];

function Templates() {
  const db = useApp((s) => s.db);
  const [cat, setCat] = useState<'all' | ChecklistCategory>('all');
  const items = db.checklist.filter((c) => cat === 'all' || c.category === cat);
  return (
    <div className="ka-card" style={{ borderRadius: 12, flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }} data-tour="baby-templates">
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '14px 16px', borderBottom: '1px solid var(--border)' }}>
        {(['all', ...CATS] as const).map((c) => (
          <button key={c} type="button" onClick={() => setCat(c)} className="ka-btn sm" style={{ height: 32, ...(cat === c ? { background: 'var(--ink)', color: 'var(--surface)', borderColor: 'var(--ink)' } : {}) }}>{c === 'all' ? 'Semua Kategori' : c}</button>
        ))}
        <span style={{ flex: 1 }} />
        <button type="button" className="ka-btn primary" data-tour="baby-add-template"><Icon n="add" size={18} />Tambah Item Templat</button>
      </div>
      <div style={{ overflow: 'auto', flex: 1 }}>
        {items.map((it) => (
          <div key={it.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderBottom: '1px solid var(--border)' }}>
            <span style={{ width: 32, height: 32, borderRadius: 8, background: 'color-mix(in srgb, #db2777 12%, transparent)', display: 'grid', placeItems: 'center' }}><Icon n="checklist" size={17} style={{ color: '#db2777' }} /></span>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>{it.name} {it.required && <span className="ka-pill red" style={{ fontSize: 10, height: 18, marginLeft: 6 }}>WAJIB</span>}</div>
              <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>Kategori: {it.category}{it.tip ? ` · Tip: ${it.tip}` : ''}</div>
            </div>
            <button type="button" className="ka-btn sm"><Icon n="edit" size={15} />Kemaskini</button>
            <button type="button" className="ka-btn sm" style={{ color: 'var(--danger)' }}><Icon n="delete" size={15} />Padam</button>
          </div>
        ))}
      </div>
    </div>
  );
}

export function BabyTracker() {
  const db = useApp((s) => s.db);
  const [view, setView] = useState<'report' | 'templates'>('report');
  const [filter, setFilter] = useState<Filter>('all');
  const [q, setQ] = useState('');
  const [openId, setOpenId] = useState<string | null>(null);
  const mothers = db.patients.filter((p) => p.edd && db.baby[p.id]).sort((a, b) => a.edd!.localeCompare(b.edd!));
  const rows = mothers.filter((p) => {
    const k = db.baby[p.id]!.kicksToday;
    const g = gestationToday(p.edd!);
    if (filter === 'overdue' && g.w <= 40) return false;
    if (filter === 'low' && riskOf(p, k) !== 'Pergerakan Rendah') return false;
    if (filter === 't3' && g.w < 28) return false;
    return !q || `${p.name} ${p.phone} ${p.email}`.toLowerCase().includes(q.toLowerCase());
  });
  const low = mothers.filter((p) => riskOf(p, db.baby[p.id]!.kicksToday) === 'Pergerakan Rendah').length;
  const bagAvg = Math.round(mothers.reduce((s, p) => s + db.baby[p.id]!.bagDone.length / BAG_ITEMS.length, 0) / Math.max(1, mothers.length) * 100);
  const open = mothers.find((p) => p.id === openId);
  const kpi = (label: string, value: string, sub: string, color?: string, tour?: string) => (
    <div className="ka-card" data-tour={tour} style={{ flex: 1, padding: '16px 16px', borderRadius: 10 }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: .6, color: 'var(--ink-2)' }}>{label}</div>
      <div style={{ fontSize: 21, fontWeight: 800, margin: '10px 0 8px', color }}>{value}</div>
      <div style={{ fontSize: 12, color: 'var(--muted)' }}>{sub}</div>
    </div>
  );
  const chip = (k: Filter, label: string) => (
    <button key={k} type="button" data-tour={`baby-filter-${k}`} onClick={() => setFilter(k)} className="ka-btn" style={{ height: 36, fontSize: 13, fontWeight: filter === k ? 700 : 500, ...(filter === k ? { background: 'var(--surface-subtle)', borderColor: 'var(--ink-2)', borderWidth: 1.5 } : {}) }}>{label}</button>
  );
  return (
    <div className="ka-page" style={{ height: '100%', padding: '16px 24px', position: 'relative' }}>
      <div className="ka-card" style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px', borderRadius: 12 }}>
        <span style={{ width: 38, height: 38, borderRadius: 10, background: 'var(--surface-subtle)', display: 'grid', placeItems: 'center' }}><Icon n="pregnant_woman" size={22} /></span>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 17, fontWeight: 700 }}>Aurora Baby Hub</div>
          <div style={{ fontSize: 12.5, color: 'var(--muted)', marginTop: 3 }}>Pemantauan Pergerakan Bayi &amp; Kawalan Senarai Semak Kelahiran</div>
        </div>
        <div style={{ display: 'flex', padding: 3, borderRadius: 8, background: 'var(--surface-subtle)' }}>
          {([['report', 'Laporan Kehamilan', 'show_chart'], ['templates', 'Templat Senarai Semak', 'tune']] as const).map(([k, l, ic]) => (
            <button key={k} type="button" data-tour={`baby-view-${k}`} onClick={() => setView(k)} style={{ height: 34, padding: '0 14px', border: 'none', borderRadius: 6, fontSize: 13.5, fontWeight: view === k ? 600 : 500, display: 'flex', alignItems: 'center', gap: 8, background: view === k ? 'var(--surface)' : 'transparent', color: view === k ? 'var(--ink)' : 'var(--muted)', boxShadow: view === k ? '0 1px 2px rgba(0,0,0,.08)' : 'none' }}>
              <Icon n={ic} size={16} />{l}
            </button>
          ))}
        </div>
      </div>
      {view === 'templates' ? <Templates /> : (
        <>
          <div style={{ display: 'flex', gap: 12 }} data-tour="baby-kpis">
            {kpi('IBU HAMIL AKTIF', String(mothers.length), 'Dalam pemantauan antenatal')}
            {kpi('MELEBIHI 40 MINGGU', '0', 'Tiada kes tertunggak')}
            {kpi('AMARAN TENDANGAN', String(low), '< 10 pergerakan hari ini (Wk 28+)', '#d97706', 'baby-kpi-kicks')}
            {kpi('PURATA BEG HOSPITAL', `${bagAvg}%`, 'Kesiapan 10 barangan wad', 'var(--info)')}
          </div>
          <div className="ka-card" style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', borderRadius: 12 }}>
            <label className="ka-search" style={{ height: 40, background: 'var(--surface-subtle)', borderColor: 'var(--border)' }}><Icon n="search" /><input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Cari nama pesakit, nombor telefon, atau emel..." /></label>
            {chip('all', 'Semua')}{chip('overdue', 'Overdue (>40 M)')}{chip('low', 'Pergerakan Rendah')}{chip('t3', 'Trimester 3 (28+ M)')}
            <span className="ka-tb-icon" style={{ width: 36, height: 36 }}><Icon n="refresh" size={20} /></span>
          </div>
          <div className="ka-card ka-table-wrap" style={{ borderRadius: 12 }}>
            <div className="ka-table-scroll">
              <table className="ka-table">
                <thead><tr>{['PESAKIT', 'TARIKH EDD / USIA', 'TENDANGAN HARI INI', 'BEG HOSPITAL', 'STATUS RISIKO', 'TINDAKAN'].map((h) => <th key={h} style={{ fontSize: 12, fontWeight: 700, letterSpacing: .4, height: 46, background: 'var(--surface)' }}>{h}</th>)}</tr></thead>
                <tbody>
                  {rows.map((p) => {
                    const b = db.baby[p.id]!;
                    const g = gestationToday(p.edd!);
                    const risk = riskOf(p, b.kicksToday);
                    const pct = Math.round((b.bagDone.length / BAG_ITEMS.length) * 100);
                    return (
                      <tr key={p.id} data-tour={`baby-row-${p.id}`}>
                        <td><div style={{ fontWeight: 600 }}>{p.name}</div><div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>{p.phone} • Klinik Aurora Bukit Rimau</div></td>
                        <td><div>{p.edd}</div><div style={{ fontSize: 12, fontWeight: 600, color: 'var(--info)', marginTop: 2 }}>Minggu {g.w} (Trimester {g.w >= 28 ? 3 : g.w >= 14 ? 2 : 1})</div></td>
                        <td><span style={{ display: 'inline-flex', alignItems: 'center', gap: 10 }}><span className="ka-pill grey" style={{ height: 26, fontSize: 13 }}>{b.kicksToday} kali</span><span style={{ fontSize: 12, color: 'var(--muted)' }}>{fmtTime(new Date(b.lastSync))}</span></span></td>
                        <td><span className="ka-pill" style={{ background: pct >= 50 ? 'var(--info-soft)' : 'var(--warning-soft)', color: pct >= 50 ? 'var(--info-text)' : 'var(--warning-text)' }}>{pct}%</span></td>
                        <td><span className={`ka-pill ${risk === 'Stabil' ? 'green' : 'amber'}`}>{risk}</span></td>
                        <td>
                          <div style={{ display: 'flex', gap: 8 }}>
                            <button type="button" className="ka-btn sm" data-tour={`baby-wa-${p.id}`} style={{ background: '#25d366', borderColor: '#25d366', color: '#fff', height: 30 }}><WaIcon />WhatsApp</button>
                            <button type="button" className="ka-btn primary sm" data-tour={`baby-open-${p.id}`} style={{ height: 30 }} onClick={() => setOpenId(p.id)}><Icon n="description" size={15} />Buka Fail</button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', padding: '10px 16px', borderTop: '1px solid var(--border)', fontSize: 12.5, color: 'var(--ink-2)' }}>
              <span style={{ flex: 1 }}>Menunjukkan rekod 1 – {rows.length} daripada {rows.length} pesakit</span>
              <button type="button" className="ka-btn sm" disabled style={{ background: 'transparent', borderColor: 'var(--border)' }}><Icon n="chevron_left" size={16} />Sebelumnya</button>
              <span style={{ fontWeight: 700, padding: '0 12px' }}>Halaman 1 / 1</span>
              <button type="button" className="ka-btn sm" disabled style={{ background: 'transparent', borderColor: 'var(--border)' }}>Seterusnya<Icon n="chevron_right" size={16} /></button>
            </div>
          </div>
        </>
      )}
      {open && <PatientFile p={open} onClose={() => setOpenId(null)} />}
    </div>
  );
}
