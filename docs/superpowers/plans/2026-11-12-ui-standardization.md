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

- [x] **Step 1: Create `AppFormField`**

- [x] **Step 2: Create `AppFilterField`**

- [x] **Step 3: Create `AppButton`**

- [x] **Step 4: Verify static analysis on new widgets**

- [x] **Step 5: Commit primitives**
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

- [x] **Step 1: Update `lib/config/theme.dart`**

- [x] **Step 2: Update legacy widget defaults**

- [x] **Step 3: Run static analysis**

- [x] **Step 4: Commit theme and legacy defaults**
```bash
git add lib/config/theme.dart lib/views/widgets/button/button.dart lib/views/widgets/button/outlined_button.dart lib/views/widgets/input_field/input_field.dart lib/views/widgets/card/card_container.dart
git commit -m "style(theme): standardize global theme and legacy widget radii to 8px"
```

---

### Task 3: Migrate Branch Module

**Files:**
- Modify: `lib/views/branch/branch_detail.dart`
- Modify: `lib/views/branch/branch_homepage.dart`

- [x] **Step 1: Refactor `branch_detail.dart`**
- [x] **Step 2: Refactor `branch_homepage.dart`**
- [x] **Step 3: Run static analysis on branch views**
- [x] **Step 4: Commit Branch migration**

---

### Task 4: Migrate Admin Module

**Files:**
- Modify: `lib/views/admin/admin_detail.dart`
- Modify: `lib/views/admin/admin_homepage.dart`

- [x] **Step 1: Refactor `admin_detail.dart`**
- [x] **Step 2: Refactor `admin_homepage.dart`**
- [x] **Step 3: Run static analysis on admin views**
- [x] **Step 4: Commit Admin migration**

---

### Task 5: Migrate Doctor Module

**Files:**
- Modify: `lib/views/doctor/doctor_detail.dart`
- Modify: `lib/views/doctor/doctor_homepage.dart`

- [x] **Step 1: Refactor `doctor_detail.dart`**
- [x] **Step 2: Refactor `doctor_homepage.dart`**
- [x] **Step 3: Run static analysis on doctor views**
- [x] **Step 4: Commit Doctor migration**

---

### Task 6: Migrate Promotion & Voucher Modules

**Files:**
- Modify: `lib/views/promotion/promotion_detail.dart`
- Modify: `lib/views/promotion/promotion_homepage.dart`
- Modify: `lib/views/voucher/voucher_detail.dart`
- Modify: `lib/views/voucher/voucher_homepage.dart`

- [x] **Step 1: Refactor `promotion_detail.dart` & `promotion_homepage.dart`**
- [x] **Step 2: Refactor `voucher_detail.dart` & `voucher_homepage.dart`**
- [x] **Step 3: Run static analysis on promotion and voucher views**
- [x] **Step 4: Commit Promotion and Voucher migration**

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

- [x] **Step 1: Refactor Reward & Reward History views**
- [x] **Step 2: Refactor Service views**
- [x] **Step 3: Refactor `user_detail.dart`**
- [x] **Step 4: Run static analysis on reward, service, and user views**
- [x] **Step 5: Commit Reward, Service, and User migrations**

---

### Task 8: Full Portal Verification & Release Build

**Files:**
- Verify: Full repository

- [x] **Step 1: Run full static analysis**
- [x] **Step 2: Run web release build**
- [x] **Step 3: Verification commit & summary**
