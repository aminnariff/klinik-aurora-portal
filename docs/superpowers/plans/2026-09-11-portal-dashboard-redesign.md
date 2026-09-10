# Portal Dashboard Redesign & Role Specialization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul the portal dashboard from dark, muddy styling into clean, high-contrast, semantic-colored views (Blue, Green, Yellow, Red) specialized for Branch Admins (Clinic Operations Command Center) and Superadmins (Executive Network Intelligence), backed by an ultra-fast indexed backend endpoint with zero regression risk.

**Architecture:** Split the dashboard into two role-tailored views: `BranchDashboardView` (today's operations, live queue, doctor roster, weekly activity) and `SuperadminDashboardView` (network revenue curve, branch leaderboard, patient growth, service distribution). Add an indexed, parallelized `GET /admin/dashboard/branch-operations` endpoint in `membership-api` and optimize `GET /admin/dashboard` with `Promise.all` and a 60s in-memory cache.

**Tech Stack:** 
- Frontend: Flutter Web, `fl_chart`, Provider, GoRouter, `intl`
- Backend: Express.js, TypeScript, MySQL (mysql2/promise)

---

## File Map

### Backend (`membership-api`)
- Create: `admin/dashboard/get-branch-operations.ts` (lightweight operational endpoint)
- Modify: `admin/dashboard/index.ts` (register `/branch-operations` route)
- Modify: `admin/dashboard/get-dashboard.ts` (parallelize with `Promise.all`, add 60s memory cache)

### Frontend (`klinik-aurora-portal`)
- Create: `lib/models/dashboard/branch_operations_response.dart` (model for branch operations)
- Create: `lib/controllers/dashboard/branch_operations_controller.dart` (controller for branch operations)
- Create: `lib/views/homepage/widgets/dashboard_metric_card.dart` (reusable clean white metric card with semantic accents)
- Create: `lib/views/homepage/branch_dashboard_view.dart` (branch clinic operations dashboard)
- Create: `lib/views/homepage/superadmin_dashboard_view.dart` (superadmin network intelligence dashboard)
- Modify: `lib/views/homepage/dashboard.dart` (role-based router between Branch and Superadmin views)
- Modify: `lib/main.dart` (register `BranchOperationsController` provider)

---

## Tasks

### Task 1: Backend Branch Operations Endpoint (`GET /admin/dashboard/branch-operations`)

**Files:**
- Create: `/Users/aminariff/Documents/Github/membership-api/admin/dashboard/get-branch-operations.ts`
- Modify: `/Users/aminariff/Documents/Github/membership-api/admin/dashboard/index.ts`

- [ ] **Step 1: Write `get-branch-operations.ts`**
  - Implement query handlers for:
    1. Today's summary counts (Total, Completed, Upcoming, Cancelled, No-Show) filtered by `branch_id` and `CURDATE()`.
    2. Next 5 upcoming appointments today (`ORDER BY appointment_datetime ASC LIMIT 5`) joining patient, service, and doctor.
    3. Doctors on duty today for the branch.
    4. Last 7 days completed vs scheduled counts for weekly chart.
    5. Top 3 services booked this month at the branch.
  - Run all queries in parallel with `Promise.all`.
  - Ensure execution time is under `10ms`.

- [ ] **Step 2: Register route in `admin/dashboard/index.ts`**
  - Add `dashboardRouter.get("/branch-operations", getBranchOperations);`

- [ ] **Step 3: Compile TypeScript & Verify Backend**
  - Run `npm run build` in `membership-api`.
  - Verify zero TypeScript compiler errors.

---

### Task 2: Backend Superadmin Dashboard Optimization

**Files:**
- Modify: `/Users/aminariff/Documents/Github/membership-api/admin/dashboard/get-dashboard.ts`

- [ ] **Step 1: Refactor queries to run in parallel using `Promise.all`**
  - Group queries into a single `Promise.all` invocation.

- [ ] **Step 2: Add 60-second in-memory cache for network superadmin aggregates**
  - Cache payload for 60 seconds when `!effectiveBranchId`.
  - Invalidate automatically on TTL expiry.

- [ ] **Step 3: Compile TypeScript & Verify**
  - Run `npm run build` in `membership-api`.

---

### Task 3: Frontend Model & Controller for Branch Operations

**Files:**
- Create: `/Users/aminariff/Documents/Github/klinik-aurora-portal/lib/models/dashboard/branch_operations_response.dart`
- Create: `/Users/aminariff/Documents/Github/klinik-aurora-portal/lib/controllers/dashboard/branch_operations_controller.dart`
- Modify: `/Users/aminariff/Documents/Github/klinik-aurora-portal/lib/main.dart`

- [ ] **Step 1: Create `branch_operations_response.dart`**
  - JSON serialization for today's summary, next patients, weekly stats, and top services.

- [ ] **Step 2: Create `branch_operations_controller.dart`**
  - Method `static Future<ApiResponse<BranchOperationsResponse>> get(BuildContext context, {String? branchId})`.

- [ ] **Step 3: Register `BranchOperationsController` in `lib/main.dart`**
  - Add `ChangeNotifierProvider<BranchOperationsController>(create: (_) => BranchOperationsController())`.

---

### Task 4: Reusable High-Contrast Metric Card Widget

**Files:**
- Create: `/Users/aminariff/Documents/Github/klinik-aurora-portal/lib/views/homepage/widgets/dashboard_metric_card.dart`

- [ ] **Step 1: Implement `DashboardMetricCard`**
  - White container (`#FFFFFF`), rounded 10px, 1px `#E2E8F0` border, subtle shadow.
  - Colored top accent line (Blue `#2563EB`, Green `#16A34A`, Amber `#D97706`, Red `#DC2626`).
  - High-contrast typography: Dark slate `#0F172A` value (20px, w800), muted label `#64748B` (10px, w700 uppercase).
  - Subtitle badge / trend indicator.

---

### Task 5: Branch Clinic Operations View (`BranchDashboardView`)

**Files:**
- Create: `/Users/aminariff/Documents/Github/klinik-aurora-portal/lib/views/homepage/branch_dashboard_view.dart`

- [ ] **Step 1: Implement Today's Operations KPI Row**
  - Total Today (Blue), Completed (Green), On Duty (Amber), Cancel / No-Show (Red).

- [ ] **Step 2: Implement 7-Day Activity Chart**
  - Clean light-mode `fl_chart` BarChart showing Green (Completed) and Blue (Scheduled) bars.

- [ ] **Step 3: Implement Live Upcoming Patient Queue**
  - Next 5 patients today with arrival time, patient name, service, and doctor tag.
  - "View Appointment Board →" button routing to `/appointment`.

- [ ] **Step 4: Implement Service Mix Donut Chart**
  - Clean circular `fl_chart` PieChart using Blue, Green, Amber for top services.

---

### Task 6: Superadmin Network Intelligence View (`SuperadminDashboardView`)

**Files:**
- Create: `/Users/aminariff/Documents/Github/klinik-aurora-portal/lib/views/homepage/superadmin_dashboard_view.dart`

- [ ] **Step 1: Implement Executive Network KPIs Row**
  - Total Revenue (Green), Appointments (Blue), Active Clinics (Amber), New Patients (Purple).

- [ ] **Step 2: Implement 6-Month Revenue & Booking Trajectory Chart**
  - Clean smooth area `fl_chart` LineChart with green gradient fill (`#16A34A` to transparent).

- [ ] **Step 3: Implement Branch Performance Ranking Leaderboard**
  - Horizontal progress bars ranking branches by revenue and appointments.

- [ ] **Step 4: Implement Network Top Services Breakdown**
  - Clean ranking of highest grossing services.

---

### Task 7: Update `MainDashboard` Entrypoint

**Files:**
- Modify: `/Users/aminariff/Documents/Github/klinik-aurora-portal/lib/views/homepage/dashboard.dart`

- [ ] **Step 1: Wire role switching**
  - If `context.read<AuthController>().isSuperAdmin`: render `SuperadminDashboardView()`.
  - Else: render `BranchDashboardView()`.
  - Fetch respective controllers cleanly on init.

- [ ] **Step 2: Test responsiveness**
  - Desktop multi-column vs Mobile stacked layout.

---

### Task 8: Verification, Build & Deployment

- [ ] **Step 1: Run `fvm flutter analyze`**
  - Verify 0 errors, 0 warnings.
- [ ] **Step 2: Build portal web release**
  - Run `fvm flutter build web --release`.
- [ ] **Step 3: Deploy to Firebase Hosting production**
  - Run `firebase deploy --only hosting:production`.
- [ ] **Step 4: Compile & deploy backend if required**
