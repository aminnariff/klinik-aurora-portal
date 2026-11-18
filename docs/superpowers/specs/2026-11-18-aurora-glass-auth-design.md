# Design Specification: Klinik Aurora Premium Glassmorphic Auth & Ambient Wave Mesh

**Date:** 2026-11-18  
**Topic:** Aurora Glass Auth & Ambient Wave Mesh  
**Status:** Approved by User  
**Target Platform:** Web (Flutter Wasm/CanvasKit) & Responsive Mobile/Desktop  

---

## 1. Executive Summary & Goals

Transform the Klinik Aurora portal login experience into an ultra-premium, minimalist interface inspired by modern Antigravity / Gemini aesthetics:
* Centered floating brand glyph with ambient elevation.
* Frosted glassmorphic card container utilizing native `BackdropFilter` and hairline borders.
* Ambient undulating Aurora wave mesh with fine particle stippling at the bottom of the viewport.
* **Dual-Mode Perfection:** Seamless, gorgeous execution across both **Dark Mode** (deep obsidian `#070D12` with glowing cyan/plum wave) and **Light Mode** (clean surgical `#F8FAFC` with airy pastel aurora glow).
* **Zero-CPU Performance Guarantee:** Vector-calculated mesh rendered via single-pass `CustomPainter` with static caching (zero continuous render loop, 0% idle CPU/GPU consumption).
* **Complete E2E Business Logic Preservation:** 100% preservation of all existing `AuthController`, session timeout guards, error handling, password recovery, and login credentials.

---

## 2. Visual Architecture & Component Breakdown

```
┌─────────────────────────────────────────────────────────────┐
│  Canvas Surface (Dark: #070D12 · Light: #F8FAFC)           │
│                                                             │
│                      [ Floating Logo ]                      │
│                  Welcome to Klinik Aurora                   │
│                                                             │
│       ┌─────────────────────────────────────────────┐       │
│       │  Frosted Glass Card (BackdropFilter blur)   │       │
│       │  · Hairline border (1px translucent)        │       │
│       │  · Username / Email input                   │       │
│       │  · Password input + visibility toggle       │       │
│       │  · Remember me & Sign In CTA button         │       │
│       │  · Having trouble signing in? modal trigger │       │
│       └─────────────────────────────────────────────┘       │
│                                                             │
│   ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~   │
│  [ AuroraWaveMeshWidget (CustomPainter) ]                   │
│  · Multi-sine wave mesh + particle point grid               │
│  · Soft ambient radial bloom (Cyan #6AD1E3 + Plum #DF6E98)  │
└─────────────────────────────────────────────────────────────┘
```

### Component 1: `AuroraWaveMesh`
* **File:** `lib/views/widgets/aurora/aurora_wave_mesh.dart`
* **Purpose:** Renders the ambient glowing Aurora wave mesh with multi-layered sine curves and fine particle points along the bottom viewport.
* **Math Model:**
  $$y(x) = \text{baseY} + A_1 \sin(k_1 x + \phi_1) + A_2 \cos(k_2 x + \phi_2)$$
  Layered across 7 discrete wave depths. Each depth line is stippled with anti-aliased particle points using `Canvas.drawPoints(PointMode.points, ...)`.
* **Zero-CPU Mode:** Renders as a crisp static picture cached in `CustomPainter(shouldRepaint: false)`, incurring 0% GPU/CPU overhead when static.
* **Ambient Radial Bloom:** Soft multi-stop radial gradient centered below the card:
  * Dark: `#6AD1E3` (Cyan, 22% alpha) to `#DF6E98` (Plum Pink, 14% alpha) to transparent.
  * Light: `#D5F5FA` (Light Cyan, 30% alpha) to `#FCE4EC` (Blush Pink, 25% alpha) to transparent.

### Component 2: `AppGlass` Decorator & Container
* **File:** `lib/views/widgets/glass/app_glass.dart`
* **Purpose:** Provides reusable glassmorphic styling tokens and container widgets for cards, inputs, and buttons.
* **Specs:**
  * **Blur:** `ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0)`
  * **Dark Card Surface:** `Color(0xC7111B22)` (`rgba(17, 27, 34, 0.78)`)
  * **Light Card Surface:** `Color(0xE0FFFFFF)` (`rgba(255, 255, 255, 0.88)`)
  * **Dark Border:** `Border.all(color: Color(0x1AFFFFFF), width: 1.0)`
  * **Light Border:** `Border.all(color: Color(0x140F172A), width: 1.0)`
  * **Elevation Shadow:** Soft atmospheric blur (`blurRadius: 40`, `offset: Offset(0, 16)`).

### Component 3: Redesigned `LoginPage`
* **File:** `lib/views/login/login_page.dart`
* **Layout Structure:**
  * Fully responsive centered single-column layout (max card width: 400px on desktop; full bleed with 20px padding on mobile).
  * Brand Header: Floating brand logo in rounded container (`48x48`), headline "Welcome to Klinik Aurora", subtitle "Enterprise Healthcare Portal".
  * Form Fields: Styled input containers with clear labels, hint text, and visibility toggles.
  * Primary Button: High-contrast gradient button with gentle hover and press states.
  * Secondary Help Action: "Having trouble signing in?" triggers password reset / support bottom sheet or dialog.

---

## 3. Light & Dark Mode Color Token Specifications

| Token | Dark Mode (`isDark == true`) | Light Mode (`isDark == false`) |
| :--- | :--- | :--- |
| **Page Canvas** | `#070D12` (Obsidian) | `#F8FAFC` (Clean Studio) |
| **Glass Card Fill** | `rgba(17, 27, 34, 0.78)` | `rgba(255, 255, 255, 0.88)` |
| **Glass Card Border** | `rgba(255, 255, 255, 0.10)` | `rgba(15, 23, 42, 0.08)` |
| **Input Fill** | `rgba(14, 23, 30, 0.75)` | `rgba(241, 245, 249, 0.85)` |
| **Input Border** | `rgba(255, 255, 255, 0.12)` | `rgba(15, 23, 42, 0.12)` |
| **Wave Mesh Primary** | `#6AD1E3` (Cyan, 35% alpha) | `#007A93` (Deep Teal, 20% alpha) |
| **Wave Mesh Accent** | `#DF6E98` (Plum Pink, 40% alpha) | `#DF6E98` (Blush, 25% alpha) |
| **Radial Bloom** | Cyan/Plum glow (`#6AD1E3` / `#DF6E98`) | Soft pastel blush (`#D5F5FA` / `#FCE4EC`) |
| **Text Primary** | `#FFFFFF` (100% white) | `#0F172A` (Obsidian Ink) |
| **Text Muted** | `#94A3B8` (Slate 400) | `#64748B` (Slate 500) |
| **Primary Button** | `#7E2D40` to `#DF6E98` gradient | `#7E2D40` to `#DF6E98` gradient |

---

## 4. Performance, Isolation & Safety

1. **Zero-CPU Rendering:**
   * `CustomPainter.shouldRepaint` returns `false` during static view.
   * Mesh is isolated in its own `RepaintBoundary` so typing into username or password fields never triggers re-rendering of the wave or background.
2. **Reduced Motion Compliance:**
   * Checks `MediaQuery.disableAnimationsOf(context)` or `prefers-reduced-motion`.
   * When enabled, renders a clean, static, non-animated gradient backdrop without any motion or particle calculations.
3. **Responsive Scaling:**
   * On mobile screens ($< 600\text{px}$): Wave height scales gracefully from $260\text{px}$ to $180\text{px}$, leaving ample space for virtual software keyboards without layout overflow.
   * Wrapped in `SingleChildScrollView(physics: ClampingScrollPhysics())` to prevent pixel overflows when virtual keyboard opens.

---

## 5. Verification & Testing Strategy

1. **Unit & Widget Tests:**
   * `test/theme/aurora_wave_mesh_test.dart`: Verifies `AuroraWaveMesh` builds without errors in both Light and Dark modes and paints points accurately.
   * `test/theme/app_glass_test.dart`: Tests `AppGlass` decorations, border radii, and blur filters.
   * `test/features/login_page_redesign_test.dart`: Verifies:
     * Card rendering and floating logo.
     * Form validation (empty email, empty password).
     * Loading state during sign-in attempt.
     * Password recovery dialog popup.
2. **Static Analysis & Suite Runs:**
   * Run `flutter analyze` ensuring 0 warnings / 0 errors.
   * Run `flutter test` ensuring 100% of existing tests (104/104) plus new tests pass.
