# Klinik Aurora Portal — Design System (`DESIGN.md`)

## 1. Brand Direction & Visual World
Klinik Aurora Portal is an **Operate-mode** clinical management interface used by reception staff, nurses, sonographers, and administrators across Klinik Aurora branches.
- **Navigation Chrome**: Deep Slate-Teal gradient (`#246E7A → #1B545E` in Light Mode; `#143C45 → #0D2830` in Dark Mode) anchors the persistent sidebar with calm clinical authority.
- **Default Primary Accent**: **Aurora Plum (`#7E2D40`)** — drawn directly from Klinik Aurora's brand identity and paired as a crisp split-complementary accent against the slate-teal sidebar (WCAG **AAA 9.2:1** with white ink).
- **Interactive User Customization**: Staff can live-switch between **Light / Dark / System** display modes and **6 WCAG-verified brand presets** via **Appearance & Theme** (accessible from Sidebar Footer, Top Bar, Profile Menu, and `⌘K` Command Palette). Selections persist via `Storage`.

---

## 2. Color Tokens (`lib/config/app_colors.dart` & `lib/config/color.dart`)

### Curated Brand Presets (`AuroraThemePreset`)
| Preset | Light Primary | Dark Primary | Dark Accessible Text | Contrast on White |
|---|---|---|---|---|
| **Aurora Plum** *(Default)* | `#7E2D40` | `#A83E58` | `#F3A6B9` | AAA 9.2:1 |
| **Aurora Berry** | `#9D2B54` | `#BE3C6B` | `#F5A3C3` | AAA 7.6:1 |
| **Aurora Petrol** | `#165E73` | `#1F7D99` | `#7DD3E8` | AAA 7.4:1 |
| **Clinical Teal** | `#0F766E` | `#159187` | `#5EEAD4` | AA 5.5:1 |
| **Aurora Indigo** | `#3730A3` | `#554CE0` | `#A5B4FC` | AAA 9.8:1 |
| **Aurora Emerald** | `#047857` | `#0B966E` | `#6EE7B7` | AA 5.5:1 |

### Semantic Surface, Border & Ink Tokens (`AppColors` ThemeExtension)
| Token | Light Mode | Dark Mode | Role |
|---|---|---|---|
| `canvas` / `appCanvas` | `#F6F8FA` | `#0B1217` | Page scaffold backdrop |
| `surface` / `appSurface` | `#FFFFFF` | `#111B22` | Cards, dialogs, tables, inputs |
| `surfaceSubtle` / `appSurfaceSubtle` | `#F1F5F9` | `#17242D` | Table headers, secondary chips, pills |
| `surfaceElevated` / `appSurfaceElevated` | `#FFFFFF` | `#1C2B36` | Menus, popovers, elevated sheets |
| `border` / `appBorder` | `#E2E8F0` | `#243644` | Dividers, card outlines |
| `borderStrong` / `appBorderStrong` | `#CBD5E1` | `#334B5E` | Input borders, secondary button strokes |
| `inkPrimary` / `appInkPrimary` | `#0F172A` | `#F1F5F9` | Primary headings & body copy (≥14:1) |
| `inkSecondary` / `appInkSecondary` | `#334155` | `#CBD5E1` | Labels, subheadings, secondary actions |
| `inkMuted` / `appInkMuted` | `#64748B` | `#94A3B8` | Metadata, hints, placeholders (≥4.6:1 AA) |

### Rules
- Never hardcode `Colors.white` for card/dialog/scaffold surfaces or `#0F172A`/`#64748B`/`#94A3B8` for text — always use `context.appColors.*` or `color.dart` semantic tokens.
- Keep `Colors.white` strictly for foreground text/icons over dark/filled surfaces (primary buttons, sidebar chrome, dark status pills).

---

## 3. Typography (`Figtree`)
- **Primary Typeface**: `Figtree` across all display, body, and label roles.
- **Scale**:
  - `displayLarge`: 28px Bold (`-0.5` tracking)
  - `displaySmall` / `titleLarge`: 24px SemiBold/Bold
  - `displayMedium`: 18px Bold
  - `bodyLarge`: 16px SemiBold
  - `bodyMedium`: 14px Regular
  - `bodySmall`: 12px Regular (`inkMuted`)
  - **Minimum Size Floor**: **11px** for badges/micro-chips; never use 8–10px labels.
- **No Gradient Text**: All headings use solid semantic ink or `brandText`.

---

## 4. Spacing, Elevation & Radius Contract
- **Controls, Inputs, Cards, Buttons**: `BorderRadius.circular(8)`
- **Dialog & Modal Shells**: `BorderRadius.circular(12)`
- **Pill Badges / Avatars**: `BorderRadius.circular(999)` or `BoxShape.circle`
- **Elevation**: Declare elevation once via `1px` `border` on flat surfaces; reserve soft shadows for overlays and modals only.

---

## 5. Accessibility, Responsiveness & Motion
- **Contrast**: WCAG 2.1 AA minimum (≥4.5:1 text, ≥3:1 UI controls) verified in both Light & Dark themes.
- **Reduced Motion**:
  - `EmilMotion`, `EmilPressable`, `EmilModalTransition`, `Button`, and `AppOutlinedButton` honor `MediaQuery.disableAnimationsOf(context)`.
  - `web/index.html` splash honors `@media (prefers-reduced-motion: reduce)` and `@media (prefers-color-scheme: dark)`.
- **Touch Targets**: Interactive icons and table row actions enforce `>=40×40px` hit boxes with `Tooltip` and `Semantics`.
- **Responsive Dialogs**: Never use raw fixed `width: 550+` on dialogs; always wrap with `ConstrainedBox(constraints: BoxConstraints(maxWidth: ...))` so narrow viewports never overflow.
