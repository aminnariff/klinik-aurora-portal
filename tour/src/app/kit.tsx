import type { CSSProperties, ReactNode } from 'react';
import { useApp } from './store';
import { Icon, Pager } from './ui';

/** Search bar + right-hand buttons used at the top of every list screen. */
export function ListToolbar({ placeholder, value, onChange, tour, children }: { placeholder: string; value: string; onChange: (v: string) => void; tour?: string; children?: ReactNode }) {
  return (
    <div style={{ display: 'flex', gap: 10, alignItems: 'center', padding: '14px 24px', background: 'var(--surface)' }}>
      <label className="ka-search" data-tour={tour} style={{ height: 40, background: 'var(--surface-subtle)', borderColor: 'var(--border)' }}>
        <Icon n="search" />
        <input value={value} onChange={(e) => onChange(e.target.value)} placeholder={placeholder} style={{ fontSize: 15 }} />
      </label>
      {children}
    </div>
  );
}

export function ToolBtn({ icon, label, tour, onClick, primary, tone }: { icon: string; label: string; tour?: string; onClick?: () => void; primary?: boolean; tone?: 'blue' | 'plum' }) {
  const style: CSSProperties = primary ? {} : tone === 'plum'
    ? { color: 'var(--primary-ink)', borderColor: 'color-mix(in srgb, var(--primary) 45%, transparent)' }
    : tone === 'blue' ? { color: 'var(--info-text, var(--info))', borderColor: 'color-mix(in srgb, #2563eb 35%, transparent)' } : {};
  return (
    <button type="button" className={`ka-btn lg${primary ? ' primary' : ''}`} data-tour={tour} onClick={onClick} style={{ fontSize: 15, ...style }}>
      <Icon n={icon} size={18} />{label}
    </button>
  );
}

/** Card + table + pager, matching AppTable in the portal. */
export function ListTable({ head, children, total, empty, pages = 1 }: { head: (string | { label: string; width?: number })[]; children: ReactNode; total: number; empty?: string; pages?: number }) {
  return (
    <div style={{ flex: 1, minHeight: 0, padding: '20px 24px 24px', display: 'flex' }}>
      <div className="ka-card ka-table-wrap" style={{ flex: 1, borderRadius: 12, boxShadow: '0 1px 3px rgba(15,23,42,.04)' }}>
        <div className="ka-table-scroll">
          <table className="ka-table kit">
            <thead>
              <tr>{head.map((h, i) => { const l = typeof h === 'string' ? h : h.label; const w = typeof h === 'string' ? undefined : h.width; return <th key={i} style={{ width: w, height: 50, fontSize: 13, background: 'var(--surface)' }}>{l}</th>; })}</tr>
            </thead>
            <tbody>{children}</tbody>
          </table>
          {total === 0 && <div className="ka-empty" style={{ padding: 80 }}><div><div className="ka-empty-icon"><Icon n="inbox" /></div><b>{empty ?? 'No records found'}</b>Try a different search</div></div>}
        </div>
        <Pager total={total} shown={Math.min(15, total)} pages={pages} />
      </div>
    </div>
  );
}

export function EditBtn({ tour, onClick, icon = 'edit' }: { tour?: string; onClick?: () => void; icon?: string }) {
  return (
    <button type="button" data-tour={tour} onClick={onClick} style={{ width: 28, height: 28, borderRadius: 6, border: 'none', background: 'color-mix(in srgb, #6366f1 12%, transparent)', display: 'grid', placeItems: 'center' }}>
      <Icon n={icon} size={16} style={{ color: 'var(--indigo-ink)' }} />
    </button>
  );
}

export function DotsBtn({ tour, onClick }: { tour?: string; onClick?: () => void }) {
  return <button type="button" className="ka-dots" data-tour={tour} onClick={onClick}><Icon n="more_horiz" /></button>;
}

export function ActivePill({ on }: { on: boolean }) {
  return <span className={`ka-pill ${on ? 'green' : 'red'}`}>{on ? 'Active' : 'Inactive'}</span>;
}

export function Thumb({ icon, hue = 'plum' }: { icon: string; hue?: 'plum' | 'teal' | 'blue' | 'amber' }) {
  const c = { plum: '#7e2d40', teal: '#0d9488', blue: '#2563eb', amber: '#d97706' }[hue];
  return (
    <span style={{ width: 36, height: 36, borderRadius: 8, flex: 'none', display: 'grid', placeItems: 'center', background: `color-mix(in srgb, ${c} 12%, transparent)` }}>
      <Icon n={icon} size={19} style={{ color: hue === 'plum' ? 'var(--primary-ink)' : c }} />
    </span>
  );
}

/** Two-line cell: bold title + muted subtitle. */
export function Cell2({ title, sub, titleColor }: { title: ReactNode; sub?: ReactNode; titleColor?: string }) {
  return (
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 14, color: titleColor ?? 'var(--ink)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{title}</div>
      {sub != null && <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{sub}</div>}
    </div>
  );
}

/** Large form dialog used for create/update screens (AppFormDialog style). */
export function FormDialog({ title, subtitle, icon, badge, width = 720, tour, children, onSave, saveLabel = 'Save', saveTour, extraHead }: {
  title: string; subtitle?: string; icon?: string; badge?: string; width?: number; tour?: string; children: ReactNode; onSave: () => void; saveLabel?: string; saveTour?: string; extraHead?: ReactNode;
}) {
  const close = useApp((s) => s.closeDialog);
  return (
    <div className="ka-overlay" onClick={close}>
      <div className="ka-dialog" style={{ width }} onClick={(e) => e.stopPropagation()} data-tour={tour}>
        <div className="ka-dialog-head">
          {badge ? <span className="ka-dialog-badge">{badge}</span> : icon && <span className="ka-dialog-badge"><Icon n={icon} size={22} /></span>}
          <div style={{ flex: 1, minWidth: 0 }}><h2>{title}</h2>{subtitle && <p>{subtitle}</p>}</div>
          {extraHead}
          <button type="button" className="ka-dialog-close" onClick={close} style={{ marginLeft: 8 }}><Icon n="close" /></button>
        </div>
        <div className="ka-dialog-body" style={{ padding: '22px 22px', maxHeight: 620 }} data-tour={tour ? `${tour}-body` : undefined}>{children}</div>
        <div className="ka-dialog-foot">
          <button type="button" className="ka-btn lg" onClick={close}>Cancel</button>
          <button type="button" className="ka-btn primary lg" data-tour={saveTour} onClick={onSave}>{saveLabel}</button>
        </div>
      </div>
    </div>
  );
}

export function Grid({ cols = 2, children, gap = '18px 16px' }: { cols?: number; children: ReactNode; gap?: string }) {
  return <div style={{ display: 'grid', gridTemplateColumns: `repeat(${cols}, minmax(0, 1fr))`, gap }}>{children}</div>;
}

export function Field({ label, required, children, span, hint }: { label: string; required?: boolean; children: ReactNode; span?: number; hint?: string }) {
  return (
    <div style={{ gridColumn: span ? `span ${span}` : undefined, minWidth: 0 }}>
      <span className="ka-field-label">{label}{required && <> <i>*</i></>}</span>
      {children}
      {hint && <div style={{ fontSize: 11.5, color: 'var(--muted)', marginTop: 5 }}>{hint}</div>}
    </div>
  );
}

export function TextInput({ tour, value, onChange, placeholder, prefix, suffix, height = 46, area }: {
  tour?: string; value: string; onChange: (v: string) => void; placeholder?: string; prefix?: ReactNode; suffix?: ReactNode; height?: number; area?: boolean;
}) {
  if (area) {
    return (
      <label className="ka-input" data-tour={tour} style={{ height: 'auto', minHeight: height, alignItems: 'flex-start', padding: '12px 14px' }}>
        <textarea value={value} onChange={(e) => onChange(e.target.value)} placeholder={placeholder} rows={3} style={{ border: 'none', outline: 'none', background: 'none', resize: 'none', flex: 1, fontSize: 14, lineHeight: 1.45 }} />
      </label>
    );
  }
  return (
    <label className="ka-input" data-tour={tour} style={{ height }}>
      {prefix}
      <input value={value} onChange={(e) => onChange(e.target.value)} placeholder={placeholder} />
      {suffix}
    </label>
  );
}

export function Toggle({ on, onChange, tour, label }: { on: boolean; onChange: (v: boolean) => void; tour?: string; label?: string }) {
  return (
    <button type="button" data-tour={tour} onClick={() => onChange(!on)} style={{ display: 'inline-flex', alignItems: 'center', gap: 10, border: 'none', background: 'none', padding: 0, fontSize: 14, color: 'var(--ink)' }}>
      <span style={{ width: 44, height: 24, borderRadius: 12, padding: 2, background: on ? 'var(--primary)' : 'var(--border-strong)', transition: 'background .2s', display: 'flex' }}>
        <span style={{ width: 20, height: 20, borderRadius: '50%', background: '#fff', transform: `translateX(${on ? 20 : 0}px)`, transition: 'transform .2s', boxShadow: '0 1px 2px rgba(0,0,0,.25)' }} />
      </span>
      {label}
    </button>
  );
}

/** Pill-shaped filter chips (All / Active / Inactive …). */
export function Chips<T extends string>({ options, value, onChange, tourPrefix, tone = 'blue' }: { options: { value: T; label: string }[]; value: T; onChange: (v: T) => void; tourPrefix?: string; tone?: 'blue' | 'plum' }) {
  const c = tone === 'blue' ? '#2196f3' : 'var(--primary)';
  return (
    <div style={{ display: 'flex', gap: 8 }}>
      {options.map((o) => (
        <button key={o.value} type="button" data-tour={tourPrefix ? `${tourPrefix}-${o.value}` : undefined} onClick={() => onChange(o.value)} className="ka-btn"
          style={{ height: 38, fontSize: 14, fontWeight: o.value === value ? 600 : 500, ...(o.value === value ? { background: c, borderColor: c, color: '#fff' } : { color: 'var(--ink-2)' }) }}>
          {o.label}
        </button>
      ))}
    </div>
  );
}

export function Kpi({ label, value, sub, color, icon, tour }: { label: string; value: string; sub: string; color: string; icon: string; tour?: string }) {
  return (
    <div className="ka-card" data-tour={tour} style={{ flex: 1, borderTop: `3px solid ${color}`, padding: '18px 14px 16px', borderRadius: 6, minWidth: 0 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: 1, color: 'var(--ink-2)', textTransform: 'uppercase' }}>{label}</span>
        <span style={{ width: 24, height: 24, borderRadius: 6, background: `color-mix(in srgb, ${color} 14%, transparent)`, display: 'grid', placeItems: 'center' }}><Icon n={icon} size={15} style={{ color }} /></span>
      </div>
      <div style={{ fontSize: 22, fontWeight: 800, margin: '14px 0 8px' }}>{value}</div>
      <div style={{ fontSize: 12, fontWeight: 600, color: `color-mix(in srgb, ${color} 75%, var(--ink))` }}>{sub}</div>
    </div>
  );
}

/** Small stat card used on Payment Records / EOD (icon tile, big value, label). */
export function StatCard({ icon, color, value, label, badge, tour, valueColor }: { icon: string; color: string; value: string; label: string; badge?: ReactNode; tour?: string; valueColor?: string }) {
  return (
    <div className="ka-card" data-tour={tour} style={{ flex: 1, padding: 14, borderRadius: 8, minWidth: 0 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <span style={{ width: 32, height: 32, borderRadius: 7, display: 'grid', placeItems: 'center', background: `color-mix(in srgb, ${color} 13%, transparent)` }}><Icon n={icon} size={17} style={{ color }} /></span>
        {badge}
      </div>
      <div style={{ fontSize: 20, fontWeight: 800, marginTop: 12, color: valueColor }}>{value}</div>
      <div style={{ fontSize: 12, color: 'var(--ink-2)', marginTop: 6 }}>{label}</div>
    </div>
  );
}

export function SectionCard({ title, children, right, tour, pad = 18 }: { title: ReactNode; children: ReactNode; right?: ReactNode; tour?: string; pad?: number }) {
  return (
    <div className="ka-card" data-tour={tour} style={{ borderRadius: 8, minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', padding: `14px ${pad}px`, borderBottom: '1px solid var(--border)' }}>
        <div style={{ fontSize: 15, fontWeight: 600, flex: 1 }}>{title}</div>{right}
      </div>
      <div style={{ padding: pad }}>{children}</div>
    </div>
  );
}
