# Aurora Glass Auth & Ambient Wave Mesh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Klinik Aurora web portal login experience into an ultra-premium, minimalist interface featuring an ambient glowing Aurora wave mesh, floating brand logo, and frosted glassmorphic card container with seamless Light and Dark mode rendering.

**Architecture:** A layered presentation architecture consisting of a high-performance `CustomPainter` wave mesh (`AuroraWaveMesh`), reusable frosted glass styling tokens (`AppGlass`), and an updated centered responsive `LoginPage` preserving 100% of existing `AuthController` session and validation logic.

**Tech Stack:** Flutter 3.47+ (Web Wasm / CanvasKit), Dart, Provider (`AuthController`, `DarkModeController`), GoRouter.

---

### Task 1: Reusable Glassmorphism Token & Container (`AppGlass`)

**Files:**
- Create: `lib/views/widgets/glass/app_glass.dart`
- Test: `test/theme/app_glass_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/theme/app_glass_test.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/widgets/glass/app_glass.dart';

void main() {
  testWidgets('AppGlass.card renders BackdropFilter with blur and border in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AppGlassCard(
            child: const Text('Test Glass Card'),
          ),
        ),
      ),
    );

    expect(find.text('Test Glass Card'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);

    final backdrop = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(backdrop.filter, isNotNull);
  });

  testWidgets('AppGlassCard adapts surface fill and border between light and dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: AppGlassCard(
            child: const Text('Light Glass Card'),
          ),
        ),
      ),
    );

    expect(find.text('Light Glass Card'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH="/Users/aminariff/fvm/versions/3.47.7/bin:$PATH" && flutter test test/theme/app_glass_test.dart`  
Expected: FAIL with compilation error: target file `app_glass.dart` not found.

- [ ] **Step 3: Implement `AppGlass` and `AppGlassCard`**

```dart
// lib/views/widgets/glass/app_glass.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable glassmorphic styling tokens and frosted container widgets.
class AppGlass {
  AppGlass._();

  /// Resolves frosted background fill based on brightness.
  static Color surfaceFill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xC7111B22) : const Color(0xE0FFFFFF);
  }

  /// Resolves hairline translucent border based on brightness.
  static Border hairlineBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Border.all(
      color: isDark ? const Color(0x1AFFFFFF) : const Color(0x140F172A),
      width: 1.0,
    );
  }

  /// Atmospheric elevation shadow for floating glass panels.
  static List<BoxShadow> elevationShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? const Color(0x66000000) : const Color(0x140F172A),
        blurRadius: 40,
        offset: const Offset(0, 16),
      ),
    ];
  }

  /// Input background fill for translucent form fields.
  static Color inputFill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xBF0E171E) : const Color(0xE6F8FAFC);
  }

  /// Input border for translucent form fields.
  static Border inputBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Border.all(
      color: isDark ? const Color(0x24FFFFFF) : const Color(0x1F0F172A),
      width: 1.0,
    );
  }
}

/// A frosted container with native [BackdropFilter], hairline border,
/// and atmospheric elevation shadows.
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final BoxConstraints? constraints;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 16.0,
    this.blurSigma = 18.0,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppGlass.elevationShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppGlass.surfaceFill(context),
              borderRadius: BorderRadius.circular(borderRadius),
              border: AppGlass.hairlineBorder(context),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH="/Users/aminariff/fvm/versions/3.47.7/bin:$PATH" && flutter test test/theme/app_glass_test.dart`  
Expected: PASS (2/2 tests pass).

- [ ] **Step 5: Commit**

```bash
git add lib/views/widgets/glass/app_glass.dart test/theme/app_glass_test.dart
git commit -m "feat(glass): add AppGlass tokens and frosted AppGlassCard widget"
```

---

### Task 2: Ambient Aurora Wave Mesh Widget (`AuroraWaveMesh`)

**Files:**
- Create: `lib/views/widgets/aurora/aurora_wave_mesh.dart`
- Test: `test/theme/aurora_wave_mesh_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/theme/aurora_wave_mesh_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/widgets/aurora/aurora_wave_mesh.dart';

void main() {
  testWidgets('AuroraWaveMesh paints wave mesh and ambient bloom in dark mode', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: AuroraWaveMesh(height: 260),
          ),
        ),
      ),
    );

    expect(find.byType(AuroraWaveMesh), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('AuroraWaveMesh paints wave mesh in light mode without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        themeMode: ThemeMode.light,
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: AuroraWaveMesh(height: 260),
          ),
        ),
      ),
    );

    expect(find.byType(AuroraWaveMesh), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH="/Users/aminariff/fvm/versions/3.47.7/bin:$PATH" && flutter test test/theme/aurora_wave_mesh_test.dart`  
Expected: FAIL with compilation error: target file `aurora_wave_mesh.dart` not found.

- [ ] **Step 3: Implement `AuroraWaveMesh`**

```dart
// lib/views/widgets/aurora/aurora_wave_mesh.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';

/// Ambient glowing wave mesh with multi-frequency harmonic sine waves
/// and precision particle points, optimized for zero idle CPU/GPU consumption.
class AuroraWaveMesh extends StatelessWidget {
  final double height;
  final bool isDark;

  const AuroraWaveMesh({
    super.key,
    this.height = 260,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final darkActive = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Soft Radial Bloom Glow behind the baseline
            Positioned(
              bottom: -40,
              left: 0,
              right: 0,
              height: height * 0.9,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomCenter,
                    radius: 0.9,
                    colors: darkActive
                        ? [
                            secondaryColor.withValues(alpha: 0.24),
                            brandPink.withValues(alpha: 0.14),
                            quaternaryColor.withValues(alpha: 0.05),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFFD5F5FA).withValues(alpha: 0.40),
                            const Color(0xFFFCE4EC).withValues(alpha: 0.30),
                            const Color(0xFFF3E8FF).withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                    stops: const [0.0, 0.40, 0.70, 1.0],
                  ),
                ),
              ),
            ),

            // High-precision vector wave mesh
            Positioned.fill(
              child: CustomPaint(
                painter: _AuroraMeshPainter(isDark: darkActive),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuroraMeshPainter extends CustomPainter {
  final bool isDark;

  const _AuroraMeshPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;
    const lines = 7;
    const pointsPerLine = 48;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..isAntiAlias = true;

    for (int l = 0; l < lines; l++) {
      final lineProgress = l / lines;

      // Color interpolation: Cyan into Plum/Pink
      final Color strokeColor;
      if (isDark) {
        final r = (106 + (117 * lineProgress)).round();
        final g = (209 - (99 * lineProgress)).round();
        final b = (227 - (75 * lineProgress)).round();
        final alpha = (0.16 + ((1.0 - lineProgress) * 0.42)).clamp(0.0, 1.0);
        strokeColor = Color.fromRGBO(r, g, b, alpha);
      } else {
        final r = (0 + (223 * lineProgress)).round();
        final g = (122 - (12 * lineProgress)).round();
        final b = (147 + (5 * lineProgress)).round();
        final alpha = (0.12 + ((1.0 - lineProgress) * 0.28)).clamp(0.0, 1.0);
        strokeColor = Color.fromRGBO(r, g, b, alpha);
      }

      basePaint.color = strokeColor;
      final path = Path();
      final particleOffsets = <Offset>[];

      for (int p = 0; p <= pointsPerLine; p++) {
        final normX = p / pointsPerLine;
        final x = normX * w;

        // Static multi-harmonic wave curve:
        // y(x) = baseY + A1 * sin(k1*x) + A2 * cos(k2*x)
        final wave1 = math.sin((normX * math.pi * 3.2) + (l * 0.55)) * (24 + (l * 2.5));
        final wave2 = math.cos((normX * math.pi * 5.4) + (l * 0.35)) * 14;
        final baseY = h - 18 - ((lines - l) * (h / (lines + 2.5)));
        final y = baseY + wave1 + wave2;

        if (p == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }

        if (p % 2 == 0) {
          particleOffsets.add(Offset(x, y));
        }
      }

      canvas.drawPath(path, basePaint);

      // Draw particle points
      final pointPaint = Paint()
        ..color = strokeColor.withValues(alpha: (strokeColor.a * 1.3).clamp(0.0, 1.0))
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawPoints(PointMode.points, particleOffsets, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraMeshPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH="/Users/aminariff/fvm/versions/3.47.7/bin:$PATH" && flutter test test/theme/aurora_wave_mesh_test.dart`  
Expected: PASS (2/2 tests pass).

- [ ] **Step 5: Commit**

```bash
git add lib/views/widgets/aurora/aurora_wave_mesh.dart test/theme/aurora_wave_mesh_test.dart
git commit -m "feat(aurora): add AuroraWaveMesh CustomPainter widget with dual-mode lighting"
```

---

### Task 3: Modern Centered Glassmorphic `LoginPage` Redesign

**Files:**
- Modify: `lib/views/login/login_page.dart`
- Test: `test/features/login_page_redesign_test.dart`

- [ ] **Step 1: Write the failing widget tests for redesigned LoginPage**

```dart
// test/features/login_page_redesign_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/widgets/aurora/aurora_wave_mesh.dart';
import 'package:klinik_aurora_portal/views/widgets/glass/app_glass.dart';
import 'package:provider/provider.dart';

Widget _buildTestApp({ThemeMode themeMode = ThemeMode.dark}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
    ],
    child: MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const LoginPage(),
    ),
  );
}

void main() {
  testWidgets('LoginPage renders floating brand logo, title, AppGlassCard, and AuroraWaveMesh', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Klinik Aurora'), findsOneWidget);
    expect(find.byType(AppGlassCard), findsOneWidget);
    expect(find.byType(AuroraWaveMesh), findsOneWidget);
    expect(find.text('Having trouble signing in?'), findsOneWidget);
  });

  testWidgets('LoginPage validates empty username and password fields on submit', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // Tap submit button without inputting text
    final submitButton = find.text('Sign In');
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify validation errors appear
    expect(find.textContaining('required'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH="/Users/aminariff/fvm/versions/3.47.7/bin:$PATH" && flutter test test/features/login_page_redesign_test.dart`  
Expected: FAIL because `AppGlassCard` and `AuroraWaveMesh` are not yet composed into `login_page.dart`.

- [ ] **Step 3: Update `lib/views/login/login_page.dart` with modern centered glassmorphic layout**

Refactor `login_page.dart` to:
1. Replace split-screen layout with a unified, responsive centered container.
2. Place `AuroraWaveMesh` at the bottom of the viewport inside the background `Stack`.
3. Wrap login form in `AppGlassCard(constraints: BoxConstraints(maxWidth: 400))` with floating logo and "Welcome to Klinik Aurora" header.
4. Provide styled username/email field and password field with visibility toggle and clean error labels.
5. Retain exact `AuthController.logIn`, session expiration handlers, remember-me persistence, and password reset sheet.

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH="/Users/aminariff/fvm/versions/3.47.7/bin:$PATH" && flutter test test/features/login_page_redesign_test.dart`  
Expected: PASS (2/2 tests pass).

- [ ] **Step 5: Commit**

```bash
git add lib/views/login/login_page.dart test/features/login_page_redesign_test.dart
git commit -m "feat(auth): redesign login page with floating logo, glassmorphic card, and ambient Aurora wave mesh"
```

---

### Task 4: Full Suite Verification & Wasm Production Build

**Files:**
- Test: All tests in `test/`
- Command: `flutter analyze` & `flutter test` & `flutter build web --wasm --release`

- [ ] **Step 1: Run static analysis across the entire project**

Run: `export PATH="/Users/aminariff/fvm/versions/3.47.7/bin:$PATH" && flutter analyze`  
Expected: `No issues found!`

- [ ] **Step 2: Run all unit and integration tests**

Run: `export PATH="/Users/aminariff/fvm/versions/3.47.7/bin:$PATH" && flutter test`  
Expected: `All tests passed!` (108/108 passing).

- [ ] **Step 3: Compile release Wasm bundle**

Run: `export PATH="/Users/aminariff/fvm/versions/3.47.7/bin:$PATH" && flutter build web --wasm --release`  
Expected: Clean compilation into `build/web/` with `main.dart.wasm`.

---

### Task 5: Deploy to Firebase Hosting Staging & End-to-End Verification

**Files:**
- Command: `firebase deploy --only hosting:staging --project klinik-aurora`

- [ ] **Step 1: Deploy release web build to Firebase Hosting staging**

Run: `firebase deploy --only hosting:staging --project klinik-aurora`  
Expected: `✔  Deploy complete! URL: https://stg-klinik-aurora.web.app`

- [ ] **Step 2: Verify live staging URL**

Run: `curl -sI https://stg-klinik-aurora.web.app/`  
Expected: HTTP 200 OK with `Cache-Control: no-cache, must-revalidate` headers.

- [ ] **Step 3: Git push to origin/main**

```bash
git push origin main
```
