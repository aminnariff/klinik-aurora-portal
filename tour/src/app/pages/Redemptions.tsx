import { useState } from 'react';
import { useApp } from '../store';
import { Avatar } from '../ui';
import { Cell2, EditBtn, ListTable, ListToolbar, ToolBtn } from '../kit';
import { fmtStamp } from '../data';

export function Redemptions() {
  const { db, openDialog, highlightId } = useApp();
  const [q, setQ] = useState('');
  const rows = db.claims
    .filter((c) => !q || db.patients.find((p) => p.id === c.patientId)!.name.toLowerCase().includes(q.toLowerCase()))
    .sort((a, b) => (a.status === b.status ? b.at.localeCompare(a.at) : a.status === 'In-Progress' ? -1 : 1));
  return (
    <div className="ka-page" style={{ height: '100%', padding: 0, gap: 0 }}>
      <ListToolbar placeholder="Search by patient name..." value={q} onChange={setQ} tour="redeem-search">
        <ToolBtn icon="filter_list" label="Filter" tone="blue" />
        <ToolBtn icon="refresh" label="Reset" onClick={() => setQ('')} />
      </ListToolbar>
      <ListTable head={['Patient', 'Reward', 'Points Used', 'Status', 'Remark', 'Last Update', { label: 'Actions', width: 90 }]} total={rows.length}>
        {rows.map((c, i) => {
          const p = db.patients.find((x) => x.id === c.patientId)!;
          const r = db.rewards.find((x) => x.id === c.rewardId)!;
          return (
            <tr key={c.id} className={c.id === highlightId ? 'hl' : ''} data-tour={`claim-row-${c.id}`} style={{ height: 64 }}>
              <td><div className="ka-cell-person"><Avatar name={p.name} idx={i + 1} /><Cell2 title={p.name} sub={p.phone} /></div></td>
              <td><Cell2 title={r.name} sub={r.description.split(' ').slice(0, 4).join(' ')} /></td>
              <td><span className="ka-pill blue" style={{ border: '1px solid color-mix(in srgb, currentColor 30%, transparent)' }}>-{r.points} pts</span></td>
              <td><span className={`ka-pill ${c.status === 'Completed' ? 'green' : 'amber'}`}>{c.status}</span></td>
              <td style={{ color: 'var(--ink-2)', fontSize: 13 }}>{c.remark}</td>
              <td style={{ fontSize: 13, color: 'var(--ink-2)' }}>{fmtStamp(c.at)}</td>
              <td><EditBtn tour={`claim-edit-${c.id}`} onClick={() => openDialog({ kind: 'claimUpdate', claimId: c.id })} /></td>
            </tr>
          );
        })}
      </ListTable>
    </div>
  );
}
