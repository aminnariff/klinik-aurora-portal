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

    expect(find.text('Welcome to'), findsOneWidget);
    expect(find.text('Klinik Aurora'), findsOneWidget);
    expect(find.byType(AppGlassCard), findsOneWidget);
    expect(find.byType(AuroraWaveMesh), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
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
}
