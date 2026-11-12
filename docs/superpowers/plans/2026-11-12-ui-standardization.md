# Klinik Aurora Portal UI Standardization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Standardize all portal input fields (top label, white surface, 8px radius, consistent border & focus state), action buttons (Brand Pink `#DF6E98` primary, Outlined Slate `#CBD5E1` secondary, Red `#DC2626` destructive, 8px radius), and search filter bars across modules.

**Architecture:** Create three core shared primitives (`AppFormField`, `AppFilterField`, `AppButton`), update global theme tokens in `theme.dart` and legacy widgets to 8px radius, and migrate detail views and homepage filters away from ad-hoc private helpers to shared components.

**Tech Stack:** Flutter Web (Dart 3.x), Material 3, `klinik_aurora_portal` design system.

---

### Task 1: Create Shared Component Primitives

**Files:**
- Create: `lib/views/widgets/input_field/app_form_field.dart`
- Create: `lib/views/widgets/input_field/app_filter_field.dart`
- Create: `lib/views/widgets/button/app_button.dart`

- [ ] **Step 1: Create `AppFormField`**
Implement the canonical form input widget with top label, optional required asterisk, 8px radius, 42px single-line height, `#CBD5E1` border, `#DF6E98` focus border, error border, password visibility toggle, and text formatting.

- [ ] **Step 2: Create `AppFilterField`**
Implement the canonical table filter/search input with 40px height, `#F8FAFC` fill, 8px radius, `#E2E8F0` border, search icon prefix, and clear button suffix.

- [ ] **Step 3: Create `AppButton`**
Implement canonical button supporting `.primary` (Brand Pink `#DF6E98`), `.secondary` (Outlined Slate `#CBD5E1`), and `.destructive` (Red `#DC2626`) variants with 8px radius, micro-scale press feedback, and built-in loading indicator.

- [ ] **Step 4: Verify static analysis on new widgets**
Run: `flutter analyze lib/views/widgets/`
Expected: 0 errors.

- [ ] **Step 5: Commit primitives**
```bash
git add lib/views/widgets/input_field/app_form_field.dart lib/views/widgets/input_field/app_filter_field.dart lib/views/widgets/button/app_button.dart
git commit -m "feat(ui): add AppFormField, AppFilterField, and AppButton primitives"
```

---

### Task 2: Standardize Global Theme and Legacy Widgets

**Files:**
- Modify: `lib/config/theme.dart`
- Modify: `lib/views/widgets/button/button.dart`
- Modify: `lib/views/widgets/button/outlined_button.dart`
- Modify: `lib/views/widgets/input_field/input_field.dart`
- Modify: `lib/views/widgets/card/card_container.dart`

- [ ] **Step 1: Update `lib/config/theme.dart`**
Change `inputDecorationTheme` radius from 10 to 8. Change `elevatedButtonTheme` radius from 50 to 8. Add `outlinedButtonTheme` and `filledButtonTheme` with 8px radius. Set `cardTheme` radius to 8px.

- [ ] **Step 2: Update legacy widget defaults**
In `Button`: change `widget.borderRadius ?? 20.0` to `8.0`.
In `AppOutlinedButton`: change `widget.borderRadius ?? 50` to `8.0`.
In `InputField`: change `BorderRadius.circular(10.0)` to `8.0`.
In `CardContainer`: change `borderRadius ?? 15` to `8.0`.

- [ ] **Step 3: Run static analysis**
Run: `flutter analyze lib/config/ lib/views/widgets/`
Expected: 0 errors.

- [ ] **Step 4: Commit theme and legacy defaults**
```bash
git add lib/config/theme.dart lib/views/widgets/button/button.dart lib/views/widgets/button/outlined_button.dart lib/views/widgets/input_field/input_field.dart lib/views/widgets/card/card_container.dart
git commit -m "style(theme): standardize global theme and legacy widget radii to 8px"
```

---

### Task 3: Migrate Branch Module

**Files:**
- Modify: `lib/views/branch/branch_detail.dart`
- Modify: `lib/views/branch/branch_homepage.dart`

- [ ] **Step 1: Refactor `branch_detail.dart`**
Replace private `_buildTextField` calls with `AppFormField`. Replace teal submit button (`#0F766E`) and cancel button with `AppButton.primary` (Brand Pink `#DF6E98`) and `AppButton.secondary`.

- [ ] **Step 2: Refactor `branch_homepage.dart`**
Replace private `_filterTextField` with `AppFilterField`. Ensure toolbar and dialog buttons use 8px radius.

- [ ] **Step 3: Run static analysis on branch views**
Run: `flutter analyze lib/views/branch/`
Expected: 0 errors.

- [ ] **Step 4: Commit Branch migration**
```bash
git add lib/views/branch/
git commit -m "refactor(branch): standardize fields and buttons to AppFormField and AppButton"
```

---

### Task 4: Migrate Admin Module

**Files:**
- Modify: `lib/views/admin/admin_detail.dart`
- Modify: `lib/views/admin/admin_homepage.dart`

- [ ] **Step 1: Refactor `admin_detail.dart`**
Replace private `_buildTextField` calls with `AppFormField`. Replace indigo submit button (`#4F46E5`) with `AppButton.primary` (Brand Pink `#DF6E98`) and cancel with `AppButton.secondary`.

- [ ] **Step 2: Refactor `admin_homepage.dart`**
Replace `_filterTextField` with `AppFilterField`. Standardize toolbar buttons to 8px radius.

- [ ] **Step 3: Run static analysis on admin views**
Run: `flutter analyze lib/views/admin/`
Expected: 0 errors.

- [ ] **Step 4: Commit Admin migration**
```bash
git add lib/views/admin/
git commit -m "refactor(admin): standardize fields and buttons to AppFormField and AppButton"
```

---

### Task 5: Migrate Doctor Module

**Files:**
- Modify: `lib/views/doctor/doctor_detail.dart`
- Modify: `lib/views/doctor/doctor_homepage.dart`

- [ ] **Step 1: Refactor `doctor_detail.dart`**
Standardize inputs with `AppFormField`. Replace cyan submit button (`secondaryColor`) with `AppButton.primary` (Brand Pink `#DF6E98`) and cancel with `AppButton.secondary`.

- [ ] **Step 2: Refactor `doctor_homepage.dart`**
Replace `_filterTextField` with `AppFilterField`. Standardize toolbar buttons to 8px radius.

- [ ] **Step 3: Run static analysis on doctor views**
Run: `flutter analyze lib/views/doctor/`
Expected: 0 errors.

- [ ] **Step 4: Commit Doctor migration**
```bash
git add lib/views/doctor/
git commit -m "refactor(doctor): standardize fields and buttons to AppFormField and AppButton"
```

---

### Task 6: Migrate Promotion & Voucher Modules

**Files:**
- Modify: `lib/views/promotion/promotion_detail.dart`
- Modify: `lib/views/promotion/promotion_homepage.dart`
- Modify: `lib/views/voucher/voucher_detail.dart`
- Modify: `lib/views/voucher/voucher_homepage.dart`

- [ ] **Step 1: Refactor `promotion_detail.dart` & `promotion_homepage.dart`**
Replace `_styledTextField` with `AppFormField` and `AppFilterField`. Standardize dialog and action buttons to `AppButton`.

- [ ] **Step 2: Refactor `voucher_detail.dart` & `voucher_homepage.dart`**
Replace `_styledTextField` and `_filterTextField` with `AppFormField` and `AppFilterField`. Standardize submit and cancel buttons to `AppButton`.

- [ ] **Step 3: Run static analysis on promotion and voucher views**
Run: `flutter analyze lib/views/promotion/ lib/views/voucher/`
Expected: 0 errors.

- [ ] **Step 4: Commit Promotion and Voucher migration**
```bash
git add lib/views/promotion/ lib/views/voucher/
git commit -m "refactor(promotion,voucher): standardize fields and buttons to AppFormField and AppButton"
```

---

### Task 7: Migrate Reward, Service & User Modules

**Files:**
- Modify: `lib/views/reward/reward_detail.dart`
- Modify: `lib/views/reward/reward_homepage.dart`
- Modify: `lib/views/reward_history/reward_history_detail.dart`
- Modify: `lib/views/reward_history/reward_history_homepage.dart`
- Modify: `lib/views/service/service_details.dart`
- Modify: `lib/views/service/service_homepage.dart`
- Modify: `lib/views/user/user_detail.dart`

- [ ] **Step 1: Refactor Reward & Reward History views**
Replace `_styledTextField` and `_filterTextField` with `AppFormField` and `AppFilterField`. Standardize buttons to `AppButton`.

- [ ] **Step 2: Refactor Service views**
Replace `_styledTextField` and `_filterTextField` in `service_details.dart` and `service_homepage.dart` with `AppFormField` and `AppFilterField`. Standardize buttons to `AppButton`.

- [ ] **Step 3: Refactor `user_detail.dart`**
Replace `_buildTextField` with `AppFormField`. Standardize footer actions to `AppButton`.

- [ ] **Step 4: Run static analysis on reward, service, and user views**
Run: `flutter analyze lib/views/reward/ lib/views/reward_history/ lib/views/service/ lib/views/user/`
Expected: 0 errors.

- [ ] **Step 5: Commit Reward, Service, and User migrations**
```bash
git add lib/views/reward/ lib/views/reward_history/ lib/views/service/ lib/views/user/
git commit -m "refactor(reward,service,user): standardize fields and buttons to AppFormField and AppButton"
```

---

### Task 8: Full Portal Verification & Release Build

**Files:**
- Verify: Full repository

- [ ] **Step 1: Run full static analysis**
Run: `flutter analyze`
Expected: 0 issues found.

- [ ] **Step 2: Run web release build**
Run: `flutter build web --release`
Expected: Successful compile with 0 errors.

- [ ] **Step 3: Verification commit & summary**
Commit any formatting/cleanup changes and verify all modules standardized to 8px radius, Brand Pink `#DF6E98` primary buttons, and unified form field layouts.
