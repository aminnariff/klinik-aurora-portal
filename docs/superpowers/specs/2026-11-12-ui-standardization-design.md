# Klinik Aurora Portal UI Standardization Design

- **Date**: 2026-11-12
- **Status**: Approved
- **Scope**: `klinik-aurora-portal`

---

## 1. Problem Statement
The Klinik Aurora Portal has visual and architectural drift across modules:
1. **Corner Radius Inconsistency**: 378 elements use 8px, 155 use 10px, 64 use 20px, and theme buttons used a 50px pill radius.
2. **Button Color Fragmentation**:
   - Branch detail submit: Teal (`#0F766E`)
   - Admin detail submit: Indigo (`#4F46E5`)
   - Doctor detail submit: Cyan (`#6AD1E3`)
   - Promotion detail submit: Brand Pink (`#DF6E98`)
   - Secondary / cancel buttons: inconsistent borders and text colors.
3. **Form Field Layout Fragmentation**:
   - Multiple duplicated private helper methods (`_buildTextField`, `_styledTextField`, `_filterTextField`) with differing paddings, borders, container wrappers, and label alignments.

---

## 2. Design Decisions & Tokens

### 2.1 Unified Radius Token
* **Universal Radius**: `8.0` (`BorderRadius.circular(8)`)
* Applied universally across:
  - Form input fields (`OutlineInputBorder` & `BoxDecoration`)
  - Filter and search inputs
  - Action buttons (`ElevatedButton`, `FilledButton`, `OutlinedButton`, `Button`, `AppButton`)
  - Cards and dialog containers

### 2.2 Standard Button Palette & Hierarchy
* **Primary Action** (Save, Create, Submit, Confirm):
  - Background: `primary` (`Color(0xFFDF6E98)`)
  - Text / Icon: `Colors.white`
  - Hover / Active: `primary` with 90% opacity, micro-scale `0.97`
  - Shape: Rounded rectangle with `8px` radius
  - Elevation: `0` (flat modern aesthetic)
* **Secondary Action** (Cancel, Back, Discard):
  - Background: `Colors.white`
  - Border: `BorderSide(color: Color(0xFFCBD5E1))` (Slate-300)
  - Text: `Color(0xFF475569)` (Slate-600), font weight `w600`
  - Shape: Rounded rectangle with `8px` radius
* **Destructive Action** (Delete, Revoke, Deactivate):
  - Background: `Color(0xFFDC2626)` (Red-600)
  - Text / Icon: `Colors.white`
  - Shape: Rounded rectangle with `8px` radius

### 2.3 Form Field Standard Layout
* **Label**: External top label sitting above the input field
  - Typography: `12px`, `FontWeight.w600`, color `Color(0xFF334155)` (Slate-700)
  - Required marker: Red asterisk (`*`) when `isRequired: true`
  - Spacing: `6px` between label and input box
* **Input Box**:
  - Height: `42px` standard for single-line inputs
  - Surface Fill: `Colors.white` when editable, `Color(0xFFF1F5F9)` when disabled/read-only
  - Border: `OutlineInputBorder` with `BorderSide(color: Color(0xFFCBD5E1))`
  - Focused Border: `OutlineInputBorder` with `BorderSide(color: Color(0xFFDF6E98), width: 1.5)`
  - Error Border: `OutlineInputBorder` with `BorderSide(color: Color(0xFFDC2626), width: 1.0)`
  - Content Padding: `EdgeInsets.symmetric(horizontal: 14, vertical: 10)`
  - Text Style: `13px`, `FontWeight.w500`, color `Color(0xFF0F172A)`
  - Hint Style: `12px`, `FontWeight.w400`, color `Color(0xFF94A3B8)`

### 2.4 Filter Bar Field Standard
* **Height**: `40px`
* **Surface Fill**: `Color(0xFFF8FAFC)` (Slate-50)
* **Border**: `OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(0xFFE2E8F0)))`
* **Prefix**: `Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8))`
* **Suffix**: Clear button when query is non-empty.

---

## 3. Shared Component Primitives

### 3.1 `AppFormField`
Location: `lib/views/widgets/input_field/app_form_field.dart`
Properties:
- `String label`
- `TextEditingController? controller`
- `String? hintText`
- `String? errorText`
- `bool isRequired`
- `bool isEditable`
- `bool isNumber`
- `bool isCurrency`
- `bool isPassword`
- `int maxLines`
- `int? maxLength`
- `Widget? prefixIcon`
- `Widget? suffixIcon`
- `void Function(String)? onChanged`
- `void Function(String)? onFieldSubmitted`
- `String? Function(String?)? validator`

### 3.2 `AppFilterField`
Location: `lib/views/widgets/input_field/app_filter_field.dart`
Properties:
- `TextEditingController controller`
- `String hintText`
- `void Function(String)? onChanged`
- `VoidCallback? onClear`
- `double? width`

### 3.3 `AppButton`
Location: `lib/views/widgets/button/app_button.dart`
Variants:
- `AppButton.primary({required String text, required VoidCallback? onPressed, bool isLoading, Widget? icon})`
- `AppButton.secondary({required String text, required VoidCallback? onPressed, Widget? icon})`
- `AppButton.destructive({required String text, required VoidCallback? onPressed, bool isLoading, Widget? icon})`

---

## 4. Global Theme Updates (`lib/config/theme.dart`)
1. Update `inputDecorationTheme`:
   - Radius: `BorderRadius.circular(8)`
   - Border sides: Normal `#E2E8F0`, Focus `#DF6E98` (width 1.5)
2. Update `elevatedButtonTheme`:
   - Radius: `BorderRadius.circular(8)` (replaces `BorderRadius.circular(50)`)
3. Update `cardTheme`:
   - Radius: `BorderRadius.circular(8)`
4. Update legacy widget defaults:
   - `lib/views/widgets/button/button.dart`: default `borderRadius` to `8.0`
   - `lib/views/widgets/button/outlined_button.dart`: default `borderRadius` to `8.0`
   - `lib/views/widgets/input_field/input_field.dart`: default `borderRadius` to `8.0`
   - `lib/views/widgets/card/card_container.dart`: default `borderRadius` to `8.0`

---

## 5. Scope of View Migrations

### Phase A: Core Shared Primitives & Theme
1. Implement `AppFormField`, `AppFilterField`, `AppButton`.
2. Update `theme.dart` and legacy widget defaults.

### Phase B: Detail & Form Views (Primary Button + Field Standardization)
1. `lib/views/branch/branch_detail.dart`: Replace teal submit button with Brand Pink `AppButton.primary`; replace `_buildTextField` with `AppFormField`.
2. `lib/views/admin/admin_detail.dart`: Replace indigo submit button with Brand Pink `AppButton.primary`; replace `_buildTextField` with `AppFormField`.
3. `lib/views/doctor/doctor_detail.dart`: Replace cyan submit button with Brand Pink `AppButton.primary`; replace field inputs with `AppFormField`.
4. `lib/views/promotion/promotion_detail.dart`: Replace `_styledTextField` with `AppFormField`; standardize buttons.
5. `lib/views/voucher/voucher_detail.dart`: Standardize fields and buttons.
6. `lib/views/reward/reward_detail.dart`: Standardize fields and buttons.
7. `lib/views/reward_history/reward_history_detail.dart`: Standardize fields and buttons.
8. `lib/views/service/service_details.dart`: Standardize fields and buttons.
9. `lib/views/user/user_detail.dart`: Standardize fields and buttons.

### Phase C: Homepage Filter Bars & Toolbars
1. `branch_homepage.dart`: Replace `_filterTextField` with `AppFilterField`.
2. `doctor_homepage.dart`: Replace `_filterTextField` with `AppFilterField`.
3. `admin_homepage.dart`: Replace `_filterTextField` with `AppFilterField`.
4. `voucher_homepage.dart`: Replace `_filterTextField` with `AppFilterField`.
5. `reward_homepage.dart`: Replace `_filterTextField` with `AppFilterField`.
6. `reward_history_homepage.dart`: Replace `_filterTextField` with `AppFilterField`.
7. `service_homepage.dart`: Replace `_filterTextField` with `AppFilterField`.
8. `promotion_homepage.dart`: Standardize toolbar and filters.

---

## 6. Verification
- `flutter analyze`: 0 errors, 0 warnings.
- Build test: `flutter build web --release`.
- Visual integrity check across modules.
