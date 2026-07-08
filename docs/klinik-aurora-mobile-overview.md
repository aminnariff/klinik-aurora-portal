# Klinik Aurora — Patient Mobile App

> The patient-facing companion to Klinik Aurora Portal. Book appointments, track health, earn rewards, and manage your clinic visits — all from your phone.

---

## What It Does

Klinik Aurora Mobile is the app your patients download. They can browse branches and services, book and pay for appointments, earn loyalty points, redeem rewards, track pregnancy health, and receive push notifications — without ever calling the clinic.

---

## Feature Overview

### 1. Onboarding & Security Checkpoint

When a user opens the app, a security checkpoint runs first:

- Checks the app version against the minimum required version
- Prompts update if the app is outdated
- Routes to login or landing page based on session state

> `[Screenshot: Security checkpoint / version update screen]`

---

### 2. Authentication

| Feature | Details |
|---|---|
| **Login** | Email + password with secure token storage |
| **Sign Up** | New patient registration with profile creation |
| **Forgot Password** | Token-based password reset flow |
| **Remember Me** | Persistent login session |
| **Account Deletion** | Self-service deletion request |

> `[Screenshot: Login page]`
> `[Screenshot: Sign up / registration form]`
> `[Screenshot: Forgot password flow]`

---

### 3. Home Dashboard

The main hub patients see after logging in:

- **Upcoming appointment card** — next booked appointment with countdown
- **Quick action buttons** — Book Appointment, View Branches, My Points
- **Promotion carousel** — scrollable banners of active promotions
- **Notification bell** — badge count of unread notifications
- **Pull-to-refresh** — reload all data

> `[Screenshot: Home dashboard with upcoming appointment + promotion carousel]`
> `[Screenshot: Promotion carousel expanded view]`

---

### 4. Branches

Browse all clinic locations:

- List view of all branches with addresses
- Tap to view branch details (contact, operating hours, services offered)
- Branch detail page with full info

> `[Screenshot: Branch list]`
> `[Screenshot: Branch detail page]`

---

### 5. Services & Booking

Full service catalog and appointment booking flow:

- **Services List** — Browse all available treatments and consultations
- **Branch Services** — See which services a specific branch offers
- **Appointment Eligibility** — Check eligibility before booking
- **Review Clinic** — Select branch, service, doctor/PIC, and time slot
- **Booking Flow** — Step-by-step: service → branch → doctor → date/time → confirm
- **Upcoming Appointments** — View all booked appointments with status

> `[Screenshot: Services list screen]`
> `[Screenshot: Branch services view]`
> `[Screenshot: Appointment booking flow — select service, branch, date/time]`
> `[Screenshot: Appointment confirmation]`

---

### 6. Appointment Management

Manage all appointments from one screen:

- View upcoming and past appointments
- Appointment statuses: Booked, Cancelled, Rescheduled, Completed, No Show
- **Appointment Details** — Full details: branch, doctor, service, time, payment
- **Payment Details** — View payment breakdown per appointment
- **Reschedule / Cancel** — Directly modify appointments

> `[Screenshot: Appointment list with status tabs]`
> `[Screenshot: Appointment detail screen]`

---

### 7. Payments

Secure in-app payment processing:

- **Payment Methods** — Select payment method (card, online banking, etc.)
- **Payment Webview** — Secure payment gateway embedded in the app
- **Payment Transition** — Loading/processing state while payment completes
- **Payment Receipt** — Digital receipt after successful payment
- **Payment History** — View past payment transactions

> `[Screenshot: Payment method selection]`
> `[Screenshot: Payment webview / gateway]`
> `[Screenshot: Payment receipt]`

---

### 8. Loyalty Points

A dedicated points dashboard:

- View current points balance
- Points earned from appointments and promotions
- Points history with transaction log
- Promotional bonus points displayed as promo cards

> `[Screenshot: Points dashboard with balance and history]`

---

### 9. Rewards & Redemption

Redeem points for rewards:

- **Rewards Catalog** — Browse available rewards (items, vouchers, discounts)
- **Redemption Flow** — Select reward, confirm point deduction, claim
- **Redemption History** — Track claimed rewards and delivery status

> `[Screenshot: Rewards catalog]`
> `[Screenshot: Reward redemption confirmation]`

---

### 10. Vouchers

View and use discount vouchers:

- List of all earned/available vouchers
- Voucher details — code, value, expiry date, terms
- Apply vouchers during appointment booking or payment

> `[Screenshot: Voucher list]`
> `[Screenshot: Voucher detail]`

---

### 11. Promotions

Stay informed about clinic promotions:

- **Promotions List** — All active promotions
- **Promotion Detail** — Full terms, discount info, validity period
- **Promotion Carousel** — Featured promotions on home screen

> `[Screenshot: Promotions list]`
> `[Screenshot: Promotion detail page]`

---

### 12. Baby Tracker (Pregnancy Health)

A dedicated maternal health tracking module:

- Track pregnancy weeks and milestones
- **Baby Kick Session Timer** — Count and time fetal movements
- Visual charts and progress indicators
- Health tips and reminders

> `[Screenshot: Baby tracker dashboard]`
> `[Screenshot: Baby kick session timer]`

---

### 13. Appointment History

Complete history of all past appointments:

- Filter by status (Completed, Cancelled, No Show)
- View details of each past visit
- Re-book a previous appointment quickly

> `[Screenshot: Appointment history with filters]`

---

### 14. Profile & Settings

Full profile management:

- **Profile Details** — Edit name, phone, email, date of birth
- **Profile Homepage** — Profile summary with quick links to settings
- **Settings** — Dark mode toggle, notifications, app preferences
- **Referral Code** — Share referral code, view referral terms
- **Rate the App** — In-app review prompt
- **Logout** — Secure session termination

> `[Screenshot: Profile page with settings options]`
> `[Screenshot: Settings — dark mode, notifications]`
> `[Screenshot: Referral code page]`

---

### 15. Notifications

Real-time push notifications:

- **Firebase Cloud Messaging** — Instant push notifications
- **Notification Inbox** — History of all received notifications
- **Badge Count** — Unread notification indicator on home screen
- **Local Notifications** — Reminders for upcoming appointments

> `[Screenshot: Notification inbox]`

---

### 16. Legal & Support

| Page | Description |
|---|---|
| **Privacy Policy** | In-app privacy policy document |
| **Terms & Conditions** | In-app terms of service |
| **Help / Support** | Help center with FAQs and contact info |
| **About** | App version, credits, and legal info |

> `[Screenshot: Settings — legal links (Privacy, Terms, About)]`

---

## Platform & Availability

| Detail | |
|---|---|
| **Platform** | iOS & Android (native) — also runs on Web, macOS, Windows, Linux |
| **Technology** | Flutter (cross-platform single codebase) |
| **Notifications** | Firebase Cloud Messaging + local notifications |
| **Payments** | Integrated payment gateway via webview |
| **Authentication** | Email/password with secure token management |
| **Dark Mode** | Full light/dark theme support |

---

## How It Connects to the Admin Portal

| Mobile App Feature | Admin Portal Counterpart |
|---|---|
| Book appointment | Appointment Management |
| Make payment | Payment Reports |
| Earn points | Points Management |
| Redeem rewards | Rewards + Redemption History |
| View promotions | Promotions Management |
| Use vouchers | Voucher Management |
| Receive notifications | Announcements |
| Update profile | Patient Management |
| Browse branches | Branch Management |
| View services | Services Management |

---

*This document is a reference overview. For a demo or deployment inquiry, contact us.*
