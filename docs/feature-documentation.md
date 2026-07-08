# Klinik Aurora Admin Portal — Feature Documentation

> **Version:** Production  
> **Platform:** Flutter Web (multi-platform)  
> **State Management:** Provider (ChangeNotifier)  
> **Routing:** go_router (ShellRoute)  
> **Architecture:** Controller + View + Model  

---

## Table of Contents

1. [Authentication & Access](#1-authentication--access)
2. [Dashboard](#2-dashboard)
3. [User Management (Patients)](#3-user-management-patients)
4. [Points Management](#4-points-management)
5. [Appointment Management](#5-appointment-management)
6. [Payment / Finance](#6-payment--finance)
7. [Services Management](#7-services-management)
8. [Admin Management](#8-admin-management)
9. [Branch Management](#9-branch-management)
10. [Doctor / Person In Charge](#10-doctor--person-in-charge)
11. [Promotions](#11-promotions)
12. [Vouchers](#12-vouchers)
13. [Rewards](#13-rewards)
14. [Reward History (Redemption)](#14-reward-history-redemption)
15. [Notifications & Announcements](#15-notifications--announcements)
16. [Legal & Policy Pages](#16-legal--policy-pages)
17. [UI Framework & Navigation](#17-ui-framework--navigation)
18. [Shared Component Library](#18-shared-component-library)
19. [Environments & Build](#19-environments--build)

---

## 1. Authentication & Access

| Page | Route | Description | Screenshot |
|---|---|---|---|
| **Login Page** | `/login` | Admin login with credentials, remember-me toggle | `[Paste screenshot here]` |
| **Password Recovery** | `/password-recovery` | Forgot password flow with token validation | `[Paste screenshot here]` |
| **Permission Guard** | _(middleware)_ | UUID-based RBAC — 11 permission keys + Super Admin role | — |
| **Session Timeout** | _(background)_ | Auto-logout after inactivity (5s configurable) | — |
| **Account Deletion** | `/account-deletion` | Self-service account deletion request | `[Paste screenshot here]` |

**Permission Map:**

| Permission | UUID | Page |
|---|---|---|
| User Management | `1bda631e-ef17-11ee-bd1b-cc801b09db2f` | Patients |
| Admin Management | `4ac042fa-ef2d-11ee-bd1b-cc801b09db2f` | Admins |
| Branch | `68c537d4-ef31-11ee-bd1b-cc801b09db2f` | Branches |
| Point Management | `a231db36-058d-11ef-943b-626efeb17d5e` | Points |
| Voucher | `d98236e8-f490-11ee-befc-aabaa50b463f` | Vouchers |
| Reward Management | `dc4e7a5a-0e15-11ef-82b0-94653af51fb9` | Reward History |
| Promotion | `e7f8bc9e-ef43-11ee-bd1b-cc801b09db2f` | Promotions |
| Doctor | `f90f9f18-057b-11ef-943b-626efeb17d5e` | Person In Charge |
| Rewards | `6e0fe1f8-2f1f-11ef-8db9-6677d190faa2` | Rewards |
| Service | `0699ac1c-ac52-11ef-a1b7-bc24115a1342` | Services |
| Payment Summary | `f57576c4-4d15-11f0-b054-1ff6746392b2` | Payment Report |

---

## 2. Dashboard

**Route:** `/`  
**Sidebar Label:** Dashboard  

| Component | Description | Screenshot |
|---|---|---|
| **Stats Cards** | Total Active Users, Total Active Branches, Total Active Promotions | `[Paste screenshot here]` |
| **Registration Chart** | Last 7 days user registration (daily bar chart) | `[Paste screenshot here]` |
| **Branch Performance Chart** | Branch-level revenue/usage trends (Super Admin only) | `[Paste screenshot here]` |
| **Branch Performance Export** | CSV export of branch performance data | `[Paste screenshot here]` |

> ![Dashboard Layout](Paste full dashboard screenshot here)

---

## 3. User Management (Patients)

**Route:** `/patients`  
**Sidebar Label:** Patients  

| Page | Description | Screenshot |
|---|---|---|
| **Patient List** | Paginated table of all registered users with search & filter | `[Paste screenshot here]` |
| **Patient Detail** | View full profile — name, contact, registration date | `[Paste screenshot here]` |
| **User Points** | Loyalty points balance & history per user | `[Paste screenshot here]` |
| **User Point Detail** | Individual point transaction breakdown | `[Paste screenshot here]` |
| **User Appointment IDs** | All appointment references linked to the user | `[Paste screenshot here]` |

**Actions:** View, search, paginate (15 per page)

---

## 4. Points Management

**Route:** `/points`  
**Sidebar Label:** Points  

| Page | Description | Screenshot |
|---|---|---|
| **Points Overview** | List of point configuration rules & rates | `[Paste screenshot here]` |
| **Create / Edit Point** | Set point earning rate, expiry, and conditions | `[Paste screenshot here]` |

---

## 5. Appointment Management

**Route:** `/appointment`  
**Sidebar Label:** Appointments  

| Page | Description | Screenshot |
|---|---|---|
| **Appointment List** | Full list with status filter (Booked, Cancelled, Rescheduled, Pending Payment, Completed, Refunded, No Show, Transferred) | `[Paste screenshot here]` |
| **Appointment Detail** | Full appointment info — patient, doctor, branch, time, status | `[Paste screenshot here]` |
| **Create Appointment** | Manually book an appointment for a patient | `[Paste screenshot here]` |
| **Date Range Dashboard** | Appointment statistics within a custom date range | `[Paste screenshot here]` |
| **Payment Details** | Payment records associated with the appointment | `[Paste screenshot here]` |
| **Rescan Appointment** | Trigger a rescan/refresh action | `[Paste screenshot here]` |
| **WhatsApp Feature** | WhatsApp integration for appointment reminders & notifications | `[Paste screenshot here]` |

**Appointment Statuses:** Booked, Cancelled, Rescheduled, Pending Payment, Completed, Refunded, No Show, Transferred

---

## 6. Payment / Finance

| Page | Route | Description | Screenshot |
|---|---|---|---|
| **Payment Report** | `/payment-summary` | Aggregated payment data across all branches | `[Paste screenshot here]` |
| **Branch Payment Summary** | `/branch-payment-summary` | Per-branch payment breakdown with date filter (Today / This Week / This Month / Custom Range), interactive charts | `[Paste screenshot here]` |
| **Payment by Appointment** | _(sub-view)_ | Link payments to specific appointment records | `[Paste screenshot here]` |

---

## 7. Services Management

**Route:** `/service`  
**Sidebar Label:** Services  

| Page | Description | Screenshot |
|---|---|---|
| **Service List** | All clinic services with active/inactive status | `[Paste screenshot here]` |
| **Service Details** | Edit service name, description, price, duration | `[Paste screenshot here]` |
| **Service-Branch Mapping** | Assign which branches offer which services | `[Paste screenshot here]` |
| **Service Timing Config** | Configure available time slots per service | `[Paste screenshot here]` |
| **Service Exception Days** | Block-out dates (holidays, closures) per service | `[Paste screenshot here]` |
| **Slot Generator** | Auto-generate appointment time slots from configuration | `[Paste screenshot here]` |

**Sub-view files:** `admin_table.dart`, `service_branch.dart`, `service_detail_timing.dart`, `service_details.dart`, `slot_generator.dart`

---

## 8. Admin Management

**Route:** `/admin`  
**Sidebar Label:** Admins  
**Access:** Super Admin only  

| Page | Description | Screenshot |
|---|---|---|
| **Admin List** | All admin accounts with role & permission summary | `[Paste screenshot here]` |
| **Admin Detail** | Create / edit admin profile, assign granular permissions | `[Paste screenshot here]` |

**Models:** Create, Update, Permission assignment, Bulk response

---

## 9. Branch Management

**Route:** `/branch`  
**Sidebar Label:** Branches  
**Access:** Super Admin only  

| Page | Description | Screenshot |
|---|---|---|
| **Branch List** | All clinic branches with address & status | `[Paste screenshot here]` |
| **Branch Detail** | Edit branch info — name, address, state, contact, operating hours | `[Paste screenshot here]` |
| **Doctor List per Branch** | View & manage doctors/PICs assigned to a branch | `[Paste screenshot here]` |

**Supported States:** Selangor, Johor, Kedah, Kelantan, Kuala Lumpur, Labuan, Melaka, Negeri Sembilan, Pahang, Perak, Perlis, Pulau Pinang, Putrajaya, Sabah, Sarawak, Terengganu

---

## 10. Doctor / Person In Charge (PIC)

**Route:** `/pic`  
**Sidebar Label:** Person In Charge  

| Page | Description | Screenshot |
|---|---|---|
| **PIC List** | All doctors/PICs, filterable by branch | `[Paste screenshot here]` |
| **PIC Detail** | Create / edit doctor profile — name, specialization, assigned branches | `[Paste screenshot here]` |

---

## 11. Promotions

**Route:** `/promotion`  
**Sidebar Label:** Promotions  
**Access:** Super Admin only  

| Page | Description | Screenshot |
|---|---|---|
| **Promotion List** | Active, upcoming, and expired promotions | `[Paste screenshot here]` |
| **Promotion Detail** | Create / edit — type, discount %, validity period, terms | `[Paste screenshot here]` |

---

## 12. Vouchers

**Route:** `/voucher`  
**Sidebar Label:** Vouchers  

| Page | Description | Screenshot |
|---|---|---|
| **Voucher List** | All issued voucher codes with status & usage | `[Paste screenshot here]` |
| **Voucher Detail** | Create / edit voucher — code, value, expiry, usage limit | `[Paste screenshot here]` |

---

## 13. Rewards

**Route:** `/reward`  
**Sidebar Label:** Rewards  

| Page | Description | Screenshot |
|---|---|---|
| **Reward List** | Reward catalog — items available for point redemption | `[Paste screenshot here]` |
| **Reward Detail** | Create / edit reward — name, description, point cost, image, stock | `[Paste screenshot here]` |

---

## 14. Reward History (Redemption)

**Route:** `/reward-history`  
**Sidebar Label:** Manage Rewards  

| Page | Description | Screenshot |
|---|---|---|
| **Redemption List** | All reward redemptions with user, reward, date, status | `[Paste screenshot here]` |
| **Status Filter** | Filter by Completed or In-Progress | `[Paste screenshot here]` |

---

## 15. Notifications & Announcements

| Page | Trigger | Description | Screenshot |
|---|---|---|---|
| **Announcement Dialog** | Top-bar bell icon (Super Admin only) | Send push/email announcements | `[Paste screenshot here]` |

**Channels:**
- `general` — All Users
- `authorised-user-announcements` — Signed In Users Only

---

## 16. Legal & Policy Pages

| Page | Route | Description | Screenshot |
|---|---|---|---|
| **Privacy Policy** | `/privacy-policy` | Full privacy policy with merchant info, payment dispute sections | `[Paste screenshot here]` |
| **Terms & Conditions** | `/terms-and-conditions` | Terms of service document | `[Paste screenshot here]` |
| **Refund / Cancellation Policy** | `/refund-policy` | Refund and cancellation terms | `[Paste screenshot here]` |

These pages link to each other via navigation chips.

---

## 17. UI Framework & Navigation

| Component | Description | Screenshot |
|---|---|---|
| **Sidebar Navigation** | Collapsible sidebar (sidebar_x), dark theme with gradient branding | `[Paste screenshot here]` |
| **Top Bar** | User profile dropdown (name + role), logout, announcement icon | `[Paste screenshot here]` |
| **Mobile Drawer** | Hamburger menu with full nav for mobile/tablet | `[Paste screenshot here]` |
| **User Profile Card** | Sidebar header showing user name, role (Super Admin / Admin), avatar | `[Paste screenshot here]` |
| **Version Badge** | App version displayed at sidebar footer | `[Paste screenshot here]` |

**Design Tokens:**
- **Primary Color:** `#86337c` (magenta-purple)
- **Sidebar BG:** Custom dark `sidebarColor`
- **Typography:** Proxima Nova family, 7 weight/size variants
- **Responsive:** 3 breakpoints — mobile, tablet, desktop
- **Dark Mode:** Full dark theme toggle available

---

## 18. Shared Component Library

Located in `lib/views/widgets/`

| Widget Group | Contents | Description |
|---|---|---|
| **Buttons** | `button/` | Custom styled buttons (elevated, outlined, text) |
| **Calendar** | `calendar/` | Date selection calendar widget |
| **Cards** | `card/` | Reusable card containers |
| **Charts** | `charts/` | Line chart with configurable attributes (fl_chart) |
| **Checkbox** | `checkbox/` | Styled checkbox inputs |
| **Date Picker** | `date_picker/` | Date picker & range selector |
| **Dialogs** | `dialog/` | Modal dialog components |
| **Dropdown** | `dropdown/` | Dropdown select with attribute model |
| **Input Fields** | `input_field/` | Form input fields with validation |
| **Layout** | `layout/` | Responsive layout wrappers (mobile/tablet/desktop) |
| **No Records** | `no_records/` | Empty state display component |
| **Read Only** | `read_only/` | Read-only text display |
| **Selectable Text** | `selectable_text/` | Selectable/copyable text widget |
| **Shimmer** | `shimmer/` | Loading shimmer placeholders |
| **Switch** | `switch/` | Toggle switch component |
| **Table** | `table/` | Data table with pagination |
| **Toast** | `toast/` | Success/error toast notifications |
| **Tooltip** | `tooltip/` | Hover tooltips |
| **Typography** | `typography/` | `AppTypography` helper — consistent text styles |
| **Upload Document** | `upload_document/` | File upload (jpg, jpeg, pdf, png, max 1MB) |
| **Debouncer** | `debouncer/` | Input debounce utility |
| **Extension** | `extension/` | Dart extension helpers |
| **Global** | `global/` | Shared global widgets |
| **Launcher** | `launcher/` | External URL/mail launcher |
| **Padding** | `padding/` | Consistent spacing helpers |
| **Size** | `size.dart` | Screen dimension utilities |

---

## 19. Environments & Build

| Environment | Entry Point | Build Command |
|---|---|---|
| **Production** | `lib/main.dart` | `flutter build web -t lib/main.dart` |
| **Staging** | `lib/main_staging.dart` | `flutter build web -t lib/main_staging.dart` |
| **Development** | `lib/main.dart` | `flutter build web -t lib/main.dart` |

**Firebase Deploy Targets:**
```
# Admin Portal
firebase deploy --project klinik-aurora

# Password Recovery site
firebase deploy --project klinik-aurora-recovery

# Get Klinik Aurora (public)
firebase deploy --project get-klinik-aurora
```

**Dependencies (key packages):**
- `go_router` — Declarative routing
- `provider` — State management
- `sidebar_x` — Sidebar navigation
- `fl_chart` — Charts & graphs
- `easy_localization` — i18n
- `flutter_screenutil` — Responsive sizing
- `font_awesome_flutter` — Icons
- `intl` — Date/number formatting
- `flutter_easyloading` — Loading indicators
- `fluttertoast` — Toast messages

---

## Appendix: Route Map

| # | Route | Page | Permission Required | Super Admin Only |
|---|---|---|---|---|
| 1 | `/login` | Login Page | — | — |
| 2 | `/password-recovery` | Password Recovery | — | — |
| 3 | `/` | Dashboard | — | — |
| 4 | `/patients` | User Homepage | ✅ | — |
| 5 | `/points` | Point Homepage | ✅ | — |
| 6 | `/appointment` | Appointment Homepage | — | — |
| 7 | `/payment-summary` | Payment Report | ✅ | — |
| 8 | `/branch-payment-summary` | Branch Payment Summary | ✅ | ✅ |
| 9 | `/service` | Service Homepage | ✅ | — |
| 10 | `/admin` | Admin Homepage | ✅ | ✅ |
| 11 | `/branch` | Branch Homepage | ✅ | ✅ |
| 12 | `/pic` | Doctor Homepage | ✅ | — |
| 13 | `/promotion` | Promotion Homepage | ✅ | ✅ |
| 14 | `/voucher` | Voucher Homepage | ✅ | — |
| 15 | `/reward` | Reward Homepage | ✅ | — |
| 16 | `/reward-history` | Reward History | ✅ | — |
| 17 | `/privacy-policy` | Privacy Policy | — | — |
| 18 | `/terms-and-conditions` | Terms & Conditions | — | — |
| 19 | `/refund-policy` | Refund Policy | — | — |
| 20 | `/account-deletion` | Account Deletion | — | — |

---

*Document generated from codebase analysis. Screenshot placeholders marked as `[Paste screenshot here]` — replace with actual screenshots for the final PDF.*
