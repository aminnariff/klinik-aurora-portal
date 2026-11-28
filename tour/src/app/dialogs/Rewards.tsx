import { useApp } from '../store';
import { Icon } from '../ui';

/** showConfirmDialog — amber question icon, Cancel / Confirm. */
export function ConfirmDialog({ title, message, confirmLabel = 'Confirm', onConfirm }: { title: string; message: string; confirmLabel?: string; onConfirm: () => void }) {
  const close = useApp((s) => s.closeDialog);
  return (
    <div className="ka-overlay blur" onClick={close}>
      <div className="ka-status-dialog" style={{ borderRadius: 28, padding: 32 }} onClick={(e) => e.stopPropagation()} data-tour="confirm-dialog">
        <div className="ka-status-halo" style={{ width: 90, height: 90, background: 'var(--warning-soft)', marginBottom: 22 }}>
          <span style={{ width: 60, height: 60, background: '#f59e0b', boxShadow: '0 8px 16px rgba(245,158,11,.3)' }}><Icon n="help_outline" size={30} /></span>
        </div>
        <h3 style={{ fontWeight: 900, letterSpacing: -0.4, marginBottom: 10 }}>{title}</h3>
        <p style={{ lineHeight: 1.55 }}>{message}</p>
        <div style={{ display: 'flex', gap: 10, marginTop: 26 }}>
          <button type="button" className="ka-btn" style={{ flex: 1, height: 50, borderRadius: 12 }} onClick={close}>Cancel</button>
          <button type="button" className="ka-btn" data-tour="confirm-yes" style={{ flex: 1, height: 50, borderRadius: 12, background: '#07272d', borderColor: '#07272d', color: '#fff', boxShadow: '0 8px 16px rgba(7,39,45,.3)' }} onClick={onConfirm}>{confirmLabel}</button>
        </div>
      </div>
    </div>
  );
}

/** EligibleRewardsPanel claim confirmation (AlertDialog with amber button). */
export function ClaimRewardDialog({ patientId, rewardId, onDone }: { patientId: string; rewardId: string; onDone?: () => void }) {
  const { db, closeDialog, claimReward, showToast } = useApp();
  const p = db.patients.find((x) => x.id === patientId)!;
  const r = db.rewards.find((x) => x.id === rewardId)!;
  const confirm = () => {
    claimReward(patientId, rewardId);
    closeDialog();
    showToast(`${r.name} claimed for ${p.name}`);
    onDone?.();
  };
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-alert" style={{ background: 'var(--surface-elevated)' }} onClick={(e) => e.stopPropagation()} data-tour="claim-dialog">
        <h3><Icon n="card_giftcard" size={22} style={{ color: '#d97706' }} />Claim Reward for Patient?</h3>
        <div style={{ fontSize: 13, fontWeight: 600 }}>Patient: {p.name}</div>
        <div style={{ fontSize: 13.5, fontWeight: 700, color: 'var(--warning-text)', marginTop: 6 }}>Reward: {r.name}</div>
        <div style={{ marginTop: 10, padding: 10, borderRadius: 8, background: 'var(--warning-soft)', border: '1px solid rgba(245,158,11,.45)' }}>
          <div style={{ fontSize: 12.5, fontWeight: 700 }}>Points Deducted: -{r.points} pts</div>
          <div style={{ fontSize: 12, marginTop: 2, color: 'var(--ink-2)' }}>Balance After Claim: {p.points} pts → {p.points - r.points} pts</div>
          <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 4 }}>Reward history will be auto-marked as Completed.</div>
        </div>
        <div className="ka-alert-actions">
          <button type="button" className="ka-text-btn" style={{ color: 'var(--ink-2)' }} onClick={closeDialog}>Cancel</button>
          <button type="button" className="ka-btn amber" data-tour="claim-confirm" onClick={confirm} style={{ fontWeight: 700 }}>Confirm Claim</button>
        </div>
      </div>
    </div>
  );
}

/** _showAwardSuccessDialog in point_homepage.dart */
export function AwardSuccessDialog({ patientId, earned, newTotal }: { patientId: string; earned: number; newTotal: number }) {
  const { db, closeDialog } = useApp();
  const p = db.patients.find((x) => x.id === patientId)!;
  return (
    <div className="ka-overlay">
      <div className="ka-dialog" style={{ width: 440, borderRadius: 16, padding: 24, alignItems: 'center', textAlign: 'center' }} data-tour="award-success">
        <span style={{ width: 52, height: 52, borderRadius: '50%', display: 'grid', placeItems: 'center', background: 'radial-gradient(circle at 35% 30%, #fde68a, #f59e0b 60%, #b45309)', boxShadow: '0 6px 16px rgba(245,158,11,.45)' }}>
          <Icon n="star" size={30} style={{ color: '#fff' }} />
        </span>
        <div style={{ fontSize: 18, fontWeight: 700, marginTop: 14 }}>Points Awarded Successfully!</div>
        <div style={{ fontSize: 13, color: 'var(--ink-2)', marginTop: 6 }}>Awarded +{earned} pts to {p.name}</div>
        <div style={{ marginTop: 16, padding: '12px 16px', borderRadius: 12, background: 'rgba(46,204,64,.1)', border: '1px solid rgba(46,204,64,.3)', width: '100%' }}>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: .5, color: 'var(--green-ink)' }}>NEW TOTAL BALANCE</div>
          <div style={{ fontSize: 20, fontWeight: 800, color: 'var(--green-ink)', marginTop: 2 }}>{newTotal} pts</div>
        </div>
        <div style={{ display: 'flex', gap: 10, width: '100%', marginTop: 18 }}>
          <button type="button" className="ka-btn" style={{ flex: 1, height: 44, color: 'var(--success-text)', borderColor: 'rgba(34,197,94,.45)' }}>
            <Icon n="chat" size={17} />WhatsApp Receipt
          </button>
          <button type="button" className="ka-btn primary" data-tour="award-done" style={{ flex: 1, height: 44 }} onClick={closeDialog}>Done</button>
        </div>
      </div>
    </div>
  );
}
