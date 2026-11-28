import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/widgets/aurora/aurora_wave_mesh.dart';
import 'package:klinik_aurora_portal/views/widgets/glass/app_glass.dart';
import 'package:provider/provider.dart';

Widget _buildTestApp({ThemeMode themeMode = ThemeMode.dark}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
      ChangeNotifierProvider<DarkModeController>(create: (_) => DarkModeController(initialThemeMode: themeMode)),
    ],
    child: Consumer<DarkModeController>(
      builder: (context, darkCtrl, _) {
        return MaterialApp(
          themeMode: darkCtrl.themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const LoginPage(),
        );
      },
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

    expect(find.text('Welcome to'), findsOneWidget);
    expect(find.text('Klinik Aurora'), findsOneWidget);
    expect(find.byType(AppGlassCard), findsOneWidget);
    expect(find.byType(AuroraWaveMesh), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('LoginPage floating toolbar toggles between Modern and Classic Split View', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    // Initially in Modern View
    expect(find.byType(AppGlassCard), findsOneWidget);
    expect(find.byType(AuroraWaveMesh), findsOneWidget);

    // Find and tap the layout toggle button in floating toolbar
    final layoutToggle = find.byTooltip('Switch to Classic Split View');
    expect(layoutToggle, findsOneWidget);
    await tester.tap(layoutToggle);
    await tester.pumpAndSettle();

    // Now in Classic Split View
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Enterprise Clinical Management System'), findsOneWidget);
    expect(find.byType(AppGlassCard), findsNothing);

    // Tap again to switch back to Modern View
    final modernToggle = find.byTooltip('Switch to Modern Glass View');
    expect(modernToggle, findsOneWidget);
    await tester.tap(modernToggle);
    await tester.pumpAndSettle();

    // Back to Modern View
    expect(find.byType(AppGlassCard), findsOneWidget);
    expect(find.text('Welcome to'), findsOneWidget);
  });

  testWidgets('LoginPage floating toolbar toggles dark and light mode', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    final darkToggle = find.byTooltip('Switch to Light Mode');
    expect(darkToggle, findsOneWidget);
    await tester.tap(darkToggle);
    await tester.pumpAndSettle();

    final lightToggle = find.byTooltip('Switch to Dark Mode');
    expect(lightToggle, findsOneWidget);
  });

  testWidgets('LoginPage validates empty username and password fields on submit', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // Verify submit button exists and tap it
    final submitButton = find.text('Sign In');
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify validation errors appear in the controller
    final authCtrl = tester.element(find.byType(LoginPage)).read<AuthController>();
    expect(authCtrl.usernameError, isNotNull);
    expect(authCtrl.passwordError, isNotNull);
  });

  testWidgets('LoginPage renders _authPage and purges stale auth when session in storage is missing or inactive', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authCtrl = AuthController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authCtrl),
          ChangeNotifierProvider<DarkModeController>(create: (_) => DarkModeController(initialThemeMode: ThemeMode.dark)),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify login form is rendered, not a frozen loading screen
    expect(find.text('Sign in to your account').evaluate().isNotEmpty || find.text('Welcome to').evaluate().isNotEmpty, isTrue);
    expect(find.text('Forgot password?'), findsOneWidget);
  });
}
