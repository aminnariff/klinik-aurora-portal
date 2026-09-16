# Spec: Patient Details Popup UI/UX Redesign & Modernization

## 1. Problem Statement
The current patient popup dialog in `lib/views/user/user_detail.dart` suffers from several usability and visual issues:
1. Rigid layout using obsolete `screenWidth1728` screen scaling and `IntrinsicWidth`, resulting in awkward squishing or scrolling on laptop/tablet viewports.
2. Inconsistent styling with the portal's modernized design system (e.g. appointment drawers and analytics dashboards).
3. Derived metadata from Malaysian IC numbers (birth date, age, gender) is not visually highlighted or reactive.
4. The patient actions menu in `user_homepage.dart` labels the booking action ambiguously as "Appointment".

## 2. Goals & Success Criteria
- **Modern Dialog Layout (Option A)**: Replace rigid wrap columns with a polished, centered Flutter `Dialog` (640px max width, 16px corner radius, max 85vh height with clean internal scroll).
- **Patient Profile Header**:
  - Gradient initials avatar circle (e.g. `SA` from full name).
  - Patient Full Name with status badge (`Active` / `Inactive`).
  - Auto-extracted IC chips: Age (`34 yrs`), Gender (`Female`/`Male` calculated from the last digit of Malaysian IC: odd = Male, even = Female), and formatted DOB (`DD-MM-YYYY`).
  - Clean close icon button in the top right.
- **Quick Stats Banner** (in update mode):
  - 3 structured stat chips: Home Branch, Total Appointments count, and Points balance.
- **Responsive 2-Column Form**:
  - Left column: Full Name, Document ID (NRIC / Passport), Date of Birth (auto-filled, tap to override with date picker).
  - Right column: Contact Number (+60 prefix), Email Address, Branch assignment dropdown.
- **Account Controls**:
  - Clean status card with switch toggle (Active vs Deactivated) and descriptive subtext.
  - Reset Password button for existing customer accounts.
- **Menu Label Update**:
  - In `lib/views/user/user_homepage.dart`, update the menu item label from `'Appointment'` to `'Book Appointment'`.
- **Zero regressions**: Form submissions (`createUser`, `updateUser`), phone validation, IC auto-population, and branch assignments work identically or better.

## 3. Detailed Component Architecture

### 3.1 Dialog Container & Layout
- **File**: `lib/views/user/user_detail.dart`
- **Root**: `Dialog` with `backgroundColor: Colors.white`, `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))`, `elevation: 8`.
- **Constraint**: `ConstrainedBox(constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.of(context).size.height * 0.88))`.
- **Internal Structure**:
  - Column with:
    1. Header: Patient Avatar, Name, Status Pill, Metadata row, Close button.
    2. Quick Stats Banner (Update mode only).
    3. Scrollable Body: `SingleChildScrollView` containing the 2-column form grid and status toggle card.
    4. Footer: Fixed bottom action bar with Reset Password (left) and Cancel / Save buttons (right).

### 3.2 IC Auto-Detection Logic
Malaysian IC format: `YYMMDD-PB-###G` (12 digits):
- `YYMMDD`:
  - `YY` >= 30 -> `19YY`, `< 30` -> `20YY`.
  - `MM` and `DD` extracted and validated.
  - Formatted DOB: `DD-MM-YYYY` set in the DOB controller.
  - Age calculated from current year.
- `G` (last digit):
  - `G % 2 != 0` -> Male.
  - `G % 2 == 0` -> Female.
- Dynamic display: reactive badge chips rendered under the patient name immediately when the user types a 12-digit IC.

### 3.3 Form Fields & Styling
- Inputs styled using clean borders (`Color(0xFFE2E8F0)`), subtle focused border (`Color(0xFF0284C7)` or primary brand teal/blue), rounded corners (8px), and 13px font size.
- Input labels clearly distinguished with 11px semi-bold slate color (`Color(0xFF475569)`).
- Required indicators (*) clearly marked on Full Name, Document ID, Contact Number, and Branch.

### 3.4 Menu Action Label Change
- **File**: `lib/views/user/user_homepage.dart`
- In `_actionMenu`:
  - Change `_menuItem('appointment', Icons.calendar_today_outlined, 'Appointment')` to `_menuItem('appointment', Icons.calendar_today_outlined, 'Book Appointment')`.

## 4. Verification & Testing
1. **Static Analysis**: Run `flutter analyze` across `klinik-aurora-portal` to verify 0 errors / 0 warnings.
2. **Form Operations**:
   - Verify creating a new patient: all required validations fire, IC auto-populates DOB and gender chips, form submits and refreshes parent table.
   - Verify updating an existing patient: pre-populates fields, shows quick stats, toggle active/inactive status works, save updates record without error.
3. **Menu Label Verification**: Confirm user homepage action menu displays "Book Appointment".
