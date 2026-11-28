import { useState, type ReactNode } from 'react';
import { useApp } from '../store';
import { BoxSelect, Icon } from '../ui';
import { ActivePill, Cell2, Chips, EditBtn, Field, FormDialog, Grid, ListTable, ListToolbar, TextInput, Toggle, ToolBtn } from '../kit';
import { addDays, fmtShortDate, fmtStamp, iso, startOfToday } from '../data';
import { PERMISSIONS, ROLE_PRESETS, type Admin, type Promotion } from '../data2';

const err = (message: string) => useApp.getState().openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message });
const done = (message: string) => { const s = useApp.getState(); s.closeDialog(); s.openDialog({ kind: 'status', tone: 'success', title: 'Success!', message }); };
const id = (p: string) => useApp.getState().nextId(p);
const dmy = (d: Date) => `${String(d.getDate()).padStart(2, '0')}-${String(d.getMonth() + 1).padStart(2, '0')}-${d.getFullYear()}`;
const parseDmy = (s: string) => { const [d, m, y] = s.split('-').map(Number); return new Date(y!, (m ?? 1) - 1, d ?? 1); };

function StatusToggle({ on, set, tour, onLabel, offLabel }: { on: boolean; set: (v: boolean) => void; tour?: string; onLabel: string; offLabel: string }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: 12, borderRadius: 10, border: '1px solid var(--border)', background: 'var(--surface-subtle)' }}>
      <Toggle tour={tour} on={on} onChange={set} />
      <div><div style={{ fontSize: 13.5, fontWeight: 600 }}>Status: {on ? 'Active' : 'Inactive'}</div><div style={{ fontSize: 12, color: 'var(--muted)' }}>{on ? onLabel : offLabel}</div></div>
    </div>
  );
}

function DateField({ tour, value, onChange, placeholder }: { tour?: string; value: string; onChange: (v: string) => void; placeholder: string }) {
  return <TextInput tour={tour} value={value} onChange={onChange} placeholder={placeholder} suffix={<Icon n="calendar_today" v="o" size={18} />} />;
}

// ── Promotions ───────────────────────────────────────────
const ART: Record<Promotion['art'], [string, string, string]> = {
  scan: ['#0e7490', '#67e8f9', 'child_care'], pink: ['#be185d', '#f9a8d4', 'favorite'], checkup: ['#0f766e', '#99f6e4', 'monitor_heart'], raya: ['#166534', '#fde68a', 'mosque'], points: ['#7e2d40', '#fbcfe8', 'stars'],
};

function PromoArt({ p }: { p: Pick<Promotion, 'art' | 'title'> }) {
  const [a, b, ic] = ART[p.art];
  return (
    <div style={{ height: 150, position: 'relative', overflow: 'hidden', background: `linear-gradient(135deg, ${a}, ${b})`, color: '#fff', padding: 16, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
      <Icon n={ic} size={110} style={{ position: 'absolute', right: -14, top: -10, opacity: 0.22, color: '#fff' }} />
      <div style={{ fontSize: 18, fontWeight: 900, lineHeight: 1.1, textTransform: 'uppercase', textShadow: '0 1px 2px rgba(0,0,0,.25)', maxWidth: '80%' }}>{p.title}</div>
    </div>
  );
}

function PromotionDialog() {
  const { patch } = useApp();
  const today = startOfToday();
  const [f, setF] = useState({ title: '', desc: '', terms: '', from: dmy(today), to: '', featured: false, active: true, banner: false });
  const set = <K extends keyof typeof f>(k: K) => (v: (typeof f)[K]) => setF((x) => ({ ...x, [k]: v }));
  const save = () => {
    if (!f.title) return err('Promotion name is required');
    if (!f.desc) return err('Description is required');
    if (!f.to) return err('End date is required');
    const p: Promotion = { id: id('pm'), title: f.title, description: f.desc, terms: f.terms, from: iso(parseDmy(f.from)), to: iso(parseDmy(f.to)), featured: f.featured, active: f.active, created: iso(new Date()), art: 'scan' };
    patch((d) => ({ ...d, promotions: [p, ...d.promotions] }), p.id);
    done('Promotion created successfully!');
  };
  return (
    <FormDialog title="New Promotion" subtitle="Create promotion content, banner images, and active schedule" icon="campaign" width={760} tour="promo-dialog" onSave={save} saveLabel="Create Promotion" saveTour="promo-save">
      <div className="ka-sec-label" style={{ marginBottom: 14 }}>Promotion Content</div>
      <Grid cols={1}>
        <Field label="Promotion Title" required><TextInput tour="promo-title" value={f.title} onChange={set('title')} placeholder="e.g. Promo Hujung Tahun" /></Field>
        <Field label="Description" required><TextInput area tour="promo-desc" value={f.desc} onChange={set('desc')} placeholder="Describe promotion offerings, highlights, or discounts..." height={70} /></Field>
        <Field label="Terms & Conditions (Optional)"><TextInput area value={f.terms} onChange={set('terms')} placeholder="Redemption terms, appointment validity, exclusions..." height={60} /></Field>
      </Grid>
      <div className="ka-sec-label" style={{ margin: '20px 0 12px' }}>Banner Images</div>
      <button type="button" data-tour="promo-banner" onClick={() => set('banner')(true)} style={{ width: '100%', padding: f.banner ? 0 : 18, borderRadius: 10, overflow: 'hidden', border: `1.5px dashed ${f.banner ? 'transparent' : 'var(--border-strong)'}`, background: 'var(--surface-subtle)', color: 'var(--muted)', fontSize: 13, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10 }}>
        {f.banner ? <div style={{ width: '100%' }}><PromoArt p={{ art: 'scan', title: f.title || 'Banner' }} /></div> : <><Icon n="add_photo_alternate" size={22} />Upload banner (1080 × 1350 recommended)</>}
      </button>
      <div className="ka-sec-label" style={{ margin: '20px 0 12px' }}>Schedule &amp; Visibility</div>
      <Grid>
        <Field label="Start Date" required><DateField value={f.from} onChange={set('from')} placeholder="Select start date" /></Field>
        <Field label="End Date" required><DateField tour="promo-to" value={f.to} onChange={set('to')} placeholder="Select end date" /></Field>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: 12, borderRadius: 10, border: '1px solid var(--border)', background: 'var(--surface-subtle)' }}>
          <Toggle tour="promo-featured" on={f.featured} onChange={set('featured')} />
          <div><div style={{ fontSize: 13.5, fontWeight: 600 }}>Featured on App Launch</div><div style={{ fontSize: 12, color: 'var(--muted)' }}>Shows full-screen popup banner when mobile app opens</div></div>
        </div>
        <StatusToggle on={f.active} set={set('active')} onLabel="Publicly visible to patients" offLabel="Hidden from promotions list" />
      </Grid>
    </FormDialog>
  );
}

export function Promotions() {
  const { db, openDialog, highlightId } = useApp();
  const [tab, setTab] = useState<'all' | 'active' | 'inactive'>('all');
  const list = db.promotions.filter((p) => tab === 'all' || (tab === 'active' ? p.active : !p.active));
  return (
    <div className="ka-page" style={{ height: '100%', padding: 0, gap: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 32px', background: 'var(--surface)' }}>
        <label className="ka-search" style={{ flex: 'none', width: 416, height: 40 }}><Icon n="search" /><input placeholder="Search promotions..." /></label>
        <Chips options={[{ value: 'all', label: 'All' }, { value: 'active', label: 'Active' }, { value: 'inactive', label: 'Inactive' }]} value={tab} onChange={setTab} tourPrefix="promo-tab" />
        <span style={{ flex: 1 }} />
        <button type="button" className="ka-btn primary lg" data-tour="add-promo" onClick={() => openDialog({ kind: 'custom', render: () => <PromotionDialog /> })}><Icon n="add" size={20} />New Promotion</button>
      </div>
      <div style={{ flex: 1, overflow: 'auto', padding: '30px 32px', display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 20, alignContent: 'start' }} data-tour="promo-grid">
        {list.map((p) => (
          <div key={p.id} className={`ka-card${p.id === highlightId ? ' hl' : ''}`} data-tour={p.id === highlightId ? 'promo-card-new' : `promo-card-${p.id}`} style={{ borderRadius: 8, overflow: 'hidden', boxShadow: '0 1px 3px rgba(15,23,42,.06)', outline: p.id === highlightId ? '2px solid var(--primary)' : undefined }}>
            <div style={{ position: 'relative' }}>
              <PromoArt p={p} />
              <span className={`ka-pill ${p.active ? 'green' : 'red'}`} style={{ position: 'absolute', top: 10, left: 10, background: p.active ? '#16a34a' : '#dc2626', color: '#fff' }}>{p.active ? 'Active' : 'Inactive'}</span>
              {p.featured && <span className="ka-pill" style={{ position: 'absolute', top: 10, right: 10, background: 'rgba(15,23,42,.6)', color: '#fff' }}>⭐ Featured</span>}
            </div>
            <div style={{ padding: '12px 12px 14px' }}>
              <div style={{ fontSize: 14.5, fontWeight: 600 }}>{p.title}</div>
              <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 6, display: 'flex', alignItems: 'center', gap: 4 }}><Icon n="calendar_today" v="o" size={13} />{fmtShortDate(p.from)} – {fmtShortDate(p.to)}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Campaigns ────────────────────────────────────────────
function CampaignDialog() {
  const { patch } = useApp();
  const t = startOfToday();
  const [f, setF] = useState({ name: '', from: dmy(t), to: dmy(addDays(t, 30)), mult: '1.5', primary: '#7E2D40', accent: '#F59E0B', active: true });
  const set = <K extends keyof typeof f>(k: K) => (v: (typeof f)[K]) => setF((x) => ({ ...x, [k]: v }));
  const save = () => {
    if (!f.name) return err('Give the campaign a name.');
    patch((d) => ({ ...d, campaigns: [{ id: id('cp'), name: f.name, from: iso(parseDmy(f.from)), to: iso(parseDmy(f.to)), multiplier: Number(f.mult), primary: f.primary, accent: f.accent, background: '#FFF7ED', active: f.active }, ...d.campaigns] }));
    done('Campaign created.');
  };
  return (
    <FormDialog title="New Campaign" subtitle="Seasonal point boosts and mobile app themes" icon="celebration" width={820} tour="camp-dialog" onSave={save} saveLabel="Create Campaign" saveTour="camp-save"
      extraHead={<Toggle on={f.active} onChange={set('active')} label="Active" />}>
      <div style={{ display: 'flex', gap: 20 }}>
        <div style={{ flex: 1 }}>
          <div className="ka-sec-label" style={{ marginBottom: 14 }}>Basics</div>
          <Grid>
            <Field label="Campaign name" required span={2}><TextInput tour="camp-name" value={f.name} onChange={set('name')} placeholder="e.g. Mother's Day Double Points" /></Field>
            <Field label="Starts"><DateField value={f.from} onChange={set('from')} placeholder="Start" /></Field>
            <Field label="Ends"><DateField value={f.to} onChange={set('to')} placeholder="End" /></Field>
            <Field label="Point multiplier" span={2} hint="Every RM1 spent during the campaign earns this many points.">
              <div style={{ display: 'flex', gap: 8 }}>{['1', '1.5', '2', '3'].map((m) => <button key={m} type="button" data-tour={`camp-mult-${m}`} onClick={() => set('mult')(m)} className="ka-btn" style={m === f.mult ? { background: 'var(--primary)', borderColor: 'var(--primary)', color: '#fff' } : {}}>{m}×</button>)}</div>
            </Field>
          </Grid>
          <div className="ka-sec-label" style={{ margin: '20px 0 6px' }}>Mobile app theme</div>
          <div style={{ fontSize: 12, color: 'var(--muted)', marginBottom: 10 }}>Leave a field blank to keep the app default.</div>
          <div style={{ display: 'flex', gap: 10 }}>
            {([['Primary colour', 'primary', ['#7E2D40', '#065F46', '#1D4ED8', '#BE185D']], ['Accent colour', 'accent', ['#F59E0B', '#D4AF37', '#DC2626', '#0EA5E9']]] as const).map(([l, k, opts]) => (
              <div key={k} style={{ flex: 1 }}>
                <div className="ka-field-label">{l}</div>
                <div style={{ display: 'flex', gap: 6 }}>{opts.map((o) => <button key={o} type="button" data-tour={`camp-${k}-${o.slice(1)}`} onClick={() => set(k)(o)} style={{ width: 34, height: 34, borderRadius: 8, background: o, border: f[k] === o ? '3px solid var(--ink)' : '2px solid var(--surface)', boxShadow: '0 0 0 1px var(--border)' }} />)}</div>
              </div>
            ))}
          </div>
        </div>
        <div style={{ width: 220 }}>
          <div className="ka-field-label">Preview</div>
          <div data-tour="camp-preview" style={{ borderRadius: 26, border: '6px solid #0f172a', overflow: 'hidden', height: 380, background: '#fff7ed', display: 'flex', flexDirection: 'column' }}>
            <div style={{ background: f.primary, color: '#fff', padding: '26px 14px 18px' }}>
              <div style={{ fontSize: 11, opacity: 0.85 }}>Your Points</div>
              <div style={{ fontSize: 24, fontWeight: 900 }}>2,050 <span style={{ fontSize: 11 }}>pts</span></div>
              <div style={{ marginTop: 8, display: 'inline-block', background: f.accent, color: '#0f172a', fontSize: 10.5, fontWeight: 800, borderRadius: 999, padding: '3px 8px' }}>{f.mult}× points · {f.name || 'Campaign'}</div>
            </div>
            <div style={{ padding: 12, display: 'flex', flexDirection: 'column', gap: 8 }}>
              {['Book a scan', 'Redeem Rewards', 'Baby Tracker'].map((x) => <div key={x} style={{ background: '#fff', borderRadius: 10, padding: '10px 12px', fontSize: 12, fontWeight: 600, color: '#0f172a', boxShadow: '0 1px 2px rgba(0,0,0,.08)', borderLeft: `3px solid ${f.accent}` }}>{x}</div>)}
            </div>
          </div>
        </div>
      </div>
    </FormDialog>
  );
}

export function Campaigns() {
  const { db, openDialog } = useApp();
  const now = Date.now();
  return (
    <div className="ka-page" style={{ height: '100%', padding: '18px 24px' }}>
      <div style={{ display: 'flex', alignItems: 'center' }}>
        <div style={{ flex: 1 }}><div style={{ fontSize: 21, fontWeight: 800 }}>Campaigns</div><div style={{ fontSize: 13, color: 'var(--muted)', marginTop: 3 }}>Seasonal point boosts and mobile app themes.</div></div>
        <button type="button" className="ka-btn primary lg" data-tour="add-campaign" onClick={() => openDialog({ kind: 'custom', render: () => <CampaignDialog /> })}><Icon n="add" size={20} />New Campaign</button>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }} data-tour="camp-list">
        {db.campaigns.map((c) => {
          const state = !c.active ? 'Inactive' : now < new Date(c.from).getTime() ? 'Scheduled' : now > new Date(c.to).getTime() ? 'Ended' : 'Live now';
          return (
            <div key={c.id} className="ka-card" style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '14px 16px', borderRadius: 10 }}>
              <span style={{ width: 48, height: 48, borderRadius: 12, background: `linear-gradient(135deg, ${c.primary}, ${c.accent})`, display: 'grid', placeItems: 'center' }}><Icon n="celebration" size={24} style={{ color: '#fff' }} /></span>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><b style={{ fontSize: 15 }}>{c.name}</b><span className={`ka-pill ${state === 'Live now' ? 'green' : state === 'Scheduled' ? 'blue' : 'grey'}`}>{state}</span></div>
                <div style={{ display: 'flex', gap: 18, fontSize: 12.5, color: 'var(--ink-2)', marginTop: 6 }}>
                  <span><b>Dates</b> {fmtShortDate(c.from)} – {fmtShortDate(c.to)}</span>
                  <span><b>Points</b> {c.multiplier === 1 ? 'Standard (1.0x)' : `${c.multiplier}x`}</span>
                  <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><b>Theme</b> Custom App Theme {[c.primary, c.accent].map((x) => <span key={x} style={{ width: 12, height: 12, borderRadius: 3, background: x }} />)}</span>
                </div>
              </div>
              <button type="button" className="ka-btn sm"><Icon n="edit" size={15} />Edit</button>
              <button type="button" className="ka-btn sm" style={{ color: 'var(--danger)' }}><Icon n="delete" size={15} />Delete</button>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ── Vouchers ─────────────────────────────────────────────
function VoucherDialog() {
  const { db, patch } = useApp();
  const t = startOfToday();
  const [f, setF] = useState({ name: '', desc: '', code: '', reward: null as string | null, points: '', from: dmy(t), to: '', active: true });
  const set = <K extends keyof typeof f>(k: K) => (v: (typeof f)[K]) => setF((x) => ({ ...x, [k]: v }));
  const save = () => {
    if (!f.name) return err('Voucher name is required');
    if (!f.code) return err('Voucher code is required');
    if (f.code.length > 10) return err('Code must be 10 characters or less');
    if (!f.to) return err('End date is required');
    const v = { id: id('vc'), code: f.code.toUpperCase(), name: f.name, description: f.desc, points: Number(f.points) || 0, from: iso(parseDmy(f.from)), to: iso(parseDmy(f.to)), active: f.active, created: iso(new Date()), rewardId: f.reward ?? undefined };
    patch((d) => ({ ...d, vouchers: [v, ...d.vouchers] }), v.id);
    done('Successfully created voucher');
  };
  return (
    <FormDialog title="New Voucher" subtitle="Create a customer voucher with redeemable points & perks" icon="confirmation_number" width={720} tour="voucher-dialog" onSave={save} saveLabel="Create Voucher" saveTour="voucher-save">
      <div className="ka-sec-label" style={{ marginBottom: 14 }}>Voucher Details</div>
      <Grid>
        <Field label="Voucher Name" required span={2}><TextInput tour="voucher-name" value={f.name} onChange={set('name')} placeholder="e.g. DISKAUN RM15 PAP SMEAR" /></Field>
        <Field label="Description" required span={2}><TextInput area value={f.desc} onChange={set('desc')} placeholder="Terms, applicable services, or redemption notes..." height={60} /></Field>
        <Field label="Voucher Code" required hint="Up to 10 characters. Patients type this in the app."><TextInput tour="voucher-code" value={f.code} onChange={(v) => set('code')(v.toUpperCase())} placeholder="e.g. PAPSMEAR15" /></Field>
        <Field label="Linked Reward (Optional)"><BoxSelect tour="voucher-reward" value={f.reward} onChange={set('reward')} placeholder="No Linked Reward (Points Only)" options={db.rewards.map((r) => ({ value: r.id, label: r.name }))} /></Field>
      </Grid>
      <div className="ka-sec-label" style={{ margin: '20px 0 12px' }}>Points &amp; Validity</div>
      <Grid>
        <Field label="Points Required to Redeem" required span={2}><TextInput tour="voucher-points" value={f.points} onChange={(v) => set('points')(v.replace(/\D/g, ''))} placeholder="0" suffix={<span style={{ fontSize: 13, color: 'var(--muted)' }}>pts</span>} /></Field>
        <Field label="Start Date" required><DateField value={f.from} onChange={set('from')} placeholder="Select start date" /></Field>
        <Field label="End Date" required><DateField tour="voucher-to" value={f.to} onChange={set('to')} placeholder="Select end date" /></Field>
        <div style={{ gridColumn: 'span 2' }}><StatusToggle on={f.active} set={set('active')} onLabel="Visible and redeemable by patients" offLabel="Hidden from patient redemption catalog" /></div>
      </Grid>
    </FormDialog>
  );
}

export function Vouchers() {
  const { db, openDialog, highlightId } = useApp();
  const [q, setQ] = useState('');
  const list = db.vouchers.filter((v) => !q || `${v.code} ${v.name}`.toLowerCase().includes(q.toLowerCase()));
  return (
    <div className="ka-page" style={{ height: '100%', padding: 0, gap: 0 }}>
      <ListToolbar placeholder="Search vouchers..." value={q} onChange={setQ}>
        <ToolBtn icon="filter_list" label="Filter" tone="blue" /><ToolBtn icon="refresh" label="Reset" onClick={() => setQ('')} />
        <ToolBtn icon="add" label="Add Voucher" primary tour="add-voucher" onClick={() => openDialog({ kind: 'custom', render: () => <VoucherDialog /> })} />
      </ListToolbar>
      <ListTable head={['Code', 'Name', 'Points', 'Status', 'Created', { label: 'Actions', width: 80 }]} total={list.length}>
        {list.map((v) => (
          <tr key={v.id} className={v.id === highlightId ? 'hl' : ''} data-tour={v.id === highlightId ? 'voucher-row-new' : `voucher-row-${v.id}`} style={{ height: 56 }}>
            <td><span style={{ fontFamily: 'ui-monospace, monospace', fontSize: 12.5, fontWeight: 600, background: 'var(--surface-subtle)', border: '1px solid var(--border)', borderRadius: 4, padding: '3px 8px' }}>{v.code}</span></td>
            <td>{v.name}</td><td>{v.points ?? '—'}</td><td><ActivePill on={v.active} /></td>
            <td style={{ fontSize: 12.5, color: 'var(--ink-2)' }}>{fmtStamp(v.created)}</td>
            <td><span className="ka-dots"><Icon n="more_horiz" /></span></td>
          </tr>
        ))}
      </ListTable>
    </div>
  );
}

// ── Rewards catalog ──────────────────────────────────────
function RewardDialog() {
  const { patch } = useApp();
  const [f, setF] = useState({ name: '', desc: '', points: '', qty: '', from: '', to: '', active: true });
  const set = <K extends keyof typeof f>(k: K) => (v: (typeof f)[K]) => setF((x) => ({ ...x, [k]: v }));
  const save = () => {
    if (!f.name) return err('Reward name is required');
    if (!f.points) return err('Points required');
    if (f.qty === '') return err('Quantity is required (enter 0 for unlimited)');
    const t = startOfToday();
    const r = { id: id('rw'), name: f.name, description: f.desc, points: Number(f.points), left: Number(f.qty) || null, from: f.from ? iso(parseDmy(f.from)) : iso(t), to: f.to ? iso(parseDmy(f.to)) : iso(addDays(t, 730)), active: f.active, created: iso(new Date()) };
    patch((d) => ({ ...d, rewards: [r, ...d.rewards] }), r.id);
    done('Successfully created new reward');
  };
  return (
    <FormDialog title="New Reward" subtitle="Create a redeemable reward item for customers" icon="redeem" width={720} tour="reward-dialog" onSave={save} saveLabel="Create Reward" saveTour="reward-save">
      <div className="ka-sec-label" style={{ marginBottom: 14 }}>Reward Details</div>
      <Grid>
        <Field label="Reward Name" required span={2}><TextInput tour="reward-name" value={f.name} onChange={set('name')} placeholder="e.g. Botol Susu Anti-Kolik" /></Field>
        <Field label="Description" required span={2}><TextInput area tour="reward-desc" value={f.desc} onChange={set('desc')} placeholder="Describe reward perks, terms, or clinic redemption..." height={60} /></Field>
        <Field label="Points Required to Redeem" required><TextInput tour="reward-points" value={f.points} onChange={(v) => set('points')(v.replace(/\D/g, ''))} placeholder="e.g. 1500" suffix={<span style={{ fontSize: 13, color: 'var(--muted)' }}>pts</span>} /></Field>
        <Field label="Total Quantity / Stock" required hint='Enter "0" if stock is infinite / unlimited.'><TextInput tour="reward-qty" value={f.qty} onChange={(v) => set('qty')(v.replace(/\D/g, ''))} placeholder="e.g. 40" /></Field>
      </Grid>
      <div className="ka-sec-label" style={{ margin: '20px 0 12px' }}>Availability &amp; Schedule</div>
      <Grid>
        <Field label="Start Date (Optional)"><DateField value={f.from} onChange={set('from')} placeholder="Select start date (optional)" /></Field>
        <Field label="End Date (Optional)"><DateField value={f.to} onChange={set('to')} placeholder="Select end date (optional)" /></Field>
        <div style={{ gridColumn: 'span 2', fontSize: 12, color: 'var(--muted)', marginTop: -8 }}>Leave dates blank to keep this reward available indefinitely.</div>
        <div style={{ gridColumn: 'span 2' }}><StatusToggle on={f.active} set={set('active')} onLabel="Patients can redeem this item" offLabel="Hidden from patient reward catalog" /></div>
      </Grid>
    </FormDialog>
  );
}

export function RewardsCatalog() {
  const { db, openDialog, highlightId } = useApp();
  const [q, setQ] = useState('');
  const list = db.rewards.filter((r) => !q || r.name.toLowerCase().includes(q.toLowerCase()));
  return (
    <div className="ka-page" style={{ height: '100%', padding: 0, gap: 0 }}>
      <ListToolbar placeholder="Search rewards..." value={q} onChange={setQ}>
        <ToolBtn icon="filter_list" label="Filter" tone="blue" /><ToolBtn icon="refresh" label="Reset" onClick={() => setQ('')} />
        <ToolBtn icon="add" label="Add Reward" primary tour="add-reward" onClick={() => openDialog({ kind: 'custom', render: () => <RewardDialog /> })} />
      </ListToolbar>
      <ListTable head={['Reward Name', 'Points', 'Total', 'Valid Period', 'Status', 'Created', { label: 'Actions', width: 90 }]} total={list.length}>
        {list.map((r) => (
          <tr key={r.id} className={r.id === highlightId ? 'hl' : ''} data-tour={r.id === highlightId ? 'reward-row-new' : `reward-row-${r.id}`} style={{ height: 60 }}>
            <td><div className="ka-cell-person"><span style={{ width: 36, height: 36, borderRadius: 8, background: 'var(--primary-soft)', display: 'grid', placeItems: 'center' }}><Icon n="redeem" size={19} style={{ color: 'var(--primary-ink)' }} /></span><Cell2 title={r.name} sub={r.description} /></div></td>
            <td><span className="ka-pill blue" style={{ border: '1px solid color-mix(in srgb, currentColor 30%, transparent)' }}>{r.points} pts</span></td>
            <td>{r.left == null ? '∞' : `${r.left} left`}</td>
            <td style={{ fontSize: 12.5, color: 'var(--ink-2)' }}>{fmtStamp(r.from)}<div>→ {fmtStamp(r.to)}</div></td>
            <td><ActivePill on={r.active} /></td>
            <td style={{ fontSize: 12.5, color: 'var(--ink-2)' }}>{fmtStamp(r.created)}</td>
            <td><div style={{ display: 'flex', gap: 6 }}><EditBtn /><Toggle on={r.active} onChange={() => {}} /></div></td>
          </tr>
        ))}
      </ListTable>
    </div>
  );
}

// ── Staff accounts ───────────────────────────────────────
function StaffDialog() {
  const { db, patch } = useApp();
  const [f, setF] = useState({ name: '', username: '', password: '', confirm: '', email: '', phone: '', branch: null as string | null, role: null as Admin['role'] | null, perms: [] as string[] });
  const set = <K extends keyof typeof f>(k: K) => (v: (typeof f)[K]) => setF((x) => ({ ...x, [k]: v }));
  const pickRole = (r: Admin['role']) => setF((x) => ({ ...x, role: r, perms: [...ROLE_PRESETS[r]] }));
  const togglePerm = (p: string) => setF((x) => ({ ...x, perms: x.perms.includes(p) ? x.perms.filter((y) => y !== p) : [...x.perms, p] }));
  const save = () => {
    if (!f.name || !f.username || !f.email) return err('Full name, username and email are required.');
    if (f.password.length < 6) return err('Password must be at least 6 characters.');
    if (f.password !== f.confirm) return err("Passwords don't match.");
    if (!f.role) return err('Choose a role.');
    const a: Admin = { id: id('ad'), name: f.name, username: f.username, email: f.email, phone: f.phone || 'N/A', branchId: f.branch === 'all' ? null : f.branch, role: f.role, permissions: f.perms, active: true, created: iso(new Date()) };
    patch((d) => ({ ...d, admins: [a, ...d.admins] }), a.id);
    done('Admin account created.');
  };
  const roles: [Admin['role'], string, string][] = [['Sonographer (Locum)', 'Appointments tab only', 'monitor_heart'], ['Clinic Staff', 'Appointments, patients & billing', 'badge'], ['Branch Manager', 'Full branch operations', 'manage_accounts'], ['Super Admin', 'Unrestricted global access', 'admin_panel_settings']];
  return (
    <FormDialog title="New Admin Account" subtitle="Manage admin permissions, contact info, and system role" icon="admin_panel_settings" width={920} tour="staff-dialog" onSave={save} saveLabel="Create Account" saveTour="staff-save">
      <div style={{ display: 'flex', gap: 22 }}>
        <div style={{ flex: 1 }}>
          <div className="ka-sec-label" style={{ marginBottom: 14 }}>Account Information</div>
          <Grid>
            <Field label="Full Name" required><TextInput tour="staff-name" value={f.name} onChange={set('name')} placeholder="e.g. Nur Aina" /></Field>
            <Field label="Username" required><TextInput tour="staff-username" value={f.username} onChange={set('username')} placeholder="e.g. aina.br" /></Field>
            <Field label="Password" required><TextInput tour="staff-password" value={f.password.replace(/./g, '•')} onChange={(v) => set('password')(v.length < f.password.length ? f.password.slice(0, v.length) : f.password + v.slice(f.password.length))} placeholder="At least 6 characters" /></Field>
            <Field label="Confirm Password" required><TextInput tour="staff-confirm" value={f.confirm.replace(/./g, '•')} onChange={(v) => set('confirm')(v.length < f.confirm.length ? f.confirm.slice(0, v.length) : f.confirm + v.slice(f.confirm.length))} placeholder="Re-enter password" /></Field>
            <Field label="Email Address" required><TextInput tour="staff-email" value={f.email} onChange={set('email')} placeholder="name@example.com" /></Field>
            <Field label="Contact Number"><TextInput value={f.phone} onChange={set('phone')} placeholder="e.g. 0123456789" /></Field>
          </Grid>
          <div className="ka-sec-label" style={{ margin: '20px 0 12px' }}>Branch Scope</div>
          <BoxSelect tour="staff-branch" value={f.branch} onChange={set('branch')} placeholder="Branch Assignment" options={[{ value: 'all', label: 'All Branches (Headquarters / Global)' }, ...db.branches.map((b) => ({ value: b.id, label: b.name }))]} />
        </div>
        <div style={{ width: 360 }}>
          <div className="ka-sec-label" style={{ marginBottom: 12 }}>Role &amp; Permissions</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
            {roles.map(([r, sub, ic]) => (
              <button key={r} type="button" data-tour={`staff-role-${r.split(' ')[0]!.toLowerCase()}`} onClick={() => pickRole(r)} style={{ textAlign: 'left', padding: 10, borderRadius: 10, border: `1.5px solid ${f.role === r ? 'var(--primary)' : 'var(--border)'}`, background: f.role === r ? 'var(--primary-soft)' : 'var(--surface)' }}>
                <Icon n={ic} size={18} style={{ color: f.role === r ? 'var(--primary-ink)' : 'var(--muted)' }} />
                <div style={{ fontSize: 12.5, fontWeight: 700, marginTop: 4 }}>{r}</div><div style={{ fontSize: 11, color: 'var(--muted)' }}>{sub}</div>
              </button>
            ))}
          </div>
          <div data-tour="staff-perms" style={{ marginTop: 12, border: '1px solid var(--border)', borderRadius: 10, padding: 10, maxHeight: 250, overflow: 'auto' }}>
            <div style={{ display: 'flex', alignItems: 'center', fontSize: 12, fontWeight: 700, marginBottom: 6 }}><span style={{ flex: 1 }}>All Permissions ({f.perms.length})</span><button type="button" className="ka-link" onClick={() => set('perms')(PERMISSIONS.flatMap((g) => g.items))}>Select All</button><button type="button" className="ka-link" style={{ marginLeft: 10 }} onClick={() => set('perms')([])}>Clear</button></div>
            {PERMISSIONS.map((g) => (
              <div key={g.group}>
                <div style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: .8, color: 'var(--muted)', textTransform: 'uppercase', margin: '8px 0 4px' }}>{g.group}</div>
                {g.items.map((p) => (
                  <button key={p} type="button" onClick={() => togglePerm(p)} style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', border: 'none', background: 'none', padding: '4px 0', fontSize: 12.5, textAlign: 'left' }}>
                    <Icon n={f.perms.includes(p) ? 'check_box' : 'check_box_outline_blank'} size={18} style={{ color: f.perms.includes(p) ? 'var(--primary-ink)' : 'var(--muted)' }} />{p}
                  </button>
                ))}
              </div>
            ))}
          </div>
        </div>
      </div>
    </FormDialog>
  );
}

export function Staff() {
  const { db, openDialog, highlightId } = useApp();
  const [q, setQ] = useState('');
  const list = db.admins.filter((a) => !q || `${a.name} ${a.email}`.toLowerCase().includes(q.toLowerCase())).sort((a, b) => a.name.localeCompare(b.name));
  return (
    <div className="ka-page" style={{ height: '100%', padding: 0, gap: 0 }}>
      <ListToolbar placeholder="Search admins..." value={q} onChange={setQ}>
        <button type="button" className="ka-btn lg" style={{ fontSize: 13, color: 'var(--primary-ink)', borderColor: 'color-mix(in srgb, var(--primary) 40%, transparent)' }}><Icon n="swap_vert" size={16} />Name (A–Z)<Icon n="arrow_drop_down" size={18} /></button>
        <ToolBtn icon="filter_list" label="Filter" tone="blue" /><ToolBtn icon="refresh" label="Reset" onClick={() => setQ('')} />
        <ToolBtn icon="add" label="Add Admin" primary tour="add-admin" onClick={() => openDialog({ kind: 'custom', render: () => <StaffDialog /> })} />
      </ListToolbar>
      <ListTable head={['Name ↑', 'Email', 'Role', 'Contact', 'Status', 'Created', { label: 'Actions', width: 80 }]} total={list.length}>
        {list.map((a) => (
          <tr key={a.id} className={a.id === highlightId ? 'hl' : ''} data-tour={a.id === highlightId ? 'staff-row-new' : `staff-row-${a.id}`} style={{ height: 56 }}>
            <td>{a.name}</td><td style={{ fontSize: 13, color: 'var(--ink-2)' }}>{a.email}</td>
            <td><span className={`ka-pill ${a.role === 'Super Admin' ? 'violet' : a.role === 'Branch Manager' ? 'blue' : 'grey'}`}>{a.role}</span></td>
            <td style={{ fontSize: 13 }}>{a.phone}</td><td><ActivePill on={a.active} /></td>
            <td style={{ fontSize: 12.5, color: 'var(--ink-2)' }}>{fmtStamp(a.created)}</td>
            <td><span className="ka-dots"><Icon n="more_horiz" /></span></td>
          </tr>
        ))}
      </ListTable>
    </div>
  );
}

// ── Branches ─────────────────────────────────────────────
function BranchDialog() {
  const { patch } = useApp();
  const [f, setF] = useState({ name: '', code: '', city: '', state: null as string | null, phone: '', email: '', open: '09:00', close: '18:00', h24: false, password: '' });
  const set = <K extends keyof typeof f>(k: K) => (v: (typeof f)[K]) => setF((x) => ({ ...x, [k]: v }));
  const save = () => {
    if (!f.name || !f.code) return err('Branch name and code are required.');
    if (!f.state) return err('Choose a state.');
    const b = { id: id('br'), name: f.name, code: f.code.toUpperCase(), city: f.city, state: f.state, created: iso(new Date()) };
    patch((d) => ({ ...d, branches: [...d.branches, b].sort((x, y) => x.name.localeCompare(y.name)) }), b.id);
    done(`Successfully created branch "${f.name}"`);
  };
  const states = ['Selangor', 'Kuala Lumpur', 'Putrajaya', 'Negeri Sembilan', 'Melaka', 'Johor', 'Pulau Pinang', 'Kedah', 'Perak', 'Pahang', 'Kelantan', 'Terengganu', 'Sabah', 'Sarawak'];
  return (
    <FormDialog title="New Branch" subtitle="Branch details, opening hours and the branch login" icon="store" width={760} tour="branch-dialog" onSave={save} saveLabel="Create Branch" saveTour="branch-save">
      <Grid>
        <Field label="Branch Name" required><TextInput tour="branch-name" value={f.name} onChange={set('name')} placeholder="e.g. Klinik Aurora Kota Damansara" /></Field>
        <Field label="Branch Code" required><TextInput tour="branch-code" value={f.code} onChange={(v) => set('code')(v.toUpperCase())} placeholder="e.g. KOTADAMANSARA" /></Field>
        <Field label="City"><TextInput tour="branch-city" value={f.city} onChange={set('city')} placeholder="e.g. Petaling Jaya" /></Field>
        <Field label="State" required><BoxSelect tour="branch-state" value={f.state} onChange={set('state')} options={states.map((s) => ({ value: s, label: s }))} /></Field>
        <Field label="Opening Hours"><TextInput value={f.open} onChange={set('open')} prefix={<Icon n="schedule" size={18} />} /></Field>
        <Field label="Closing Hours"><TextInput value={f.close} onChange={set('close')} prefix={<Icon n="schedule" size={18} />} /></Field>
        <div style={{ gridColumn: 'span 2' }}><Toggle on={f.h24} onChange={set('h24')} label="Open 24 Hours" /></div>
        <Field label="Contact No."><TextInput tour="branch-phone" value={f.phone} onChange={set('phone')} placeholder="e.g. 0361234567" /></Field>
        <Field label="Email" hint="The branch logs in to the portal with this email."><TextInput tour="branch-email" value={f.email} onChange={set('email')} placeholder="branch@example.com" /></Field>
        <Field label="Branch Image" span={2}><div style={{ padding: 16, borderRadius: 10, border: '1.5px dashed var(--border-strong)', background: 'var(--surface-subtle)', fontSize: 13, color: 'var(--muted)', display: 'flex', alignItems: 'center', gap: 10 }}><Icon n="add_photo_alternate" size={22} />Browse your files here (max 1MB)</div></Field>
      </Grid>
    </FormDialog>
  );
}

export function Branches() {
  const { db, openDialog, highlightId } = useApp();
  const [q, setQ] = useState('');
  const list = db.branches.filter((b) => !q || b.name.toLowerCase().includes(q.toLowerCase()));
  return (
    <div className="ka-page" style={{ height: '100%', padding: 0, gap: 0 }}>
      <ListToolbar placeholder="Search branches..." value={q} onChange={setQ}>
        <ToolBtn icon="filter_list" label="Filter" tone="blue" /><ToolBtn icon="refresh" label="Reset" onClick={() => setQ('')} />
        <ToolBtn icon="add" label="Add Branch" primary tour="add-branch" onClick={() => openDialog({ kind: 'custom', render: () => <BranchDialog /> })} />
      </ListToolbar>
      <ListTable head={['Branch', 'City', 'State', 'Status', 'Created', { label: 'Actions', width: 80 }]} total={list.length} pages={2}>
        {list.map((b) => (
          <tr key={b.id} className={b.id === highlightId ? 'hl' : ''} data-tour={b.id === highlightId ? 'branch-row-new' : `branch-row-${b.id}`} style={{ height: 60 }}>
            <td><div className="ka-cell-person"><span style={{ width: 38, height: 38, borderRadius: 6, background: 'linear-gradient(160deg,#7dd3fc,#0e7490 60%,#134e4a)', display: 'grid', placeItems: 'center' }}><Icon n="storefront" size={20} style={{ color: '#fff' }} /></span><Cell2 title={b.name} sub={b.code} /></div></td>
            <td style={{ fontSize: 13 }}>{b.city}</td><td style={{ fontSize: 13 }}>{b.state}</td><td><ActivePill on /></td>
            <td style={{ fontSize: 12.5, color: 'var(--ink-2)' }}>{fmtStamp(b.created)}</td>
            <td><span className="ka-dots"><Icon n="more_horiz" /></span></td>
          </tr>
        ))}
      </ListTable>
    </div>
  );
}

// ── Activity logs ────────────────────────────────────────
const ACTION_TONE: Record<string, string> = { CREATE: 'green', UPDATE: 'blue', TRANSFER: 'violet', STATUS_CHANGE: 'amber', CANCEL: 'red', DELETE: 'red', RECALL_SENT: 'grey', RESCHEDULE: 'violet' };

function DiffDialog({ entryId }: { entryId: string }) {
  const { db, closeDialog } = useApp();
  const e = db.audit.find((x) => x.id === entryId)!;
  const block = (title: string, v?: Record<string, unknown>) => (
    <div style={{ flex: 1 }}>
      <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--muted)', marginBottom: 6 }}>{title}</div>
      <pre style={{ margin: 0, padding: 12, borderRadius: 8, background: 'var(--surface-subtle)', border: '1px solid var(--border)', fontSize: 12.5, minHeight: 120, color: 'var(--ink)' }}>{v ? JSON.stringify(v, null, 2) : '—'}</pre>
    </div>
  );
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 720, padding: 20 }} onClick={(x) => x.stopPropagation()} data-tour="audit-diff">
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}><span className={`ka-pill ${ACTION_TONE[e.action]}`}>{e.action}</span><b style={{ flex: 1 }}>{e.summary}</b><button type="button" className="ka-dialog-close" onClick={closeDialog}><Icon n="close" /></button></div>
        <div style={{ fontSize: 12.5, color: 'var(--muted)', margin: '6px 0 14px' }}>{fmtStamp(e.at)} · {e.admin} · {e.entity} {e.entityId}</div>
        <div style={{ display: 'flex', gap: 12 }}>{block('Before State', e.before)}{block('After State', e.after)}</div>
      </div>
    </div>
  );
}

export function ActivityLogs() {
  const { db, openDialog } = useApp();
  const [action, setAction] = useState<string | null>('all');
  const list = db.audit.filter((e) => action === 'all' || e.action === action);
  return (
    <div className="ka-page" style={{ height: '100%', padding: '18px 24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ flex: 1, fontSize: 21, fontWeight: 800 }}>Audit Trail &amp; Activity Log</div>
        <button type="button" className="ka-btn lg"><Icon n="date_range" size={18} />Date Range</button>
        <button type="button" className="ka-btn lg"><Icon n="download" size={18} />Export CSV</button>
        <button type="button" className="ka-btn primary lg"><Icon n="refresh" size={18} />Refresh</button>
      </div>
      <div style={{ display: 'flex', gap: 10 }}>
        <label className="ka-search" style={{ height: 40 }}><Icon n="search" /><input placeholder="Search admin, summary, or ID... (press /)" /></label>
        <div style={{ width: 200 }}><BoxSelect tour="audit-action" value={action} onChange={setAction} options={[{ value: 'all', label: 'All Actions' }, ...['CREATE', 'UPDATE', 'TRANSFER', 'STATUS_CHANGE', 'RESCHEDULE', 'CANCEL', 'RECALL_SENT'].map((a) => ({ value: a, label: a }))]} /></div>
      </div>
      <div className="ka-card" style={{ borderRadius: 10, overflow: 'auto', flex: 1 }} data-tour="audit-list">
        {list.map((e) => (
          <div key={e.id} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '12px 16px', borderBottom: '1px solid var(--border)' }}>
            <span style={{ width: 120, fontSize: 12, color: 'var(--muted)' }}>{fmtStamp(e.at)}</span>
            <span className={`ka-pill ${ACTION_TONE[e.action]}`} style={{ width: 118, justifyContent: 'center' }}>{e.action}</span>
            <div style={{ flex: 1, minWidth: 0 }}><div style={{ fontSize: 13.5, fontWeight: 600 }}>{e.summary}</div><div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2 }}>{e.admin} · {e.branch} · {e.entity} {e.entityId}</div></div>
            {(e.before || e.after) && <button type="button" className="ka-link" data-tour={`audit-inspect-${e.id}`} onClick={() => openDialog({ kind: 'custom', render: () => <DiffDialog entryId={e.id} /> })} style={{ fontSize: 12.5 }}>Inspect diff →</button>}
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Peak hours & capacity ────────────────────────────────
export function PeakHours() {
  const db = useApp((s) => s.db);
  const hours = Array.from({ length: 10 }, (_, i) => 9 + i);
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const util = (d: number, h: number) => (d === 6 ? 0 : Math.max(0, Math.min(100, Math.round(((Math.sin(h * 1.3 + d) + 1) * 30) + (h >= 10 && h <= 12 ? 35 : 0) + (d === 5 ? 20 : 0) + (h >= 17 ? -20 : 0)))));
  const tone = (u: number) => (u >= 95 ? '#dc2626' : u >= 75 ? '#f59e0b' : u >= 25 ? '#10b981' : 'var(--surface-subtle)');
  const cells: ReactNode[] = [];
  days.forEach((d, di) => {
    cells.push(<span key={`l${d}`} style={{ fontSize: 12, fontWeight: 600, color: 'var(--ink-2)', alignSelf: 'center' }}>{d}</span>);
    hours.forEach((h) => { const u = util(di, h); cells.push(<span key={`${d}${h}`} title={`${d} ${h}:00 · ${u}%`} style={{ height: 34, borderRadius: 6, background: tone(u), opacity: u >= 25 ? 0.35 + u / 160 : 1, display: 'grid', placeItems: 'center', fontSize: 11, fontWeight: 700, color: u >= 25 ? '#fff' : 'var(--muted)' }}>{u ? `${u}%` : ''}</span>); });
  });
  return (
    <div className="ka-page" style={{ height: '100%', padding: '18px 24px', overflow: 'auto' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ flex: 1, fontSize: 21, fontWeight: 800 }}>Branch Utilization Heatmap &amp; Capacity Alerts</div>
        <div className="ka-input" style={{ width: 240, height: 40, justifyContent: 'space-between', fontSize: 13 }}>Klinik Aurora Bukit Rimau<Icon n="arrow_drop_down" /></div>
        <button type="button" className="ka-btn primary lg"><Icon n="refresh" size={18} />Refresh</button>
      </div>
      <div style={{ display: 'flex', gap: 12 }} data-tour="peak-kpis">
        {[['Avg Utilization', '58%', 'Window: next 14 days', 'var(--ink)'], ['Overloaded Staff', '1', 'At >=85% roster capacity', 'var(--danger)'], ['Underutilized Staff', '1', 'Below <=30% roster capacity', 'var(--warning-text)'], ['Unassigned Bookings', '0', 'Appointments without doctor', 'var(--success-text)']].map(([l, v, s, c]) => (
          <div key={l} className="ka-card" style={{ flex: 1, padding: 14, borderRadius: 10 }}><div style={{ fontSize: 12, color: 'var(--ink-2)', fontWeight: 600 }}>{l}</div><div style={{ fontSize: 22, fontWeight: 800, color: c, margin: '6px 0' }}>{v}</div><div style={{ fontSize: 11.5, color: 'var(--muted)' }}>{s}</div></div>
        ))}
      </div>
      <div className="ka-card" style={{ borderRadius: 10, padding: 16 }} data-tour="peak-matrix">
        <div style={{ display: 'flex', alignItems: 'center', marginBottom: 12 }}>
          <b style={{ flex: 1, fontSize: 15 }}>Day × Hour Capacity Matrix</b>
          {[['Idle (<25%)', 'var(--surface-subtle)'], ['Balanced (25–75%)', '#10b981'], ['Peak (75–95%)', '#f59e0b'], ['Overload (>=95%)', '#dc2626']].map(([l, c]) => <span key={l} style={{ fontSize: 11.5, color: 'var(--ink-2)', display: 'flex', alignItems: 'center', gap: 5, marginLeft: 12 }}><span style={{ width: 12, height: 12, borderRadius: 3, background: c, border: '1px solid var(--border)' }} />{l}</span>)}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: `44px repeat(${hours.length}, 1fr)`, gap: 4 }}>
          <span />{hours.map((h) => <span key={h} style={{ fontSize: 11, color: 'var(--muted)', textAlign: 'center' }}>{h > 12 ? h - 12 : h}{h >= 12 ? 'pm' : 'am'}</span>)}
          {cells}
        </div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        <div className="ka-card" style={{ borderRadius: 10, padding: 16 }} data-tour="peak-bottlenecks"><b style={{ fontSize: 14 }}>Peak Bottleneck Hours (Add Locum Capacity)</b>{['Sat 10am–12pm · 96%', 'Wed 11am · 88%', 'Fri 10am · 82%'].map((x) => <div key={x} style={{ fontSize: 13, padding: '8px 0', borderBottom: '1px solid var(--border)', color: 'var(--danger-text)' }}>{x}</div>)}</div>
        <div className="ka-card" style={{ borderRadius: 10, padding: 16 }}><b style={{ fontSize: 14 }}>Off-Peak Idle Windows (Promo Voucher Targets)</b>{['Mon 4–6pm · 12%', 'Tue 5pm · 18%', 'Thu 3pm · 21%'].map((x) => <div key={x} style={{ fontSize: 13, padding: '8px 0', borderBottom: '1px solid var(--border)', color: 'var(--success-text)' }}>{x}</div>)}</div>
      </div>
      <div style={{ fontSize: 12, color: 'var(--muted)' }}>{db.practitioners.filter((p) => p.branchId === 'br-bukitrimau').length} rostered practitioners in this window.</div>
    </div>
  );
}
