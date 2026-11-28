import { useMemo, useState } from 'react';
import { useApp } from '../store';
import { Icon } from '../ui';
import { availableSlots, fmtLongDate, fmtMonthYear, fmtTimeUpper, startOfToday, ymd } from '../data';

/** SelectionCalendarView from lib/views/widgets/calendar/selection_calendar_view.dart */
export function SlotPickerDialog({ serviceId, branchId, onPick }: { serviceId: string; branchId: string; onPick: (slot: string) => void }) {
  const { db, closeDialog } = useApp();
  const slots = useMemo(() => availableSlots(db, serviceId, branchId), [db, serviceId, branchId]);
  const today = startOfToday();
  const [monthOffset, setMonthOffset] = useState(0);
  const [date, setDate] = useState<string | null>(null);
  const [time, setTime] = useState<string | null>(null);
  const view = new Date(today.getFullYear(), today.getMonth() + monthOffset, 1);
  const y = view.getFullYear(), m = view.getMonth();
  const days = new Date(y, m + 1, 0).getDate();
  const start = view.getDay();
  const cells: (number | null)[] = [...Array(start).fill(null), ...Array.from({ length: days }, (_, i) => i + 1)];
  while (cells.length % 7) cells.push(null);
  const weeks = Array.from({ length: cells.length / 7 }, (_, i) => cells.slice(i * 7, i * 7 + 7));
  const todayKey = ymd(today);

  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 560, padding: 20, borderRadius: 12, alignItems: 'center' }} onClick={(e) => e.stopPropagation()} data-tour="slot-dialog">
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <button type="button" className="ka-tb-icon" data-tour="slot-prev" disabled={monthOffset === 0} style={{ opacity: monthOffset === 0 ? .35 : 1 }} onClick={() => setMonthOffset(monthOffset - 1)}><Icon n="chevron_left" /></button>
          <span style={{ fontSize: 16, fontWeight: 700, width: 170, textAlign: 'center' }}>{fmtMonthYear(y, m)}</span>
          <button type="button" className="ka-tb-icon" data-tour="slot-next" disabled={monthOffset >= 1} style={{ opacity: monthOffset >= 1 ? .35 : 1 }} onClick={() => setMonthOffset(monthOffset + 1)}><Icon n="chevron_right" /></button>
        </div>
        <table style={{ borderCollapse: 'collapse', marginTop: 6 }}>
          <thead>
            <tr>{['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((d, i) => <th key={d} style={{ width: 42, padding: 4, fontSize: 14, color: i === 0 || i === 6 ? '#9e9e9e' : 'var(--ink)' }}>{d}</th>)}</tr>
          </thead>
          <tbody>
            {weeks.map((w, i) => (
              <tr key={i}>
                {w.map((d, j) => {
                  if (!d) return <td key={j} style={{ height: 44 }} />;
                  const key = ymd(new Date(y, m, d));
                  const enabled = !!slots[key];
                  const sel = date === key;
                  const isToday = key === todayKey;
                  return (
                    <td key={j} style={{ padding: 4 }}>
                      <button type="button" data-tour={`slot-day-${key}`} disabled={!enabled} onClick={() => { setDate(key); setTime(null); }}
                        style={{ width: 36, height: 36, borderRadius: '50%', border: sel ? '2px solid #2196f3' : 'none', background: sel ? '#bbdefb' : isToday ? '#ffe0b2' : 'transparent', fontSize: 14, fontWeight: sel || isToday ? 700 : 400, color: enabled ? 'var(--ink)' : 'var(--muted)', cursor: enabled ? 'pointer' : 'default', opacity: enabled ? 1 : .55 }}>
                        {d}
                      </button>
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
        {date && (
          <>
            <div style={{ fontSize: 16, fontWeight: 700, margin: '18px 0 10px' }}>{fmtLongDate(date)}</div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12, justifyContent: 'center' }} data-tour="slot-times">
              {slots[date]!.map((t, i) => (
                <button key={t} type="button" data-tour={`slot-time-${i}`} onClick={() => setTime(t)}
                  style={{ height: 40, padding: '0 22px', borderRadius: 20, border: '1px solid #79747e', background: time === t ? '#e3f2fd' : 'transparent', color: 'var(--primary-ink)', fontWeight: 500, fontSize: 14 }}>
                  {fmtTimeUpper(new Date(t))}
                </button>
              ))}
            </div>
          </>
        )}
        <button type="button" data-tour="slot-continue" disabled={!date || !time} onClick={() => { onPick(time!); closeDialog(); }}
          style={{ marginTop: 24, height: 44, padding: '0 40px', borderRadius: 22, border: 'none', fontWeight: 600, fontSize: 14, background: date && time ? '#2196f3' : 'var(--border-strong)', color: date && time ? '#fff' : 'var(--ink-2)', boxShadow: date && time ? '0 2px 4px rgba(0,0,0,.2)' : 'none' }}>
          Continue
        </button>
      </div>
    </div>
  );
}
