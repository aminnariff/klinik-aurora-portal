import { useState } from 'react';
import { useApp } from '../store';
import { BoxSelect, Icon } from '../ui';

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return <div><span className="ka-field-label">{label} <i>*</i></span>{children}</div>;
}

export function RegisterPatientDialog() {
  const { db, closeDialog, addPatient, openDialog } = useApp();
  const [f, setF] = useState({ name: '', phone: '', nric: '', email: '', dob: '', branchId: null as string | null, username: '' });
  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement>) => setF({ ...f, [k]: e.target.value });
  const submit = () => {
    const missing = Object.entries(f).find(([, v]) => !v);
    if (missing) {
      openDialog({ kind: 'status', tone: 'error', title: 'Something Went Wrong', message: 'Please fill in every required field.' });
      return;
    }
    const [d, m, y] = f.dob.split(/[-/]/);
    addPatient({ name: f.name, phone: f.phone, nric: f.nric.replace(/-/g, ''), email: f.email, dob: `${y}-${m}-${d}`, branchId: f.branchId, username: f.username });
    closeDialog();
    openDialog({ kind: 'status', tone: 'success', title: 'Success!', message: 'Patient registered successfully.' });
  };
  return (
    <div className="ka-overlay" onClick={closeDialog}>
      <div className="ka-dialog" style={{ width: 640 }} onClick={(e) => e.stopPropagation()} data-tour="register-dialog">
        <div className="ka-dialog-head">
          <span className="ka-dialog-badge">PT</span>
          <div><h2>Register New Patient</h2><p>Fill details below to register patient</p></div>
          <button type="button" className="ka-dialog-close" onClick={closeDialog}><Icon n="close" /></button>
        </div>
        <div className="ka-dialog-body" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '18px 16px', padding: '22px 20px' }}>
          <Field label="Full Name"><input className="ka-input" data-tour="reg-name" value={f.name} onChange={set('name')} placeholder="e.g. Siti Aminah Binti Yusof" style={{ fontSize: 13 }} /></Field>
          <Field label="Contact Number"><input className="ka-input" data-tour="reg-phone" value={f.phone} onChange={set('phone')} placeholder="e.g. 0123456789 or +60123456789" style={{ fontSize: 13 }} /></Field>
          <Field label="Document ID (NRIC / Passport)"><input className="ka-input" data-tour="reg-nric" value={f.nric} onChange={set('nric')} placeholder="12-digit NRIC or Passport No" style={{ fontSize: 13 }} /></Field>
          <Field label="Email Address"><input className="ka-input" data-tour="reg-email" value={f.email} onChange={set('email')} placeholder="e.g. patient@gmail.com" style={{ fontSize: 13 }} /></Field>
          <Field label="Date of Birth">
            <label className="ka-input" data-tour="reg-dob" style={{ height: 42 }}>
              <input value={f.dob} onChange={set('dob')} placeholder="Select Date of Birth" />
              <Icon n="calendar_today" v="o" size={18} />
            </label>
          </Field>
          <Field label="Registered Branch">
            <BoxSelect tour="reg-branch" bold value={f.branchId} placeholder="Select Branch" onChange={(v) => setF({ ...f, branchId: v })}
              options={db.branches.map((b) => ({ value: b.id, label: b.name }))} />
          </Field>
          <Field label="Username"><input className="ka-input" data-tour="reg-username" value={f.username} onChange={set('username')} placeholder="e.g. sitiaminah" style={{ fontSize: 13 }} /></Field>
        </div>
        <div className="ka-dialog-foot">
          <button type="button" className="ka-btn lg" onClick={closeDialog}>Cancel</button>
          <button type="button" className="ka-btn primary lg" data-tour="reg-submit" onClick={submit}>Register Patient</button>
        </div>
      </div>
    </div>
  );
}
