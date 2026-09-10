# Technical Design Specification: Portal Dashboard Redesign & Role Specialization

**Date:** 2026-09-11  
**Status:** Approved  
**Target Repositories:**  
- Frontend: `klinik-aurora-portal`  
- Backend: `membership-api`

---

## 1. Problem Statement & Objectives

### Current State
1. **Aesthetic & Color Palette:**
   - The current portal dashboard uses dark slate `#232d37` chart backgrounds and dark/muddy stat card containers (`#2A0D18`, `#0D1A2E`, `#0D2A1D`) which clash heavily with the rest of the light, clean healthcare portal.
   - Using pink/cyan theme colors for complex data visualizations makes charts muddy and hard to read.
2. **One-Size-Fits-All Inadequacy:**
   - Branch admins and Superadmins currently share essentially the same dashboard.
   - Branch admins see global metrics (e.g. "Active Branches: 1", global promotions) instead of real-time clinic operations (today's appointment queue, doctors on duty, today's arrivals).
   - Superadmins lack executive comparison views (branch revenue leaderboard, network growth trajectories).
3. **API Performance:**
   - Current `/admin/dashboard` executes 11 sequential database queries in waterfall fashion.
   - Need to ensure any new queries are lightweight, indexed, and do not put heavy load on the MySQL database.

### Objectives
1. **Eye-Catching, High-Contrast Semantic Colors:**
   - Ditch the muddy pink/cyan theme on dashboard cards and charts.
   - Use clean, standard, high-contrast semantic colors:
     - **Blue (`#2563EB`)**: Appointments, Scheduled bookings, Active metrics.
     - **Green (`#16A34A` / `#15803D`)**: Revenue, Completed visits, Growth rates.
     - **Yellow / Amber (`#D97706` / `#F59E0B`)**: Doctors on duty, In-progress, Attention.
     - **Red (`#DC2626` / `#EF4444`)**: Cancelled, No-shows, Alerts.
   - Clean white cards with crisp `#E2E8F0` borders and deep `#0F172A` text.
2. **Role-Specialized Dashboards:**
   - **Branch Admin:** Clinic Command Center focused on today's appointments, doctor rosters, arrival queue, and branch monthly performance.
   - **Superadmin:** Executive Network Intelligence focused on revenue trends, multi-branch comparisons, patient growth, and service utilization.
3. **Zero Performance Overhead & Zero Regressions:**
   - Parallel `Promise.all` queries with strict composite index coverage.
   - 60-second in-memory cache for heavy network aggregates.
   - Zero breaking changes to existing endpoints.

---

## 2. Visual & Semantic Color System

| Semantic Role | Hex Code | Purpose | Visual Representation |
|---|---|---|---|
| **Card Surface** | `#FFFFFF` | Card backgrounds | Clean white with 1px `#E2E8F0` border |
| **Blue (Primary)** | `#2563EB` | Appointments, Scheduled visits, Main action links | Blue top-bar accent, scheduled chart bars |
| **Green (Success / Revenue)** | `#16A34A` | Completed appointments, Gross revenue, Positive growth | Green top-bar accent, completed chart bars, revenue curve |
| **Yellow / Amber (Operational)** | `#D97706` / `#F59E0B` | Doctors on duty, In-progress consults, Moderate warnings | Amber top-bar accent, duty status indicators |
| **Red (Alert / Inactive)** | `#DC2626` | Cancelled appointments, No-shows, Alerts | Red top-bar accent, warning counts |
| **Deep Text (High Contrast)** | `#0F172A` / `#1E293B` | Numbers, headings, patient names | WCAG AAA contrast |
| **Muted Text** | `#64748B` | Secondary labels, descriptions, timestamps | WCAG AA contrast |

---

## 3. Frontend Architecture (`klinik-aurora-portal`)

### 3.1 Branch Level Dashboard (`BranchDashboardView`)
When `!authController.isSuperAdmin`:

1. **Today's Operational Pulse (4 Stat Cards with Semantic Accent Borders):**
   - **Total Today (Blue):** Total scheduled today (`#2563EB` accent).
   - **Completed (Green):** Count and percentage of completed visits (`#16A34A` accent).
   - **On Duty (Amber):** Count of active doctors scheduled today (`#D97706` accent).
   - **Cancel / No-Show (Red):** Missed visits requiring follow-up (`#DC2626` accent).
2. **7-Day Activity Chart (Weekly Bar Chart):**
   - Light-themed bar chart (`fl_chart`) comparing **Completed (Green `#16A34A`)** vs **Scheduled (Blue `#2563EB`)** bookings over the last 7 days.
3. **Live Upcoming Patient Queue (Today):**
   - Next 5 patients arriving today (Time, Patient Name, Service Name, Doctor).
   - Clean badges with doctor tags.
   - "View Board →" deep link navigating to `/appointment`.
4. **Service Mix Donut Chart:**
   - Clean circular chart showing top 3 booked services + "Others" using high-contrast primary colors (Blue, Green, Yellow).

### 3.2 Superadmin Dashboard (`SuperadminDashboardView`)
When `authController.isSuperAdmin`:

1. **Executive Network KPIs (4 Stat Cards):**
   - **Network Revenue (Green):** Total revenue across all branches + % change vs previous month (`#16A34A`).
   - **Total Appointments (Blue):** Month-to-date network bookings (`#2563EB`).
   - **Active Clinics (Amber):** Operational branches e.g. `8 / 8` (`#F59E0B`).
   - **New Patients (Purple/Blue):** New user accounts created this month (`#7C3AED`).
2. **6-Month Revenue & Booking Trajectory Chart:**
   - Smooth area curve (`fl_chart`) showing monthly network revenue trajectory with green gradient fill (`#16A34A` fading to transparent) and key data points.
3. **Branch Performance Ranking Leaderboard:**
   - Horizontal comparative progress bars ranking all clinics by revenue and appointment volume.
   - High-contrast bars distinguishing top clinics.
4. **Network Top Services Breakdown:**
   - Clean distribution of highest earning treatments across all clinics.

---

## 4. Backend API Design (`membership-api`)

### 4.1 New / Optimized Endpoint: `GET /admin/dashboard/branch-operations`
**Purpose:** Provides real-time operational clinic data for the branch dashboard without heavy aggregates.

- **Access:** Admin authorized. Branch admins are strictly scoped to their `req.user.branchId`. Superadmins can optionally pass `?branchId=...`.
- **Query Optimization:**
  - **Today's stats:** `SELECT count(...) FROM appointment WHERE branch_id = ? AND appointment_datetime BETWEEN CURDATE() AND CURDATE() + INTERVAL 1 DAY AND appointment_is_deleted = 0`.
    - Hits composite index `idx_appt_status_datetime` and `FK_AdminBranch`. Execution time: `< 5ms`.
  - **Upcoming Queue:** `SELECT appointment_datetime, patient_name, service_name, doctor_name FROM ... WHERE branch_id = ? AND appointment_datetime >= NOW() AND appointment_status IN (1, 3) ORDER BY appointment_datetime ASC LIMIT 5`.
    - Hits index, execution time: `< 3ms`.
  - **Doctors on Duty:** Extracted from active roster / assigned doctors for `branch_id`.

### 4.2 Superadmin Optimization: `GET /admin/dashboard`
- **Parallel Query Execution:**
  - Replace sequential `await connection.query(...)` with `Promise.all([ ... ])` across connections in the pool.
- **In-Memory Caching (60-Second TTL):**
  - Network-wide monthly sums (revenueByMonth, totalUser, etc.) are cached in-memory for 60 seconds with cache key `superadmin_dashboard_network`.
  - Eliminates redundant MySQL calculations when admins refresh or multiple admins log in simultaneously.

---

## 5. Verification & Testing Plan

### 5.1 Performance & Load Verification
- Verify execution time of `GET /admin/dashboard/branch-operations` is under `15ms`.
- Verify `EXPLAIN` query plans confirm all queries use indexes without `filesort` or `ALL` table scans.
- Verify 60-second cache hit returns in `< 1ms` on repeat requests.

### 5.2 UI / Layout Verification
- Verify high contrast on all cards and charts under light theme.
- Verify responsive layout: on desktop (multi-column), on tablet/mobile (clean vertical stack).
- Verify role permissions: branch admin never sees cross-branch data; superadmin sees complete network overview.
- Verify zero analyzer errors with `fvm flutter analyze`.
- Verify successful build and deployment.
