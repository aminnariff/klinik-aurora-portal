import { useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { useApp } from './store';

/** Material icon. `v` picks the font: round (default, like Icons.*_rounded), outlined, or filled. */
export function Icon({ n, v = 'r', size, style, className = '' }: { n: string; v?: 'r' | 'o' | 'f'; size?: number; style?: CSSProperties; className?: string }) {
  const cls = v === 'o' ? 'mi o' : v === 'f' ? 'mi f' : 'mi';
  return <span className={`${cls} ${className}`} style={{ fontSize: size, ...style }} aria-hidden>{n}</span>;
}

/** FontAwesome user-doctor stand-in for the Doctors menu item. */
export function DoctorIcon({ size = 23 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <circle cx="12" cy="6" r="4.2" />
      <path d="M3.5 21.5c0-4.3 3.1-7.7 7.2-8.3l1.3 2.4 1.3-2.4c4.1.6 7.2 4 7.2 8.3v.5h-17z" />
      <path d="M16.2 16.4h1.4v1.3h1.3v1.4h-1.3v1.3h-1.4v-1.3h-1.3v-1.4h1.3z" fill="var(--sidebar-bottom)" />
      <path d="M8.2 14.2v3.1a1.4 1.4 0 1 0 1.3 0v-3.4" fill="var(--sidebar-bottom)" />
    </svg>
  );
}

export function Avatar({ name, idx, size = 36 }: { name: string; idx: number; size?: number }) {
  const ini = name.split(/\s+/).filter((w) => /^[A-Za-z]/.test(w)).slice(0, 2).map((w) => w[0]!.toUpperCase()).join('');
  return <span className={`ka-avatar av-${idx % 5}`} style={{ width: size, height: size }}>{ini}</span>;
}

/** Rect of an element in the replica's own (unscaled) coordinates. */
export function relRect(el: Element) {
  const root = document.getElementById('ka-root')!;
  const r = el.getBoundingClientRect();
  const rr = root.getBoundingClientRect();
  const s = rr.width / root.offsetWidth || 1;
  return { left: (r.left - rr.left) / s, top: (r.top - rr.top) / s, width: r.width / s, height: r.height / s };
}

/** A pop-over (dropdown list, row menu) rendered above everything inside the replica. */
export function Popover({ anchor, onClose, children, width, align = 'left', offset = 4, className = 'ka-menu', tour }: {
  anchor: HTMLElement | null; onClose: () => void; children: ReactNode; width?: number | 'anchor'; align?: 'left' | 'right'; offset?: number; className?: string; tour?: string;
}) {
  const [pos, setPos] = useState<{ left: number; top: number; width: number } | null>(null);
  useLayoutEffect(() => {
    if (!anchor) return;
    const r = relRect(anchor);
    const w = width === 'anchor' ? r.width : width ?? 220;
    setPos({ left: align === 'right' ? r.left + r.width - w : r.left, top: r.top + r.height + offset, width: w });
  }, [anchor, width, align, offset]);
  const layer = document.getElementById('ka-layer');
  if (!layer || !pos) return null;
  return createPortal(
    <>
      <div style={{ position: 'absolute', inset: 0, zIndex: 39, pointerEvents: 'auto' }} onClick={onClose} />
      <div className={className} data-tour={tour} style={{ left: pos.left, top: pos.top, width: pos.width, pointerEvents: 'auto' }}>{children}</div>
    </>,
    layer,
  );
}

export interface Option { value: string; label: string }

/** Flutter DropdownButton2-style outlined select with a floating label. */
export function FloatSelect({ label, icon, value, options, onChange, tour, disabled, placeholder = 'Select', labelTone = 'primary' }: {
  label: string; icon: string; value: string | null; options: Option[]; onChange: (v: string) => void; tour: string; disabled?: boolean; placeholder?: string; labelTone?: 'primary' | 'muted';
}) {
  const ref = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);
  const current = options.find((o) => o.value === value);
  return (
    <>
      <button
        ref={ref}
        type="button"
        className={`ka-float${open ? ' focus' : ''}`}
        data-tour={tour}
        style={disabled ? { background: 'var(--surface-subtle)', cursor: 'default' } : undefined}
        onClick={() => !disabled && setOpen(true)}
      >
        <span className={`ka-float-label${labelTone === 'muted' ? ' muted' : ''}`}>{label}</span>
        <Icon n={icon} />
        <span className={`grow${current ? '' : ' placeholder'}`}>{current?.label ?? placeholder}</span>
        {!disabled && <Icon n="keyboard_arrow_down" size={22} style={{ color: 'var(--ink-2)' }} />}
      </button>
      {open && (
        <Popover anchor={ref.current} onClose={() => setOpen(false)} width="anchor" tour={`${tour}-menu`}>
          {options.map((o) => (
            <button key={o.value} type="button" className="ka-menu-item" data-tour={`${tour}-opt-${o.value}`} onClick={() => { onChange(o.value); setOpen(false); }}>
              {o.label}
            </button>
          ))}
        </Popover>
      )}
    </>
  );
}

/** Plain bordered select used in register-patient and filters. */
export function BoxSelect({ value, options, onChange, tour, placeholder = 'Select', bold }: {
  value: string | null; options: Option[]; onChange: (v: string) => void; tour: string; placeholder?: string; bold?: boolean;
}) {
  const ref = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);
  const current = options.find((o) => o.value === value);
  return (
    <>
      <button ref={ref} type="button" className={`ka-input${open ? ' focus' : ''}`} data-tour={tour} onClick={() => setOpen(true)} style={{ justifyContent: 'space-between', textAlign: 'left', fontWeight: bold ? 600 : 400, borderColor: open ? 'var(--primary)' : undefined }}>
        <span style={{ color: current ? 'var(--ink)' : bold ? 'var(--ink-2)' : 'var(--muted)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{current?.label ?? placeholder}</span>
        <Icon n="keyboard_arrow_down" size={20} style={{ color: 'var(--ink-2)' }} />
      </button>
      {open && (
        <Popover anchor={ref.current} onClose={() => setOpen(false)} width="anchor" tour={`${tour}-menu`}>
          {options.map((o) => (
            <button key={o.value} type="button" className="ka-menu-item" data-tour={`${tour}-opt-${o.value}`} onClick={() => { onChange(o.value); setOpen(false); }}>
              {o.label}
            </button>
          ))}
        </Popover>
      )}
    </>
  );
}

export function Checkbox({ on }: { on: boolean }) {
  return <span className={`ka-checkbox${on ? ' on' : ''}`}>{on && <Icon n="check" />}</span>;
}

export function Pager({ total, shown, pages = 1 }: { total: number; shown: number; pages?: number }) {
  return (
    <div className="ka-pager">
      <button className="ka-pager-arrow" type="button"><Icon n="arrow_back" /></button>
      {Array.from({ length: Math.min(pages, 5) }, (_, i) => (
        <span key={i} className={`ka-pager-num${i === 0 ? ' on' : ''}`}>{i + 1}</span>
      ))}
      <button className={`ka-pager-arrow${pages > 1 ? ' on' : ''}`} type="button"><Icon n="arrow_forward" /></button>
      <div className="ka-pager-info">
        <span style={{ display: 'flex', alignItems: 'center', gap: 28 }}>Rows: <Icon n="keyboard_arrow_down" size={20} /></span>
        <span>1–{shown} of {total}</span>
      </div>
    </div>
  );
}

/** Large centred status dialog (showDialogSuccess / showDialogError in the app). */
export function StatusDialog({ tone, title, message, button, onClose }: { tone: 'success' | 'error' | 'info'; title: string; message: string; button?: string; onClose: () => void }) {
  const c = tone === 'success' ? ['#d1fae5', '#10b981', 'check'] : tone === 'error' ? ['#fee2e2', '#ef4444', 'close'] : ['#cfe9ec', '#1b545e', 'priority_high'];
  return (
    <div className="ka-overlay blur" onClick={onClose} data-tour="status-overlay">
      <div className="ka-status-dialog" onClick={(e) => e.stopPropagation()} data-tour="status-dialog">
        <div className="ka-status-halo" style={{ background: c[0] }}><span style={{ background: c[1] }}><Icon n={c[2]!} /></span></div>
        <h3>{title}</h3>
        <p>{message}</p>
        {button && <button type="button" className="ka-btn primary" data-tour="status-ok" onClick={onClose}>{button}</button>}
      </div>
    </div>
  );
}

export function useCloseTop() {
  return useApp((s) => s.closeDialog);
}
